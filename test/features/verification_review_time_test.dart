import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/platform_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/mock_data/data/mock/resident_record_mock.dart';
import 'package:taytay_resident/features/platform/data/platform_api_repository.dart';
import 'package:taytay_resident/features/platform/domain/app_bootstrap.dart';
import 'package:taytay_resident/features/platform/domain/platform_repository.dart';
import 'package:taytay_resident/features/platform/domain/verification_review_time.dart';
import 'package:taytay_resident/features/verification/presentation/profile_wizard_page.dart';
import 'package:taytay_resident/features/verification/presentation/profile_wizard_screen.dart';
import 'package:taytay_resident/features/verification/presentation/review_time_copy.dart';
import 'package:taytay_resident/features/verification/presentation/verification_status_pages.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/s3_surface.dart';

import '../support/layout_matrix.dart';

/// The ID review time the office sets from the console (D-200, backend
/// `39d650b`): `verification_review_working_days` on `GET /app/config`.
///
/// Three cases, and every layer is held to all three: a range, `null` (the
/// office states no review time, so the sentence goes), and absent or
/// malformed (an older server, or nothing read yet: the copy this build
/// shipped with stays).

/// Answers every request with the next scripted response.
class _Scripted implements ApiTransport {
  _Scripted(this.responses);

  final List<Result<ApiHttpResponse>> responses;

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async =>
      responses.isEmpty
      ? const Err<ApiHttpResponse>(NetworkFailure())
      : responses.removeAt(0);
}

/// A platform repository that answers from a list, then fails.
class _Sequence implements PlatformRepository {
  _Sequence(this.answers);

  final List<AppBootstrap> answers;

  @override
  Future<Result<AppBootstrap>> loadBootstrap() async => answers.isEmpty
      ? const Err<AppBootstrap>(NetworkFailure(debugMessage: 'offline'))
      : Ok<AppBootstrap>(answers.removeAt(0));

  @override
  Future<Result<ServiceHealth>> checkHealth() async =>
      const Err<ServiceHealth>(NetworkFailure(debugMessage: 'not used here'));
}

AppConfig _config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

ApiClient _client(ApiTransport transport) => ApiClient(
  config: _config(),
  transport: transport,
  accessTokenProvider: () async => null,
);

/// `GET /app/config` data shaped like the vendored contract, with the review
/// time as given. [omit] leaves the key out, as an older server does.
Map<String, Object?> _configData(Object? reviewTime, {bool omit = false}) =>
    <String, Object?>{
      'contact_line': null,
      'support_email': null,
      'privacy_version': '2026-03-privacy',
      'terms_version': '2026-03-terms',
      'minimum_app_version': null,
      if (!omit) 'verification_review_working_days': reviewTime,
      'feature_flags': <String, Object?>{},
      'privacy_notice': null,
      'terms': null,
      'updated_at': '2026-11-11T00:00:00.000Z',
    };

Future<VerificationReviewTime> _decode(
  Object? reviewTime, {
  bool omit = false,
}) async {
  final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
    Ok<ApiHttpResponse>(
      ApiHttpResponse(
        statusCode: 200,
        body: jsonEncode(<String, Object?>{
          'data': _configData(reviewTime, omit: omit),
          'meta': <String, Object?>{'request_id': 'req-1'},
        }),
        headers: const <String, String>{'x-request-id': 'req-1'},
      ),
    ),
  ]);
  final Result<AppBootstrap> result = await PlatformApiRepository(
    apiClient: _client(transport),
  ).loadBootstrap();
  return switch (result) {
    Ok<AppBootstrap>(:final AppBootstrap value) => value.verificationReviewTime,
    Err<AppBootstrap>(:final AppFailure failure) => throw TestFailure(
      'app/config did not decode: $failure',
    ),
  };
}

AppBootstrap _bootstrap(VerificationReviewTime reviewTime) => AppBootstrap(
  service: '',
  apiVersion: '',
  timezone: 'Asia/Manila',
  channel: 'citizen-mobile',
  defaultPageSize: 25,
  minimumVersion: '',
  features: FeatureFlags.none,
  support: SupportContact.none,
  verificationReviewTime: reviewTime,
);

const String _pendingLead =
    'Taytay LGU staff are checking your valid ID and selfie.';

/// The pending page's paragraph as it read before the setting existed.
const String _pendingToday =
    'Taytay LGU staff are checking your valid ID and selfie. This usually '
    'takes 1–3 working days. No action needed.';

