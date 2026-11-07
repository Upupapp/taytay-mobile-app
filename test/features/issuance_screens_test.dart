import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
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
import 'package:taytay_resident/features/issuance/data/mock_issuance_repository.dart';
import 'package:taytay_resident/features/issuance/domain/issuance_repository.dart';
import 'package:taytay_resident/features/issuance/domain/issuance_request.dart';
import 'package:taytay_resident/features/issuance/domain/issuance_type.dart';

/// Hands back whatever file it was given, from any source.
class _Picker implements DocumentPicker {
  _Picker(this.document);

  CapturedDocument? document;

  @override
  Future<CapturedDocument?> pick(
    DocumentSource source,
    UploadPolicy policy,
  ) async => document;

  @override
  bool supports(DocumentSource source) => true;
}

/// The dev mock, with the submit answer scriptable and every send recorded.
class _Issuance implements IssuanceRepository {
  _Issuance()
    : _inner = MockIssuanceRepository(
        MockBehaviorController(
          latency: Duration.zero,
          failure: MockFailureMode.none,
        ),
      );

  final MockIssuanceRepository _inner;
  AppFailure? failSubmit;
  final List<Map<String, CapturedDocument>> submitted =
      <Map<String, CapturedDocument>>[];

  @override
  Future<Result<List<IssuanceType>>> listTypes() => _inner.listTypes();

  @override
  Future<Result<IssuanceType>> loadType(String typeId) =>
      _inner.loadType(typeId);

