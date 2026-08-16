import 'package:flutter/foundation.dart';

/// Where the OS notification permission stands.
enum PushPermission {
  /// Never asked. The only state in which asking is allowed.
  notRequested,

  granted,

  /// Refused. **Asking again is not possible on iOS and is hostile on
  /// Android**, so the app never re-prompts; it points at system settings.
  denied,

  /// No push on this platform or build.
  unsupported;

  bool get isGranted => this == PushPermission.granted;
}

/// Registering this device to receive notifications.
///
/// ---
///
/// **An interface with no plugin behind it yet, deliberately.** The
/// `Notification` module is `planned` in the committed boundary map: there is no
/// endpoint to register a token with, and nothing to send one. Adding a push SDK
/// now would mean shipping a third-party service that collects a device
/// identifier for a feature that cannot work — and on a government app, a
/// dependency that phones home before it does anything useful is the wrong
/// default.
///
/// So the seam exists, the permission timing is decided and tested, and the
/// implementation lands with the endpoint.
abstract interface class PushService {
  /// The current permission, without asking for it.
  Future<PushPermission> permission();

  /// Asks the OS. Only ever called through [PushPromptPolicy].
  Future<PushPermission> requestPermission();

  /// The device token, once permission is granted.
  ///
  /// Sent to the backend so the LGU can reach this device, and **never** logged
  /// or put in an analytics event: a push token is a stable device identifier.
  Future<String?> token();
}

/// Reports push as unavailable, and never prompts.
///
/// The shipped implementation until the `Notification` module exists, and the
/// default in tests.
class UnavailablePushService implements PushService {
  const UnavailablePushService();

  @override
  Future<PushPermission> permission() async => PushPermission.unsupported;

  @override
  Future<PushPermission> requestPermission() async =>
      PushPermission.unsupported;

  @override
  Future<String?> token() async => null;
}

/// Something a resident did that makes notifications worth having.
///
/// Each of these is a moment where the app has just created a thing the LGU will
/// send updates about — which is the only honest reason to ask for permission.
enum PushMoment {
  /// Submitted an assistance request.
  submittedAssistanceRequest,

  /// Sent a document the office was waiting for.
  submittedRequirement,

  /// Registered for an event.
  registeredForEvent,

  /// Sent identity documents for verification.
  submittedVerification,
}

/// When this app is allowed to ask for notification permission.
///
/// ---
///
/// ## The rule, and why it is a class rather than a comment
///
/// The Master Command says the prompt must come "at a meaningful moment, not
/// immediately on first frame". That is easy to agree with and easy to lose:
/// the prompt is one line, and the tempting place to put it is `initState` on
/// the root widget.
///
/// It matters because the permission is **one-shot**. On iOS a refusal is
/// permanent — the app cannot ask again, and the resident has to find it in
/// Settings. So a prompt fired before the app has done anything for them is not
/// merely rude; it spends the only chance the LGU has to reach that person
/// about a case they have not yet opened. The people most likely to dismiss a
/// cold prompt are the people least familiar with the app, who are the people
/// most in need of being told their assistance was approved.
///
/// So the decision is a pure function, with tests, rather than a convention
/// somebody remembers.
abstract final class PushPromptPolicy {
  /// Whether to ask, given what has happened.
  ///
  /// Asks only when **all** of these hold:
  ///
  /// * the resident has just completed something the LGU will follow up on;
  /// * the OS has never been asked (a refusal is final, and a grant needs
  ///   nothing);
  /// * this app has not already asked during this install.
  static bool shouldPrompt({
    required PushMoment? moment,
    required PushPermission permission,
    required bool hasPromptedBefore,
  }) {
    if (moment == null) return false;
    if (hasPromptedBefore) return false;
    return permission == PushPermission.notRequested;
  }

  /// Why the app wants permission, in the resident's terms.
  ///
  /// Shown **before** the OS dialog, so the one-shot system prompt is answered
  /// by somebody who knows what it is for. Naming the thing they just did is
  /// what makes it a reason rather than a demand.
  static String reasonFor(PushMoment moment) => switch (moment) {
    PushMoment.submittedAssistanceRequest =>
      'Taytay LGU can tell you when your application moves — approved, waiting '
          'for a document, or ready to collect — instead of you checking back.',
    PushMoment.submittedRequirement =>
      'Taytay LGU can tell you when the office has checked your document, so '
          'you know whether anything else is needed.',
    PushMoment.registeredForEvent =>
      'Taytay LGU can remind you before this event, and tell you if it is moved '
          'or cancelled.',
    PushMoment.submittedVerification =>
      'Taytay LGU can tell you as soon as your identity is confirmed, which is '
          'what unlocks the rest of the app.',
  };
}

/// A push payload as it arrives from the OS.
///
/// ---
///
/// **Carries a destination, never content the app trusts.** The Master Command
/// requires that authorized detail be fetched after the tap rather than read
/// from the payload, and this type is where that is enforced: it exposes the
/// key-value map for `DeepLink` to resolve and offers nothing that a screen
/// could render directly.
///
/// The reason is not only trust. A notification is stored by the OS, shown on a
/// lock screen, and often mirrored to a watch or a car display — anything
/// readable there has been disclosed to whoever is standing nearby.
@immutable
class PushPayload {
  const PushPayload(this.data);

  /// The raw key-value data. Handed to `DeepLink.resolve`, which rejects
  /// personal keys outright rather than sanitising them.
  final Map<String, String> data;

  /// Redacted wholesale. Even the keys are not logged: a payload that wrongly
  /// carried a personal field would otherwise be copied into a log by the very
  /// code meant to catch it.
  @override
  String toString() => 'PushPayload(${data.length} keys)';
}
