import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/router/route_guard.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/access_policy.dart';
import 'package:taytay_resident/core/session/session_state.dart';

const SessionState _restoring = SessionRestoring();
const SessionState _guest = GuestSession();
const SessionState _unverified = AuthenticatedSession(
  ResidentSession(accountId: 'a', accessLevel: AccessLevel.unverified),
);
const SessionState _verified = AuthenticatedSession(
  ResidentSession(accountId: 'a', accessLevel: AccessLevel.verified),
);

void main() {
  group('route table', () {
    test('every route has a unique path and name', () {
      final paths = AppRoute.values.map((r) => r.path).toSet();
      final names = AppRoute.values.map((r) => r.routeName).toSet();

      expect(paths, hasLength(AppRoute.values.length));
      expect(names, hasLength(AppRoute.values.length));
    });

    test('every path is absolute', () {
      for (final route in AppRoute.values) {
        expect(route.path.startsWith('/'), isTrue, reason: route.name);
      }
    });

    test('the credential route is verified-only', () {
      // An LGU credential is a statement about a person whose identity the
      // municipality has confirmed. Anything less is a defect.
      expect(AppRoute.digitalId.requirement, AccessRequirement.verified);
    });

    test('verification itself is reachable without being verified', () {
      // Otherwise an unverified resident could never become verified.
      expect(
        AppRoute.verification.requirement,
        AccessRequirement.authenticated,
      );
    });

    test('sign-in, onboarding and splash are public', () {
      for (final route in <AppRoute>[
        AppRoute.splash,
        AppRoute.onboarding,
        AppRoute.signIn,
      ]) {
        expect(route.requirement, AccessRequirement.public, reason: route.name);
      }
    });
  });

  group('resolveRedirect while the session is restoring', () {
    test('holds on the splash screen', () {
      expect(
        resolveRedirect(session: _restoring, location: AppRoute.splash.path),
        isNull,
      );
    });

    test('sends every other destination back to the splash screen', () {
      for (final route in AppRoute.values.where((r) => r != AppRoute.splash)) {
        expect(
          resolveRedirect(session: _restoring, location: route.path),
          AppRoute.splash.path,
          reason: route.name,
        );
      }
    });
  });

  group('resolveRedirect once the session is known', () {
    test('leaves the splash screen for home', () {
      for (final session in <SessionState>[_guest, _unverified, _verified]) {
        expect(
          resolveRedirect(session: session, location: AppRoute.splash.path),
          AppRoute.home.path,
        );
      }
    });

    test('a guest may browse public routes', () {
      for (final route in <AppRoute>[
        AppRoute.home,
        AppRoute.onboarding,
        AppRoute.signIn,
      ]) {
        expect(
          resolveRedirect(session: _guest, location: route.path),
          isNull,
          reason: route.name,
        );
      }
    });

    test('a guest is sent to sign in, keeping where they were going', () {
      final redirect = resolveRedirect(
        session: _guest,
        location: AppRoute.account.path,
      );

      expect(redirect, startsWith(AppRoute.signIn.path));
      final query = Uri.parse(redirect!).queryParameters;
      expect(query[AppRoute.redirectQueryParam], AppRoute.account.path);
    });

    test('an unverified resident asking for the ID lands on verification', () {
      expect(
        resolveRedirect(
          session: _unverified,
          location: AppRoute.digitalId.path,
        ),
        AppRoute.verification.path,
      );
    });

    test('a verified resident reaches every route directly', () {
      for (final route in AppRoute.values.where(
        (r) => r != AppRoute.splash && r != AppRoute.signIn,
      )) {
        expect(
          resolveRedirect(session: _verified, location: route.path),
          isNull,
          reason: route.name,
        );
      }
    });

    test('a signed-in resident is moved off the sign-in screen', () {
      expect(
        resolveRedirect(session: _verified, location: AppRoute.signIn.path),
        AppRoute.home.path,
      );
    });

    test('sign-in resumes the destination the resident was pushed off', () {
      final signInLocation =
          '${AppRoute.signIn.path}?${AppRoute.redirectQueryParam}='
          '${Uri.encodeQueryComponent(AppRoute.account.path)}';

      expect(
        resolveRedirect(session: _unverified, location: signInLocation),
        AppRoute.account.path,
      );
    });

    test(
      'a resumed destination the resident still cannot reach is dropped',
      () {
        final signInLocation =
            '${AppRoute.signIn.path}?${AppRoute.redirectQueryParam}='
            '${Uri.encodeQueryComponent(AppRoute.digitalId.path)}';

        expect(
          resolveRedirect(session: _unverified, location: signInLocation),
          AppRoute.home.path,
        );
      },
    );

    test('an external `from` target is never honoured', () {
      // Deep links reach this app from SMS, email and printed QR codes. A
      // redirect parameter is attacker-writable, so only known internal routes
      // may be resumed.
      for (final hostile in <String>[
        'https://evil.example/phish',
        '//evil.example',
        '/not-a-route',
        'javascript:alert(1)',
      ]) {
        final location =
            '${AppRoute.signIn.path}?${AppRoute.redirectQueryParam}='
            '${Uri.encodeQueryComponent(hostile)}';

        expect(
          resolveRedirect(session: _verified, location: location),
          AppRoute.home.path,
          reason: hostile,
        );
      }
    });

    test('query strings on a protected route do not defeat the guard', () {
      expect(
        resolveRedirect(
          session: _guest,
          location: '${AppRoute.digitalId.path}?share=true',
        ),
        startsWith(AppRoute.signIn.path),
      );
    });

    test('an unknown location is left for the not-found page', () {
      expect(
        resolveRedirect(session: _guest, location: '/does-not-exist'),
        isNull,
      );
    });
  });
}
