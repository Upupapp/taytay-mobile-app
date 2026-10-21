import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/verification/data/resident_record_api_repository.dart';
import 'package:taytay_resident/features/verification/domain/resident_record.dart';
import 'package:taytay_resident/features/verification/domain/resident_record_repository.dart';
import 'package:taytay_resident/features/verification/presentation/profile_wizard_page.dart';
import 'package:taytay_resident/features/verification/presentation/profile_wizard_screen.dart';

AppConfig _config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

ApiHttpResponse _json(int status, Object body) => ApiHttpResponse(
  statusCode: status,
  body: jsonEncode(body),
  headers: const <String, String>{'x-request-id': 'req-s3'},
);

ApiHttpResponse _ok(Object? data) =>
    _json(200, <String, dynamic>{'data': data});

ApiHttpResponse _error(int status, String code) => _json(status, <String, dynamic>{
  'error': <String, dynamic>{'code': code, 'request_id': 'req-s3'},
});

class _Scripted implements ApiTransport {
  _Scripted(this.script);

  final List<ApiHttpResponse> script;
  final List<ApiRequest> sent = <ApiRequest>[];
  int _index = 0;

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    sent.add(request);
    final response = script[math.min(_index, script.length - 1)];
    _index++;
    return Ok<ApiHttpResponse>(response);
  }
}

Map<String, dynamic> _profile({String status = 'pending'}) => <String, dynamic>{
  'name': 'Juana Santos Dela Cruz',
  'birthdate': '1992-03-14',
  'sex': 'female',
  'mobile': '09171234567',
  'email': 'juana.delacruz@example.com',
  'barangay_id': 'barangay-san-juan',
  'street': '12 Sampaguita St.',
  'purok': '3',
  'verification_status': status,
  'rejection_reason': status == 'rejected' ? 'The ID photo is blurred.' : null,
};

Map<String, dynamic> _household() => <String, dynamic>{
  'id': 'hh-secret',
  'barangay_id': 'barangay-san-juan',
  'barangay_name': 'San Juan',
  'address': '12 Sampaguita St., Purok 3',
  'members': <Object?>[
    <String, dynamic>{
      'name': 'Pedro Planted Cruz',
      'birthdate': '2010-01-02',
      'sex': 'male',
      'user_id': 'user-pedro',
    },
    <String, dynamic>{'name': 'Maria Planted Cruz'},
    <String, dynamic>{'name': 'Luis Planted Cruz'},
    <String, dynamic>{'name': 'Ana Planted Cruz'},
  ],
};

