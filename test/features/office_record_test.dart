import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/account/presentation/account_copy.dart';
import 'package:taytay_resident/features/account/presentation/account_pages.dart';
import 'package:taytay_resident/features/account/presentation/office_record_section.dart';
import 'package:taytay_resident/features/profile/data/resident_profile_api_repository.dart';
import 'package:taytay_resident/features/profile/domain/barangay_lock.dart';
import 'package:taytay_resident/features/profile/domain/office_record.dart';
import 'package:taytay_resident/features/profile/domain/profile_fields.dart';
import 'package:taytay_resident/features/profile/domain/resident_profile_detail.dart';
import 'package:taytay_resident/features/profile/domain/resident_profile_repository.dart';
import 'package:taytay_resident/features/registration/domain/registration_domain.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/barangay_picker.dart';

/// D-235: the resident's record at the MSWDO office, read-only on her
/// profile, and her barangay the office's to change once she is verified.
///
/// Synthetic: the names, dates and ids are made up and nobody here is a real
/// resident.
const String _sanJuanId = '00000000-0000-4000-8000-0000000000a1';
const String _doloresId = '00000000-0000-4000-8000-0000000000d1';
const List<Barangay> _barangays = <Barangay>[
  Barangay(id: _sanJuanId, name: 'San Juan'),
  Barangay(id: _doloresId, name: 'Dolores'),
];

Map<String, Object?> _officeRecordWire({String? sex = 'female'}) =>
    <String, Object?>{
      'first_name': 'Juana',
      'middle_name': 'Santos',
      'last_name': 'Dela Cruz',
      'suffix': null,
      'sex': sex,
      'birth_date': '1990-03-04',
      'barangay_id': _doloresId,
    };

/// Answers `GET /me` with [profile].
class _Me implements ApiTransport {
  _Me(this.profile);

  final Map<String, Object?> profile;

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async =>
      Ok<ApiHttpResponse>(
        ApiHttpResponse(
          statusCode: 200,
          body: jsonEncode(<String, Object?>{
            'data': profile,
            'meta': <String, Object?>{'request_id': 'req-ok'},
          }),
          headers: const <String, String>{'x-request-id': 'req-ok'},
        ),
      );
}

Future<ResidentProfileDetail> _decoded(Map<String, Object?> profile) async =>
    (await ResidentProfileApiRepository(
      apiClient: ApiClient(
        config: AppConfig.from(
          rawEnvironment: 'dev',
          rawApiBaseUrl: 'https://example.test/api/v1',
          isReleaseBuild: false,
        ),
        transport: _Me(profile),
        accessTokenProvider: () async => 'tok',
      ),
    ).loadOwnDetail()).valueOrNull!;

/// Returns [detail] and records each `PATCH /me`, answering it with [refusal]
/// when one is set.
class _Profile implements ResidentProfileRepository {
  _Profile(this.detail, {this.refusal});

  final ResidentProfileDetail detail;
  final AppFailure? refusal;
  final List<Map<String, Object?>> changes = <Map<String, Object?>>[];

  @override
  Future<Result<ResidentProfileDetail>> loadOwnDetail() async =>
      Ok<ResidentProfileDetail>(detail);

  @override
  Future<Result<ResidentProfileSummary>> loadOwnSummary() async =>
      const Err<ResidentProfileSummary>(NetworkFailure());

  @override
  Future<Result<void>> updateContactDetails({
    required ContactDetailsUpdate update,
    required String idempotencyKey,
  }) async => const Err<void>(NetworkFailure());

  @override
  Future<Result<void>> submitOwnUpdate({
    required Map<String, Object?> changes,
    required String idempotencyKey,
  }) async {
    this.changes.add(changes);
    final AppFailure? refused = refusal;
    return refused == null ? const Ok<void>(null) : Err<void>(refused);
  }
}

class _Directory implements BarangayDirectory {
  const _Directory();

  @override
  Future<Result<List<Barangay>>> listBarangays() async =>
      const Ok<List<Barangay>>(_barangays);
}

ResidentProfileDetail _detail(String? tier, {OfficeRecord? record}) =>
    ResidentProfileDetail(
      verificationTier: tier,
      values: const <ResidentProfileField, String>{
        ResidentProfileField.fullName: 'Juana Dela Cruz',
        ResidentProfileField.mobileNumber: '09170000000',
        ResidentProfileField.emailAddress: 'juana@example.com',
        ResidentProfileField.barangay: _sanJuanId,
      },
      officeRecord: record,
    );

const OfficeRecord _record = OfficeRecord(
  firstName: 'Juana',
  middleName: 'Santos',
  lastName: 'Dela Cruz',
  sex: OfficeRecordSex.female,
  birthDate: '1990-03-04',
  barangayId: _doloresId,
);

