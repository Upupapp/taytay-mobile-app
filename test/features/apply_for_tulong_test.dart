import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/api/send_key.dart';
import 'package:taytay_resident/core/api/server_value.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/config/app_environment.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/documents/upload_policy.dart';
import 'package:taytay_resident/core/mock/mock_behavior.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/assistance/data/mock_own_assistance_repository.dart';
import 'package:taytay_resident/features/assistance/data/own_assistance_api_repository.dart';
import 'package:taytay_resident/features/assistance/data/own_assistance_codec.dart';
import 'package:taytay_resident/features/assistance/domain/assistance_application.dart';
import 'package:taytay_resident/features/assistance/domain/own_assistance_repository.dart';
import 'package:taytay_resident/features/assistance/domain/own_assistance_request.dart';
import 'package:taytay_resident/features/assistance/presentation/apply_controller.dart';
import 'package:taytay_resident/features/assistance/presentation/apply_for_tulong_screen.dart';
import 'package:taytay_resident/features/assistance/presentation/documents_sent_screen.dart';
import 'package:taytay_resident/features/assistance/presentation/my_requests_canvas.dart';
import 'package:taytay_resident/features/profile/data/resident_profile_api_repository.dart';
import 'package:taytay_resident/features/profile/domain/resident_profile_detail.dart';
import 'package:taytay_resident/features/profile/domain/resident_profile_repository.dart';
import 'package:taytay_resident/features/tulong/data/social_service_api_repository.dart';
import 'package:taytay_resident/features/tulong/data/social_service_codec.dart';
import 'package:taytay_resident/features/tulong/domain/social_service.dart';
import 'package:taytay_resident/features/verification/presentation/verification_status_pages.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';

import '../support/layout_matrix.dart';

/// D-226: applying for Tulong from the app, and sending the documents a
/// returned request still needs.
///
/// Synthetic throughout: the programmes, codes, control numbers and files are
/// made up, and nobody here is a real resident.

CapturedDocument _png() => CapturedDocument(
  bytes: Uint8List.fromList(<int>[0x89, 0x50, 0x4E, 0x47, 1, 2, 3, 4]),
  fileName: 'photo.png',
  mimeType: 'image/png',
  source: DocumentSource.camera,
);

const ApplicationRequirement _required = ApplicationRequirement(
  code: 'sample-enrolment',
  name: 'Sample certificate of enrolment',
  obligation: ApplicationObligation.required,
);
const ApplicationRequirement _optional = ApplicationRequirement(
  code: 'sample-grades',
  name: 'Sample report card',
  obligation: ApplicationObligation.optional,
);

const SocialService _service = SocialService(
  id: 'svc-sample',
  name: 'Sample educational assistance',
  slug: 'sample-education',
  summary: '',
  details: '',
  officeSlug: 'sample-mswdo',
  takesApplications: true,
  applicationRequirements: <ApplicationRequirement>[_required, _optional],
);

/// Hands back whatever file it was given, from any source.
class _Picker implements DocumentPicker {
  _Picker(this.document);

  CapturedDocument? document;
  final List<UploadPolicy> policies = <UploadPolicy>[];

  @override
  Future<CapturedDocument?> pick(
    DocumentSource source,
    UploadPolicy policy,
  ) async {
    policies.add(policy);
    return document;
  }

  @override
  bool supports(DocumentSource source) => true;
}

/// The dev mock, with the sends scriptable and every one recorded.
class _Assistance implements OwnAssistanceRepository {
  _Assistance()
    : _inner = MockOwnAssistanceRepository(
        MockBehaviorController(
          latency: Duration.zero,
          failure: MockFailureMode.none,
        ),
      );

  final MockOwnAssistanceRepository _inner;

  /// Answers for the next sends, in order; an empty list files.
  final List<AppFailure> failures = <AppFailure>[];
  final List<
    ({String slug, String purpose, int? amount, Set<String> codes, String key})
  >
  applies =
      <
        ({
          String slug,
          String purpose,
          int? amount,
          Set<String> codes,
          String key,
        })
      >[];
  final List<({String id, Set<String> codes, String key})> documents =
      <({String id, Set<String> codes, String key})>[];

  @override
  Future<Result<Paginated<OwnAssistanceRequest>>> listOwn({String? cursor}) =>
      _inner.listOwn(cursor: cursor);

  @override
  Future<Result<OwnAssistanceRequest>> findOwn(String id) => _inner.findOwn(id);