  @override
  Future<Result<IssuanceRequestDetail>> submit({
    required String typeId,
    required String purpose,
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  }) async {
    submitted.add(files);
    final AppFailure? failure = failSubmit;
    if (failure != null) return Err<IssuanceRequestDetail>(failure);
    return _inner.submit(
      typeId: typeId,
      purpose: purpose,
      files: files,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<Result<Paginated<IssuanceRequestSummary>>> listOwn({String? cursor}) =>
      _inner.listOwn(cursor: cursor);

  @override
  Future<Result<IssuanceRequestDetail>> loadOwn(String requestId) =>
      _inner.loadOwn(requestId);

  @override
  Future<Result<IssuanceRequestDetail>> cancel(
    String requestId, {
    String? reason,
    required String idempotencyKey,
  }) =>
      _inner.cancel(requestId, reason: reason, idempotencyKey: idempotencyKey);

  @override
  Future<Result<IssuanceRequestDetail>> resubmit(
    String requestId, {
    String? note,
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  }) => _inner.resubmit(
    requestId,
    note: note,
    files: files,
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<Result<Uint8List>> loadAttachmentImage(
    String requestId,
    String attachmentId,
  ) => _inner.loadAttachmentImage(requestId, attachmentId);
}

CapturedDocument _pdf({String mimeType = 'application/pdf'}) =>
    CapturedDocument(
      bytes: Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46, 1, 2, 3, 4]),
      fileName: 'scan.pdf',
      mimeType: mimeType,
      source: DocumentSource.file,
    );

typedef _Booted = ({_Issuance issuance, _Picker picker});

Future<_Booted> _boot(
  WidgetTester tester, {
  AccessLevel? level = AccessLevel.verified,
  String location = '/documents',
  CapturedDocument? document,
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
  final _Picker picker = _Picker(document ?? _pdf());
  final _Issuance issuance = _Issuance();
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
    residentProfileRepository: base.residentProfileRepository,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: base.verificationRepository,
    serviceRequestRepository: base.serviceRequestRepository,
    requirementRepository: base.requirementRepository,
    documentPicker: picker,
    shareService: base.shareService,
    externalLinks: base.externalLinks,
    accountControlsRepository: base.accountControlsRepository,
    notificationRepository: base.notificationRepository,
    registrationRepository: base.registrationRepository,
    barangayDirectory: base.barangayDirectory,
    platform: base.platform,
    mockBehavior: base.mockBehavior,
    issuance: issuance,
    onDispose: base.onDispose,
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
  _go(tester, location);
  await tester.pumpAndSettle();
  return (issuance: issuance, picker: picker);
}

void _go(WidgetTester tester, String location) {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
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

const String _form = '/documents/types/dt-sample-birth/request';

void main() {
  group('the verified-only gate, from every session state', () {
    testWidgets('a guest reads the catalogue and is asked to sign in', (
      tester,
    ) async {
      await _boot(tester, level: null);

      expect(find.text('Certified copy of a birth record'), findsOneWidget);
      expect(find.text('Sign in to request a document'), findsOneWidget);
      expect(find.byKey(const Key('issuance-my-requests')), findsNothing);
    });

    testWidgets('an unverified resident is told verification comes first', (
      tester,
    ) async {
      await _boot(
        tester,
        level: AccessLevel.unverified,
        location: '/documents/types/dt-sample-birth',
      );

      expect(find.text('Verify your account first'), findsOneWidget);
      expect(find.text('Valid ID · Required'), findsOneWidget);
      expect(find.byKey(const Key('issuance-start-request')), findsNothing);

      // A typed or linked address to the form lands on verification.
      _go(tester, _form);
      await tester.pumpAndSettle();
      expect(_path(tester), '/verification');
    });

    testWidgets('a verified resident sees no notice and can start', (
      tester,
    ) async {
      await _boot(tester, location: '/documents/types/dt-sample-birth');

      expect(find.byKey(const Key('issuance-access-notice')), findsNothing);
      expect(find.text('Fee: ₱50.00, paid at the office'), findsWidgets);
      expect(find.text('About 3 working days'), findsOneWidget);
      await _tap(tester, find.byKey(const Key('issuance-start-request')));
      // Pushed, so the router's location stays the type; the form is on top.
      expect(find.text('What is the document for?'), findsOneWidget);
    });

    testWidgets('a type with no stated fee or time says so', (tester) async {
      await _boot(tester, location: '/documents/types/dt-sample-permit-copy');

      expect(find.text('Processing time not stated'), findsOneWidget);
      _go(tester, '/documents/types/dt-sample-indigency');
      await tester.pumpAndSettle();
      expect(find.text('No fee stated'), findsOneWidget);
    });
  });

  group('the form is checked before anything is sent', () {
    testWidgets('an empty form marks what is missing and sends nothing', (
      tester,
    ) async {
      final _Booted booted = await _boot(tester, location: _form);

      await _tap(tester, find.byKey(const Key('issuance-review')));

      expect(
        find.textContaining('Say what the document is for'),
        findsOneWidget,
      );
      expect(find.text('Add this file to continue.'), findsOneWidget);
      expect(find.text('Review your request'), findsNothing);
      expect(booted.issuance.submitted, isEmpty);
    });

    testWidgets('a purpose under ten characters is refused', (tester) async {
      await _boot(tester, location: _form);

      await tester.enterText(find.byKey(const Key('issuance-purpose')), 'Work');
      await _tap(tester, find.byKey(const Key('issuance-review')));

      expect(find.textContaining('at least 10 characters'), findsOneWidget);
    });

    testWidgets(
      'a file whose bytes do not match its type is refused on the phone',
      (tester) async {
        await _boot(
          tester,
          location: _form,
          document: _pdf(mimeType: 'image/png'),
        );

        await _tap(tester, find.byKey(const Key('issuance-add-valid-id')));
        await _tap(tester, find.byKey(const Key('issuance-source-file')));

        expect(find.textContaining('could not be read'), findsOneWidget);
        expect(find.textContaining('added ·'), findsNothing);
      },
    );

    testWidgets('a complete request is reviewed, sent, and numbered', (
      tester,
    ) async {
      final _Booted booted = await _boot(tester, location: _form);

      await tester.enterText(
        find.byKey(const Key('issuance-purpose')),
        'For a school enrolment requirement',
      );
      await _tap(tester, find.byKey(const Key('issuance-add-valid-id')));
      await _tap(tester, find.byKey(const Key('issuance-source-file')));
      expect(find.text('PDF added · 8 bytes'), findsOneWidget);

      await _tap(tester, find.byKey(const Key('issuance-review')));
      expect(find.text('Review your request'), findsOneWidget);
      expect(find.text('For a school enrolment requirement'), findsOneWidget);

      await _tap(tester, find.byKey(const Key('issuance-send')));

      expect(find.text('The office has your request'), findsOneWidget);
      expect(find.text('DR-2026-000131'), findsOneWidget);
      expect(booted.issuance.submitted.single.keys, <String>['valid-id']);
    });

    testWidgets(
      'a refusal from the server says nothing was sent, in our words',
      (tester) async {
        final _Booted booted = await _boot(tester, location: _form);
        const String serverText =
            'Only a verified resident can request a document.';
        booted.issuance.failSubmit = const ForbiddenFailure(
          debugMessage: serverText,
        );

        await tester.enterText(
          find.byKey(const Key('issuance-purpose')),
          'For a school enrolment requirement',
        );
        await _tap(tester, find.byKey(const Key('issuance-add-valid-id')));
        await _tap(tester, find.byKey(const Key('issuance-source-file')));
        await _tap(tester, find.byKey(const Key('issuance-review')));
        await _tap(tester, find.byKey(const Key('issuance-send')));

        expect(find.byKey(const Key('issuance-send-failure')), findsOneWidget);
        expect(
          find.text('Only verified residents can do this'),
          findsOneWidget,
        );
        expect(find.textContaining('Nothing was sent.'), findsOneWidget);
        expect(find.textContaining(serverText), findsNothing);
        expect(find.text('Go to verification'), findsOneWidget);
        // Still on review, with everything kept, ready to send again.
        expect(find.byKey(const Key('issuance-send')), findsOneWidget);
      },
    );

    testWidgets('offline, the resident is told nothing was sent', (
      tester,
    ) async {
      final _Booted booted = await _boot(tester, location: _form);
      booted.issuance.failSubmit = const NetworkFailure();

      await tester.enterText(
        find.byKey(const Key('issuance-purpose')),
        'For a school enrolment requirement',
      );
      await _tap(tester, find.byKey(const Key('issuance-add-valid-id')));
      await _tap(tester, find.byKey(const Key('issuance-source-file')));
      await _tap(tester, find.byKey(const Key('issuance-review')));
      await _tap(tester, find.byKey(const Key('issuance-send')));

      expect(find.text('You are offline'), findsOneWidget);
      expect(find.textContaining('Nothing was sent.'), findsOneWidget);
    });
  });

  group('following a request', () {
    testWidgets('the list shows each request without its purpose', (
      tester,
    ) async {
      await _boot(tester, location: '/documents/mine');

      expect(
        find.text('DR-2026-000118 · Municipal Civil Registrar'),
        findsOneWidget,
      );
      expect(find.text('Ready to claim'), findsOneWidget);
      expect(find.text('Needs more from you'), findsOneWidget);
      expect(find.textContaining('school enrolment'), findsNothing);
    });

    testWidgets(
      'needs-info shows the timeline, the office\'s words and a resubmit',
      (tester) async {
        await _boot(tester, location: '/documents/mine/dr-sample-needs-info');

        expect(find.byKey(const Key('issuance-needs-info')), findsOneWidget);
        expect(find.text('You sent the request'), findsOneWidget);
        expect(find.text('The office started reviewing it'), findsOneWidget);
        expect(find.text('The office asked for more'), findsOneWidget);
        expect(find.text('FROM THE OFFICE'), findsOneWidget);
        expect(find.text('Ready to claim'), findsOneWidget);
        expect(find.byKey(const Key('issuance-cancel')), findsOneWidget);

        // Nothing to send yet: the server needs a note or a file.
        await _tap(tester, find.byKey(const Key('issuance-resubmit-send')));
        expect(find.text('Add a note or a file first.'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('issuance-resubmit-note')),
          'Here is a certificate from this month.',
        );
        await _tap(tester, find.byKey(const Key('issuance-resubmit-send')));

        expect(find.text('Being reviewed'), findsOneWidget);
        expect(find.text('You sent what the office asked for'), findsOneWidget);
        expect(find.byKey(const Key('issuance-resubmit-send')), findsNothing);
      },
    );

    testWidgets('ready to claim shows when and where', (tester) async {
      await _boot(tester, location: '/documents/mine/dr-sample-ready');

      expect(find.byKey(const Key('issuance-claim-details')), findsOneWidget);
      expect(find.textContaining('Civil Registry window'), findsWidgets);
      expect(find.text('Claimed at the office'), findsOneWidget);
      expect(find.byKey(const Key('issuance-cancel')), findsNothing);
    });

    testWidgets('cancel asks first, then follows the server', (tester) async {
      await _boot(tester, location: '/documents/mine/dr-sample-needs-info');

      await _tap(tester, find.byKey(const Key('issuance-cancel')));
      expect(find.text('Cancel this request?'), findsOneWidget);
      await _tap(tester, find.text('Cancel request'));

      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('You cancelled the request'), findsOneWidget);
      expect(find.byKey(const Key('issuance-cancel')), findsNothing);
    });
  });
}
