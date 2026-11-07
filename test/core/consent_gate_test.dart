import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/router/route_guard.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/consent_gate_controller.dart';
import 'package:taytay_resident/core/session/session_controller.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/features/platform/domain/app_bootstrap.dart';
import 'package:taytay_resident/features/platform/domain/consent_review.dart';
import 'package:taytay_resident/features/platform/domain/platform_repository.dart';
import 'package:taytay_resident/features/settings/domain/account_controls.dart';

/// `GET /app/config`, answering in order and then repeating the last answer.
class FakeConfig implements PlatformRepository {
  FakeConfig(this.answers);

  final List<Result<AppBootstrap>> answers;
  int calls = 0;

  @override
  Future<Result<ServiceHealth>> checkHealth() async => const Ok<ServiceHealth>(
    ServiceHealth(service: 'taytay', status: 'ok', apiVersion: '1'),
  );

  @override
  Future<Result<AppBootstrap>> loadBootstrap() async {
    final int index = calls < answers.length ? calls : answers.length - 1;
    calls++;
    return answers[index];
  }
}

/// `GET` and `POST /me/consents` against an in-memory list.
class FakeConsents implements AccountControlsRepository {
  FakeConsents({List<String> accepted = const <String>[]})
    : held = <ConsentRecord>[for (final String v in accepted) record(v)];

  static ConsentRecord record(String version, {DateTime? withdrawnAt}) =>
      ConsentRecord(
        key: version,
        label: 'Privacy notice',
        statement: 'Agreed under privacy notice $version',
        grantedAt: DateTime.utc(2026, 10, 1),
        withdrawnAt: withdrawnAt,
        isWithdrawable: true,
      );

  final List<ConsentRecord> held;
  AppFailure? listFailure;

  /// Answers for `POST /me/consents`, used one at a time before the default.
  final List<Result<ConsentRecord>> acceptAnswers = <Result<ConsentRecord>>[];
  final List<String> posted = <String>[];
  int lists = 0;

  /// When set, a list read takes its snapshot now and answers later.
  Completer<void>? holdList;

  @override
  Future<Result<AccountControls>> loadControls() async =>
      const Ok<AccountControls>(AccountControls.none);

  @override
  Future<Result<List<ConsentRecord>>> listConsents() async {
    lists++;
    final AppFailure? failure = listFailure;
    if (failure != null) return Err<List<ConsentRecord>>(failure);
    final List<ConsentRecord> snapshot = List<ConsentRecord>.of(held);
    final Completer<void>? hold = holdList;
    if (hold != null) await hold.future;
    return Ok<List<ConsentRecord>>(snapshot);
  }

  @override
  Future<Result<ConsentRecord>> acceptConsent({required String version}) async {
    posted.add(version);
    if (acceptAnswers.isNotEmpty) return acceptAnswers.removeAt(0);
    final ConsentRecord accepted = record(version);
    held.add(accepted);
    return Ok<ConsentRecord>(accepted);
  }

  @override
  Future<Result<ConsentRecord>> withdrawConsent({
    required String key,
    required String idempotencyKey,
  }) async => const Err<ConsentRecord>(UnexpectedFailure());

  @override
  Future<Result<void>> requestDataCorrection({
    required String detail,
    required String idempotencyKey,
  }) async => const Ok<void>(null);

  @override
  Future<Result<void>> requestAccountClosure({
    required bool permanent,
    required String reason,
    required String idempotencyKey,
  }) async => const Ok<void>(null);
}

AppBootstrap versions({
  String terms = 'terms-2',
  String privacy = 'privacy-2',
}) => AppBootstrap(
  service: '',
  apiVersion: '',
  timezone: 'Asia/Manila',
  channel: 'citizen-mobile',
  defaultPageSize: 25,
  minimumVersion: '',
  features: FeatureFlags.none,
  support: SupportContact.none,
  termsVersion: terms,
  privacyVersion: privacy,
);

const ResidentSession _ana = ResidentSession(
  accountId: 'acct-sample-ana',
  accessLevel: AccessLevel.verified,
);
const ResidentSession _ben = ResidentSession(
  accountId: 'acct-sample-ben',
  accessLevel: AccessLevel.unverified,
);

