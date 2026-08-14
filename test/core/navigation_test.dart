import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/router/deep_link.dart';
import 'package:taytay_resident/core/router/route_guard.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/access_policy.dart';
import 'package:taytay_resident/core/session/resident_capability.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/features/shell/presentation/root_shell.dart';
import 'package:taytay_resident/features/shell/presentation/shell_destinations.dart';

SessionState guest() => const GuestSession();

SessionState unverified() => const AuthenticatedSession(
  ResidentSession(accountId: 'acct-1', accessLevel: AccessLevel.unverified),
);

SessionState verified() => const AuthenticatedSession(
  ResidentSession(accountId: 'acct-1', accessLevel: AccessLevel.verified),
);

const List<String> allSessionNames = <String>[
  'guest',
  'unverified',
  'verified',
];

List<SessionState> allSessions() => <SessionState>[
  guest(),
  unverified(),
  verified(),
];

void main() {
  group('the route table', () {
    test('every route declares a requirement and a unique name and path', () {
      final names = AppRoute.values.map((r) => r.routeName).toList();
      final paths = AppRoute.values.map((r) => r.path).toList();

      expect(names.toSet(), hasLength(names.length));
      expect(paths.toSet(), hasLength(paths.length));
      for (final route in AppRoute.values) {
        expect(route.path, startsWith('/'), reason: route.routeName);
      }
    });

    test('a parameterised route declares every segment it carries', () {
      for (final route in AppRoute.values) {
        final declared = RegExp(
          r':(\w+)',
        ).allMatches(route.path).map((m) => m.group(1)).toList();
        expect(
          route.parameters,
          orderedEquals(declared),
          reason: route.routeName,
        );
      }
    });

    test('an exact path beats a parameterised one', () {
      // `/news` must be the list, not a post whose id happens to be empty.
      expect(AppRoute.forPath('/news'), AppRoute.news);
      expect(AppRoute.forPath('/news/abc123'), AppRoute.newsPost);
      expect(AppRoute.forPath('/events'), AppRoute.events);
      expect(AppRoute.forPath('/events/e-1'), AppRoute.eventDetail);
      expect(AppRoute.forPath('/requests'), AppRoute.requests);
      expect(AppRoute.forPath('/requests/r-1'), AppRoute.requestDetail);
      expect(
        AppRoute.forPath('/requests/r-1/requirements'),
        AppRoute.requestRequirements,
      );
    });

    test('a parameter can never span a slash', () {
      // This is the single restriction that stops an identifier carrying its
      // own path and resolving to a route other than the one the guard saw.
      expect(AppRoute.forPath('/news/a/b'), isNull);
      expect(AppRoute.forPath('/news/../digital-id'), isNull);
    });

    test('an unknown path resolves to nothing', () {
      expect(AppRoute.forPath('/nope'), isNull);
      expect(AppRoute.forPath('/admin'), isNull);
      expect(AppRoute.forPath('/staff/queue'), isNull);
    });

    test('location() builds a concrete path and encodes the value', () {
      expect(
        AppRoute.newsPost.location(<String, String>{'postId': 'abc'}),
        '/news/abc',
      );
      expect(
        AppRoute.requestRequirements.location(<String, String>{
          'requestId': 'r-1',
        }),
        '/requests/r-1/requirements',
      );
      // A value that would otherwise change the shape of the path is encoded,
      // so it becomes a 404 instead of a different route.
      expect(
        AppRoute.newsPost.location(<String, String>{'postId': 'a/b'}),
        '/news/a%2Fb',
      );
    });

    test('parametersOf round-trips', () {
      expect(AppRoute.newsPost.parametersOf('/news/abc'), <String, String>{
        'postId': 'abc',
      });
      expect(AppRoute.newsPost.parametersOf('/events/abc'), isNull);
    });
  });

  group('no admin navigation — acceptance 1', () {
    /// Words that would indicate a staff surface had appeared.
    const forbidden = <String>[
      'admin',
      'staff',
      'moderat',
      'approve',
      'reject',
      'caseworker',
      'reviewer',
      'backoffice',
      'back-office',
      'console',
      'dashboard',
    ];

    test('no route name or path uses staff vocabulary', () {
      for (final route in AppRoute.values) {
        final text = '${route.routeName} ${route.path}'.toLowerCase();
        for (final word in forbidden) {
          expect(text, isNot(contains(word)), reason: '${route.name}/$word');
        }
      }
    });

    test('no capability uses staff vocabulary', () {
      for (final capability in ResidentCapability.values) {
        final text = '${capability.name} ${capability.label}'.toLowerCase();
        for (final word in forbidden) {
          expect(
            text,
            isNot(contains(word)),
            reason: '${capability.name}/$word',
          );
        }
      }
    });

    test('no shell destination uses staff vocabulary', () {
      for (final destination in ShellDestination.values) {
        final text = '${destination.name} ${destination.label}'.toLowerCase();
        for (final word in forbidden) {
          expect(text, isNot(contains(word)));
        }
      }
    });

    test('no deep-link target reaches a staff route', () {
      // Every target must resolve to a route in this app's own table, and that
      // table has no staff surface (asserted above).
      for (final target in <String>['admin', 'staff', 'console', 'queue']) {
        final result = DeepLink.resolve(<String, String>{'target': target});
        expect(result, isA<DeepLinkRejected>(), reason: target);
      }
    });

    test('no source file registers an admin route', () {
      final offenders = <String>[];
      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final source = file
            .readAsStringSync()
            .split('\n')
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');
        if (RegExp(r"""['"]/(admin|staff|console)""").hasMatch(source)) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('the shell is stable across access levels — acceptance 3', () {
    test('exactly five destinations, in a fixed order', () {
      expect(ShellDestination.values, hasLength(5));
      expect(
        ShellDestination.values.map((d) => d.route).toList(),
        orderedEquals(AppRoute.shellDestinations),
      );
      expect(
        ShellDestination.values.map((d) => d.label).toList(),
        orderedEquals(<String>[
          'Home',
          'Services',
          'News',
          'Events',
          'Profile',
        ]),
      );
    });

    test('every destination is reachable by every access level', () {
      // The bar does not change shape as a person's status changes, so every
      // destination route must be public. A destination that redirected would
      // be a tab that bounces.
      for (final destination in ShellDestination.values) {
        expect(
          destination.route.requirement,
          AccessRequirement.public,
          reason: destination.name,
        );
      }

      for (final session in allSessions()) {
        for (final destination in ShellDestination.values) {
          expect(
            resolveRedirect(session: session, location: destination.route.path),
            isNull,
            reason: '${destination.name} for ${session.accessLevel.name}',
          );
        }
      }
    });

    test('a branch route maps back to its destination', () {
      expect(ShellDestination.forLocation('/home'), ShellDestination.home);
      expect(ShellDestination.forLocation('/news'), ShellDestination.news);
      expect(ShellDestination.forLocation('/news/abc'), ShellDestination.news);
      expect(
        ShellDestination.forLocation('/events/e-1'),
        ShellDestination.events,
      );
      // Outside the shell entirely.
      expect(ShellDestination.forLocation('/sign-in'), isNull);
      expect(ShellDestination.forLocation('/digital-id'), isNull);
    });

    test('layout breakpoints follow the Material 3 window size classes', () {
      expect(ShellLayout.forWidth(320), ShellLayout.compact);
      expect(ShellLayout.forWidth(599), ShellLayout.compact);
      expect(ShellLayout.forWidth(600), ShellLayout.medium);
      expect(ShellLayout.forWidth(839), ShellLayout.medium);
      expect(ShellLayout.forWidth(840), ShellLayout.expanded);
      expect(ShellLayout.compact.usesRail, isFalse);
      expect(ShellLayout.medium.usesRail, isTrue);
    });
  });

  group('the capability service is the single evaluation', () {
    test('it agrees with AccessPolicy on every capability and session', () {
      for (final session in allSessions()) {
        for (final capability in ResidentCapability.values) {
          final verdict = CapabilityService.evaluate(
            session: session,
            capability: capability,
          );
          final decision = AccessPolicy.evaluate(
            session: session,
            requirement: capability.requirement,
          );
          // Same access answer, with availability layered on top.
          expect(
            verdict is CapabilityNeedsSignIn,
            decision is AccessNeedsAuthentication,
            reason: capability.name,
          );
          expect(
            verdict is CapabilityNeedsVerification,
            decision is AccessNeedsVerification,
            reason: capability.name,
          );
        }
      }
    });

    test('access is answered before availability', () {
      // A guest asking for a verified-only capability is told to sign in — not
      // that the feature is missing, which would be a different answer for
      // different people and would send them away instead of onward.
      final verdict = CapabilityService.evaluate(
        session: guest(),
        capability: ResidentCapability.trackAssistanceRequests,
      );
      expect(verdict, const CapabilityNeedsSignIn());
    });

    test('a verified resident meets the availability answer', () {
      expect(
        CapabilityService.evaluate(
          session: verified(),
          capability: ResidentCapability.trackAssistanceRequests,
        ),
        const CapabilityNotYetAvailable(),
      );
    });

    test('nothing is usable that the backend cannot serve', () {
      for (final capability in ResidentCapability.values) {
        final verdict = CapabilityService.evaluate(
          session: verified(),
          capability: capability,
        );
        if (verdict is CapabilityUsable) {
          expect(
            capability.availability,
            BackendAvailability.available,
            reason: capability.name,
          );
        }
      }
    });

    test('a guest can use only public, available capabilities', () {
      for (final capability in ResidentCapability.values) {
        final usable = CapabilityService.evaluate(
          session: guest(),
          capability: capability,
        ).isUsable;
        if (usable) {
          expect(
            capability.requirement,
            AccessRequirement.public,
            reason: capability.name,
          );
        }
      }
    });

    test('availability never blocks opening a screen that exists', () {
      // Regression. Treating "the backend is planned" as a reason to refuse
      // navigation hid working screens — the digital ID, verification, the
      // account — behind a generic message, replacing each screen's own honest
      // explanation with a worse one.
      for (final capability in ResidentCapability.values) {
        if (capability.route == null) continue;
        expect(
          CapabilityService.canOpen(
            session: verified(),
            capability: capability,
          ),
          isTrue,
          reason: capability.name,
        );
      }
    });

    test('canOpen still refuses on access, at every level', () {
      expect(
        CapabilityService.canOpen(
          session: guest(),
          capability: ResidentCapability.holdDigitalId,
        ),
        isFalse,
      );
      expect(
        CapabilityService.canOpen(
          session: unverified(),
          capability: ResidentCapability.holdDigitalId,
        ),
        isFalse,
      );
      expect(
        CapabilityService.canOpen(
          session: unverified(),
          capability: ResidentCapability.completeVerification,
        ),
        isTrue,
      );
      // Restoring is not "allowed".
      expect(
        CapabilityService.canOpen(
          session: const SessionRestoring(),
          capability: ResidentCapability.manageAccount,
        ),
        isFalse,
      );
    });

    test('a capability with no screen can never be opened', () {
      expect(ResidentCapability.viewHouseholdSummary.route, isNull);
    });

    test('the household summary is withheld, not faked', () {
      // The committed contract has no `/me/household` row; the only household
      // route is staff-scoped. Declaring the capability unavailable is the
      // honest state.
      expect(
        ResidentCapability.viewHouseholdSummary.availability,
        BackendAvailability.planned,
      );
      expect(
        CapabilityService.evaluate(
          session: verified(),
          capability: ResidentCapability.viewHouseholdSummary,
        ),
        const CapabilityNotYetAvailable(),
      );
    });
  });

  group('every gate has a recovery path — acceptance 2', () {
    test('every refusal, for every capability and session, offers a route', () {
      for (var i = 0; i < allSessions().length; i++) {
        final session = allSessions()[i];
        for (final capability in ResidentCapability.values) {
          final verdict = CapabilityService.evaluate(
            session: session,
            capability: capability,
          );
          if (verdict is CapabilityUsable || verdict is CapabilityPending) {
            continue;
          }
          expect(
            CapabilityService.recoveryRoute(verdict),
            isNotNull,
            reason: '${capability.name} / ${allSessionNames[i]}',
          );
          expect(
            CapabilityService.explain(verdict),
            isNotEmpty,
            reason: '${capability.name} / ${allSessionNames[i]}',
          );
          expect(
            CapabilityService.requirementLabel(verdict),
            isNotNull,
            reason: '${capability.name} / ${allSessionNames[i]}',
          );
        }
      }
    });

    test(
      'a recovery route is always reachable by the session that needs it',
      () {
        // A recovery that redirected would be a dead end wearing a button.
        expect(
          resolveRedirect(session: guest(), location: AppRoute.signIn.path),
          isNull,
        );
        expect(
          resolveRedirect(
            session: unverified(),
            location: AppRoute.verification.path,
          ),
          isNull,
        );
        expect(
          resolveRedirect(session: guest(), location: AppRoute.services.path),
          isNull,
        );
      },
    );

    test('no refusal message is empty or blames the resident', () {
      for (final verdict in <CapabilityVerdict>[
        const CapabilityNeedsSignIn(),
        const CapabilityNeedsVerification(),
        const CapabilityNotYetAvailable(),
      ]) {
        final copy = CapabilityService.explain(verdict).toLowerCase();
        expect(copy, isNotEmpty);
        for (final blame in <String>[
          'denied',
          'forbidden',
          'not allowed',
          'error',
          'invalid',
        ]) {
          expect(copy, isNot(contains(blame)), reason: blame);
        }
      }
    });
  });

  group('deep links resolve only where they should', () {
    test('every target the Master Command names is routable', () {
      const cases = <String, AppRoute>{
        'news_post': AppRoute.newsPost,
        'announcement': AppRoute.newsPost,
        'event': AppRoute.eventDetail,
        'assistance_request': AppRoute.requestDetail,
        'assistance_requirements': AppRoute.requestRequirements,
      };

      cases.forEach((target, route) {
        final result = DeepLink.resolve(<String, String>{
          'target': target,
          'id': 'abc-123',
        });
        expect(result, isA<DeepLinkResolved>(), reason: target);
        expect((result as DeepLinkResolved).target.route, route);
      });

      // Verification steps take no identifier.
      final verification = DeepLink.resolve(<String, String>{
        'target': 'verification',
      });
      expect(
        (verification as DeepLinkResolved).target.route,
        AppRoute.verification,
      );
    });

    test('a resolved target builds the location the router expects', () {
      final result =
          DeepLink.resolve(<String, String>{
                'target': 'assistance_requirements',
                'id': 'r-1',
              })
              as DeepLinkResolved;
      expect(result.target.location, '/requests/r-1/requirements');
      // The location a link produces must resolve back to the route the guard
      // will evaluate — otherwise access is decided for one screen and another
      // one opens.
      expect(
        AppRoute.forPath(result.target.location),
        AppRoute.requestRequirements,
      );
    });

    test('an unknown target is refused', () {
      expect(
        DeepLink.resolve(<String, String>{'target': 'mystery'}),
        isA<DeepLinkRejected>(),
      );
      expect(DeepLink.resolve(<String, String>{}), isA<DeepLinkRejected>());
      expect(
        DeepLink.resolve(<String, String>{'target': '  '}),
        isA<DeepLinkRejected>(),
      );
    });

    test('a link may never act on the resident behalf', () {
      for (final target in <String>[
        'submit_request',
        'cancel_request',
        'confirm',
        'acknowledge',
        'approve',
        'sign_out',
        'delete_account',
      ]) {
        final result = DeepLink.resolve(<String, String>{
          'target': target,
          'id': 'r-1',
        });
        expect(
          result,
          const DeepLinkRejected(DeepLinkRejection.actionNotPermitted),
          reason: target,
        );
      }
    });

    test('identifiers are bounded and cannot carry a path', () {
      for (final bad in <String>[
        '../digital-id',
        'a/b',
        'a b',
        'a?b=1',
        'a#b',
        'a%2Fb',
        'a.b',
        '',
      ]) {
        final result = DeepLink.resolve(<String, String>{
          'target': 'news_post',
          'id': bad,
        });
        expect(result, isA<DeepLinkRejected>(), reason: 'id="$bad"');
      }

      // 64 characters is the ceiling.
      expect(
        DeepLink.resolve(<String, String>{
          'target': 'news_post',
          'id': 'a' * 64,
        }),
        isA<DeepLinkResolved>(),
      );
      expect(
        DeepLink.resolve(<String, String>{
          'target': 'news_post',
          'id': 'a' * 65,
        }),
        const DeepLinkRejected(DeepLinkRejection.invalidIdentifier),
      );
    });

    test('arity is enforced in both directions', () {
      // A target that needs an id and did not get one.
      expect(
        DeepLink.resolve(<String, String>{'target': 'news_post'}),
        const DeepLinkRejected(DeepLinkRejection.wrongArity),
      );
      // An id on a target that takes none means the sender meant something else.
      expect(
        DeepLink.resolve(<String, String>{'target': 'news', 'id': 'abc'}),
        const DeepLinkRejected(DeepLinkRejection.wrongArity),
      );
    });

    test('a payload carrying personal data is refused outright', () {
      // Not sanitised — refused. A notification payload with a resident's name
      // in it has already been mishandled server-side, and silently dropping
      // the field would hide a contract breach.
      for (final key in <String>[
        'name',
        'address',
        'mobile_number',
        'philsys_number',
        'amount',
        'diagnosis',
        'remarks',
        'reviewer',
      ]) {
        final result = DeepLink.resolve(<String, String>{
          'target': 'news_post',
          'id': 'abc',
          key: 'anything',
        });
        expect(result, isA<DeepLinkRejected>(), reason: key);
      }
    });

    test('the refusal copy does not say whether the item exists', () {
      // Distinguishing "no such post" from "malformed id" tells whoever sent
      // the link whether their guess landed.
      expect(
        DeepLinkRejection.unknownTarget.residentMessage,
        DeepLinkRejection.invalidIdentifier.residentMessage,
      );
      expect(
        DeepLinkRejection.wrongArity.residentMessage,
        DeepLinkRejection.unknownTarget.residentMessage,
      );
    });

    test('an action refusal says what the app will not do', () {
      expect(
        DeepLinkRejection.actionNotPermitted.residentMessage,
        contains('never acts from a link'),
      );
    });
  });

  group('deep links are re-authorised by the guard', () {
    ({AppRoute route, String location}) resolved(String target, String id) {
      final result =
          DeepLink.resolve(<String, String>{'target': target, 'id': id})
              as DeepLinkResolved;
      return (route: result.target.route, location: result.target.location);
    }

    test(
      'a guest deep-linking into a request is sent to sign in, with return',
      () {
        final link = resolved('assistance_request', 'r-1');
        final redirect = resolveRedirect(
          session: guest(),
          location: link.location,
        );
        expect(redirect, startsWith(AppRoute.signIn.path));
        // The destination is preserved so they land there after signing in.
        expect(redirect, contains(Uri.encodeQueryComponent(link.location)));
      },
    );

    test('an unverified resident is sent to verification', () {
      final link = resolved('assistance_requirements', 'r-1');
      expect(
        resolveRedirect(session: unverified(), location: link.location),
        AppRoute.verification.path,
      );
    });

    test('a verified resident is allowed through', () {
      final link = resolved('assistance_request', 'r-1');
      expect(
        resolveRedirect(session: verified(), location: link.location),
        isNull,
      );
    });

    test('a public deep link opens for everyone, including a guest', () {
      final link = resolved('news_post', 'abc');
      for (final session in allSessions()) {
        expect(
          resolveRedirect(session: session, location: link.location),
          isNull,
          reason: session.accessLevel.name,
        );
      }
    });

    test('a deep link during session restore waits rather than refusing', () {
      // Deciding early is what signs a returning resident out on every cold
      // start, and a notification tap is exactly a cold start.
      final link = resolved('assistance_request', 'r-1');
      expect(
        resolveRedirect(
          session: const SessionRestoring(),
          location: link.location,
        ),
        AppRoute.splash.path,
      );
    });
  });
}