Future<_Profile> _openEdit(WidgetTester tester, _Profile profile) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final InMemorySecretStore secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  final AppDependencies base = AppDependencies.build(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: 'https://example.test/api/v1',
      isReleaseBuild: false,
    ),
    secrets: secrets,
    sessionStore: InMemorySessionStore(),
    localAuthenticator: const UnavailableLocalAuthenticator(),
  );
  final AppDependencies dependencies = AppDependencies(
    config: base.config,
    session: base.session,
    launch: base.launch,
    intents: base.intents,
    appLock: base.appLock,
    apiClient: base.apiClient,
    cache: base.cache,
    network: base.network,
    telemetry: base.telemetry,
    authRepository: base.authRepository,
    deviceSessionRepository: base.deviceSessionRepository,
    platformRepository: base.platformRepository,
    serviceCatalogRepository: base.serviceCatalogRepository,
    programRepository: base.programRepository,
    announcementRepository: base.announcementRepository,
    eventRepository: base.eventRepository,
    residentProfileRepository: profile,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: base.verificationRepository,
    documentPicker: base.documentPicker,
    shareService: base.shareService,
    externalLinks: base.externalLinks,
    accountControlsRepository: base.accountControlsRepository,
    notificationRepository: base.notificationRepository,
    registrationRepository: base.registrationRepository,
    barangayDirectory: const _Directory(),
    platform: base.platform,
    onDispose: base.onDispose,
  );
  addTearDown(dependencies.dispose);
  await dependencies.session.signIn(
    resident: const ResidentSession(
      accountId: 'acct-sample',
      accessLevel: AccessLevel.verified,
    ),
    accessToken: 'token',
  );
  final GoRouter router = GoRouter(
    initialLocation: '/edit',
    routes: <RouteBase>[
      GoRoute(
        path: '/edit',
        builder: (BuildContext context, GoRouterState state) =>
            const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: AppRoute.profile.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('saved')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    AppDependenciesScope(
      dependencies: dependencies,
      child: MaterialApp.router(
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppLocales.supported,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return profile;
}

final Finder _save = find.byWidgetPredicate(
  (Widget widget) => widget is Text && widget.data == 'Save changes',
);

void main() {
  group('office_record on GET /me (ADR 0016)', () {
    test('is read with its name parts, sex, birth date and barangay', () async {
      final ResidentProfileDetail detail = await _decoded(<String, Object?>{
        'verification_status': 'verified',
        'office_record': _officeRecordWire(),
      });
      final OfficeRecord record = detail.officeRecord!;
      expect(record.fullName, 'Juana Santos Dela Cruz');
      expect(record.sex, OfficeRecordSex.female);
      expect(record.birthDate, '1990-03-04');
      expect(record.birthDateLabel, 'Mar 4, 1990');
      expect(record.barangayId, _doloresId);
    });

    test('null, absent or not an object is no record', () async {
      for (final Object? value in <Object?>[null, 'linked', 7, <Object?>[]]) {
        final ResidentProfileDetail detail = await _decoded(<String, Object?>{
          'office_record': value,
        });
        expect(detail.officeRecord, isNull, reason: '$value');
      }
      final ResidentProfileDetail absent = await _decoded(<String, Object?>{
        'verification_status': 'verified',
      });
      expect(absent.officeRecord, isNull);
    });

    test('a record missing a required part is not drawn with a hole', () async {
      for (final String key in <String>[
        'first_name',
        'last_name',
        'birth_date',
        'barangay_id',
      ]) {
        final Map<String, Object?> wire = _officeRecordWire()..remove(key);
        final ResidentProfileDetail detail = await _decoded(<String, Object?>{
          'office_record': wire,
        });
        expect(detail.officeRecord, isNull, reason: key);
      }
    });

    test('an unknown sex is unknown, never guessed', () async {
      final ResidentProfileDetail detail = await _decoded(<String, Object?>{
        'office_record': _officeRecordWire(sex: 'other'),
      });
      expect(detail.officeRecord?.sex, isNull);
      expect(OfficeRecordSex.parse('male'), OfficeRecordSex.male);
    });

    test('a date that is not YYYY-MM-DD is shown as sent', () {
      const OfficeRecord odd = OfficeRecord(
        firstName: 'A',
        lastName: 'B',
        birthDate: '04/03/1990',
        barangayId: _doloresId,
      );
      expect(odd.birthDateLabel, '04/03/1990');
    });

    test('toString names nobody', () {
      expect(_record.toString(), isNot(contains('Juana')));
      expect(_record.toString(), isNot(contains('1990')));
    });
  });

  group('the barangay of a verified account is the office\'s (D-235)', () {
    test('only verified locks it; every other tier is unchanged', () {
      expect(BarangayLock.heldByOffice('verified'), isTrue);
      for (final String? tier in <String?>[
        'unverified',
        'pending',
        'rejected',
        null,
        '',
        'VERIFIED-ish',
      ]) {
        expect(BarangayLock.heldByOffice(tier), isFalse, reason: '$tier');
      }
    });

    test('BARANGAY_HELD_BY_OFFICE is said in the app\'s own words', () {
      final AppFailure failure = failureFromApiError(
        statusCode: 409,
        code: ApiErrorCode.parse('BARANGAY_HELD_BY_OFFICE'),
        message: 'server words that are never shown',
      );
      expect(failure, isA<ConflictFailure>());
      expect((failure as ConflictFailure).isBarangayHeldByOffice, isTrue);
      expect(failure.residentMessage, BarangayLock.refused);
      expect(failure.residentMessage, isNot(contains('server words')));
    });

    testWidgets('verified: read-only, with the sentence, and never sent', (
      tester,
    ) async {
      final _Profile profile = await _openEdit(
        tester,
        _Profile(_detail('verified')),
      );

      expect(find.text('San Juan'), findsOneWidget);
      expect(find.text(BarangayLock.heldNote), findsOneWidget);

      await tester.tap(find.text('San Juan'));
      await tester.pumpAndSettle();
      expect(find.byType(BarangayPicker), findsNothing);

      await tester.enterText(find.byType(TextField).at(0), '09171111111');
      await tester.tap(_save);
      await tester.pumpAndSettle();
      expect(profile.changes.single.keys, <String>['mobile']);
    });

    for (final String tier in <String>['unverified', 'pending', 'rejected']) {
      testWidgets('$tier: the barangay is still hers to pick and send', (
        tester,
      ) async {
        final _Profile profile = await _openEdit(
          tester,
          _Profile(_detail(tier)),
        );

        expect(find.text(BarangayLock.heldNote), findsNothing);
        await tester.tap(find.text('San Juan'));
        await tester.pumpAndSettle();
        expect(find.byType(BarangayPicker), findsOneWidget);
        await tester.tap(find.text('Dolores'));
        await tester.pumpAndSettle();
        await tester.tap(_save);
        await tester.pumpAndSettle();
        expect(profile.changes.single['barangay_id'], _doloresId);
      });
    }

    testWidgets('a refusal from an older screen says why, never "try again"', (
      tester,
    ) async {
      final _Profile profile = await _openEdit(
        tester,
        _Profile(
          _detail('unverified'),
          refusal: const ConflictFailure(isBarangayHeldByOffice: true),
        ),
      );

      await tester.tap(find.text('San Juan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dolores'));
      await tester.pumpAndSettle();
      await tester.tap(_save);
      await tester.pumpAndSettle();

      expect(profile.changes.single['barangay_id'], _doloresId);
      expect(find.text(BarangayLock.refusedTitle), findsOneWidget);
      expect(find.text(BarangayLock.refused), findsOneWidget);
      expect(find.text(AccountCopy.nothingChangedTitle), findsNothing);

      // The field locks on what the account holds.
      await tester.tap(find.text('OK').last);
      await tester.pumpAndSettle();
      expect(find.text(BarangayLock.heldNote), findsOneWidget);
      expect(find.text('San Juan'), findsOneWidget);
    });

    test('a refusal with other changes says nothing was saved', () {
      expect(
        AccountCopy.barangayNotChanged(
          BarangayLock.refused,
          otherChanges: true,
        ),
        endsWith('Nothing was saved. Save again to keep your other changes.'),
      );
      expect(
        AccountCopy.barangayNotChanged(
          BarangayLock.refused,
          otherChanges: false,
        ),
        BarangayLock.refused,
      );
    });
  });

  group('the record at the office on the profile (D-235)', () {
    testWidgets('shows its values, the barangay by name, and the sentence', (
      tester,
    ) async {
      await _openEdit(tester, _Profile(_detail('verified', record: _record)));

      expect(find.byKey(officeRecordSectionKey), findsOneWidget);
      expect(find.text(OfficeRecordCopy.title), findsOneWidget);
      expect(find.text('Juana Santos Dela Cruz'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Mar 4, 1990'), findsOneWidget);
      expect(find.text('Dolores'), findsOneWidget);
      expect(find.textContaining(_doloresId), findsNothing);
      expect(find.text(OfficeRecordCopy.keptByOffice), findsOneWidget);
      expect(
        OfficeRecordCopy.keptByOffice,
        'The office keeps this record. If something here is wrong, visit the '
        'MSWDO office with your ID.',
      );
    });

    testWidgets('a barangay the list cannot name is never its id', (
      tester,
    ) async {
      const OfficeRecord elsewhere = OfficeRecord(
        firstName: 'Juana',
        lastName: 'Dela Cruz',
        birthDate: '1990-03-04',
        barangayId: '00000000-0000-4000-8000-00000000ffff',
      );
      await _openEdit(tester, _Profile(_detail('verified', record: elsewhere)));
      expect(find.textContaining('00000000-0000'), findsNothing);
      // No sex and no barangay name: both say to ask the office.
      expect(find.text(OfficeRecordCopy.notShown), findsNWidgets(2));
    });

    testWidgets('nothing extra when the account is not linked', (tester) async {
      await _openEdit(tester, _Profile(_detail('verified')));
      expect(find.byKey(officeRecordSectionKey), findsNothing);
      expect(find.text(OfficeRecordCopy.title), findsNothing);
    });
  });
}
