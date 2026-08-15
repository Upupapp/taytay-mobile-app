import 'package:flutter/foundation.dart';

import 'app_routes.dart';

/// Why a deep link could not be opened.
enum DeepLinkRejection {
  /// The target names nothing this build knows. A newer server, a typo, or a
  /// link for a feature this app version does not have.
  unknownTarget,

  /// The identifier is missing, empty, over-long, or contains characters an
  /// opaque server id never contains.
  invalidIdentifier,

  /// The target needs an identifier and none was supplied, or supplied one it
  /// does not take.
  wrongArity,

  /// The link asked the app to *do* something rather than open something.
  actionNotPermitted;

  /// Resident-facing copy. Deliberately the same for the first three.
  ///
  /// A link that arrived by SMS or push and does not work is one situation from
  /// the resident's side, and distinguishing "no such post" from "malformed id"
  /// tells whoever sent the link whether their guess landed. The app is not an
  /// oracle for what exists.
  String get residentMessage => switch (this) {
    unknownTarget || invalidIdentifier || wrongArity =>
      'That link could not be opened. It may be for a newer version of the '
          'app, or the item may no longer be available.',
    actionNotPermitted =>
      'That link tried to do something on your behalf. Taytay LGU IDS never '
          'acts from a link — open the item and choose for yourself.',
  };
}

/// A deep link that resolved to a real destination.
@immutable
class DeepLinkTarget {
  const DeepLinkTarget({required this.route, required this.arguments});

  final AppRoute route;
  final Map<String, String> arguments;

  /// The concrete location to navigate to.
  String get location => route.location(arguments);

  /// Redacted: an identifier is opaque but still names a record this resident
  /// interacted with, which is a fact about them.
  @override
  String toString() => 'DeepLinkTarget(${route.routeName})';
}

/// The outcome of resolving a deep link.
@immutable
sealed class DeepLinkResult {
  const DeepLinkResult();
}

final class DeepLinkResolved extends DeepLinkResult {
  const DeepLinkResolved(this.target);

  final DeepLinkTarget target;

  @override
  String toString() => 'DeepLinkResolved(${target.route.routeName})';
}

final class DeepLinkRejected extends DeepLinkResult {
  const DeepLinkRejected(this.reason);

  final DeepLinkRejection reason;

  @override
  String toString() => 'DeepLinkRejected(${reason.name})';
}

/// Turns a notification payload into a destination — or refuses.
///
/// ---
///
/// ## What arrives here
///
/// A push notification, an SMS link or a printed QR code. All three are
/// **attacker-writable**: anyone who can send a resident a message can put a
/// string in front of this function. It is therefore treated as untrusted input
/// in the same way a request body is, and every rule below exists because the
/// alternative had a specific failure.
///
/// ## The rules
///
/// 1. **An allow-list of targets, not a path.** The payload names a *target*
///    (`news_post`, `event`, `assistance_request`) and this maps it to a route.
///    Accepting a path directly would mean the server — or anyone imitating it —
///    choosing which screen opens, including screens added in later versions
///    that were never meant to be linkable.
///
/// 2. **One bounded identifier, validated.** At most 64 characters of
///    `[A-Za-z0-9_-]`. That excludes `/`, `.`, `%`, `?` and `#`, so an
///    identifier cannot carry a path segment, traverse upward, smuggle a query
///    string, or reach a different route than the one whose access was
///    evaluated.
///
/// 3. **No personal data in a link, ever.** The payload carries an opaque id and
///    nothing else — no name, no address, no case detail, no status. A
///    notification is stored by the OS, shown on a lock screen, and often
///    mirrored to a watch or a car display. Anything readable there has been
///    disclosed to whoever is standing nearby. A rejected key set enforces it.
///
/// 4. **Links open; they never act.** There is no target that submits, cancels,
///    confirms or acknowledges. A link that could act is a link that can be
///    forged into acting, and the resident would never see the request that was
///    made in their name.
///
/// 5. **Authorization is re-run afterwards, by the guard.** This function
///    decides *where*, never *whether*. The router's `resolveRedirect` evaluates
///    the resolved route's requirement against the live session, so a deep link
///    into a verified-only screen is gated exactly as a tap would be — including
///    on a cold start, before any shell has been built.
abstract final class DeepLink {
  /// Payload key naming the destination.
  static const String targetKey = 'target';