void main() {
  test('a household member name never leaves the decoder', () async {
    final transport = _Scripted(<ApiHttpResponse>[
      _ok(_profile(status: 'rejected')),
      _ok(_household()),
    ]);
    final repository = ResidentRecordApiRepository(
      apiClient: ApiClient(
        config: _config(),
        transport: transport,
        accessTokenProvider: () async => 'token',
      ),
    );

    final result = await repository.load();
    final record = result.valueOrNull!;

    expect(record.memberCount, '4');
    expect(record.verificationTier, 'rejected');
    expect(record.rejectionReason, 'The ID photo is blurred.');
    expect(record.street, '12 Sampaguita St.');
    expect(record.purok, '3');
    expect(record.givenName, 'Juana');
    expect(record.familyName, 'Cruz');
    expect(record.toString(), 'ResidentRecord(completeness: 100)');
    expect(record.toString(), isNot(contains('Pedro')));
    expect(record.toString(), isNot(contains('Sampaguita')));
    expect(record.toString(), isNot(contains('hh-secret')));
    expect('$record', isNot(contains('2010-01-02')));
    expect(transport.sent.map((ApiRequest r) => r.path), <String>[
      'me',
      'households/current',
    ]);
  });

  test('street and purok are written with the published names', () async {
    final transport = _Scripted(<ApiHttpResponse>[
      _ok(null),
      _ok(null),
      _ok(_profile()),
      _ok(_household()),
    ]);
    final repository = ResidentRecordApiRepository(
      apiClient: ApiClient(
        config: _config(),
        transport: transport,
        accessTokenProvider: () async => 'token',
      ),
    );

    const draft = HouseholdDraft(
      barangayId: 'barangay-san-juan',
      barangayName: 'San Juan',
      street: '12 Sampaguita St.',
      purok: '3',
      yearsAtAddress: '6',
      memberCount: '4',
      residenceType: 'Owned',
    );
    final saved = await repository.saveHousehold(draft);
    expect(saved.isOk, isTrue);

    final profilePatch = transport.sent.first;
    expect(profilePatch.method, HttpMethod.patch);
    expect(profilePatch.path, 'me');
    final body = profilePatch.body! as Map<String, Object?>;
    expect(body['street'], '12 Sampaguita St.');
    expect(body['purok'], '3');
    expect(body.containsKey('years_at_address'), isFalse);
    expect(body.containsKey('residence_type'), isFalse);
    expect(body.containsKey('member_count'), isFalse);

    final householdPatch = transport.sent[1];
    expect(householdPatch.path, 'households/current');
    final householdBody = householdPatch.body! as Map<String, Object?>;
    expect(householdBody.containsKey('members'), isFalse);
    expect(householdBody.containsKey('household_id'), isFalse);
  });

  test('a missing household is created without an id', () async {
    final transport = _Scripted(<ApiHttpResponse>[
      _ok(null),
      _error(404, 'NOT_FOUND'),
      _ok(<String, dynamic>{'id': 'hh-new'}),
      _ok(_profile()),
      _ok(_household()),
    ]);
    final repository = ResidentRecordApiRepository(
      apiClient: ApiClient(
        config: _config(),
        transport: transport,
        accessTokenProvider: () async => 'token',
      ),
    );

    const draft = HouseholdDraft(
      barangayId: 'barangay-san-juan',
      barangayName: 'San Juan',
      street: '12 Sampaguita St.',
      purok: '3',
      yearsAtAddress: '6',
      memberCount: '4',
      residenceType: 'Owned',
    );
    expect((await repository.saveHousehold(draft)).isOk, isTrue);
    expect(transport.sent[2].method, HttpMethod.post);
    expect(transport.sent[2].path, 'households');
    final created = transport.sent[2].body! as Map<String, Object?>;
    expect(created.containsKey('id'), isFalse);
    expect(created['barangay_id'], 'barangay-san-juan');
  });

  testWidgets('the wizard keeps the record off the session', (tester) async {
    final secrets = InMemorySecretStore();
    await secrets.write(LaunchController.welcomeCompletedKey, 'true');
    final sessionStore = InMemorySessionStore();
    await sessionStore.write(
      const StoredSession(
        resident: ResidentSession(
          accountId: 'acct-1',
          accessLevel: AccessLevel.unverified,
          displayName: 'Ana',
        ),
        accessToken: 'token',
      ),
    );
    final base = AppDependencies.build(
      config: _config(),
      secrets: secrets,
      sessionStore: sessionStore,
    );
    final dependencies = AppDependencies(
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
      residentProfileRepository: base.residentProfileRepository,
      householdRepository: base.householdRepository,
      credentialRepository: base.credentialRepository,
      verificationRepository: base.verificationRepository,
      residentRecordRepository: const _FixedRecordRepository(),
      serviceRequestRepository: base.serviceRequestRepository,
      requirementRepository: base.requirementRepository,
      documentPicker: base.documentPicker,
      shareService: base.shareService,
      externalLinks: base.externalLinks,
      accountControlsRepository: base.accountControlsRepository,
      notificationRepository: base.notificationRepository,
      registrationRepository: base.registrationRepository,
      barangayDirectory: base.barangayDirectory,
      platform: base.platform,
      onDispose: base.onDispose,
    );
    addTearDown(dependencies.dispose);
    await dependencies.session.restore();

    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: dependencies,
        child: const MaterialApp(
          home: ProfileWizardScreen(step: ProfileWizardStep.overview),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Juana Dela Cruz'), findsOneWidget);
    final resident = dependencies.session.state.residentOrNull!;
    expect(resident.displayName, 'Ana');
    expect(resident.accessLevel, AccessLevel.unverified);
    expect(resident.accountId, 'acct-1');
    expect(dependencies.session.toString(), isNot(contains('Juana')));
    expect(dependencies.session.toString(), isNot(contains('Sampaguita')));
  });
}

class _FixedRecordRepository implements ResidentRecordRepository {
  const _FixedRecordRepository();

  static const ResidentRecord _record = ResidentRecord(
    givenName: 'Juana',
    middleName: 'Santos',
    familyName: 'Dela Cruz',
    sex: 'Female',
    birthdate: '1992-03-14',
    street: '12 Sampaguita St.',
    purok: '3',
    barangayName: 'San Juan',
    verificationTier: 'pending',
    completeness: 60,
  );

  @override
  Future<Result<ResidentRecord>> load() async => const Ok<ResidentRecord>(_record);

  @override
  Future<Result<ResidentRecord>> saveHousehold(HouseholdDraft draft) async =>
      const Ok<ResidentRecord>(_record);

  @override
  Future<Result<ResidentRecord>> savePersonal(PersonalDraft draft) async =>
      const Ok<ResidentRecord>(_record);

  @override
  Future<Result<ResidentRecord>> submit({
    required PersonalDraft personal,
    required HouseholdDraft household,
  }) async => const Ok<ResidentRecord>(_record);
}