  @override
  Future<Result<OwnAssistanceRequest>> apply({
    required String serviceSlug,
    required String purpose,
    int? requestedAmountCentavos,
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  }) async {
    applies.add((
      slug: serviceSlug,
      purpose: purpose,
      amount: requestedAmountCentavos,
      codes: files.keys.toSet(),
      key: idempotencyKey,
    ));
    if (failures.isNotEmpty) {
      return Err<OwnAssistanceRequest>(failures.removeAt(0));
    }
    return _inner.apply(
      serviceSlug: serviceSlug,
      purpose: purpose,
      requestedAmountCentavos: requestedAmountCentavos,
      files: files,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<Result<OwnAssistanceRequest>> addDocuments(
    String requestId, {
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  }) async {
    documents.add((
      id: requestId,
      codes: files.keys.toSet(),
      key: idempotencyKey,
    ));
    if (failures.isNotEmpty) {
      return Err<OwnAssistanceRequest>(failures.removeAt(0));
    }
    return _inner.addDocuments(
      requestId,
      files: files,
      idempotencyKey: idempotencyKey,
    );
  }
}

/// Answers each request through [answer], and keeps what was asked.
class _Transport implements ApiTransport {
  _Transport(this.answer);

  Result<ApiHttpResponse> Function(ApiRequest request) answer;
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return answer(request);
  }
}

ApiClient _client(_Transport transport) => ApiClient(
  config: AppConfig.from(
    rawEnvironment: 'dev',
    rawApiBaseUrl: 'https://example.test/api/v1',
    isReleaseBuild: false,
    rawMockLatencyMs: '0',
  ),
  transport: transport,
  accessTokenProvider: () async => 'tok',
);

OwnAssistanceApiRepository _api(_Transport transport) =>
    OwnAssistanceApiRepository(apiClient: _client(transport));

/// What the local API answered in the P3 flow simulation, verbatim
/// (`test/fixtures/local_api/apply_flow.json`).
Map<String, dynamic> _localApi() =>
    jsonDecode(
          File('test/fixtures/local_api/apply_flow.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

/// Answers as the local API did: the Tulong page, the filing (or the 409 for
/// an account the office has not linked), her list; anything else is a 404.
_Transport _localTransport({required bool linked}) {
  final Map<String, dynamic> api = _localApi();
  ApiHttpResponse answer(String key) {
    final Map<String, dynamic> recorded = api[key] as Map<String, dynamic>;
    return ApiHttpResponse(
      statusCode: recorded['status'] as int,
      body: jsonEncode(recorded['body']),
    );
  }

  final String slug = _localSlug();
  return _Transport((ApiRequest request) {
    if (request.path == 'services/$slug') {
      return Ok(answer('service_detail'));
    }
    if (request.path == 'me/assistance-applications') {
      return Ok(answer(linked ? 'apply_201' : 'apply_409_unlinked'));
    }
    if (request.path == 'me/assistance-requests') {
      return Ok(answer('my_requests'));
    }
    return Ok(_error(404, 'NOT_FOUND'));
  });
}

String _localSlug() {
  final Map<String, dynamic> detail =
      _localApi()['service_detail'] as Map<String, dynamic>;
  final Map<String, dynamic> body = detail['body'] as Map<String, dynamic>;
  final Map<String, dynamic> data = body['data'] as Map<String, dynamic>;
  return data['slug'] as String;
}

Map<String, Object?> _row({
  String status = 'submitted',
  String channel = 'online',
  List<Object?> missing = const <Object?>[],
}) => <String, Object?>{
  'id': 'ar-sample-1',
  'reference_number': 'TAY-SAMPLE-0001',
  'program_name': 'Sample educational assistance',
  'filed_at': '2026-11-20T01:00:00Z',
  'status': status,
  'status_changed_at': '2026-11-20T01:00:00Z',
  'approved_amount_centavos': null,
  'payout_scheduled_for': null,
  'payout_venue': null,
  'released_at': null,
  'channel': channel,
  'missing_documents': missing,
};

ApiHttpResponse _created(Map<String, Object?> row) => ApiHttpResponse(
  statusCode: 201,
  body: jsonEncode(<String, Object?>{'data': row, 'meta': <String, Object?>{}}),
);

ApiHttpResponse _error(int status, String code, {Object? details}) =>
    ApiHttpResponse(
      statusCode: status,
      body: jsonEncode(<String, Object?>{
        'error': <String, Object?>{
          'code': code,
          'message': 'operator text',
          'details': details,
          'request_id': 'req-synthetic',
        },
      }),
    );

/// `GET /me` as the wizard reads it: [linked] is `linked_to_office_record`,
/// and [fails] makes the read fail, as a dropped connection would.
class _Profiles implements ResidentProfileRepository {
  _Profiles({this.linked, this.fails = false, this.tier = 'verified'});

  final bool? linked;
  final bool fails;

  /// What `GET /me` says the account is. The app reads it on start and takes
  /// its tier (D-228), so an unverified session needs an unverified answer.
  final String tier;
  int reads = 0;

  @override
  Future<Result<ResidentProfileDetail>> loadOwnDetail() async {
    reads++;
    if (fails) {
      return const Err<ResidentProfileDetail>(NetworkFailure());
    }
    return Ok<ResidentProfileDetail>(
      ResidentProfileDetail(
        verificationTier: tier,
        linkedToOfficeRecord: linked,
      ),
    );
  }

  @override
  Future<Result<ResidentProfileSummary>> loadOwnSummary() async =>
      const Ok<ResidentProfileSummary>(
        ResidentProfileSummary(verificationTier: 'verified'),
      );

  @override
  Future<Result<void>> updateContactDetails({
    required ContactDetailsUpdate update,
    required String idempotencyKey,
  }) async => const Ok<void>(null);

  @override
  Future<Result<void>> submitOwnUpdate({
    required Map<String, Object?> changes,
    required String idempotencyKey,
  }) async => const Ok<void>(null);
}

ApplyController _controller(
  _Assistance assistance, {
  bool verified = true,
  bool? linked,
  SocialService service = _service,
  List<String>? keys,
}) {
  int minted = 0;
  return ApplyController(
    repository: assistance,
    picker: _Picker(_png()),
    service: service,
    verified: verified,
    linkedToOfficeRecord: linked,
    sendKey: SendKey(mint: () => keys?[minted++] ?? 'key-${++minted}'),
  );
}

/// Walks a controller to the review with a purpose, an amount and the
/// required file.
Future<void> _toReview(ApplyController c, {String amount = ''}) async {
  c
    ..start()
    ..setPurpose('Sample school fees for my daughter')
    ..setAmount(amount);
  expect(c.toDocuments(), isTrue);
  await c.choose(_required.code, DocumentSource.camera);
  expect(c.toReview(), isTrue);
}

typedef _Booted = ({_Assistance assistance, _Picker picker});

Future<_Booted> _boot(
  WidgetTester tester, {
  AccessLevel? level = AccessLevel.verified,
  required String location,
  ApiClient? liveApi,
  ResidentProfileRepository? profiles,
}) async {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final InMemorySecretStore secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  final InMemorySessionStore store = InMemorySessionStore();
  if (level != null) {
    await store.write(
      StoredSession(
        resident: ResidentSession(
          accountId: 'acct-sample',
          accessLevel: level,
          displayName: 'Ana',
        ),
        accessToken: 'token-sample',
      ),
    );
  }
  final _Picker picker = _Picker(_png());
  final _Assistance assistance = _Assistance();
  final AppDependencies base = AppDependencies.build(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: '',
      isReleaseBuild: false,
      rawDataMode: 'mock',
      rawMockLatencyMs: '0',
    ),
    secrets: secrets,
    sessionStore: store,
    localAuthenticator: const UnavailableLocalAuthenticator(),
    documentPicker: picker,
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
    residentProfileRepository: profiles ?? base.residentProfileRepository,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: base.verificationRepository,
    documentPicker: picker,
    shareService: base.shareService,
    externalLinks: base.externalLinks,
    accountControlsRepository: base.accountControlsRepository,
    notificationRepository: base.notificationRepository,
    registrationRepository: base.registrationRepository,
    barangayDirectory: base.barangayDirectory,
    platform: base.platform,
    mockBehavior: base.mockBehavior,
    socialServices: liveApi == null
        ? base.socialServiceRepository
        : SocialServiceApiRepository(apiClient: liveApi),
    issuance: base.issuanceRepository,
    sectors: base.sectorRepository,
    ownAssistance: liveApi == null
        ? assistance
        : OwnAssistanceApiRepository(apiClient: liveApi),
    onDispose: base.onDispose,
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();
  return (assistance: assistance, picker: picker);
}

String _path(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(Scaffold).first),
).routerDelegate.currentConfiguration.uri.path;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

const String _apply = '/tulong/educational-assistance/apply';

void main() {
  group('a Tulong page says whether it takes applications', () {
    test('can_apply and the requirements, each obligation read', () {
      final SocialService? service = decodeSocialService(<String, Object?>{
        'slug': 'sample',
        'name': 'Sample',
        'can_apply': true,
        'application_requirements': <Object?>[
          <String, Object?>{
            'code': 'a',
            'name': 'A',
            'obligation': 'required',
            'condition': null,
          },
          <String, Object?>{
            'code': 'b',
            'name': 'B',
            'obligation': 'optional',
            'condition': null,
          },
          <String, Object?>{
            'code': 'c',
            'name': 'C',
            'obligation': 'conditional',
            'condition': 'When it applies',
          },
          // A value this build does not know is never read as required.
          <String, Object?>{'code': 'd', 'name': 'D', 'obligation': 'later'},
          // Nothing to send it under, or nothing to call it: dropped.
          <String, Object?>{'name': 'E', 'obligation': 'required'},
          <String, Object?>{'code': 'f', 'obligation': 'required'},
          // A code twice is one document.
          <String, Object?>{
            'code': 'a',
            'name': 'A2',
            'obligation': 'optional',
          },
        ],
      }, allowPresentation: false);
      expect(service?.takesApplications, isTrue);
      final List<ApplicationRequirement> rows =
          service?.applicationRequirements ?? const <ApplicationRequirement>[];
      expect(rows.map((ApplicationRequirement r) => r.code), <String>[
        'a',
        'b',
        'c',
        'd',
      ]);
      expect(rows.map((ApplicationRequirement r) => r.obligation), <Object>[
        ApplicationObligation.required,
        ApplicationObligation.optional,
        ApplicationObligation.conditional,
        ApplicationObligation.conditional,
      ]);
      expect(rows[2].condition, 'When it applies');
      expect(rows[0].required, isTrue);
      expect(rows[3].required, isFalse);
    });

    test('a list read without the fields takes no applications', () {
      final SocialService? service = decodeSocialService(<String, Object?>{
        'slug': 'sample',
        'name': 'Sample',
        'can_apply': 'yes',
      }, allowPresentation: false);
      expect(service?.takesApplications, isFalse);
      expect(service?.applicationRequirements, isEmpty);
    });
  });

  group('her own row says how it was filed and what is missing', () {
    test('channel and missing documents', () {
      final OwnAssistanceRequest? row = OwnAssistanceCodec.row(
        _row(
          status: 'returned',
          missing: <Object?>[
            <String, Object?>{
              'code': 'a',
              'name': 'A',
              'state': 'not-sent',
              'instruction': 'A clear photo.',
            },
            <String, Object?>{
              'code': 'b',
              'name': 'B',
              'state': 'send-again',
              'instruction': '',
            },
            <String, Object?>{'code': 'c', 'name': 'C', 'state': 'new'},
            <String, Object?>{'name': 'no code', 'state': 'not-sent'},
          ],
        ),
      );
      expect(row?.channel, AssistanceChannel.online);
      final List<MissingDocument> missing =
          row?.missingDocuments ?? const <MissingDocument>[];
      expect(missing.map((MissingDocument d) => d.state), <Object>[
        MissingDocumentState.notSent,
        MissingDocumentState.sendAgain,
        MissingDocumentState.other,
      ]);
      expect(missing[0].instruction, 'A clear photo.');
      expect(missing[1].instruction, isNull);
      expect(row?.takesDocuments, isTrue);
    });

    test('office, an unknown channel, and nothing to add', () {
      expect(
        OwnAssistanceCodec.row(_row(channel: 'office'))?.channel,
        AssistanceChannel.office,
      );
      expect(OwnAssistanceCodec.row(_row(channel: 'kiosk'))?.channel, isNull);
      // Missing documents on a request that is not returned offer nothing.
      final OwnAssistanceRequest? moved = OwnAssistanceCodec.row(
        _row(
          status: 'assessment',
          missing: <Object?>[
            <String, Object?>{'code': 'a', 'name': 'A', 'state': 'not-sent'},
          ],
        ),
      );
      expect(moved?.takesDocuments, isFalse);
      expect(
        OwnAssistanceCodec.row(_row(status: 'returned'))?.takesDocuments,
        isFalse,
      );
    });
  });

  group('what the wizard checks before anything leaves the phone', () {
    test('the purpose: 12 to 2000 characters, trimmed', () {
      expect(checkApplicationPurpose('   '), ApplicationPurposeProblem.empty);
      expect(
        checkApplicationPurpose(' too short '),
        ApplicationPurposeProblem.tooShort,
      );
      expect(checkApplicationPurpose('Twelve chars'), isNull);
      expect(checkApplicationPurpose('x' * 2000), isNull);
      expect(
        checkApplicationPurpose('x' * 2001),
        ApplicationPurposeProblem.tooLong,
      );
    });

    test('an amount is read into integer centavos, never a double', () {
      int? centavos(String typed) => switch (ApplicationAmount.parse(typed)) {
        AmountGiven(:final centavos) => centavos,
        _ => null,
      };
      ApplicationAmountProblem? problem(String typed) =>
          switch (ApplicationAmount.parse(typed)) {
            AmountRefused(:final problem) => problem,
            _ => null,
          };
      expect(ApplicationAmount.parse('  '), isA<AmountNotGiven>());
      expect(centavos('1500'), 150000);
      expect(centavos('1,500'), 150000);
      expect(centavos('1500.5'), 150050);
      expect(centavos('1,500.50'), 150050);
      expect(centavos('₱ 2,000'), 200000);
      expect(centavos('PHP 0.10'), 10);
      expect(centavos('99999999.99'), 9999999999);
      expect(problem('1,50'), ApplicationAmountProblem.unreadable);
      expect(problem('-5'), ApplicationAmountProblem.unreadable);
      expect(problem('1.234'), ApplicationAmountProblem.unreadable);
      expect(problem('five'), ApplicationAmountProblem.unreadable);
      expect(problem('.5'), ApplicationAmountProblem.unreadable);
      expect(problem('0'), ApplicationAmountProblem.zero);
      expect(problem('0.00'), ApplicationAmountProblem.zero);
      expect(problem('100000000'), ApplicationAmountProblem.tooLarge);
      expect(problem('123456789012345'), ApplicationAmountProblem.tooLarge);
    });

    test('only required documents are missing ones', () {
      expect(
        missingRequiredDocuments(const <ApplicationRequirement>[
          _required,
          _optional,
        ], const <String, CapturedDocument>{}),
        <ApplicationRequirement>[_required],
      );
      expect(
        missingRequiredDocuments(
          const <ApplicationRequirement>[_required, _optional],
          <String, CapturedDocument>{_required.code: _png()},
        ),
        isEmpty,
      );
    });
  });

  group('the repository sends the application the route reads', () {
    test('apply: multipart fields, files by code, 201 is her row', () async {
      final _Transport transport = _Transport((_) => Ok(_created(_row())));
      final Result<OwnAssistanceRequest> result = await _api(transport).apply(
        serviceSlug: 'sample-education',
        purpose: '  Sample school fees for my daughter  ',
        requestedAmountCentavos: 150050,
        files: <String, CapturedDocument>{'sample-enrolment': _png()},
        idempotencyKey: 'key-1',
      );
      final ApiRequest sent = transport.requests.single;
      expect(sent.method, HttpMethod.post);
      expect(sent.path, 'me/assistance-applications');
      expect(sent.body, <String, Object?>{
        'service_slug': 'sample-education',
        'purpose': 'Sample school fees for my daughter',
        'requested_amount_centavos': '150050',
        'idempotency_key': 'key-1',
      });
      expect(sent.files.map((MultipartFile f) => f.field), <String>[
        'sample-enrolment',
      ]);
      expect(sent.files.single.mimeType, 'image/png');
      expect(sent.files.single.filename, 'sample-enrolment.png');
      expect(switch (result) {
        Ok(:final value) => value.referenceNumber,
        Err() => null,
      }, 'TAY-SAMPLE-0001');
    });

    test('no amount is no field at all', () async {
      final _Transport transport = _Transport((_) => Ok(_created(_row())));
      await _api(transport).apply(
        serviceSlug: 's',
        purpose: 'Sample school fees',
        files: const <String, CapturedDocument>{},
        idempotencyKey: 'key-1',
      );
      final Object? body = transport.requests.single.body;
      expect(body, isA<Map<String, Object?>>());
      expect(
        (body as Map<String, Object?>?)?.containsKey(
          'requested_amount_centavos',
        ),
        isFalse,
      );
    });

    test('a 200 is not a filing', () async {
      final _Transport transport = _Transport(
        (_) => Ok(
          ApiHttpResponse(
            statusCode: 200,
            body: jsonEncode(<String, Object?>{'data': _row()}),
          ),
        ),
      );
      final Result<OwnAssistanceRequest> result = await _api(transport).apply(
        serviceSlug: 's',
        purpose: 'Sample school fees',
        files: const <String, CapturedDocument>{},
        idempotencyKey: 'key-1',
      );
      expect(result, isA<Err<OwnAssistanceRequest>>());
    });

    test('the refusals arrive as the kinds the wizard says', () async {
      Future<AppFailure?> refusal(ApiHttpResponse answer) async {
        final _Transport transport = _Transport((_) => Ok(answer));
        final Result<OwnAssistanceRequest> result = await _api(transport).apply(
          serviceSlug: 's',
          purpose: 'Sample school fees',
          files: const <String, CapturedDocument>{},
          idempotencyKey: 'key-1',
        );
        return switch (result) {
          Err(:final failure) => failure,
          Ok() => null,
        };
      }

      final AppFailure? notVerified = await refusal(
        _error(403, 'VERIFICATION_REQUIRED'),
      );
      expect(
        notVerified,
        isA<ForbiddenFailure>().having(
          (ForbiddenFailure f) => f.requiresVerification,
          'requiresVerification',
          isTrue,
        ),
      );
      expect(await refusal(_error(409, 'CONFLICT')), isA<ConflictFailure>());
      final AppFailure? invalid = await refusal(
        _error(
          422,
          'VALIDATION_FAILED',
          details: <String, Object?>{
            'sample-enrolment': <String>['Attach this document.'],
          },
        ),
      );
      expect(
        invalid,
        isA<ValidationFailure>().having(
          (ValidationFailure f) => f.fieldErrors.keys,
          'fields',
          contains('sample-enrolment'),
        ),
      );
    });

    test('add documents: the returned request, files by code', () async {
      final _Transport transport = _Transport(
        (_) => Ok(_created(_row(status: 'returned'))),
      );
      await _api(transport).addDocuments(
        'ar-sample-1',
        files: <String, CapturedDocument>{'a': _png()},
        idempotencyKey: 'key-2',
      );
      final ApiRequest sent = transport.requests.single;
      expect(sent.method, HttpMethod.post);
      expect(sent.path, 'me/assistance-requests/ar-sample-1/documents');
      expect(sent.body, <String, Object?>{'idempotency_key': 'key-2'});
      expect(sent.files.single.field, 'a');
    });
  });

  group('the wizard, step by step', () {
    test('an unverified resident starts on what to do first', () {
      final ApplyController c = _controller(_Assistance(), verified: false);
      expect(c.stage, ApplyStage.notVerified);
      c.start();
      expect(c.stage, ApplyStage.notVerified);
    });

    test('details refuse a short purpose and an unreadable amount', () {
      final ApplyController c = _controller(_Assistance())..start();
      expect(c.stage, ApplyStage.details);
      expect(c.showDetailProblems, isFalse);
      c
        ..setPurpose('short')
        ..setAmount('1,50');
      expect(c.toDocuments(), isFalse);
      expect(c.showDetailProblems, isTrue);
      expect(c.purposeProblem, ApplicationPurposeProblem.tooShort);
      expect(c.amountProblem, ApplicationAmountProblem.unreadable);
      c
        ..setPurpose('Sample school fees for my daughter')
        ..setAmount('');
      expect(c.toDocuments(), isTrue);
      expect(c.stage, ApplyStage.documents);
    });

    test(
      'a required document must have a file; an optional need not',
      () async {
        final ApplyController c = _controller(_Assistance())
          ..start()
          ..setPurpose('Sample school fees for my daughter');
        c.toDocuments();
        expect(c.toReview(), isFalse);
        expect(c.missing, <ApplicationRequirement>[_required]);
        await c.choose(_required.code, DocumentSource.camera);
        expect(c.toReview(), isTrue);
        expect(c.stage, ApplyStage.review);
        expect(c.files.keys, <String>[_required.code]);
      },
    );

    test('a file the phone refuses is said, not kept', () async {
      final _Assistance assistance = _Assistance();
      final ApplyController c = ApplyController(
        repository: assistance,
        picker: _Picker(
          CapturedDocument(
            bytes: Uint8List(9 * 1024 * 1024),
            fileName: 'big.png',
            mimeType: 'image/png',
            source: DocumentSource.file,
          ),
        ),
        service: _service,
        verified: true,
      );
      await c.choose(_required.code, DocumentSource.file);
      expect(c.files, isEmpty);
      expect(c.refusedFor(_required.code)?.reason, DocumentRejection.tooLarge);
      expect(c.uploadPolicy.maxMegabytes, 8);
    });

    test('back walks the steps, and the review edits a step', () async {
      final ApplyController c = _controller(_Assistance());
      await _toReview(c);
      c.edit(ApplyStage.details);
      expect(c.stage, ApplyStage.details);
      expect(c.back(), isTrue);
      expect(c.stage, ApplyStage.about);
      expect(c.back(), isFalse);
    });

    test('sending files it: the control number, the fields, the key', () async {
      final _Assistance assistance = _Assistance();
      final ApplyController c = _controller(assistance);
      await _toReview(c, amount: '2,500.50');
      await c.submit();
      expect(c.stage, ApplyStage.done);
      expect(c.filed?.referenceNumber, startsWith('TAY-SAMPLE-'));
      expect(c.files, isEmpty);
      final sent = assistance.applies.single;
      expect(sent.slug, 'sample-education');
      expect(sent.amount, 250050);
      expect(sent.codes, <String>{_required.code});
    });

    test('not linked (409) keeps the answers and can send again', () async {
      final _Assistance assistance = _Assistance()
        ..failures.add(const ConflictFailure());
      final ApplyController c = _controller(assistance);
      await _toReview(c);
      await c.submit();
      expect(c.stage, ApplyStage.notLinked);
      expect(c.files.keys, <String>[_required.code]);
      expect(c.purpose, 'Sample school fees for my daughter');
      await c.submit();
      expect(c.stage, ApplyStage.done);
      expect(assistance.applies, hasLength(2));
    });

    test('VERIFICATION_REQUIRED at the send says to verify first', () async {
      final _Assistance assistance = _Assistance()
        ..failures.add(const ForbiddenFailure(requiresVerification: true));
      final ApplyController c = _controller(assistance);
      await _toReview(c);
      await c.submit();
      expect(c.stage, ApplyStage.notVerified);
    });

    test('a refusal goes back to the step that holds what it named', () async {
      final _Assistance assistance = _Assistance()
        ..failures.addAll(const <AppFailure>[
          ValidationFailure(
            fieldErrors: <String, List<String>>{
              'purpose': <String>['too short'],
            },
          ),
          ValidationFailure(
            fieldErrors: <String, List<String>>{
              'sample-enrolment': <String>['not a PDF'],
            },
          ),
          ValidationFailure(
            fieldErrors: <String, List<String>>{
              'service_slug': <String>['closed'],
            },
          ),
        ]);
      final ApplyController c = _controller(assistance);
      await _toReview(c);
      await c.submit();
      expect(c.stage, ApplyStage.details);
      expect(c.serverFlagged('purpose'), isTrue);
      c.toDocuments();
      c.toReview();
      await c.submit();
      expect(c.stage, ApplyStage.documents);
      expect(c.serverFlagged(_required.code), isTrue);
      c.toReview();
      await c.submit();
      expect(c.stage, ApplyStage.review);
      expect(c.closed, isTrue);
    });

    test(
      'an unanswered send keeps its key; a changed one gets a new one',
      () async {
        final _Assistance assistance = _Assistance()
          ..failures.addAll(const <AppFailure>[
            TimeoutFailure(),
            NetworkFailure(),
          ]);
        final ApplyController c = _controller(
          assistance,
          keys: <String>['first', 'second'],
        );
        await _toReview(c);
        await c.submit();
        expect(c.stage, ApplyStage.review);
        expect(c.failure, isA<TimeoutFailure>());
        await c.submit();
        expect(c.failure, isA<NetworkFailure>());
        c.edit(ApplyStage.details);
        c.setPurpose('Sample school fees for my two daughters');
        c.toDocuments();
        c.toReview();
        await c.submit();
        expect(c.stage, ApplyStage.done);
        expect(assistance.applies.map((a) => a.key), <String>[
          'first',
          'first',
          'second',
        ]);
      },
    );
  });

  group('on screen', () {
    testWidgets('a page that takes applications offers Apply; another does '
        'not', (tester) async {
      await _boot(tester, location: '/programs/educational-assistance');
      expect(find.byKey(const Key('tulong-apply')), findsOneWidget);
      expect(find.text('Apply in the app'), findsOneWidget);
    });

    testWidgets('a page that takes none offers no Apply', (tester) async {
      await _boot(tester, location: '/programs/aics');
      expect(find.text('Call'), findsOneWidget);
      expect(find.byKey(const Key('tulong-apply')), findsNothing);
    });

    testWidgets('a guest who taps Apply is asked to sign in, and nothing '
        'opens', (tester) async {
      await _boot(
        tester,
        level: null,
        location: '/programs/educational-assistance',
      );
      await _tap(tester, find.byKey(const Key('tulong-apply')));
      expect(
        find.textContaining(
          'You need a Taytay LGU account to apply for this service.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('apply-about')), findsNothing);
    });

    testWidgets('the whole way: about, details, documents, review, sent', (
      tester,
    ) async {
      final _Booted booted = await _boot(
        tester,
        location: '/programs/educational-assistance',
      );
      await _tap(tester, find.byKey(const Key('tulong-apply')));

      // About: what it is, who can apply (the account link), what it asks.
      expect(find.byKey(const Key('apply-about')), findsOneWidget);
      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Who can apply in the app'), findsOneWidget);
      expect(find.textContaining('links your account'), findsOneWidget);
      expect(
        find.text('Sample certificate of enrolment · Required'),
        findsOneWidget,
      );
      expect(
        find.text('Sample: when the family has no income on record.'),
        findsOneWidget,
      );
      await _tap(tester, find.byKey(const Key('apply-start')));

      // Details: Next with nothing typed says what is missing.
      await _tap(tester, find.byKey(const Key('apply-details-next')));
      expect(find.text('Say what the assistance is for.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('apply-purpose')),
        'Sample school fees for my daughter',
      );
      await tester.enterText(find.byKey(const Key('apply-amount')), '1,500');
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const Key('apply-details-next')));

      // Documents: the limit is said before any pick.
      expect(find.byKey(const Key('apply-documents')), findsOneWidget);
      expect(find.textContaining('up to 8 MB each'), findsOneWidget);
      await _tap(tester, find.byKey(const Key('apply-documents-next')));
      expect(find.byKey(const Key('apply-required-missing')), findsOneWidget);
      expect(find.text('Add this file to continue.'), findsOneWidget);
      await _tap(
        tester,
        find.byKey(const Key('apply-add-sample-school-enrolment')),
      );
      await _tap(tester, find.byKey(const Key('apply-source-camera')));
      expect(find.text('Photo added · 8 bytes'), findsOneWidget);
      expect(booted.picker.policies.single.maxMegabytes, 8);
      await _tap(tester, find.byKey(const Key('apply-documents-next')));

      // Review: everything, then the send.
      expect(find.byKey(const Key('apply-review')), findsOneWidget);
      expect(find.text('Sample school fees for my daughter'), findsOneWidget);
      expect(find.text('₱1,500.00'), findsOneWidget);
      expect(
        find.text('Sample certificate of enrolment: Photo, 8 bytes'),
        findsOneWidget,
      );
      expect(find.text('Sample report card: not sent'), findsOneWidget);
      await _tap(tester, find.byKey(const Key('apply-send')));

      // Sent: the control number, and the way to My requests.
      expect(find.byKey(const Key('apply-done')), findsOneWidget);
      expect(find.text('TAY-SAMPLE-1001'), findsOneWidget);
      expect(
        find.textContaining('Some requests are discussed only in person'),
        findsOneWidget,
      );
      final sent = booted.assistance.applies.single;
      expect(sent.slug, 'educational-assistance');
      expect(sent.amount, 150000);
      await _tap(tester, find.text('Open My requests'));
      expect(_path(tester), '/my-requests');
      expect(find.text('Applied in the app'), findsWidgets);
    });

    testWidgets('an unverified resident is told to finish verification', (
      tester,
    ) async {
      await _boot(tester, level: AccessLevel.unverified, location: _apply);
      expect(find.byKey(const Key('apply-not-verified')), findsOneWidget);
      expect(find.text('Finish verifying your account first'), findsOneWidget);
      expect(find.byKey(const Key('apply-go-verify')), findsOneWidget);
      expect(find.byKey(const Key('apply-purpose')), findsNothing);
    });

    testWidgets('not linked: what to do, never a dead end', (tester) async {
      final _Booted booted = await _boot(tester, location: _apply);
      booted.assistance.failures.add(const ConflictFailure());
      await _tap(tester, find.byKey(const Key('apply-start')));
      await tester.enterText(
        find.byKey(const Key('apply-purpose')),
        'Sample school fees for my daughter',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const Key('apply-details-next')));
      await _tap(
        tester,
        find.byKey(const Key('apply-add-sample-school-enrolment')),
      );
      await _tap(tester, find.byKey(const Key('apply-source-camera')));
      await _tap(tester, find.byKey(const Key('apply-documents-next')));
      await _tap(tester, find.byKey(const Key('apply-send')));

      expect(find.byKey(const Key('apply-not-linked')), findsOneWidget);
      expect(find.textContaining('Nothing was sent.'), findsOneWidget);
      expect(find.textContaining('ask them to link'), findsOneWidget);
      expect(find.byKey(const Key('apply-try-again')), findsOneWidget);

      await _tap(tester, find.byKey(const Key('apply-try-again')));
      expect(find.byKey(const Key('apply-done')), findsOneWidget);
    });

    testWidgets('a failed send says plainly that nothing was sent', (
      tester,
    ) async {
      final _Booted booted = await _boot(tester, location: _apply);
      booted.assistance.failures.add(const NetworkFailure());
      await _tap(tester, find.byKey(const Key('apply-start')));
      await tester.enterText(
        find.byKey(const Key('apply-purpose')),
        'Sample school fees for my daughter',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const Key('apply-details-next')));
      await _tap(
        tester,
        find.byKey(const Key('apply-add-sample-school-enrolment')),
      );
      await _tap(tester, find.byKey(const Key('apply-source-camera')));
      await _tap(tester, find.byKey(const Key('apply-documents-next')));
      await _tap(tester, find.byKey(const Key('apply-send')));

      expect(find.byKey(const Key('apply-send-failure')), findsOneWidget);
      expect(find.textContaining('Nothing was sent.'), findsOneWidget);
      expect(find.byKey(const Key('apply-review')), findsOneWidget);
      expect(find.text('operator text'), findsNothing);
    });

    testWidgets('a page that takes no applications opens no wizard', (
      tester,
    ) async {
      await _boot(tester, location: '/tulong/aics/apply');
      expect(find.byKey(const Key('apply-not-offered')), findsOneWidget);
      expect(find.byKey(const Key('apply-about')), findsNothing);
    });

    testWidgets('a returned request lists what is missing and takes it', (
      tester,
    ) async {
      final _Booted booted = await _boot(
        tester,
        location: '/my-requests/ar-sample-returned',
      );
      expect(find.byKey(const Key('my-request-missing')), findsOneWidget);
      expect(
        find.text('Sample medical certificate · Send it again'),
        findsOneWidget,
      );
      expect(find.text('Applied in the app'), findsOneWidget);
      expect(
        find.textContaining('Some requests are discussed only in person'),
        findsOneWidget,
      );
      // What the officer wrote for her, said as the MSWDO's words (D-230).
      const String note = 'Sample: the photo is too blurred to read the date.';
      final Finder inRequest = find.byKey(
        const Key('my-request-applicant-note-sample-medical-certificate'),
      );
      expect(
        find.descendant(of: inRequest, matching: find.text('From the MSWDO:')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: inRequest, matching: find.text(note)),
        findsOneWidget,
      );
      await _tap(tester, find.byKey(const Key('my-request-add-documents')));
      expect(find.byKey(const Key('add-docs-limit')), findsOneWidget);
      final Finder inSlot = find.byKey(
        const Key('apply-applicant-note-sample-medical-certificate'),
      );
      expect(
        find.descendant(of: inSlot, matching: find.text('From the MSWDO:')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: inSlot, matching: find.text(note)),
        findsOneWidget,
      );

      // Nothing chosen is said, and nothing is sent.
      await _tap(tester, find.byKey(const Key('add-docs-send')));
      expect(find.byKey(const Key('add-docs-nothing-chosen')), findsOneWidget);
      expect(booted.assistance.documents, isEmpty);

      await _tap(
        tester,
        find.byKey(const Key('apply-add-sample-medical-certificate')),
      );
      await _tap(tester, find.byKey(const Key('apply-source-camera')));
      await _tap(tester, find.byKey(const Key('add-docs-send')));
      expect(find.byKey(const Key('add-docs-done')), findsOneWidget);
      expect(booted.assistance.documents.single.codes, <String>{
        'sample-medical-certificate',
      });
      expect(booted.assistance.documents.single.id, 'ar-sample-returned');

      // What was sent and when, what happens next, and the way back (D-231).
      expect(find.text('Documents sent'), findsOneWidget);
      expect(
        find.text(
          'The MSWDO will review what you sent. Until then, your request '
          'shows that it is waiting for the office.',
        ),
        findsOneWidget,
      );
      expect(find.text('TAY-SAMPLE-0004'), findsOneWidget);
      expect(find.text('Sample medical assistance'), findsOneWidget);
      expect(find.text('Sample medical certificate'), findsOneWidget);
      expect(find.text('Photo, 8 bytes'), findsOneWidget);
      expect(find.text('Sent on'), findsOneWidget);
      expect(find.textContaining('PHT'), findsOneWidget);
      expect(find.textContaining('Open the request any time'), findsOneWidget);

      await _tap(tester, find.text('Back to the request'));
      expect(find.byKey(const Key('add-docs-done')), findsNothing);
      expect(
        find.byKey(const Key('my-request-documents-sent')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('my-request-add-documents')), findsNothing);
    });

    testWidgets('a request that moved on says nothing was sent', (
      tester,
    ) async {
      final _Booted booted = await _boot(
        tester,
        location: '/my-requests/ar-sample-returned/documents',
      );
      booted.assistance.failures.add(const ConflictFailure());
      await _tap(
        tester,
        find.byKey(const Key('apply-add-sample-medical-certificate')),
      );
      await _tap(tester, find.byKey(const Key('apply-source-camera')));
      await _tap(tester, find.byKey(const Key('add-docs-send')));
      expect(find.text('The request has moved on'), findsOneWidget);
      expect(find.textContaining('Nothing was sent.'), findsOneWidget);
    });

    testWidgets('a request not returned offers no Add documents', (
      tester,
    ) async {
      await _boot(tester, location: '/my-requests/ar-sample-assessment');
      expect(find.byKey(const Key('my-request-missing')), findsNothing);
      expect(find.byKey(const Key('my-request-add-documents')), findsNothing);
    });

    // P3: the real wizard, against what the local API actually answered in the
    // flow simulation — the page, the filing or the 409, and her list.
    testWidgets('against the local API: the page, the filing, My requests', (
      tester,
    ) async {
      final _Transport transport = _localTransport(linked: true);
      await _boot(
        tester,
        location: '/tulong/${_localSlug()}/apply',
        liveApi: _client(transport),
      );
      expect(find.byKey(const Key('apply-about')), findsOneWidget);
      expect(find.text('Valid ID · Required'), findsOneWidget);
      expect(
        find.text('Barangay certificate of indigency · Required'),
        findsOneWidget,
      );
      await _tap(tester, find.byKey(const Key('apply-start')));
      await tester.enterText(
        find.byKey(const Key('apply-purpose')),
        'School fees and books for my son this semester.',
      );
      await tester.enterText(find.byKey(const Key('apply-amount')), '1,500');
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const Key('apply-details-next')));
      for (final String code in <String>[
        'valid-id',
        'certificate-of-indigency',
      ]) {
        await _tap(tester, find.byKey(Key('apply-add-$code')));
        await _tap(tester, find.byKey(const Key('apply-source-camera')));
      }
      await _tap(tester, find.byKey(const Key('apply-documents-next')));
      expect(find.byKey(const Key('apply-review')), findsOneWidget);
      await _tap(tester, find.byKey(const Key('apply-send')));

      expect(find.byKey(const Key('apply-done')), findsOneWidget);
      expect(find.text('TAY-2026-000042'), findsOneWidget);
      final ApiRequest sent = transport.requests.singleWhere(
        (ApiRequest r) => r.path == 'me/assistance-applications',
      );
      expect(sent.body, containsPair('service_slug', _localSlug()));
      expect(sent.body, containsPair('requested_amount_centavos', '150000'));
      expect(sent.files.map((MultipartFile f) => f.field).toSet(), <String>{
        'valid-id',
        'certificate-of-indigency',
      });

      await _tap(tester, find.text('Open My requests'));
      expect(_path(tester), '/my-requests');
      expect(find.text('Applied in the app'), findsWidgets);
      expect(find.textContaining('TAY-2026-000042'), findsWidgets);
    });

    testWidgets('against the local API: not linked is the 409 it sent', (
      tester,
    ) async {
      await _boot(
        tester,
        location: '/tulong/${_localSlug()}/apply',
        liveApi: _client(_localTransport(linked: false)),
      );
      await _tap(tester, find.byKey(const Key('apply-start')));
      await tester.enterText(
        find.byKey(const Key('apply-purpose')),
        'Rent and food after a fire in our street.',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const Key('apply-details-next')));
      for (final String code in <String>[
        'valid-id',
        'certificate-of-indigency',
      ]) {
        await _tap(tester, find.byKey(Key('apply-add-$code')));
        await _tap(tester, find.byKey(const Key('apply-source-camera')));
      }
      await _tap(tester, find.byKey(const Key('apply-documents-next')));
      await _tap(tester, find.byKey(const Key('apply-send')));
      expect(find.byKey(const Key('apply-not-linked')), findsOneWidget);
      expect(find.textContaining('Nothing was sent.'), findsOneWidget);
      // The server's own sentence never reaches the resident (Article 8).
      expect(find.textContaining('MSWDO has not linked'), findsNothing);
    });
  });

  group('every stage fits every phone, at 200% text', () {
    Widget l10n(Widget child) => Builder(
      builder: (BuildContext context) => Localizations.override(
        context: context,
        locale: const Locale('en'),
        delegates: AppStrings.localizationsDelegates,
        child: child,
      ),
    );

    final Map<String, Future<ApplyController> Function()> stages =
        <String, Future<ApplyController> Function()>{
          'about': () async => _controller(_Assistance()),
          'not verified': () async =>
              _controller(_Assistance(), verified: false),
          'not linked, said up front': () async =>
              _controller(_Assistance(), linked: false),
          'details with problems': () async {
            final ApplyController c = _controller(_Assistance())
              ..start()
              ..setAmount('five');
            c.toDocuments();
            return c;
          },
          'documents, one missing': () async {
            final ApplyController c = _controller(_Assistance())
              ..start()
              ..setPurpose('Sample school fees for my daughter');
            c
              ..toDocuments()
              ..toReview();
            return c;
          },
          'review after a failure': () async {
            final _Assistance assistance = _Assistance()
              ..failures.add(const NetworkFailure());
            final ApplyController c = _controller(assistance);
            await _toReview(c, amount: '99,999,999.99');
            await c.submit();
            return c;
          },
          'not linked': () async {
            final _Assistance assistance = _Assistance()
              ..failures.add(const ConflictFailure(requestId: 'req-sample'));
            final ApplyController c = _controller(assistance);
            await _toReview(c);
            await c.submit();
            return c;
          },
          'sent': () async {
            final ApplyController c = _controller(_Assistance());
            await _toReview(c);
            await c.submit();
            return c;
          },
        };

    for (final MapEntry<String, Future<ApplyController> Function()> stage
        in stages.entries) {
      testWidgets(stage.key, (tester) async {
        final ApplyController c = await stage.value();
        addTearDown(c.dispose);
        await expectCleanLayouts(
          tester,
          () => l10n(ApplyForTulongView(controller: c, onLeave: () {})),
          scrollable: false,
          height: 1400,
        );
      });
    }

    testWidgets('a returned request with what is missing', (tester) async {
      final OwnAssistanceRequest? returned = OwnAssistanceCodec.row(
        _row(
          status: 'returned',
          missing: <Object?>[
            <String, Object?>{
              'code': 'a',
              'name': 'Sample certificate with a long name from the office',
              'state': 'send-again',
              'instruction':
                  'Sample: a clear photo of the whole page, '
                  'with the signature and the dry seal readable.',
            },
          ],
        ),
      );
      await expectCleanLayouts(
        tester,
        () => l10n(
          MyRequestDetailCanvas(
            environment: AppEnvironment.dev,
            request: returned,
            onAddDocuments: () {},
          ),
        ),
        scrollable: false,
        height: 1400,
      );
    });
  });

  group('the account link, said before anything is typed', () {
    Future<bool?> decode(Map<String, Object?> me) async {
      final _Transport transport = _Transport(
        (ApiRequest request) => Ok(
          ApiHttpResponse(
            statusCode: 200,
            body: jsonEncode(<String, Object?>{
              'data': me,
              'meta': <String, Object?>{},
            }),
          ),
        ),
      );
      final Result<ResidentProfileDetail> read =
          await ResidentProfileApiRepository(
            apiClient: _client(transport),
          ).loadOwnDetail();
      expect(transport.requests.single.path, 'me');
      return switch (read) {
        Ok(:final ResidentProfileDetail value) => value.linkedToOfficeRecord,
        Err() => fail('GET /me did not decode'),
      };
    }

    Map<String, Object?> me([Object? linked = #missing]) => <String, Object?>{
      'name': 'Sample Resident',
      'role': 'verified',
      'verification_status': 'verified',
      if (linked != #missing) 'linked_to_office_record': linked,
    };

    test('GET /me: true and false are read; null, missing and anything '
        'else are unknown', () async {
      expect(await decode(me(true)), isTrue);
      expect(await decode(me(false)), isFalse);
      expect(await decode(me(null)), isNull);
      expect(await decode(me()), isNull);
      // Not a boolean is "not said", never "not linked".
      expect(await decode(me('false')), isNull);
      expect(await decode(me(0)), isNull);
    });

    test('verified and not linked starts on what to do first, with no '
        'form', () async {
      final _Assistance assistance = _Assistance();
      final ApplyController c = _controller(assistance, linked: false);
      expect(c.stage, ApplyStage.unlinked);
      expect(c.stepNumber, isNull);
      c.start();
      expect(c.stage, ApplyStage.unlinked);
      expect(c.toDocuments(), isFalse);
      expect(c.back(), isFalse);
      await c.submit();
      expect(c.stage, ApplyStage.unlinked);
      expect(assistance.applies, isEmpty);
    });

    test('linked, or not said, keeps the four steps; unverified comes '
        'first', () {
      expect(_controller(_Assistance(), linked: true).stage, ApplyStage.about);
      expect(_controller(_Assistance()).stage, ApplyStage.about);
      expect(
        _controller(_Assistance(), verified: false, linked: false).stage,
        ApplyStage.notVerified,
      );
    });

    testWidgets('the wizard says it up front and offers no form', (
      tester,
    ) async {
      final _Profiles profiles = _Profiles(linked: false);
      final _Booted booted = await _boot(
        tester,
        location: _apply,
        profiles: profiles,
      );
      expect(profiles.reads, greaterThanOrEqualTo(1));
      expect(find.byKey(const Key('apply-unlinked')), findsOneWidget);
      expect(find.text('The MSWDO needs to link your account'), findsOneWidget);
      expect(
        find.textContaining('ask them to link your app account'),
        findsOneWidget,
      );
      expect(find.textContaining('come back to this page'), findsOneWidget);
      // Nothing was typed, so nothing is said about a send.
      expect(find.textContaining('Nothing was sent.'), findsNothing);
      expect(find.text('Step 1 of 4'), findsNothing);
      expect(find.byKey(const Key('apply-start')), findsNothing);
      expect(find.byKey(const Key('apply-purpose')), findsNothing);
      expect(find.byKey(const Key('apply-try-again')), findsNothing);
      expect(find.byKey(const Key('apply-back-to-programme')), findsOneWidget);
      expect(
        find.text('You can also apply in person at the MSWDO.'),
        findsOneWidget,
      );
      expect(booted.assistance.applies, isEmpty);
    });

    testWidgets('linked opens the first step as before', (tester) async {
      await _boot(tester, location: _apply, profiles: _Profiles(linked: true));
      expect(find.byKey(const Key('apply-about')), findsOneWidget);
      expect(find.byKey(const Key('apply-unlinked')), findsNothing);
    });

    testWidgets('an older API (null) finds out at the send, as before', (
      tester,
    ) async {
      final _Booted booted = await _boot(
        tester,
        location: _apply,
        profiles: _Profiles(),
      );
      expect(find.byKey(const Key('apply-about')), findsOneWidget);
      booted.assistance.failures.add(const ConflictFailure());
      await _tap(tester, find.byKey(const Key('apply-start')));
      await tester.enterText(
        find.byKey(const Key('apply-purpose')),
        'Sample school fees for my daughter',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const Key('apply-details-next')));
      await _tap(
        tester,
        find.byKey(const Key('apply-add-sample-school-enrolment')),
      );
      await _tap(tester, find.byKey(const Key('apply-source-camera')));
      await _tap(tester, find.byKey(const Key('apply-documents-next')));
      await _tap(tester, find.byKey(const Key('apply-send')));
      expect(find.byKey(const Key('apply-not-linked')), findsOneWidget);
      expect(find.textContaining('Nothing was sent.'), findsOneWidget);
    });

    testWidgets('a failed GET /me is unknown, never "not linked"', (
      tester,
    ) async {
      await _boot(tester, location: _apply, profiles: _Profiles(fails: true));
      expect(find.byKey(const Key('apply-about')), findsOneWidget);
      expect(find.byKey(const Key('apply-unlinked')), findsNothing);
    });

    testWidgets('an unverified resident is told to verify, not about the '
        'link', (tester) async {
      await _boot(
        tester,
        level: AccessLevel.unverified,
        location: _apply,
        profiles: _Profiles(linked: false, tier: 'unverified'),
      );
      expect(find.byKey(const Key('apply-not-verified')), findsOneWidget);
      expect(find.byKey(const Key('apply-unlinked')), findsNothing);
    });

    testWidgets('the Tulong card says when the account is not linked', (
      tester,
    ) async {
      await _boot(
        tester,
        location: '/programs/educational-assistance',
        profiles: _Profiles(linked: false),
      );
      expect(find.byKey(const Key('tulong-apply')), findsOneWidget);
      expect(
        find.text(
          'Your account is not yet linked to your MSWDO record. The MSWDO '
          'links it when it reviews your ID, or at the counter.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the Tulong card says linked when it is', (tester) async {
      await _boot(
        tester,
        location: '/programs/educational-assistance',
        profiles: _Profiles(linked: true),
      );
      expect(
        find.text('Your account is linked to your MSWDO record.'),
        findsOneWidget,
      );
    });

    testWidgets('the Tulong card says nothing of the link when not said', (
      tester,
    ) async {
      await _boot(
        tester,
        location: '/programs/educational-assistance',
        profiles: _Profiles(),
      );
      expect(find.byKey(const Key('tulong-apply')), findsOneWidget);
      expect(find.byKey(const Key('tulong-apply-linked')), findsNothing);
      expect(find.byKey(const Key('tulong-apply-not-linked')), findsNothing);
    });

    testWidgets('an empty My requests names an unlinked account only', (
      tester,
    ) async {
      Future<void> pump(bool? linked) => tester.pumpWidget(
        layoutHost(
          MyRequestsCanvas(
            environment: AppEnvironment.dev,
            items: const <OwnAssistanceRequest>[],
            accountLinked: linked,
          ),
          scrollable: false,
        ),
      );
      await pump(false);
      expect(find.byKey(const Key('my-requests-empty')), findsOneWidget);
      expect(find.byKey(const Key('my-requests-not-linked')), findsOneWidget);
      await pump(true);
      expect(find.byKey(const Key('my-requests-not-linked')), findsNothing);
      await pump(null);
      expect(find.byKey(const Key('my-requests-not-linked')), findsNothing);
    });

    testWidgets('the Verified page says linked, or explains the link', (
      tester,
    ) async {
      Future<void> pump(bool? linked) => tester.pumpWidget(
        layoutHost(
          VerifiedStatusPage(linkedToOfficeRecord: linked),
          scrollable: false,
        ),
      );
      await pump(true);
      expect(
        find.textContaining('Your account is linked to your MSWDO record.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('One more step happens at the office'),
        findsNothing,
      );
      await pump(false);
      expect(
        find.textContaining('One more step happens at the office'),
        findsOneWidget,
      );
      await pump(null);
      expect(
        find.textContaining('One more step happens at the office'),
        findsOneWidget,
      );
    });
  });

  group('Documents sent says what was sent and what happens next (D-231)', () {
    OwnAssistanceRequest after({
      List<MissingDocument> stillNeeded = const <MissingDocument>[],
      DateTime? sentAt,
    }) => OwnAssistanceRequest(
      id: 'ar-1',
      referenceNumber: 'TAY-SAMPLE-0099',
      programName: 'Sample medical assistance',
      filedAt: DateTime.utc(2026, 11, 14),
      status: const ServerValue<AssistanceRequestStatus>(
        raw: 'returned',
        known: AssistanceRequestStatus.returned,
      ),
      statusChangedAt: DateTime.utc(2026, 11, 17),
      missingDocuments: stillNeeded,
      documentsSentAt: sentAt,
    );
    const List<SentDocument> sent = <SentDocument>[
      SentDocument(
        name: 'Sample medical certificate',
        isImage: true,
        size: '1.2 MB',
      ),
      SentDocument(
        name: 'Sample barangay certificate',
        isImage: false,
        size: '300 KB',
      ),
    ];

    testWidgets('each document, the time the API recorded, and the way back', (
      tester,
    ) async {
      var back = 0;
      await tester.pumpWidget(
        layoutHost(
          DocumentsSentScreen(
            request: after(sentAt: DateTime.utc(2026, 11, 22, 7, 40)),
            sent: sent,
            onBackToRequest: () => back++,
          ),
          scrollable: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TAY-SAMPLE-0099'), findsOneWidget);
      expect(find.text('Photo, 1.2 MB'), findsOneWidget);
      expect(find.text('PDF, 300 KB'), findsOneWidget);
      // 07:40 UTC is 3:40 PM in Manila.
      expect(find.text('Sun 22 Nov 2026, 3:40 PM PHT'), findsOneWidget);
      expect(find.textContaining('still needs'), findsNothing);
      await tester.tap(find.text('Back to the request'));
      expect(back, 1);
    });

    testWidgets('a request still naming documents says which', (tester) async {
      await tester.pumpWidget(
        layoutHost(
          DocumentsSentScreen(
            request: after(
              stillNeeded: const <MissingDocument>[
                MissingDocument(
                  code: 'sample-id',
                  name: 'Sample valid ID',
                  state: MissingDocumentState.notSent,
                ),
              ],
              sentAt: DateTime.utc(2026, 11, 22, 7, 40),
            ),
            sent: sent.take(1).toList(),
            onBackToRequest: () {},
          ),
          scrollable: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'The office still needs: Sample valid ID. Send them from the '
          'request when you have them.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('will review'), findsNothing);
    });

    testWidgets('no time is said when the API sent none', (tester) async {
      await tester.pumpWidget(
        layoutHost(
          DocumentsSentScreen(
            request: after(),
            sent: sent,
            onBackToRequest: () {},
          ),
          scrollable: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sent on'), findsNothing);
      expect(find.textContaining('PHT'), findsNothing);
    });

    testWidgets('it fits every phone, at 200% text', (tester) async {
      await expectCleanLayouts(
        tester,
        () => DocumentsSentScreen(
          request: after(
            stillNeeded: const <MissingDocument>[
              MissingDocument(
                code: 'sample-id',
                name: 'Sample valid ID',
                state: MissingDocumentState.notSent,
              ),
            ],
            sentAt: DateTime.utc(2026, 11, 22, 7, 40),
          ),
          sent: sent,
          onBackToRequest: () {},
        ),
        scrollable: false,
      );
    });
  });

  group('every new string speaks Filipino too', () {
    test('the Tulong card, the steps and the states', () {
      final AppStrings en = lookupAppStrings(const Locale('en'));
      final AppStrings fil = lookupAppStrings(const Locale('fil'));
      final List<String Function(AppStrings)> keys =
          <String Function(AppStrings)>[
            (AppStrings s) => s.applyCardTitle,
            (AppStrings s) => s.applyAboutBody,
            (AppStrings s) => s.applyWhoBody,
            (AppStrings s) => s.applyNotVerifiedBody,
            (AppStrings s) => s.applyNotLinkedBody,
            (AppStrings s) => s.applyPurposeLabel,
            (AppStrings s) => s.applyDocumentsIntro(8),
            (AppStrings s) => s.applyRequiredMissing,
            (AppStrings s) => s.applyReviewNote,
            (AppStrings s) => s.applyOfflineBody,
            (AppStrings s) => s.applyDoneNote,
            (AppStrings s) => s.addDocsIntro(8),
            (AppStrings s) => s.myRequestsChannelOnline,
            (AppStrings s) => s.myRequestMissingHeading,
            (AppStrings s) => s.verifiedLinkNote,
            (AppStrings s) => s.verifiedLinkedNote,
            (AppStrings s) => s.applyUnlinkedBody,
            (AppStrings s) => s.accountLinkedNote,
            (AppStrings s) => s.accountNotLinkedNote,
            (AppStrings s) => s.addDocsDoneMessage,
            (AppStrings s) => s.addDocsDoneStillNeeded('X'),
            (AppStrings s) => s.addDocsDoneFile('Photo', '1 MB'),
            (AppStrings s) => s.addDocsDoneSentOn,
            (AppStrings s) => s.addDocsDoneNote,
            (AppStrings s) => s.accountSectorsSubtitle,
          ];
      for (final String Function(AppStrings) key in keys) {
        expect(key(fil), isNot(key(en)));
        expect(key(fil), isNotEmpty);
      }
      // The failure sentences keep D-087's promise in both languages.
      expect(en.applyOfflineBody, startsWith('Nothing was sent.'));
      expect(fil.applyOfflineBody, startsWith('Walang naipadala.'));
      expect(fil.applyNotLinkedBody, startsWith('Walang naipadala.'));
    });
  });
}
