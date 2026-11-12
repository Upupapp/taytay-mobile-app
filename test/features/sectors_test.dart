import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/config/app_environment.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/documents/upload_policy.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/router/route_guard.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/access_policy.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/sectors/data/sector_api_repository.dart';
import 'package:taytay_resident/features/sectors/data/sector_codec.dart';
import 'package:taytay_resident/features/sectors/domain/resident_sector.dart';
import 'package:taytay_resident/features/sectors/domain/sector_repository.dart';
import 'package:taytay_resident/features/sectors/presentation/sector_apply_canvas.dart';
import 'package:taytay_resident/features/sectors/presentation/sector_apply_controller.dart';
import 'package:taytay_resident/features/sectors/presentation/sectors_canvas.dart';
import 'package:taytay_resident/features/sectors/presentation/sectors_copy.dart';
import 'package:taytay_resident/shared/widgets/failure_view.dart';
import 'package:taytay_resident/shared/widgets/loading_skeleton.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';

import '../support/layout_matrix.dart';

// ── Synthetic data. Nobody here is a real person or a real record. ───────

final DateTime _today = DateTime.utc(2026, 11, 12, 4);

final SectorOverview _overview = SectorOverview(
  recorded: <OwnSector>[
    OwnSector(
      sector: ResidentSector.pwd,
      since: DateTime.utc(2025, 3, 2),
      idLastFour: '0000',
      validUntil: DateTime.utc(2028, 3, 2),
    ),
  ],
  applications: <SectorApplication>[
    SectorApplication(
      id: 'sa-sample-1',
      sector: ResidentSector.soloParent,
      status: SectorApplicationStatus.pending,
      submittedAt: DateTime.utc(2026, 11, 2, 6, 41),
    ),
  ],
);

final CapturedDocument _photo = CapturedDocument(
  bytes: Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 1, 2, 3, 4]),
  fileName: 'IMG_sample.jpg',
  mimeType: 'image/jpeg',
  source: DocumentSource.gallery,
);

class _Picker implements DocumentPicker {
  _Picker([this.answer]);

  CapturedDocument? answer;
  int picks = 0;

  @override
  Future<CapturedDocument?> pick(
    DocumentSource source,
    UploadPolicy policy,
  ) async {
    picks++;
    return answer ?? _photo;
  }

  @override
  bool supports(DocumentSource source) => source == DocumentSource.gallery;
}

/// A repository that records what it was asked and answers from a script.
class _Repository implements SectorRepository {
  _Repository({this.own = const <OwnSector>[]});

  List<OwnSector> own;
  final List<SectorApplication> applications = const <SectorApplication>[];
  Result<List<OwnSector>>? ownFailure;
  final List<Result<String>> uploads = <Result<String>>[];
  final List<Result<SectorApplication>> answers = <Result<SectorApplication>>[];
  final List<CapturedDocument> uploaded = <CapturedDocument>[];
  final List<({ResidentSector sector, List<String> ids})> sent =
      <({ResidentSector sector, List<String> ids})>[];
  int reads = 0;

  @override
  Future<Result<List<OwnSector>>> listOwn() async {
    reads++;
    return ownFailure ?? Ok<List<OwnSector>>(own);
  }

  @override
  Future<Result<List<SectorApplication>>> listApplications() async =>
      Ok<List<SectorApplication>>(applications);

  @override
  Future<Result<String>> uploadProof(CapturedDocument proof) async {
    uploaded.add(proof);
    return uploads.isEmpty ? const Ok<String>('media-1') : uploads.removeAt(0);
  }

  @override
  Future<Result<SectorApplication>> apply({
    required ResidentSector sector,
    required List<String> proofMediaIds,
  }) async {
    sent.add((sector: sector, ids: proofMediaIds));
    if (answers.isNotEmpty) return answers.removeAt(0);
    return Ok<SectorApplication>(
      SectorApplication(
        id: 'sa-new',
        sector: sector,
        status: SectorApplicationStatus.pending,
        submittedAt: DateTime.utc(2026, 11, 12, 6, 41),
      ),
    );
  }
}

class _Scripted implements ApiTransport {
  final List<Result<ApiHttpResponse>> responses = <Result<ApiHttpResponse>>[];
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return responses.isEmpty
        ? const Err<ApiHttpResponse>(NetworkFailure())
        : responses.removeAt(0);
  }
}