/// Lets the unawaited check a session change starts run to its end.
Future<void> settle() async {
  for (int i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Rig {
  _Rig({required this.config, required this.consents, DateTime? start})
    : now = start ?? DateTime.utc(2026, 11, 7, 2) {
    gate = ConsentGateController(
      session: session,
      platform: config,
      consents: consents,
      clock: () => now,
    );
  }

  final SessionController session = SessionController(
    store: InMemorySessionStore(),
  );
  final FakeConfig config;
  final FakeConsents consents;
  late final ConsentGateController gate;
  DateTime now;

  Future<void> signIn([ResidentSession resident = _ana]) async {
    await session.signIn(resident: resident, accessToken: 'token-sample');
    await settle();
  }

  void dispose() {
    gate.dispose();
    session.dispose();
  }
}

void main() {
  group('the re-consent gate', () {
    test('a resident who accepted both versions is not asked', () async {
      final _Rig rig = _Rig(
        config: FakeConfig(<Result<AppBootstrap>>[
          Ok<AppBootstrap>(versions()),
        ]),
        consents: FakeConsents(accepted: <String>['terms-2', 'privacy-2']),
      );
      await rig.session.restore();
      await rig.signIn();
      expect(rig.gate.isRequired, isFalse);
      expect(rig.consents.lists, 1);
      rig.dispose();
    });

    test('a new version closes the gate on sign-in and says which', () async {
      final _Rig rig = _Rig(
        config: FakeConfig(<Result<AppBootstrap>>[
          Ok<AppBootstrap>(versions(terms: 'terms-3')),
        ]),
        consents: FakeConsents(accepted: <String>['terms-2', 'privacy-2']),
      );
      await rig.session.restore();
      expect(rig.gate.isRequired, isFalse, reason: 'a guest is never asked');
      await rig.signIn();
      expect(rig.gate.isRequired, isTrue);
      expect(rig.gate.review?.missing, <ConsentText>{ConsentText.termsOfUse});
      rig.dispose();
    });

    test('a failed config read never locks anybody out', () async {
      final _Rig rig = _Rig(
        config: FakeConfig(<Result<AppBootstrap>>[
          const Err<AppBootstrap>(TimeoutFailure()),
        ]),
        consents: FakeConsents(),
      );
      await rig.session.restore();
      await rig.signIn();
      expect(rig.gate.isRequired, isFalse);
      expect(rig.consents.lists, 0);
      rig.dispose();
    });

    test('a failed consents read never locks anybody out', () async {
      final _Rig rig = _Rig(
        config: FakeConfig(<Result<AppBootstrap>>[
          Ok<AppBootstrap>(versions(terms: 'terms-3')),
        ]),
        consents: FakeConsents()..listFailure = const NetworkFailure(),
      );
      await rig.session.restore();
      await rig.signIn();
      expect(rig.gate.isRequired, isFalse);

      // And the next return asks again: a failure is not remembered as an
      // answer, so the interval does not hold it back.
      rig.consents.listFailure = null;
      await rig.gate.checkOnResume();
      expect(rig.gate.isRequired, isTrue);
      rig.dispose();
    });

    test(
      'no version named means nothing to ask, and nothing looked up',
      () async {
        final _Rig rig = _Rig(
          config: FakeConfig(<Result<AppBootstrap>>[
            Ok<AppBootstrap>(versions(terms: '', privacy: '')),
          ]),
          consents: FakeConsents(),
        );
        await rig.session.restore();
        await rig.signIn();
        expect(rig.gate.isRequired, isFalse);
        expect(rig.consents.lists, 0);
        rig.dispose();
      },
    );

    test('agreeing records each missing version once, then opens', () async {
      final _Rig rig = _Rig(
        config: FakeConfig(<Result<AppBootstrap>>[
          Ok<AppBootstrap>(versions(terms: '2026-11', privacy: '2026-11')),
        ]),
        consents: FakeConsents(accepted: <String>['2026-10']),
      );
      await rig.session.restore();
      await rig.signIn();
      expect(rig.gate.review?.missing, hasLength(2));

      expect(await rig.gate.agree(), isTrue);
      expect(rig.consents.posted, <String>['2026-11']);
      expect(rig.gate.isRequired, isFalse);
      expect(rig.gate.recordFailure, isNull);
      rig.dispose();
    });

    test('a failed agreement is never reported as recorded', () async {
      final FakeConsents consents = FakeConsents(
        accepted: <String>['terms-2', 'privacy-2'],
      );
      final _Rig rig = _Rig(
        config: FakeConfig(<Result<AppBootstrap>>[
          Ok<AppBootstrap>(versions(terms: 'terms-3', privacy: 'privacy-3')),
        ]),
        consents: consents,
      );
      await rig.session.restore();
      await rig.signIn();

      // The Privacy Notice is recorded; the Terms time out.
      consents.acceptAnswers.addAll(<Result<ConsentRecord>>[
        Ok<ConsentRecord>(FakeConsents.record('privacy-3')),
        const Err<ConsentRecord>(TimeoutFailure()),
      ]);
      expect(await rig.gate.agree(), isFalse);
      expect(rig.gate.isRequired, isTrue);
      expect(rig.gate.recordFailure, isA<TimeoutFailure>());
      expect(rig.gate.recordFailure?.outcomeUnknown, isTrue);

      // Trying again sends only what is still unconfirmed.
      expect(await rig.gate.agree(), isTrue);
      expect(consents.posted, <String>['privacy-3', 'terms-3', 'terms-3']);
      rig.dispose();
    });

    test('a check read before the agreement does not close it again', () async {
      final FakeConsents consents = FakeConsents();
      final _Rig rig = _Rig(
        config: FakeConfig(<Result<AppBootstrap>>[
          Ok<AppBootstrap>(versions(terms: 'terms-3', privacy: '')),
        ]),
        consents: consents,
      );
      await rig.session.restore();
      await rig.signIn();
      expect(rig.gate.isRequired, isTrue);

      // A return to the app reads the list, and its answer is slow.
      final Completer<void> slow = Completer<void>();
      consents.holdList = slow;
      final Future<void> stale = rig.gate.check();
      await settle();

      expect(await rig.gate.agree(), isTrue);
      slow.complete();
      await stale;
      expect(rig.gate.isRequired, isFalse);
      rig.dispose();
    });

    test('an answer that does not confirm the version is a failure', () async {
      final FakeConsents consents = FakeConsents();
      final _Rig rig = _Rig(
        config: FakeConfig(<Result<AppBootstrap>>[
          Ok<AppBootstrap>(versions(terms: 'terms-3', privacy: '')),
        ]),
        consents: consents,
      );
      await rig.session.restore();
      await rig.signIn();
      consents.acceptAnswers.add(
        Ok<ConsentRecord>(
          FakeConsents.record('terms-3', withdrawnAt: DateTime.utc(2026, 11)),
        ),
      );
      expect(await rig.gate.agree(), isFalse);
      expect(rig.gate.isRequired, isTrue);
      expect(rig.gate.recordFailure, isA<ContractFailure>());
      rig.dispose();
    });

    test(
      'continuing for now opens without recording, and asks next time',
      () async {
        final FakeConsents consents = FakeConsents();
        final _Rig rig = _Rig(
          config: FakeConfig(<Result<AppBootstrap>>[
            Ok<AppBootstrap>(versions(terms: 'terms-3', privacy: '')),
          ]),
          consents: consents,
        );
        await rig.session.restore();
        await rig.signIn();

        // Not offered before anything failed.
        rig.gate.continueForNow();
        expect(rig.gate.isRequired, isTrue);

        consents.acceptAnswers.add(const Err<ConsentRecord>(NetworkFailure()));
        await rig.gate.agree();
        rig.gate.continueForNow();
        expect(rig.gate.isRequired, isFalse);
        expect(consents.held, isEmpty, reason: 'nothing was recorded');

        await rig.gate.checkOnResume();
        expect(rig.gate.isRequired, isTrue);
        rig.dispose();
      },
    );

    test('a return to the app asks again only after the interval', () async {
      final FakeConfig config = FakeConfig(<Result<AppBootstrap>>[
        Ok<AppBootstrap>(versions()),
        Ok<AppBootstrap>(versions(privacy: 'privacy-3')),
      ]);
      final _Rig rig = _Rig(
        config: config,
        consents: FakeConsents(accepted: <String>['terms-2', 'privacy-2']),
      );
      await rig.session.restore();
      await rig.signIn();
      expect(config.calls, 1);

      rig.now = rig.now.add(const Duration(minutes: 2));
      await rig.gate.checkOnResume();
      expect(config.calls, 1);
      expect(rig.gate.isRequired, isFalse);

      rig.now = rig.now.add(const Duration(minutes: 4));
      await rig.gate.checkOnResume();
      expect(config.calls, 2);
      expect(rig.gate.isRequired, isTrue);
      rig.dispose();
    });

    test(
      'signing out opens the gate; another account is asked afresh',
      () async {
        final FakeConsents consents = FakeConsents();
        final _Rig rig = _Rig(
          config: FakeConfig(<Result<AppBootstrap>>[
            Ok<AppBootstrap>(versions(terms: 'terms-3', privacy: '')),
          ]),
          consents: consents,
        );
        await rig.session.restore();
        await rig.signIn();
        expect(rig.gate.isRequired, isTrue);

        await rig.session.signOut();
        await settle();
        expect(rig.gate.isRequired, isFalse);
        expect(rig.gate.review, isNull);

        consents.held.add(FakeConsents.record('terms-3'));
        await rig.signIn(_ben);
        expect(rig.gate.isRequired, isFalse);
        expect(consents.lists, 2);
        rig.dispose();
      },
    );
  });

  group('the guard while a consent is owed', () {
    const SessionState guest = GuestSession();
    const SessionState unverified = AuthenticatedSession(_ben);
    const SessionState verified = AuthenticatedSession(_ana);

    test('a signed-in resident is sent to the consent screen, and back', () {
      for (final SessionState session in <SessionState>[unverified, verified]) {
        for (final String location in <String>[
          '/home',
          '/account',
          '/documents/mine',
          '/profile/settings',
        ]) {
          final String? redirect = resolveRedirect(
            session: session,
            location: location,
            consentRequired: true,
          );
          expect(
            redirect,
            '${AppRoute.consentUpdate.path}?from='
            '${Uri.encodeQueryComponent(location)}',
            reason: '$session $location',
          );
        }
      }
      expect(
        resolveRedirect(
          session: verified,
          location: '/consent-update?from=%2Fdocuments%2Fmine',
          consentRequired: true,
        ),
        isNull,
      );
      // Agreed: back to where they were going.
      expect(
        resolveRedirect(
          session: verified,
          location: '/consent-update?from=%2Fdocuments%2Fmine%2Fdr-sample-1',
        ),
        '/documents/mine/dr-sample-1',
      );
    });

    test('a guest is never asked, and browsing stays open', () {
      for (final String location in <String>['/home', '/services', '/news']) {
        expect(
          resolveRedirect(
            session: guest,
            location: location,
            consentRequired: true,
          ),
          isNull,
          reason: location,
        );
      }
      // A guest who lands on the consent screen goes home.
      expect(
        resolveRedirect(session: guest, location: '/consent-update'),
        AppRoute.home.path,
      );
    });

    test('registration and the other gates stay reachable', () {
      for (final AppRoute route in <AppRoute>[
        AppRoute.register,
        AppRoute.updateRequired,
        AppRoute.maintenance,
      ]) {
        expect(
          resolveRedirect(
            session: unverified,
            location: route.path,
            consentRequired: true,
          ),
          isNull,
          reason: route.routeName,
        );
      }
    });

    test('a return address outside the route table is not followed', () {
      // Only the path of a known route is kept: a host is dropped, and an
      // unknown path, the gate itself and sign-in all fall back to home.
      for (final String from in <String>[
        'https://evil.example/news',
        '/not-a-route',
        '/consent-update',
        '/sign-in',
      ]) {
        final String? redirect = resolveRedirect(
          session: verified,
          location: '/consent-update?from=${Uri.encodeQueryComponent(from)}',
        );
        expect(
          redirect,
          from.startsWith('https') ? AppRoute.news.path : AppRoute.home.path,
          reason: from,
        );
      }
      // A verified-only page is not where an unverified resident resumes.
      expect(
        resolveRedirect(
          session: unverified,
          location: '/consent-update?from=%2Fdigital-id',
        ),
        AppRoute.home.path,
      );
    });

    test('the update gate still comes first', () {
      expect(
        resolveRedirect(
          session: verified,
          location: '/home',
          consentRequired: true,
          mustUpgrade: true,
        ),
        AppRoute.updateRequired.path,
      );
    });
  });
}
