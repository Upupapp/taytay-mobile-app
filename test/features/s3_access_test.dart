import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/router/route_guard.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/access_policy.dart';
import 'package:taytay_resident/core/session/session_state.dart';

const SessionState _guest = GuestSession();
const SessionState _unverified = AuthenticatedSession(
  ResidentSession(accountId: 'a', accessLevel: AccessLevel.unverified),
);
const SessionState _verified = AuthenticatedSession(
  ResidentSession(accountId: 'a', accessLevel: AccessLevel.verified),
);

/// Routes the S3 sign-off matrix has to cover: verification, household, and
/// the digital ID. Matched by path prefix so a new nested screen is included
/// the day it is added to the table.
List<AppRoute> get _matrixRoutes => AppRoute.values
    .where(
      (AppRoute route) =>
          route.path.startsWith('/verification') ||
          route.path.startsWith('/household') ||
          route.path == '/digital-id',
    )
    .toList(growable: false);

void main() {
  test('the matrix names every verification, household and ID route', () {
    final paths = _matrixRoutes.map((AppRoute route) => route.path).toSet();
    expect(paths, containsAll(<String>[
      '/verification',
      '/verification/start',
      '/verification/profile',
      '/verification/profile/personal',
      '/verification/profile/address',
      '/verification/profile/review',
      '/verification/profile/submitted',
      '/household',
      '/household/correction',
      '/digital-id',
    ]));
    expect(paths.length, greaterThanOrEqualTo(10));
  });

  test('verification routes are authenticated and the others are verified', () {
    for (final AppRoute route in _matrixRoutes) {
      if (route.path.startsWith('/verification')) {
        expect(
          route.requirement,
          AccessRequirement.authenticated,
          reason: route.path,
        );
      } else {
        expect(
          route.requirement,
          AccessRequirement.verified,
          reason: route.path,
        );
      }
    }
  });

  group('access matrix', () {
    for (final AppRoute route in _matrixRoutes) {
      test('${route.path} × guest, unverified, verified', () {
        final guest = resolveRedirect(session: _guest, location: route.path);
        expect(guest, startsWith(AppRoute.signIn.path), reason: 'guest');
        expect(
          Uri.parse(guest!).queryParameters[AppRoute.redirectQueryParam],
          route.path,
        );

        final unverified = resolveRedirect(
          session: _unverified,
          location: route.path,
        );
        if (route.requirement == AccessRequirement.verified) {
          expect(
            unverified,
            AppRoute.verification.path,
            reason: 'unverified is denied',
          );
        } else {
          expect(unverified, isNull, reason: 'unverified may open it');
        }

        expect(
          resolveRedirect(session: _verified, location: route.path),
          isNull,
          reason: 'verified reaches it',
        );
      });
    }

    test('an unknown tier is unverified, so the ID stays denied', () {
      expect(
        AccessLevel.fromVerificationTier('gold'),
        AccessLevel.unverified,
      );
      const unknown = AuthenticatedSession(
        ResidentSession(accountId: 'a', accessLevel: AccessLevel.unverified),
      );
      expect(
        resolveRedirect(session: unknown, location: AppRoute.digitalId.path),
        AppRoute.verification.path,
      );
      expect(
        resolveRedirect(
          session: unknown,
          location: AppRoute.household.path,
        ),
        AppRoute.verification.path,
      );
    });
  });
}
