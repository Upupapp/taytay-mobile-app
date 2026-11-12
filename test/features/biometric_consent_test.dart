import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/biometric_consent_controller.dart';
import 'package:taytay_resident/features/citizen_api/domain/citizen_contract.dart';
import 'package:taytay_resident/features/platform/data/platform_api_repository.dart';
import 'package:taytay_resident/features/platform/domain/app_bootstrap.dart';
import 'package:taytay_resident/features/settings/domain/account_controls.dart';
import 'package:taytay_resident/features/verification/data/kyc_api_repository.dart';
import 'package:taytay_resident/features/verification/domain/verification_status_detail.dart';
import 'package:taytay_resident/features/verification/domain/verification_submit_outcome.dart';
import 'package:taytay_resident/shared/widgets/biometric_consent_dialog.dart';
import 'package:taytay_resident/shared/widgets/consent_check_card.dart';
import 'package:taytay_resident/shared/widgets/soft_note.dart';

import '../support/biometric_fakes.dart';
import '../support/layout_matrix.dart';

/// The selfie's biometric consent (D-209) and the in-person way (D-210).
void main() {
  ApiClient clientAnswering(Object? data, {int status = 200}) => ApiClient(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: 'https://example.test/api/v1',
      isReleaseBuild: false,
    ),
    accessTokenProvider: () async => 'sample-token',
    transport: _OneAnswer(
      ApiHttpResponse(
        statusCode: status,
        body: jsonEncode(
          status < 400
              ? <String, Object?>{
                  'data': data,
                  'meta': <String, Object?>{'request_id': 'req-1'},
                }
              : data,
        ),
      ),
    ),
  );

  BiometricConsentController controller({
    BiometricPlatform? platform,
    BiometricConsents? consents,
    MunicipalOffice? office,
  }) => BiometricConsentController(
    platform: platform ?? BiometricPlatform(),
    consents: consents ?? BiometricConsents(start: BiometricStart.owed),
    inPersonOffice: () async => Ok<MunicipalOffice?>(office),
  );

  const MunicipalOffice mswdo = MunicipalOffice(
    id: 'office-1',
    name: 'Synthetic Social Welfare Office',
    slug: 'mswdo',
    description: '',
    head: '',
    hours: 'Mon–Fri, sample hours',
    phone: '0900-000-0002',
    email: '',
    address: 'Sample Street, Sample Barangay',
    category: 'social',
  );

  group('app config carries the text and its version', () {
    test('a published text and version decode', () async {
      final AppBootstrap config = (await PlatformApiRepository(
        apiClient: clientAnswering(<String, Object?>{
          'biometric_consent_version': 'bio-2',
          'biometric_consent': <String, Object?>{
            'version': 'bio-2',
            'updated_at': '2026-11-12T00:00:00.000Z',
            'body_markdown': '# Selfie\nSample.',
          },
        }),
      ).loadBootstrap()).valueOrNull!;
      expect(config.biometricConsentVersion, 'bio-2');
      expect(config.biometricConsent.isPublished, isTrue);
      expect(config.biometricConsent.bodyMarkdown, contains('Sample.'));
    });

    test(
      'null, the placeholder, or an older server: nothing to agree to',
      () async {
        for (final Map<String, Object?> body in <Map<String, Object?>>[
          <String, Object?>{
            'biometric_consent_version': null,
            'biometric_consent': <String, Object?>{
              'version': 'placeholder',
              'updated_at': '2026-11-12T00:00:00.000Z',
              'body_markdown': 'Placeholder.',
            },
          },
          <String, Object?>{},
        ]) {
          final AppBootstrap config = (await PlatformApiRepository(
            apiClient: clientAnswering(body),
          ).loadBootstrap()).valueOrNull!;
          expect(config.biometricConsentVersion, isEmpty);
          expect(config.biometricConsent.isPublished, isFalse);
        }
      },
    );
  });

  group('the server refuses a selfie without consent', () {
    test('BIOMETRIC_CONSENT_REQUIRED is its own failure, in app words', () {
      final AppFailure failure = failureFromApiError(
        statusCode: 403,
        code: ApiErrorCode.parse('BIOMETRIC_CONSENT_REQUIRED'),
        message: 'operator-only sentence',
      );
      expect(failure, isA<ForbiddenFailure>());
      final ForbiddenFailure forbidden = failure as ForbiddenFailure;
      expect(forbidden.requiresBiometricConsent, isTrue);
      expect(forbidden.requiresVerification, isFalse);
      expect(forbidden.kind, 'biometric_consent_required');
      expect(forbidden.residentMessage, contains('Nothing was sent'));
      expect(forbidden.residentMessage, isNot(contains('operator')));
      // Not mistaken for a staff account, which a plain 403 means here.
      expect(
        verificationSubmitOutcome(forbidden),
        VerificationSubmitOutcome.failed,
      );
      expect(
        verificationSubmitOutcome(const ForbiddenFailure()),
        VerificationSubmitOutcome.continueVerified,
      );
    });

    test('selfie_erased_at is read from the request', () async {
      final ApiClient client = clientAnswering(<String, Object?>{
        'id': 'req-1',
        'status': 'pending',
        'can_edit': true,
        'selfie_media_id': 'media-1',
        'selfie_erased_at': '2026-11-10T02:00:00.000Z',
      });
      final VerificationStatusDetail detail = (await KycApiRepository(
        apiClient: client,
      ).loadOwnStatusDetail()).valueOrNull!;
      expect(detail.selfieErased, isTrue);
      expect(detail.selfieErasedAt, DateTime.utc(2026, 11, 10, 2));

      final VerificationStatusDetail kept = (await KycApiRepository(
        apiClient: clientAnswering(<String, Object?>{
          'id': 'req-2',
          'status': 'pending',
          'selfie_erased_at': null,
        }),
      ).loadOwnStatusDetail()).valueOrNull!;
      expect(kept.selfieErased, isFalse);
    });
  });

  group('where the consent stands, as the server says', () {
    test('no published text: unavailable, and nothing is asked', () async {
      final BiometricConsents consents = BiometricConsents(
        start: BiometricStart.unpublished,
      );
      final BiometricConsentController c = controller(
        platform: BiometricPlatform(published: false),
        consents: consents,
      );
      await c.load();
      expect(c.status, isA<BiometricConsentUnavailable>());
      expect(c.allowsSelfie, isFalse);
      expect(consents.stateReads, 0);
      expect(await c.agree(), isFalse);
      expect(consents.accepted, isEmpty);
      c.dispose();
    });

    test('published, not agreed: owed, with the text and version', () async {
      final BiometricConsentController c = controller();
      expect(c.status, isA<BiometricConsentChecking>());
      await c.load();
      final BiometricConsentStatus status = c.status;
      expect(status, isA<BiometricConsentOwed>());
      expect((status as BiometricConsentOwed).version, sampleBiometricVersion);
      expect(status.text.bodyMarkdown, sampleBiometricBody);
      expect(c.allowsSelfie, isFalse);
      c.dispose();
    });

    test('agreed: given, and a selfie is allowed', () async {
      final BiometricConsentController c = controller(
        consents: BiometricConsents(),
      );
      await c.load();
      expect(c.status, isA<BiometricConsentGiven>());
      expect(c.allowsSelfie, isTrue);
      c.dispose();
    });

    test('a failed read is failed, never given', () async {
      final BiometricConsentController configFails = controller(
        platform: BiometricPlatform(
          answer: const Err<AppBootstrap>(NetworkFailure()),
        ),
      );
      await configFails.load();
      expect(configFails.status, isA<BiometricConsentFailed>());
      expect(configFails.allowsSelfie, isFalse);
      configFails.dispose();

      final BiometricConsents consents = BiometricConsents()
        ..stateFailure = const TimeoutFailure();
      final BiometricConsentController stateFails = controller(
        consents: consents,
      );
      await stateFails.load();
      expect(stateFails.status, isA<BiometricConsentFailed>());
      // Trying again reads afresh.
      await stateFails.load();
      expect(stateFails.status, isA<BiometricConsentGiven>());
      stateFails.dispose();
    });

    test('agreeing records the biometric kind and the version shown', () async {
      final BiometricConsents consents = BiometricConsents(
        start: BiometricStart.owed,
      );
      final BiometricConsentController c = controller(consents: consents);
      await c.load();
      expect(await c.agree(), isTrue);
      expect(consents.accepted.single.kind, ConsentKind.biometric);
      expect(consents.accepted.single.version, sampleBiometricVersion);
      expect(c.status, isA<BiometricConsentGiven>());
      c.dispose();
    });

    test('a failed agreement is never called recorded', () async {
      final BiometricConsents consents = BiometricConsents(
        start: BiometricStart.owed,
      )..acceptFailure = const TimeoutFailure();
      final BiometricConsentController c = controller(consents: consents);
      await c.load();
      expect(await c.agree(), isFalse);
      expect(c.status, isA<BiometricConsentOwed>());
      expect(c.recordFailure?.outcomeUnknown, isTrue);
      c.dispose();
    });

    test('a 409 or 422 on agreeing reads the text again', () async {
      final BiometricConsents consents = BiometricConsents(
        start: BiometricStart.owed,
      )..acceptFailure = const ConflictFailure();
      final BiometricPlatform platform = BiometricPlatform();
      final BiometricConsentController c = controller(
        platform: platform,
        consents: consents,
      );
      await c.load();
      final int before = platform.reads;
      expect(await c.agree(), isFalse);
      expect(platform.reads, before + 1);
      c.dispose();
    });

    test('withdrawing names the biometric kind and reads again', () async {
      final BiometricConsents consents = BiometricConsents();
      final BiometricConsentController c = controller(consents: consents);
      await c.load();
      expect(await c.withdraw(), isTrue);
      expect(consents.withdrawn.single.kind, ConsentKind.biometric);
      expect(consents.withdrawn.single.version, sampleBiometricVersion);
      expect(c.status, isA<BiometricConsentOwed>());
      c.dispose();
    });

    test('a failed withdrawal keeps the consent and says why', () async {
      final BiometricConsents consents = BiometricConsents()
        ..withdrawFailure = const NetworkFailure();
      final BiometricConsentController c = controller(consents: consents);
      await c.load();
      expect(await c.withdraw(), isFalse);
      expect(c.status, isA<BiometricConsentGiven>());
      expect(c.recordFailure, isA<NetworkFailure>());
      c.dispose();
    });

    test('the in-person office is read once, from the directory', () async {
      int reads = 0;
      final BiometricConsentController c = BiometricConsentController(
        platform: BiometricPlatform(),
        consents: BiometricConsents(),
        inPersonOffice: () async {
          reads++;
          return const Ok<MunicipalOffice?>(mswdo);
        },
      );
      await c.loadInPersonOffice();
      await c.loadInPersonOffice();
      expect(reads, 1);
      expect(c.inPersonOffice?.name, mswdo.name);
      c.dispose();
    });

    test('no version or statement is in the consent state toString', () {
      final ConsentState state = ConsentState(
        biometric: ConsentStanding(
          publishedVersion: 'v-sample-secret',
          consent: BiometricConsents.record('v-sample-secret'),
          upToDate: true,
        ),
      );
      expect(state.toString(), isNot(contains('v-sample-secret')));
      expect(state.toString(), isNot(contains('Agreed')));
      expect(state.biometric.toString(), isNot(contains('v-sample-secret')));
    });
  });

  group('the consent is its own act before the camera', () {
    Future<(BiometricConsentController, BiometricConsents)> pumpOpener(
      WidgetTester tester,
      List<BiometricConsentChoice> choices, {
      BiometricConsents? consents,
    }) async {
      final BiometricConsents held =
          consents ?? BiometricConsents(start: BiometricStart.owed);
      final BiometricConsentController c = controller(consents: held);
      await c.load();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        layoutHost(
          dialogOpener((BuildContext context) async {
            choices.add(await ensureBiometricConsent(context, c));
          }),
          scrollable: false,
        ),
      );
      await tester.tap(find.byKey(dialogOpenerKey));
      await tester.pumpAndSettle();
      return (c, held);
    }

    testWidgets('it shows why, the text, and an unticked tick', (tester) async {
      final List<BiometricConsentChoice> choices = <BiometricConsentChoice>[];
      await pumpOpener(tester, choices);

      expect(find.text(BiometricConsentCopy.dialogTitle), findsOneWidget);
      expect(find.text(BiometricConsentCopy.what), findsOneWidget);
      expect(find.text('Sample selfie consent'), findsOneWidget);
      expect(find.text(BiometricConsentCopy.choice), findsOneWidget);
      expect(
        tester
            .widget<ConsentCheckCard>(find.byKey(biometricConsentTickKey))
            .value,
        isFalse,
      );
      // Agree is off until the resident ticks.
      final Finder agree = find.byKey(biometricConsentAgreeKey);
      await tester.ensureVisible(agree);
      await tester.tap(agree);
      await tester.pumpAndSettle();
      expect(choices, isEmpty);
      expect(find.text(BiometricConsentCopy.dialogTitle), findsOneWidget);
    });

    testWidgets('ticking and agreeing records it, then lets the camera open', (
      tester,
    ) async {
      final List<BiometricConsentChoice> choices = <BiometricConsentChoice>[];
      final (BiometricConsentController c, BiometricConsents held) =
          await pumpOpener(tester, choices);
      await tester.ensureVisible(find.byKey(biometricConsentTickKey));
      await tester.tap(find.byKey(biometricConsentTickKey));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(biometricConsentAgreeKey));
      await tester.tap(find.byKey(biometricConsentAgreeKey));
      await tester.pumpAndSettle();
      expect(choices, <BiometricConsentChoice>[BiometricConsentChoice.agreed]);
      expect(held.accepted.single.kind, ConsentKind.biometric);
      expect(c.allowsSelfie, isTrue);
    });

    testWidgets('"No, I\'ll verify in person" records nothing', (tester) async {
      final List<BiometricConsentChoice> choices = <BiometricConsentChoice>[];
      final (_, BiometricConsents held) = await pumpOpener(tester, choices);
      await tester.ensureVisible(find.byKey(biometricConsentDeclineKey));
      expect(find.text(BiometricConsentCopy.decline), findsOneWidget);
      await tester.tap(find.byKey(biometricConsentDeclineKey));
      await tester.pumpAndSettle();
      expect(choices, <BiometricConsentChoice>[
        BiometricConsentChoice.declined,
      ]);
      expect(held.accepted, isEmpty);
    });

    testWidgets('a failed agreement stays open and says nothing was taken', (
      tester,
    ) async {
      final List<BiometricConsentChoice> choices = <BiometricConsentChoice>[];
      await pumpOpener(
        tester,
        choices,
        consents: BiometricConsents(start: BiometricStart.owed)
          ..acceptFailure = const ServerFailure(isTemporary: true),
      );
      await tester.ensureVisible(find.byKey(biometricConsentTickKey));
      await tester.tap(find.byKey(biometricConsentTickKey));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(biometricConsentAgreeKey));
      await tester.tap(find.byKey(biometricConsentAgreeKey));
      await tester.pumpAndSettle();
      expect(choices, isEmpty);
      expect(find.text(BiometricConsentCopy.notRecorded), findsOneWidget);
    });

    testWidgets('a consent already given opens no dialog', (tester) async {
      final List<BiometricConsentChoice> choices = <BiometricConsentChoice>[];
      await pumpOpener(tester, choices, consents: BiometricConsents());
      expect(find.text(BiometricConsentCopy.dialogTitle), findsNothing);
      expect(choices, <BiometricConsentChoice>[BiometricConsentChoice.agreed]);
    });

    testWidgets('the dialog fits every phone at 200% text, centred', (
      tester,
    ) async {
      final BiometricConsentController c = controller();
      await c.load();
      addTearDown(c.dispose);
      await expectCleanDialogLayouts(
        tester,
        () => dialogOpener(
          (BuildContext context) => ensureBiometricConsent(context, c),
        ),
      );
    });
  });

  group('the in-person way (D-210)', () {
    testWidgets('it says what to bring, and the office from the directory', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(const InPersonVerificationNote(office: mswdo)),
      );
      final SoftNote note = tester.widget<SoftNote>(
        find.byKey(inPersonVerificationNoteKey),
      );
      expect(note.heading, BiometricConsentCopy.inPersonHeading);
      expect(note.message, startsWith(BiometricConsentCopy.inPerson));
      expect(note.message, contains('No selfie is taken.'));
      expect(note.message, contains(mswdo.name));
      expect(note.message, contains(mswdo.address));
      expect(note.message, contains(mswdo.hours));
    });

    testWidgets('without the directory it still names the MSWDO alone', (
      tester,
    ) async {
      await tester.pumpWidget(layoutHost(const InPersonVerificationNote()));
      final SoftNote note = tester.widget<SoftNote>(
        find.byKey(inPersonVerificationNoteKey),
      );
      expect(note.message, BiometricConsentCopy.inPerson);
    });

    testWidgets('the note fits every phone at 200% text', (tester) async {
      await expectCleanLayouts(
        tester,
        () => const InPersonVerificationNote(office: mswdo),
      );
    });
  });

  group('the contract (vendored Node export, backend ebd7aeb)', () {
    final Map<String, dynamic> node =
        jsonDecode(
              File(
                'docs/integration/taytay-node-openapi.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final Map<String, dynamic> schemas =
        (node['components'] as Map<String, dynamic>)['schemas']
            as Map<String, dynamic>;
    Map<String, dynamic> schema(String name) =>
        schemas[name] as Map<String, dynamic>;
    List<String> required(String name) =>
        (schema(name)['required'] as List<dynamic>).cast<String>();
    Map<String, dynamic> properties(String name) =>
        schema(name)['properties'] as Map<String, dynamic>;

    test('app config always sends the biometric version and text', () {
      expect(
        required('AppConfig'),
        containsAll(<String>['biometric_consent_version', 'biometric_consent']),
      );
      expect(
        required('BiometricConsentText'),
        unorderedEquals(<String>['version', 'updated_at', 'body_markdown']),
      );
    });

    test('the kinds the app sends are the kinds the server accepts', () {
      expect(
        (schema('ConsentKind')['enum'] as List<dynamic>).cast<String>(),
        unorderedEquals(<String>[
          for (final ConsentKind kind in ConsentKind.values)
            if (kind != ConsentKind.unspecified) kind.wireValue,
        ]),
      );
      expect(
        (schema('RecordedConsentKind')['enum'] as List<dynamic>).cast<String>(),
        unorderedEquals(<String>[
          for (final ConsentKind kind in ConsentKind.values) kind.wireValue,
        ]),
      );
      expect(required('PrivacyConsent'), contains('kind'));
    });

    test('GET /me/consents/current answers the three standings', () {
      expect(
        (node['paths'] as Map<String, dynamic>).keys,
        contains('/api/v1/me/consents/current'),
      );
      expect(
        required('ConsentState'),
        unorderedEquals(<String>[
          'terms',
          'privacy',
          'biometric',
          'unspecified',
        ]),
      );
      expect(
        required('ConsentStanding'),
        unorderedEquals(<String>['published_version', 'consent', 'up_to_date']),
      );
    });

    test('a verification request carries selfie_erased_at', () {
      final String name = schemas.keys.firstWhere(
        (String key) =>
            (schemas[key] as Map<String, dynamic>)['properties'] is Map &&
            properties(key).containsKey('selfie_erased_at'),
      );
      expect(required(name), contains('selfie_erased_at'));
    });
  });
}

/// Answers the one request a decode test makes.
class _OneAnswer implements ApiTransport {
  _OneAnswer(this._response);

  final ApiHttpResponse _response;

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async =>
      Ok<ApiHttpResponse>(_response);
}