/// The three cases, with what each page must then say.
const List<(String, VerificationReviewTime, String, String)> _cases =
    <(String, VerificationReviewTime, String, String)>[
      (
        'a range the office set',
        ReviewTimeStated(2, 5),
        '$_pendingLead This usually takes 2–5 working days. No action needed.',
        'Usually 2–5 working days',
      ),
      (
        'no review time stated',
        VerificationReviewTime.notStated,
        '$_pendingLead No action needed.',
        '',
      ),
      (
        'nothing sent',
        VerificationReviewTime.notSent,
        _pendingToday,
        'Usually 1–3 working days',
      ),
    ];

void main() {
  final AppStrings english = lookupAppStrings(AppLocales.english);
  final AppStrings filipino = lookupAppStrings(AppLocales.filipino);

  group(
    'the parser reads absent, null, a range, and refuses the malformed',
    () {
      test(
        'an absent key is not sent: an older server keeps today\'s copy',
        () async {
          expect(
            await _decode(null, omit: true),
            VerificationReviewTime.notSent,
          );
        },
      );

      test('null is the office stating no review time', () async {
        expect(await _decode(null), VerificationReviewTime.notStated);
      });

      test(
        'a range decodes both ends, and one number is a range of one',
        () async {
          expect(
            await _decode(<String, Object?>{'min': 1, 'max': 3}),
            const ReviewTimeStated(1, 3),
          );
          expect(
            await _decode(<String, Object?>{'min': 5, 'max': 5}),
            const ReviewTimeStated(5, 5),
          );
          expect(
            await _decode(<String, Object?>{'min': 1, 'max': 30}),
            const ReviewTimeStated(1, 30),
          );
        },
      );

      test('a key beside min and max is ignored, never rejected', () async {
        expect(
          await _decode(<String, Object?>{'min': 2, 'max': 4, 'unit': 'days'}),
          const ReviewTimeStated(2, 4),
        );
      });

      test('a malformed value counts as absent and never throws', () async {
        final List<Object?> malformed = <Object?>[
          <String, Object?>{'min': 4, 'max': 2},
          <String, Object?>{'min': 0, 'max': 3},
          <String, Object?>{'min': 1, 'max': 31},
          <String, Object?>{'min': -1, 'max': 3},
          <String, Object?>{'min': 1.5, 'max': 3},
          <String, Object?>{'min': 2.0, 'max': 3},
          <String, Object?>{'min': '1', 'max': '3'},
          <String, Object?>{'min': true, 'max': 3},
          <String, Object?>{'min': 1},
          <String, Object?>{'max': 3},
          <String, Object?>{'min': null, 'max': null},
          <String, Object?>{},
          '1-3',
          3,
          <Object?>[1, 3],
          false,
        ];
        for (final Object? value in malformed) {
          expect(
            await _decode(value),
            VerificationReviewTime.notSent,
            reason: 'verification_review_working_days: ${jsonEncode(value)}',
          );
        }
      });

      test('a payload that is not an object reads as not sent', () async {
        final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
          Ok<ApiHttpResponse>(
            ApiHttpResponse(
              statusCode: 200,
              body: jsonEncode(<String, Object?>{
                'data': <Object?>[],
                'meta': <String, Object?>{'request_id': 'req-1'},
              }),
              headers: const <String, String>{'x-request-id': 'req-1'},
            ),
          ),
        ]);
        final Result<AppBootstrap> result = await PlatformApiRepository(
          apiClient: _client(transport),
        ).loadBootstrap();
        expect(
          result.valueOrNull?.verificationReviewTime,
          VerificationReviewTime.notSent,
        );
      });

      test('fromRange holds the server\'s bounds', () {
        expect(VerificationReviewTime.fewestDays, 1);
        expect(VerificationReviewTime.mostDays, 30);
        expect(
          VerificationReviewTime.fromRange(30, 30),
          const ReviewTimeStated(30, 30),
        );
        expect(
          VerificationReviewTime.fromRange(3, 1),
          VerificationReviewTime.notSent,
        );
        expect(
          VerificationReviewTime.fromRange(null, 3),
          VerificationReviewTime.notSent,
        );
      });

      test('before the server answers, the app has nothing sent', () {
        expect(
          AppBootstrap.unknown.verificationReviewTime,
          VerificationReviewTime.notSent,
        );
        expect(VerificationReviewTime.bundled, const ReviewTimeStated(1, 3));
      });
    },
  );

  group('it lives where the rest of app config lives', () {
    test('a failed refresh keeps the last range the server sent', () async {
      final PlatformController controller = PlatformController(
        repository: _Sequence(<AppBootstrap>[
          _bootstrap(const ReviewTimeStated(2, 5)),
        ]),
      );
      expect(
        controller.bootstrap.verificationReviewTime,
        VerificationReviewTime.notSent,
      );

      await controller.refresh();
      expect(
        controller.bootstrap.verificationReviewTime,
        const ReviewTimeStated(2, 5),
      );

      await controller.refresh(); // offline now
      expect(
        controller.bootstrap.verificationReviewTime,
        const ReviewTimeStated(2, 5),
      );
    });

    test('and a cleared one stays cleared offline', () async {
      final PlatformController controller = PlatformController(
        repository: _Sequence(<AppBootstrap>[
          _bootstrap(VerificationReviewTime.notStated),
        ]),
      );
      await controller.refresh();
      await controller.refresh(); // offline now
      expect(
        controller.bootstrap.verificationReviewTime,
        VerificationReviewTime.notStated,
      );
    });
  });

  group('one formatter, in every locale the app ships', () {
    test('a range', () {
      const VerificationReviewTime range = ReviewTimeStated(1, 3);
      expect(ReviewTimeCopy.duration(range, english), '1–3 working days');
      expect(ReviewTimeCopy.duration(range, filipino), '1–3 araw ng trabaho');
      expect(
        ReviewTimeCopy.sentence(range, english),
        'This usually takes 1–3 working days.',
      );
      expect(
        ReviewTimeCopy.sentence(range, filipino),
        'Karaniwang inaabot ito ng 1–3 araw ng trabaho.',
      );
      expect(
        ReviewTimeCopy.timelineDetail(range, english),
        'Usually 1–3 working days',
      );
      expect(
        ReviewTimeCopy.timelineDetail(range, filipino),
        'Karaniwang 1–3 araw ng trabaho',
      );
    });

    test('one day is singular, never "1–1"', () {
      const VerificationReviewTime one = ReviewTimeStated(1, 1);
      expect(
        ReviewTimeCopy.sentence(one, english),
        'This usually takes 1 working day.',
      );
      expect(
        ReviewTimeCopy.timelineDetail(one, english),
        'Usually 1 working day',
      );
      expect(
        ReviewTimeCopy.sentence(one, filipino),
        'Karaniwang inaabot ito ng 1 araw ng trabaho.',
      );
    });

    test('one number above one is plural, never a range', () {
      for (final int days in <int>[2, 5, 21, 30]) {
        final VerificationReviewTime same = ReviewTimeStated(days, days);
        expect(
          ReviewTimeCopy.sentence(same, english),
          'This usually takes $days working days.',
        );
        expect(
          ReviewTimeCopy.timelineDetail(same, english),
          'Usually $days working days',
        );
        // Filipino does not inflect the noun for number.
        expect(
          ReviewTimeCopy.sentence(same, filipino),
          'Karaniwang inaabot ito ng $days araw ng trabaho.',
        );
      }
    });

    test('a range is always plural, whatever its ends', () {
      expect(
        ReviewTimeCopy.duration(const ReviewTimeStated(1, 2), english),
        '1–2 working days',
      );
      expect(
        ReviewTimeCopy.duration(const ReviewTimeStated(10, 30), english),
        '10–30 working days',
      );
    });

    test('nothing stated says nothing, in every locale', () {
      for (final AppStrings strings in <AppStrings>[english, filipino]) {
        expect(
          ReviewTimeCopy.duration(VerificationReviewTime.notStated, strings),
          isNull,
        );
        expect(
          ReviewTimeCopy.sentence(VerificationReviewTime.notStated, strings),
          isNull,
        );
        expect(
          ReviewTimeCopy.timelineDetail(
            VerificationReviewTime.notStated,
            strings,
          ),
          isNull,
        );
      }
    });

    test('nothing sent says what this build always said', () {
      expect(
        ReviewTimeCopy.sentence(VerificationReviewTime.notSent),
        'This usually takes 1–3 working days.',
      );
      expect(
        ReviewTimeCopy.timelineDetail(VerificationReviewTime.notSent),
        'Usually 1–3 working days',
      );
      expect(
        ReviewTimeCopy.sentence(VerificationReviewTime.notSent, filipino),
        'Karaniwang inaabot ito ng 1–3 araw ng trabaho.',
      );
    });

    test('the pages read English, as the rest of their copy is', () {
      expect(ReviewTimeCopy.pageStrings.localeName, 'en');
    });
  });

  group('the pending page', () {
    for (final (String name, VerificationReviewTime time, String body, _)
        in _cases) {
      testWidgets('with $name', (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: PendingStatusPage(reviewTime: time)),
        );
        expect(find.text(body), findsOneWidget);
        // No dangling clause: the sentence goes whole, spaces and all.
        expect(find.textContaining('  '), findsNothing);
        expect(find.textContaining(' .'), findsNothing);
        if (time == VerificationReviewTime.notStated) {
          expect(find.textContaining('working day'), findsNothing);
          expect(find.textContaining('usually'), findsNothing);
        }
      });

      testWidgets('with $name fits every phone at 200%', (tester) async {
        await expectCleanLayouts(
          tester,
          () => PendingStatusPage(
            onBack: () {},
            accountCreated: '05 Nov 2026, 9:14 AM',
            email: 'sample@example.test',
            idType: 'Passport',
            submittedOn: '06 Nov 2026',
            reviewTime: time,
          ),
          scrollable: false,
        );
      });
    }

    testWidgets('the longest range fits every phone at 200%', (tester) async {
      await expectCleanLayouts(
        tester,
        () => PendingStatusPage(
          onBack: () {},
          reviewTime: const ReviewTimeStated(10, 30),
        ),
        scrollable: false,
      );
    });

    testWidgets('one day reads singular on the page', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PendingStatusPage(reviewTime: ReviewTimeStated(1, 1)),
        ),
      );
      expect(
        find.text(
          '$_pendingLead This usually takes 1 working day. No action needed.',
        ),
        findsOneWidget,
      );
    });
  });

  group("the profile wizard's submitted frame", () {
    for (final (String name, VerificationReviewTime time, _, String line)
        in _cases) {
      Widget page() => ProfileWizardPage(
        step: ProfileWizardStep.submitted,
        record: MockResidentRecordRepository.sampleRecord,
        submittedAt: MockResidentRecordRepository.sampleSubmittedAt,
        onBack: () {},
        onContinue: () {},
        reviewTime: time,
      );

      testWidgets('with $name', (tester) async {
        await tester.pumpWidget(MaterialApp(home: page()));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('LGU review'), findsOneWidget);
        if (line.isEmpty) {
          expect(find.textContaining('working day'), findsNothing);
          expect(find.textContaining('Usually'), findsNothing);
        } else {
          expect(find.text(line), findsOneWidget);
        }
      });

      testWidgets('with $name fits every phone at 200%', (tester) async {
        await expectCleanLayouts(tester, page, scrollable: false);
      });
    }

    testWidgets('no review time leaves no empty line in the timeline', (
      tester,
    ) async {
      List<String> timelineTexts() => <String>[
        for (final Text text in tester.widgetList<Text>(
          find.descendant(
            of: find.byType(Timeline),
            matching: find.byType(Text),
          ),
        ))
          text.data ?? '',
      ];
      Future<List<String>> texts(VerificationReviewTime time) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileWizardPage(
              step: ProfileWizardStep.submitted,
              record: MockResidentRecordRepository.sampleRecord,
              reviewTime: time,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 50));
        return timelineTexts();
      }

      final List<String> bundled = await texts(VerificationReviewTime.notSent);
      final List<String> none = await texts(VerificationReviewTime.notStated);
      expect(bundled, contains('Usually 1–3 working days'));
      expect(none, <String>[
        for (final String text in bundled)
          if (text != 'Usually 1–3 working days') text,
      ]);
      expect(none.where((String text) => text.trim().isEmpty), isEmpty);
    });

    testWidgets('one number of days reads plural on the frame', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileWizardPage(
            step: ProfileWizardStep.submitted,
            record: MockResidentRecordRepository.sampleRecord,
            reviewTime: ReviewTimeStated(4, 4),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Usually 4 working days'), findsOneWidget);
    });
  });

  group('the wizard screen follows app config as it arrives', () {
    testWidgets('a range, then none, then the bundled copy', (tester) async {
      final AppDependencies dependencies = AppDependencies.build(
        config: _config(),
        transport: _Scripted(<Result<ApiHttpResponse>>[]),
        secrets: InMemorySecretStore(),
        sessionStore: InMemorySessionStore(),
      );
      addTearDown(dependencies.dispose);

      await tester.pumpWidget(
        AppDependenciesScope(
          dependencies: dependencies,
          child: const MaterialApp(
            home: ProfileWizardScreen(
              step: ProfileWizardStep.submitted,
              preview: MockResidentRecordRepository.sampleRecord,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Usually 1–3 working days'), findsOneWidget);

      dependencies.platform.replaceBootstrapForTesting(
        _bootstrap(const ReviewTimeStated(3, 7)),
      );
      await tester.pump();
      expect(find.text('Usually 3–7 working days'), findsOneWidget);
      expect(find.text('Usually 1–3 working days'), findsNothing);

      dependencies.platform.replaceBootstrapForTesting(
        _bootstrap(VerificationReviewTime.notStated),
      );
      await tester.pump();
      expect(find.text('LGU review'), findsOneWidget);
      expect(find.textContaining('working day'), findsNothing);

      dependencies.platform.replaceBootstrapForTesting(
        _bootstrap(VerificationReviewTime.notSent),
      );
      await tester.pump();
      expect(find.text('Usually 1–3 working days'), findsOneWidget);
    });
  });
}
