import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/router/route_guard.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_state.dart';

const SessionState _guest = GuestSession();
const SessionState _unverified = AuthenticatedSession(
  ResidentSession(
    accountId: 'acct-sample',
    accessLevel: AccessLevel.unverified,
  ),
);
const SessionState _verified = AuthenticatedSession(
  ResidentSession(accountId: 'acct-sample', accessLevel: AccessLevel.verified),
);

void main() {
  test('every route declares whether it shows a back button', () {
    for (final route in AppRoute.values) {
      expect(
        route.showsBackButton,
        !AppRoute.navigationRoots.contains(route),
        reason: route.routeName,
      );
    }
  });

  test('approved tabs are recorded separately from the live shell', () {
    expect(AppRoute.designRootTabs, <AppRoute>[
      AppRoute.home,
      AppRoute.services,
      AppRoute.news,
      AppRoute.programs,
      AppRoute.profile,
    ]);
    expect(AppRoute.designRootTabs, isNot(contains(AppRoute.events)));
    expect(AppRoute.shellDestinations, contains(AppRoute.events));
  });

  test('new public routes stay reachable for a guest', () {
    for (final route in <AppRoute>[
      AppRoute.forgotPassword,
      AppRoute.hotlines,
      AppRoute.photoCredits,
    ]) {
      expect(
        resolveRedirect(session: _guest, location: route.path),
        isNull,
        reason: route.routeName,
      );
    }
    expect(
      resolveRedirect(session: _guest, location: '/offices/mswdo'),
      isNull,
    );
  });

  test('office messaging is verified-only', () {
    const locations = <String>[
      '/messages',
      '/messages/thread-sample-1',
      '/offices/mswdo/message',
      '/offices/mswdo/message/sent',
    ];
    for (final location in locations) {
      expect(
        resolveRedirect(session: _guest, location: location),
        contains(AppRoute.signIn.path),
        reason: location,
      );
      expect(
        resolveRedirect(session: _unverified, location: location),
        AppRoute.verification.path,
        reason: location,
      );
      expect(
        resolveRedirect(session: _verified, location: location),
        isNull,
        reason: location,
      );
    }
  });

  test('the component gallery is refused outside a dev build', () {
    for (final session in <SessionState>[_guest, _unverified, _verified]) {
      expect(
        resolveRedirect(
          session: session,
          location: AppRoute.componentGallery.path,
        ),
        AppRoute.home.path,
        reason: session.runtimeType.toString(),
      );
      expect(
        resolveRedirect(
          session: session,
          location: AppRoute.componentGallery.path,
          allowDevRoutes: true,
        ),
        isNull,
      );
    }
  });

  test('a restoring session still waits, including on the gallery', () {
    expect(
      resolveRedirect(
        session: const SessionRestoring(),
        location: AppRoute.componentGallery.path,
        allowDevRoutes: true,
      ),
      AppRoute.splash.path,
    );
  });

  test('non-root screens name the shared back button', () {
    const roots = <String>{
      'lib/features/home/presentation/home_screen.dart',
      'lib/features/services/presentation/services_screen.dart',
      'lib/features/news/presentation/news_screen.dart',
      'lib/features/events/presentation/events_screen.dart',
      'lib/features/profile/presentation/profile_screen.dart',
      'lib/features/onboarding/presentation/onboarding_screen.dart',
    };
    final missing = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final path = file.path.replaceAll('\\', '/');
      final source = file.readAsStringSync();
      if (!source.contains('AppBar(')) continue;
      if (roots.contains(path)) {
        if (!source.contains('automaticallyImplyLeading: false')) {
          missing.add('$path is a root and still implies a leading control');
        }
        continue;
      }
      if (!source.contains('TaytayBackButton')) {
        missing.add('$path has an AppBar and no TaytayBackButton');
      }
    }
    expect(missing, isEmpty, reason: missing.join('\n'));
  });
}