  /// Payload key carrying the opaque identifier.
  static const String idKey = 'id';

  /// Identifiers this app is willing to carry.
  ///
  /// The same conservative shape `ResidentIntent` uses, for the same reason and
  /// so that the two cannot disagree about what an id may look like.
  static final RegExp identifierPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  /// Keys that must never appear in a notification payload.
  ///
  /// Not sanitised — *rejected*. A payload carrying a resident's name has
  /// already been mishandled server-side, and quietly dropping the field would
  /// hide a contract breach that needs fixing at the source.
  static const Set<String> forbiddenKeys = <String>{
    'name',
    'full_name',
    'first_name',
    'last_name',
    'address',
    'birth_date',
    'mobile_number',
    'email',
    'philsys_number',
    'household_id',
    'amount',
    'diagnosis',
    'sector',
    'remarks',
    'notes',
    'reviewer',
    'assessment',
  };

  /// The targets a notification may name, and where each goes.
  ///
  /// Every one of these is a *place*, and every one is reachable by tapping
  /// through the app as well. A deep link is a shortcut to somewhere a resident
  /// could already have gone, never a door of its own.
  static const Map<String, AppRoute> _targets = <String, AppRoute>{
    // Exact Newsfeed post.
    'news_post': AppRoute.newsPost,
    'announcement': AppRoute.newsPost,
    // Events.
    'events': AppRoute.events,
    'event': AppRoute.eventDetail,
    // Assistance request and its status.
    'assistance_requests': AppRoute.requests,
    'assistance_request': AppRoute.requestDetail,
    // Outstanding requirements on a request.
    'assistance_requirements': AppRoute.requestRequirements,
    // Verification steps.
    'verification': AppRoute.verification,
    // Programs and services directory.
    'service': AppRoute.serviceDetail,
    'programs': AppRoute.programs,
    'program': AppRoute.programDetail,
    // Generic landing places.
    'news': AppRoute.news,
    'services': AppRoute.services,
    'home': AppRoute.home,
  };

  /// Target names that would perform an action rather than open a screen.
  ///
  /// Listed so the refusal is explicit and testable rather than incidental. If
  /// the notification service ever starts sending one of these, this app says no
  /// loudly instead of silently ignoring it.
  static const Set<String> _actionTargets = <String>{
    'submit_request',
    'cancel_request',
    'confirm',
    'acknowledge',
    'approve',
    'sign_out',
    'delete_account',
  };

  /// Resolves a notification payload.
  static DeepLinkResult resolve(Map<String, String> payload) {
    for (final key in payload.keys) {
      if (forbiddenKeys.contains(key.toLowerCase())) {
        return const DeepLinkRejected(DeepLinkRejection.unknownTarget);
      }
    }

    final target = payload[targetKey]?.trim().toLowerCase();
    if (target == null || target.isEmpty) {
      return const DeepLinkRejected(DeepLinkRejection.unknownTarget);
    }
    if (_actionTargets.contains(target)) {
      return const DeepLinkRejected(DeepLinkRejection.actionNotPermitted);
    }

    final route = _targets[target];
    if (route == null) {
      return const DeepLinkRejected(DeepLinkRejection.unknownTarget);
    }

    final id = payload[idKey]?.trim();

    if (!route.isParameterised) {
      // An id on a route that takes none is not merely useless — it means the
      // sender believed they were linking somewhere else.
      if (id != null && id.isNotEmpty) {
        return const DeepLinkRejected(DeepLinkRejection.wrongArity);
      }
      return DeepLinkResolved(
        DeepLinkTarget(route: route, arguments: const <String, String>{}),
      );
    }

    if (id == null || id.isEmpty) {
      return const DeepLinkRejected(DeepLinkRejection.wrongArity);
    }
    if (!identifierPattern.hasMatch(id)) {
      return const DeepLinkRejected(DeepLinkRejection.invalidIdentifier);
    }

    return DeepLinkResolved(
      DeepLinkTarget(
        route: route,
        arguments: <String, String>{
          for (final name in route.parameters) name: id,
        },
      ),
    );
  }

  /// Whether an identifier taken from a resolved route is safe to use.
  ///
  /// Called by the screens themselves, because a path can also be typed or
  /// pasted rather than arriving through [resolve]. Same rule, one definition.
  static bool isValidIdentifier(String? value) =>
      value != null && identifierPattern.hasMatch(value);
}