Result<ApiHttpResponse> _ok(Object? data, {int status = 200}) =>
    Ok<ApiHttpResponse>(
      ApiHttpResponse(
        statusCode: status,
        body: jsonEncode(<String, Object?>{
          'data': data,
          'meta': <String, Object?>{'request_id': 'req-1'},
        }),
        headers: const <String, String>{'x-request-id': 'req-1'},
      ),
    );

AppConfig _mockConfig() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: '',
  isReleaseBuild: false,
  rawDataMode: 'mock',
  rawMockLatencyMs: '0',
);

/// The whole app on the dev mock, with [sectors] and [picker] in place of
/// the mock's, signed in at [level], at [location].
Future<AppDependencies> _boot(
  WidgetTester tester, {
  SectorRepository? sectors,
  DocumentPicker? picker,
  AccessLevel level = AccessLevel.verified,
  String location = '/sectors',
  Size size = const Size(400, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final InMemorySecretStore secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  final InMemorySessionStore store = InMemorySessionStore();
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
  final AppDependencies base = AppDependencies.build(
    config: _mockConfig(),
    secrets: secrets,
    sessionStore: store,
    localAuthenticator: const UnavailableLocalAuthenticator(),
    documentPicker: picker ?? const UnavailableDocumentPicker(),
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
    residentProfileRepository: base.residentProfileRepository,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: base.verificationRepository,
    residentRecordRepository: base.residentRecordRepository,
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
    mockBehavior: base.mockBehavior,
    officeMessaging: base.officeMessagingRepository,
    socialServices: base.socialServiceRepository,
    issuance: base.issuanceRepository,
    sectors: sectors ?? base.sectorRepository,
    passwordClient: base.accountPasswordClient,
    onDispose: base.onDispose,
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();
  return dependencies;
}

String _rendered(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((Text text) => text.data ?? text.textSpan?.toPlainText() ?? '')
    .join('\n');

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('the wire (citizen pack B4)', () {
    test('sectors are an allow-list: a sensitive sector is never held', () {
      final List<OwnSector> own = SectorCodec.ownList(<Object?>[
        <String, Object?>{'sector': 'senior-citizen', 'since': '2026-01-15'},
        <String, Object?>{'sector': 'vawc-survivor', 'since': '2026-01-15'},
        <String, Object?>{'sector': 'cicl'},
        <String, Object?>{'sector': 'indigency'},
        <String, Object?>{'sector': 'four-ps'},
        <String, Object?>{'sector': 'Senior-Citizen'},
        <String, Object?>{'sector': 42},
        'not a row',
      ]);
      expect(own.map((OwnSector o) => o.sector), <ResidentSector>[
        ResidentSector.seniorCitizen,
      ]);
      expect(ResidentSector.values, hasLength(3));
    });

    test('an ID number is held as its last four characters only', () {
      // The server masks it (`••••1234`, backend `maskDocumentNumber`).
      final OwnSector? own = SectorCodec.own(<String, Object?>{
        'sector': 'pwd',
        'since': '2026-01-15',
        'id_number': '••••0042',
        'valid_until': '2027-03-02',
      });
      expect(own?.idLastFour, '0042');
      expect(SectorCodec.lastFour('XX-SAMPLE-0042'), '0042');
      expect(SectorCodec.lastFour('42'), '42');
      expect(SectorCodec.lastFour('••••'), isNull);
      expect(SectorCodec.lastFour('  '), isNull);
      expect(own.toString(), isNot(contains('0042')));
    });

    test('a date-only value is that day on the Manila calendar', () {
      final OwnSector? own = SectorCodec.own(<String, Object?>{
        'sector': 'pwd',
        'since': '2026-11-02',
        'valid_until': '2027-03-02T00:00:00Z',
      });
      expect(own?.since, DateTime.utc(2026, 11, 2));
      expect(own?.validUntil, DateTime.utc(2027, 3, 2));
    });

    test('an application with an unknown status or no id is dropped', () {
      final List<SectorApplication> rows = SectorCodec.applicationList(
        <Object?>[
          <String, Object?>{
            'id': 'sa-1',
            'sector': 'solo-parent',
            'status': 'returned',
            'reason': '  The photo is blurred.  ',
            'submitted_at': '2026-11-02T06:41:00Z',
          },
          <String, Object?>{'id': 'sa-2', 'sector': 'pwd', 'status': 'lost'},
          <String, Object?>{'sector': 'pwd', 'status': 'pending'},
          <String, Object?>{
            'id': 'sa-3',
            'sector': 'cicl',
            'status': 'pending',
          },
        ],
      );
      expect(rows, hasLength(1));
      expect(rows.single.status, SectorApplicationStatus.returned);
      expect(rows.single.reason, 'The photo is blurred.');
      expect(rows.single.submittedAt, DateTime.utc(2026, 11, 2, 6, 41));
    });

    test('the application body is the sector and the proof, nothing else', () {
      final Map<String, Object?> body = SectorCodec.applicationBody(
        sector: ResidentSector.soloParent,
        proofMediaIds: <String>['media-1'],
      );
      expect(body.keys, unorderedEquals(<String>['sector', 'proof_media_ids']));
      expect(body['sector'], 'solo-parent');
      expect(body['proof_media_ids'], <String>['media-1']);
      expect(
        SectorCodec.wireSector(ResidentSector.seniorCitizen),
        'senior-citizen',
      );
      expect(SectorCodec.wireSector(ResidentSector.pwd), 'pwd');
    });
  });

  group('SectorApiRepository', () {
    late _Scripted transport;
    late SectorApiRepository repository;

    setUp(() {
      transport = _Scripted();
      repository = SectorApiRepository(
        apiClient: ApiClient(
          config: AppConfig.from(
            rawEnvironment: 'dev',
            rawApiBaseUrl: 'https://example.test/api/v1',
            isReleaseBuild: false,
          ),
          transport: transport,
          accessTokenProvider: () async => 'tok',
        ),
      );
    });

    test('reads the two /me lists with the bearer token', () async {
      transport.responses
        ..add(
          _ok(<Object?>[
            <String, Object?>{'sector': 'pwd', 'id_number': '1234'},
          ]),
        )
        ..add(_ok(<Object?>[]));
      final Result<List<OwnSector>> own = await repository.listOwn();
      final Result<List<SectorApplication>> sent = await repository
          .listApplications();

      expect(own.valueOrNull?.single.sector, ResidentSector.pwd);
      expect(sent.valueOrNull, isEmpty);
      expect(
        transport.requests.map((ApiRequest r) => '${r.method.name} ${r.path}'),
        <String>['get me/sectors', 'get me/sector-applications'],
      );
      for (final ApiRequest request in transport.requests) {
        expect(request.headers['Authorization'], 'Bearer tok');
        expect(request.query, isEmpty);
      }
    });

    test('uploads the photo under its own name, never the phone\'s', () async {
      transport.responses.add(
        _ok(<String, Object?>{'id': 'media-9'}, status: 201),
      );
      final Result<String> id = await repository.uploadProof(_photo);

      expect(id.valueOrNull, 'media-9');
      final ApiRequest request = transport.requests.single;
      expect(request.method, HttpMethod.post);
      expect(request.path, 'media');
      expect(request.file?.field, 'file');
      expect(request.file?.filename, 'sector-proof.jpg');
      expect(request.file?.filename, isNot(contains('IMG')));
    });

    test('files the application and reads back what was filed', () async {
      transport.responses.add(
        _ok(<String, Object?>{
          'id': 'sa-7',
          'sector': 'senior-citizen',
          'status': 'pending',
          'submitted_at': '2026-11-12T06:41:00Z',
        }, status: 201),
      );
      final Result<SectorApplication> filed = await repository.apply(
        sector: ResidentSector.seniorCitizen,
        proofMediaIds: <String>['media-9'],
      );

      expect(filed.valueOrNull?.id, 'sa-7');
      final ApiRequest request = transport.requests.single;
      expect(request.method, HttpMethod.post);
      expect(request.path, 'me/sector-applications');
      expect(request.body, <String, Object?>{
        'sector': 'senior-citizen',
        'proof_media_ids': <String>['media-9'],
      });
    });

    test('a success with no readable body is a contract failure', () async {
      transport.responses.add(_ok(null, status: 201));
      final Result<SectorApplication> filed = await repository.apply(
        sector: ResidentSector.pwd,
        proofMediaIds: <String>['media-9'],
      );
      expect(filed.failureOrNull, isA<ContractFailure>());
    });
  });

  group('SectorOverview', () {
    test('the newest application per sector, approved ones not repeated', () {
      final SectorOverview overview = SectorOverview(
        recorded: const <OwnSector>[],
        applications: <SectorApplication>[
          SectorApplication(
            id: 'a',
            sector: ResidentSector.pwd,
            status: SectorApplicationStatus.returned,
            submittedAt: DateTime.utc(2026, 10, 1),
          ),
          SectorApplication(
            id: 'b',
            sector: ResidentSector.pwd,
            status: SectorApplicationStatus.pending,
            submittedAt: DateTime.utc(2026, 11, 1),
          ),
          SectorApplication(
            id: 'c',
            sector: ResidentSector.seniorCitizen,
            status: SectorApplicationStatus.approved,
            submittedAt: DateTime.utc(2026, 9, 1),
          ),
        ],
      );
      expect(overview.latest.map((SectorApplication a) => a.id), <String>[
        'b',
        'c',
      ]);
      expect(overview.open.map((SectorApplication a) => a.id), <String>['b']);
    });

    test('offers what is neither being checked nor held', () {
      expect(_overview.offered, <ResidentSector>[ResidentSector.seniorCitizen]);
      final SectorOverview lapsed = SectorOverview(
        recorded: <OwnSector>[
          OwnSector(
            sector: ResidentSector.soloParent,
            validUntil: DateTime.utc(2026, 11, 11),
          ),
        ],
        applications: const <SectorApplication>[
          SectorApplication(
            id: 'r',
            sector: ResidentSector.pwd,
            status: SectorApplicationStatus.returned,
          ),
        ],
      );
      // A returned application is offered again. A held sector is not, even
      // with its ID lapsed: the server refuses it with a conflict.
      expect(lapsed.offered, <ResidentSector>[
        ResidentSector.seniorCitizen,
        ResidentSector.pwd,
      ]);
      expect(lapsed.recorded.single.lapsedOn(_today), isTrue);
      // Valid through today is still valid.
      expect(
        OwnSector(
          sector: ResidentSector.soloParent,
          validUntil: DateTime.utc(2026, 11, 12),
        ).lapsedOn(_today),
        isFalse,
      );
    });
  });

  group('SectorApplyController', () {
    test('uploads once: a retried application reuses the photo', () async {
      final _Repository repository = _Repository();
      repository.answers.add(const Err<SectorApplication>(NetworkFailure()));
      final SectorApplyController controller = SectorApplyController(
        repository: repository,
        picker: _Picker(),
        initial: ResidentSector.pwd,
      );
      addTearDown(controller.dispose);
      controller.next();
      await controller.pick(DocumentSource.gallery);
      controller.confirm(true);
      expect(controller.readyToSend, isTrue);

      await controller.send();
      expect(controller.step, SectorApplyStep.proof);
      expect(controller.failure, isA<NetworkFailure>());
      expect(controller.proof, isNotNull);

      await controller.send();
      expect(controller.step, SectorApplyStep.sent);
      expect(repository.uploaded, hasLength(1));
      expect(repository.sent, hasLength(2));
      expect(repository.sent.last.ids, <String>['media-1']);
      expect(controller.proof, isNull, reason: 'the bytes are let go');
    });

    test('changing the sector drops the photo and the tick', () async {
      final SectorApplyController controller = SectorApplyController(
        repository: _Repository(),
        picker: _Picker(),
        initial: ResidentSector.soloParent,
      );
      addTearDown(controller.dispose);
      controller.next();
      await controller.pick(DocumentSource.gallery);
      controller.confirm(true);
      controller.back();
      controller.choose(ResidentSector.seniorCitizen);
      expect(controller.proof, isNull);
      expect(controller.confirmed, isFalse);
    });

    test('a photo the upload rule refuses is not kept', () async {
      final SectorApplyController controller = SectorApplyController(
        repository: _Repository(),
        picker: _Picker(
          CapturedDocument(
            bytes: Uint8List.fromList(<int>[0x47, 0x49, 0x46, 0x38]),
            fileName: 'sample.gif',
            mimeType: 'image/gif',
            source: DocumentSource.gallery,
          ),
        ),
        initial: ResidentSector.pwd,
      );
      addTearDown(controller.dispose);
      controller.next();
      await controller.pick(DocumentSource.gallery);
      expect(controller.proof, isNull);
      expect(controller.refused?.reason, DocumentRejection.unsupportedType);
    });

    test('every failure says in words whether anything was sent', () {
      for (final AppFailure failure in <AppFailure>[
        const NetworkFailure(),
        const TimeoutFailure(),
        const ConflictFailure(),
        const ForbiddenFailure(),
        const ServerFailure(),
        const ContractFailure(),
      ]) {
        final ({String title, String body}) copy = sectorSendFailure(failure);
        expect(copy.title, isNotEmpty);
        if (failure.outcomeUnknown) {
          expect(copy.body, SectorsCopy.unconfirmed);
        } else {
          expect(copy.body, startsWith('Nothing'), reason: '$failure');
        }
      }
    });
  });

  group('access', () {
    const SessionState guest = GuestSession();
    const SessionState unverified = AuthenticatedSession(
      ResidentSession(accountId: 'a', accessLevel: AccessLevel.unverified),
    );
    const SessionState verified = AuthenticatedSession(
      ResidentSession(accountId: 'a', accessLevel: AccessLevel.verified),
    );

    for (final AppRoute route in <AppRoute>[
      AppRoute.sectors,
      AppRoute.sectorApply,
    ]) {
      test('${route.path} × guest, unverified, verified', () {
        expect(route.requirement, AccessRequirement.verified);
        final String? toGuest = resolveRedirect(
          session: guest,
          location: route.path,
        );
        expect(toGuest, startsWith(AppRoute.signIn.path));
        expect(
          resolveRedirect(session: unverified, location: route.path),
          AppRoute.verification.path,
        );
        expect(
          resolveRedirect(session: verified, location: route.path),
          isNull,
        );
      });
    }
  });

  group('Sectors and benefits', () {
    Widget canvas({
      SectorOverview? overview,
      AppFailure? failure,
      bool loading = false,
    }) => SectorsCanvas(
      today: _today,
      environment: AppEnvironment.dev,
      overview: overview,
      failure: failure,
      loading: loading,
      onRetry: () {},
      onApply: (_) {},
    );

    testWidgets('loading is a skeleton, never "nothing here"', (tester) async {
      await tester.pumpWidget(
        layoutHost(canvas(loading: true), scrollable: false),
      );
      expect(find.byType(LoadingSkeleton), findsOneWidget);
      expect(find.text(SectorsCopy.none), findsNothing);
    });

    testWidgets('a failed read is the failure view with Try again', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(canvas(failure: const NetworkFailure()), scrollable: false),
      );
      expect(find.byType(FailureView), findsOneWidget);
      expect(find.text(SectorsCopy.yoursHeading), findsNothing);
    });

    testWidgets('an empty record says so and still offers all three', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(
          canvas(
            overview: SectorOverview(
              recorded: const <OwnSector>[],
              applications: const <SectorApplication>[],
            ),
          ),
          scrollable: false,
        ),
      );
      expect(find.text(SectorsCopy.none), findsOneWidget);
      for (final ResidentSector sector in ResidentSector.values) {
        expect(find.byKey(Key('sectors-apply-${sector.name}')), findsOneWidget);
      }
    });

    testWidgets('rows say the status in words, from the API only', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(canvas(overview: _overview), scrollable: false),
      );
      await tester.pumpAndSettle();
      expect(find.text('Person with disability'), findsOneWidget);
      expect(
        find.text(
          'Since 02 Mar 2025 · ID ending 0000 · Valid until 02 Mar 2028',
        ),
        findsOneWidget,
      );
      expect(find.text(SectorsCopy.recorded), findsOneWidget);
      expect(find.byKey(const Key('sectors-none')), findsNothing);
      expect(find.text(SectorsCopy.beingChecked), findsOneWidget);
      expect(find.text('You applied 02 Nov 2026'), findsOneWidget);
      // Solo parent is being checked and PWD is held: only senior is offered.
      expect(
        find.byKey(const Key('sectors-apply-seniorCitizen')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('sectors-apply-pwd')), findsNothing);
      expect(find.byKey(const Key('sectors-apply-soloParent')), findsNothing);
      // Claims the API does not support stay out.
      final String text = _rendered(tester);
      for (final String claim in <String>['remind', 'notif', 'DSWD']) {
        expect(text, isNot(contains(claim)), reason: claim);
      }
    });

    testWidgets('a returned application shows the office\'s words and is '
        'offered again', (tester) async {
      ResidentSector? opened;
      await tester.pumpWidget(
        layoutHost(
          SectorsCanvas(
            today: _today,
            environment: AppEnvironment.dev,
            overview: SectorOverview(
              recorded: const <OwnSector>[],
              applications: const <SectorApplication>[
                SectorApplication(
                  id: 'r',
                  sector: ResidentSector.pwd,
                  status: SectorApplicationStatus.returned,
                  reason: 'Please send a clearer photo.',
                ),
              ],
            ),
            onApply: (ResidentSector sector) => opened = sector,
          ),
          scrollable: false,
        ),
      );
      expect(
        find.text('The office said: Please send a clearer photo.'),
        findsOneWidget,
      );
      // Nothing is recorded until the office links the account on its first
      // approval, and the page says so beside the application.
      expect(find.text(SectorsCopy.none), findsOneWidget);
      await _tapVisible(tester, find.byKey(const Key('sectors-returned-pwd')));
      expect(opened, ResidentSector.pwd);
    });

    testWidgets('every frame fits every phone at 200% text', (tester) async {
      for (final Widget Function() frame in <Widget Function()>[
        () => canvas(loading: true),
        () => canvas(failure: const ServerFailure()),
        () => canvas(
          overview: SectorOverview(
            recorded: const <OwnSector>[],
            applications: const <SectorApplication>[],
          ),
        ),
        () => canvas(overview: _overview),
      ]) {
        await expectCleanLayouts(tester, frame, scrollable: false);
      }
    });
  });

  group('Apply for a sector', () {
    Widget apply(
      SectorApplyStep step, {
      CapturedDocument? proof,
      bool confirmed = false,
      AppFailure? failure,
    }) => SectorApplyCanvas(
      step: step,
      policy: UploadPolicy.fallback,
      chosen: ResidentSector.soloParent,
      proof: proof,
      confirmed: confirmed,
      failure: failure,
      filed: SectorApplication(
        id: 'sa-new',
        sector: ResidentSector.soloParent,
        status: SectorApplicationStatus.pending,
        submittedAt: DateTime.utc(2026, 11, 12, 6, 41),
      ),
      onChoose: (_) {},
      onNext: () {},
      onStepBack: () {},
      onAddPhoto: () {},
      onConfirm: (_) {},
      onSend: () {},
      onSectors: () {},
      onHome: () {},
    );

    testWidgets('every step fits every phone at 200% text', (tester) async {
      for (final Widget Function() frame in <Widget Function()>[
        () => apply(SectorApplyStep.choose),
        () => apply(SectorApplyStep.proof),
        () => apply(
          SectorApplyStep.proof,
          proof: _photo,
          confirmed: true,
          failure: const NetworkFailure(),
        ),
        () => apply(SectorApplyStep.sending, proof: _photo, confirmed: true),
        () => apply(SectorApplyStep.sent),
      ]) {
        await expectCleanLayouts(tester, frame, scrollable: false);
      }
    });

    testWidgets('the proof step collects no number, date or reason', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(apply(SectorApplyStep.proof), scrollable: false),
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Add your Solo Parent ID'), findsOneWidget);
      // Send stays off until a photo is added and the tick is given.
      final Finder send = find.byKey(const Key('sector-apply-send'));
      expect(send, findsOneWidget);
    });

    testWidgets('the whole flow from My Account to the receipt', (
      tester,
    ) async {
      final _Repository repository = _Repository(
        own: <OwnSector>[const OwnSector(sector: ResidentSector.pwd)],
      );
      await _boot(
        tester,
        sectors: repository,
        picker: _Picker(),
        location: '/profile',
      );

      await _tapVisible(tester, find.text('Sectors and benefits'));
      expect(find.text('Person with disability'), findsOneWidget);
      expect(find.byType(TaytayBackButton), findsOneWidget);
      final int readsBefore = repository.reads;

      await _tapVisible(
        tester,
        find.byKey(const Key('sectors-apply-soloParent')),
      );
      // Step 1, with the tapped sector already chosen; nothing in the URL.
      expect(find.byKey(const Key('sector-apply-choose')), findsOneWidget);
      expect(find.text(SectorsCopy.stepOne), findsOneWidget);
      await _tapVisible(tester, find.byKey(const Key('sector-apply-next')));

      // Step 2.
      expect(find.byKey(const Key('sector-apply-proof')), findsOneWidget);
      expect(find.text(SectorsCopy.stepTwo), findsOneWidget);
      await _tapVisible(tester, find.byKey(const Key('sector-apply-add')));
      await _tapVisible(tester, find.byKey(const Key('sector-source-gallery')));
      expect(
        find.text(SectorsCopy.photoAdded(_photo.readableSize)),
        findsOneWidget,
      );
      expect(_rendered(tester), isNot(contains('IMG_sample')));
      await _tapVisible(tester, find.byKey(const Key('sector-apply-confirm')));
      await _tapVisible(tester, find.byKey(const Key('sector-apply-send')));

      // The receipt.
      expect(find.byKey(const Key('sector-apply-sent')), findsOneWidget);
      expect(find.text(SectorsCopy.sentTitle), findsOneWidget);
      expect(repository.sent.single.sector, ResidentSector.soloParent);
      expect(repository.sent.single.ids, <String>['media-1']);

      // Back to the list, which reads again.
      await _tapVisible(tester, find.text(SectorsCopy.backToSectors));
      expect(find.text(SectorsCopy.yoursHeading), findsOneWidget);
      expect(repository.reads, greaterThan(readsBefore));
    });

    testWidgets('a failed send keeps the form and says nothing was sent', (
      tester,
    ) async {
      final _Repository repository = _Repository();
      repository.answers.add(const Err<SectorApplication>(ConflictFailure()));
      await _boot(tester, sectors: repository, picker: _Picker());

      await _tapVisible(tester, find.byKey(const Key('sectors-apply-pwd')));
      await _tapVisible(tester, find.byKey(const Key('sector-apply-next')));
      await _tapVisible(tester, find.byKey(const Key('sector-apply-add')));
      await _tapVisible(tester, find.byKey(const Key('sector-source-gallery')));
      await _tapVisible(tester, find.byKey(const Key('sector-apply-confirm')));
      await _tapVisible(tester, find.byKey(const Key('sector-apply-send')));

      expect(find.byKey(const Key('sector-apply-failure')), findsOneWidget);
      expect(find.text(SectorsCopy.waitingTitle), findsOneWidget);
      expect(find.byKey(const Key('sector-apply-proof')), findsOneWidget);
      expect(find.byKey(const Key('sector-apply-sent')), findsNothing);
    });

    testWidgets('step 2 back returns to step 1, not out of the flow', (
      tester,
    ) async {
      await _boot(tester, sectors: _Repository(), picker: _Picker());
      await _tapVisible(tester, find.byKey(const Key('sectors-apply-pwd')));
      await _tapVisible(tester, find.byKey(const Key('sector-apply-next')));
      expect(find.byKey(const Key('sector-apply-proof')), findsOneWidget);
      await _tapVisible(tester, find.byType(TaytayBackButton));
      expect(find.byKey(const Key('sector-apply-choose')), findsOneWidget);
      await _tapVisible(tester, find.byType(TaytayBackButton));
      expect(find.text(SectorsCopy.yoursHeading), findsOneWidget);
    });

    testWidgets('the dev mock opens with its synthetic record', (tester) async {
      await _boot(tester);
      expect(find.byKey(const Key('sectors-own-pwd')), findsOneWidget);
      expect(find.text(SectorsCopy.beingChecked), findsOneWidget);
      expect(
        find.byKey(const Key('sectors-apply-seniorCitizen')),
        findsOneWidget,
      );
    });

    testWidgets('a failed read offers Try again, and Try again reads', (
      tester,
    ) async {
      final _Repository repository = _Repository()
        ..ownFailure = const Err<List<OwnSector>>(ServerFailure());
      await _boot(tester, sectors: repository);
      expect(find.byType(FailureView), findsOneWidget);
      repository.ownFailure = null;
      await _tapVisible(tester, find.text('Try again'));
      expect(find.text(SectorsCopy.none), findsOneWidget);
    });
  });
}
