import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/access_policy.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/resident_capability.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/requirements/data/planned_requirement_repository.dart';
import 'package:taytay_resident/features/requirements/domain/resident_requirement.dart';
import 'package:taytay_resident/features/requirements/presentation/requirements_controller.dart';
import 'package:taytay_resident/features/services/domain/lgu_service.dart'
    show ServerValue;

// ─── Fixtures ───────────────────────────────────────────────────────────────
//
// Obviously synthetic. No real Taytay resident, document number or filename.

/// Real leading bytes, so the signature check in `DocumentCapturePolicy` is
/// exercised rather than bypassed.
Uint8List jpegBytes([int padding = 64]) => Uint8List.fromList(<int>[
  0xFF,
  0xD8,
  0xFF,
  ...List<int>.filled(padding, 0),
]);

Uint8List pngBytes([int padding = 64]) => Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  ...List<int>.filled(padding, 0),
]);

Uint8List pdfBytes([int padding = 64]) => Uint8List.fromList(<int>[
  0x25,
  0x50,
  0x44,
  0x46,
  ...List<int>.filled(padding, 0),
]);

CapturedDocument captured({
  Uint8List? bytes,
  String mimeType = 'image/jpeg',
  String fileName = 'document.jpg',
  DocumentSource source = DocumentSource.camera,
}) => CapturedDocument(
  bytes: bytes ?? jpegBytes(),
  fileName: fileName,
  mimeType: mimeType,
  source: source,
);

ServerValue<RequirementStatus> status(RequirementStatus value) =>
    ServerValue<RequirementStatus>(raw: value.wireValue, known: value);

ServerValue<RequirementObligation> obligation(RequirementObligation value) =>
    ServerValue<RequirementObligation>(raw: value.wireValue, known: value);

ResidentRequirement requirement({
  String code = 'BARANGAY_CLEARANCE',
  String label = 'Barangay clearance',
  RequirementStatus state = RequirementStatus.missing,
  RequirementObligation obligationValue = RequirementObligation.required,
  String? instruction,
  String? reviewerMessage,
  DateTime? lastSubmittedAt,
}) => ResidentRequirement(
  code: code,
  label: label,
  obligation: obligation(obligationValue),
  status: status(state),
  instruction: instruction,
  reviewerMessage: reviewerMessage,
  lastSubmittedAt: lastSubmittedAt,
);

RequirementChecklist checklist(List<ResidentRequirement> items) =>
    RequirementChecklist(requestId: 'req-1', items: items);

/// Hands back a fixed document, or nothing when the resident "cancels".
class FakeDocumentPicker implements DocumentPicker {
  FakeDocumentPicker({this.document, this.available = true});

  CapturedDocument? document;
  bool available;

  final List<DocumentSource> picked = <DocumentSource>[];

  @override
  Future<CapturedDocument?> pick(DocumentSource source) async {
    picked.add(source);
    return document;
  }

  @override
  bool supports(DocumentSource source) => available;
}

/// Records uploads, and can be told how to behave mid-flight.
class RecordingRequirementRepository implements RequirementRepository {
  RecordingRequirementRepository({this.list});

  RequirementChecklist? list;

  int listCalls = 0;
  int uploadCalls = 0;
  final List<String> idempotencyKeys = <String>[];
  final List<String> requirementCodes = <String>[];

  /// Fractions reported before the result resolves.
  List<double> progressToReport = const <double>[0.5, 1];

  /// Set to have the repository observe a cancellation part-way through.
  bool cancelDuringUpload = false;

  Result<UploadedDocumentReference> outcome =
      const Ok<UploadedDocumentReference>(
        UploadedDocumentReference(
          id: 'doc-1',
          requirementCode: 'BARANGAY_CLEARANCE',
        ),
      );

  @override
  Future<Result<RequirementChecklist>> listRequirements(
    String requestId,
  ) async {
    listCalls++;
    final value = list;
    return value == null
        ? const Err<RequirementChecklist>(ServerFailure(isTemporary: true))
        : Ok<RequirementChecklist>(value);
  }

  @override
  Future<Result<UploadedDocumentReference>> uploadRequirementDocument({
    required String requestId,
    required String requirementCode,
    required CapturedDocument document,
    required String idempotencyKey,
    void Function(double fraction)? onProgress,
    UploadCancellation? cancellation,
  }) async {
    uploadCalls++;
    idempotencyKeys.add(idempotencyKey);
    requirementCodes.add(requirementCode);

    for (final fraction in progressToReport) {
      onProgress?.call(fraction);
    }
    if (cancelDuringUpload) cancellation?.cancel();

    return outcome;
  }
}

// ─── Widget harness ─────────────────────────────────────────────────────────

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

typedef BootedRequirements = ({
  AppDependencies dependencies,
  RecordingRequirementRepository requirements,
  FakeDocumentPicker picker,
});

Future<BootedRequirements> bootRequirements(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.verified,
  RequirementChecklist? list,
  CapturedDocument? document,
  bool pickerAvailable = true,
  RequirementRepository? repositoryOverride,
  String location = '/requests/req-1/requirements',
  Size size = const Size(400, 3000),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');

  final sessionStore = InMemorySessionStore();
  if (level != AccessLevel.guest) {
    await sessionStore.write(
      StoredSession(
        resident: ResidentSession(
          accountId: 'acct-1',
          accessLevel: level,
          displayName: 'Ana',
        ),
        accessToken: 'token',
      ),
    );
  }

  final requirements = RecordingRequirementRepository(list: list);
  final picker = FakeDocumentPicker(
    document: document,
    available: pickerAvailable,
  );

  final base = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: sessionStore,
    localAuthenticator: const UnavailableLocalAuthenticator(),
    documentPicker: picker,
  );
  final dependencies = AppDependencies(
    config: base.config,
    session: base.session,
    launch: base.launch,
    intents: base.intents,
    appLock: base.appLock,
    apiClient: base.apiClient,
    cache: base.cache,
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
    requirementRepository: repositoryOverride ?? requirements,
    documentPicker: picker,
    shareService: base.shareService,
    externalLinks: base.externalLinks,
    notificationRepository: base.notificationRepository,
    registrationRepository: base.registrationRepository,
    onDispose: base.onDispose,
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(
        tester.view,
      ).copyWith(textScaler: textScaler),
      child: TaytayResidentApp(dependencies: dependencies),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();

  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();

  return (
    dependencies: dependencies,
    requirements: requirements,
    picker: picker,
  );
}

String currentLocation(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(Scaffold).first),
).routerDelegate.currentConfiguration.uri.path;

String renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((widget) => widget.data ?? '')
    .join('\n');

RequirementsController controllerFor(
  RecordingRequirementRepository repository,
  FakeDocumentPicker picker,
) => RequirementsController(
  repository: repository,
  picker: picker,
  requestId: 'req-1',
);

void main() {
  group('what may be uploaded', () {
    test('an empty file is refused', () {
      expect(
        DocumentCapturePolicy.inspect(captured(bytes: Uint8List(0))),
        DocumentRejection.empty,
      );
    });

    test('a file over the ceiling is refused', () {
      final huge = Uint8List.fromList(<int>[
        0xFF,
        0xD8,
        0xFF,
        ...List<int>.filled(DocumentCapturePolicy.maxBytes, 0),
      ]);

      expect(
        DocumentCapturePolicy.inspect(captured(bytes: huge)),
        DocumentRejection.tooLarge,
      );
    });

    test('a type the office does not accept is refused', () {
      expect(
        DocumentCapturePolicy.inspect(captured(mimeType: 'application/zip')),
        DocumentRejection.unsupportedType,
      );
    });

    test('a declared type is checked against the actual bytes', () {
      // A ZIP renamed to .jpg: the declared type is acceptable, the bytes are
      // not. Caught on the device so the resident is told something useful now,
      // rather than after a round trip.
      final spoofed = Uint8List.fromList(<int>[
        0x50,
        0x4B,
        0x03,
        0x04,
        ...List<int>.filled(32, 0),
      ]);

      expect(
        DocumentCapturePolicy.inspect(captured(bytes: spoofed)),
        DocumentRejection.contentsDoNotMatchType,
      );
    });

    test('JPEG, PNG and PDF are all accepted', () {
      expect(DocumentCapturePolicy.inspect(captured()), isNull);
      expect(
        DocumentCapturePolicy.inspect(
          captured(bytes: pngBytes(), mimeType: 'image/png'),
        ),
        isNull,
      );
      expect(
        DocumentCapturePolicy.inspect(
          captured(bytes: pdfBytes(), mimeType: 'application/pdf'),
        ),
        isNull,
      );
    });

    test('a PDF is never re-encoded, an image may be', () {
      expect(DocumentCapturePolicy.mayCompress('application/pdf'), isFalse);
      expect(DocumentCapturePolicy.mayCompress('image/jpeg'), isTrue);
    });

    test('the readability floor stays above 150 DPI on A4 — acceptance 1', () {
      // A4's long edge is 8.27in, so 150 DPI needs ~1240px and 200 DPI ~1654px.
      // The floor must sit inside that band or small print stops being legible
      // after the platform re-encodes.
      expect(DocumentCapturePolicy.minLongEdge, greaterThanOrEqualTo(1240));
      expect(DocumentCapturePolicy.imageQuality, greaterThanOrEqualTo(80));
    });
  });

  group('the shipped backend declines rather than pretending', () {
    test('both operations fail, and the upload reports no progress', () async {
      const repository = PlannedRequirementRepository();
      final reported = <double>[];

      final list = await repository.listRequirements('req-1');
      final upload = await repository.uploadRequirementDocument(
        requestId: 'req-1',
        requirementCode: 'BARANGAY_CLEARANCE',
        document: captured(),
        idempotencyKey: 'key-1',
        onProgress: reported.add,
      );

      expect(list.isErr, isTrue);
      expect(upload.isErr, isTrue);
      expect(
        reported,
        isEmpty,
        reason: 'Bytes moving is the one thing a decline must not report.',
      );
    });
  });

  group('sending a document', () {
    test('a refused file is dropped rather than previewed', () async {
      final repository = RecordingRequirementRepository(
        list: checklist(<ResidentRequirement>[requirement()]),
      );
      final picker = FakeDocumentPicker(
        document: captured(mimeType: 'application/zip'),
      );
      final controller = controllerFor(repository, picker);
      addTearDown(controller.dispose);
      await controller.load();

      controller.beginUpload('BARANGAY_CLEARANCE');
      await controller.choose(DocumentSource.file);

      expect(controller.rejection, DocumentRejection.unsupportedType);
      expect(controller.document, isNull);
      expect(controller.stage, UploadStage.choosing);
    });

    test('cancelling the picker is not an error', () async {
      final repository = RecordingRequirementRepository(
        list: checklist(<ResidentRequirement>[requirement()]),
      );
      // `document: null` — the resident backed out of the camera.
      final picker = FakeDocumentPicker();
      final controller = controllerFor(repository, picker);
      addTearDown(controller.dispose);

      controller.beginUpload('BARANGAY_CLEARANCE');
      await controller.choose(DocumentSource.camera);

      expect(controller.rejection, isNull);
      expect(controller.uploadFailure, isNull);
      expect(controller.stage, UploadStage.choosing);
    });

    test('a full progress bar is not an accepted document', () async {
      final repository = RecordingRequirementRepository(
        list: checklist(<ResidentRequirement>[requirement()]),
      )..outcome = const Err<UploadedDocumentReference>(NetworkFailure());
      final picker = FakeDocumentPicker(document: captured());
      final controller = controllerFor(repository, picker);
      addTearDown(controller.dispose);
      await controller.load();

      controller.beginUpload('BARANGAY_CLEARANCE');
      await controller.choose(DocumentSource.camera);
      await controller.send();

      // Progress reached 1.0, and the upload still failed.
      expect(controller.stage, UploadStage.stopped);
      expect(controller.stage, isNot(UploadStage.accepted));
    });

    test('a cancelled upload never reports success', () async {
      final repository = RecordingRequirementRepository(
        list: checklist(<ResidentRequirement>[requirement()]),
      )..cancelDuringUpload = true;
      final picker = FakeDocumentPicker(document: captured());
      final controller = controllerFor(repository, picker);
      addTearDown(controller.dispose);
      await controller.load();

      controller.beginUpload('BARANGAY_CLEARANCE');
      await controller.choose(DocumentSource.camera);
      // The repository resolves `Ok`, but the resident pressed stop.
      await controller.send();

      expect(
        controller.stage,
        UploadStage.stopped,
        reason:
            'Reporting success for a stopped upload is the worst possible '
            'outcome of a cancel button.',
      );
      expect(controller.uploadFailure, isNull);
    });

    test('a retry replays the same key and keeps the document', () async {
      final repository = RecordingRequirementRepository(
        list: checklist(<ResidentRequirement>[requirement()]),
      )..outcome = const Err<UploadedDocumentReference>(TimeoutFailure());
      final picker = FakeDocumentPicker(document: captured());
      final controller = controllerFor(repository, picker);
      addTearDown(controller.dispose);
      await controller.load();

      controller.beginUpload('BARANGAY_CLEARANCE');
      await controller.choose(DocumentSource.camera);
      await controller.send();
      // The document survives, so the resident does not re-photograph it.
      expect(controller.document, isNotNull);

      await controller.retry();

      expect(repository.uploadCalls, 2);
      expect(
        repository.idempotencyKeys.first,
        repository.idempotencyKeys.last,
        reason: 'A duplicate ID card creates work for the office.',
      );
    });

    test('a success moves the row to submitted, never to verified', () async {
      final repository = RecordingRequirementRepository(
        list: checklist(<ResidentRequirement>[requirement()]),
      );
      final picker = FakeDocumentPicker(document: captured());
      final controller = controllerFor(repository, picker);
      addTearDown(controller.dispose);
      await controller.load();

      controller.beginUpload('BARANGAY_CLEARANCE');
      await controller.choose(DocumentSource.camera);
      await controller.send();

      expect(controller.stage, UploadStage.accepted);
      expect(
        controller.checklist!.items.single.status.known,
        RequirementStatus.submitted,
        reason: 'The app has no standing to decide a document was checked.',
      );
      // And the bytes are released as soon as they are no longer needed.
      expect(controller.document, isNull);
    });

    test('a new document gets a new key', () async {
      final repository = RecordingRequirementRepository(
        list: checklist(<ResidentRequirement>[requirement()]),
      )..outcome = const Err<UploadedDocumentReference>(TimeoutFailure());
      final picker = FakeDocumentPicker(document: captured());
      final controller = controllerFor(repository, picker);
      addTearDown(controller.dispose);
      await controller.load();

      controller.beginUpload('BARANGAY_CLEARANCE');
      await controller.choose(DocumentSource.camera);
      await controller.send();

      // Chose again — a different file, so a different attempt.
      picker.document = captured(bytes: pngBytes(), mimeType: 'image/png');
      await controller.choose(DocumentSource.gallery);
      await controller.send();

      expect(
        repository.idempotencyKeys.first,
        isNot(repository.idempotencyKeys.last),
      );
    });

    test(
      'server validation messages are surfaced, the headline is not',
      () async {
        final repository =
            RecordingRequirementRepository(
                list: checklist(<ResidentRequirement>[requirement()]),
              )
              ..outcome = const Err<UploadedDocumentReference>(
                ValidationFailure(
                  fieldErrors: <String, List<String>>{
                    'file': <String>['The photo is too dark to read.'],
                  },
                  debugMessage: 'internal: OCR confidence 0.11 below threshold',
                ),
              );
        final picker = FakeDocumentPicker(document: captured());
        final controller = controllerFor(repository, picker);
        addTearDown(controller.dispose);
        await controller.load();

        controller.beginUpload('BARANGAY_CLEARANCE');
        await controller.choose(DocumentSource.camera);
        await controller.send();

        expect(controller.serverFieldMessages, <String>[
          'The photo is too dark to read.',
        ]);
        // The operator-facing message stays out of the resident's view.
        expect(
          controller.serverFieldMessages.join(),
          isNot(contains('OCR confidence')),
        );
      },
    );
  });

  group('which rows accept an upload', () {
    test('missing, needs-replacement and expired do; the rest do not', () {
      expect(requirement().acceptsUpload, isTrue);
      expect(
        requirement(state: RequirementStatus.needsReplacement).acceptsUpload,
        isTrue,
      );
      expect(
        requirement(state: RequirementStatus.expired).acceptsUpload,
        isTrue,
      );
      expect(
        requirement(state: RequirementStatus.submitted).acceptsUpload,
        isFalse,
      );
      expect(
        requirement(state: RequirementStatus.underVerification).acceptsUpload,
        isFalse,
      );
      expect(
        requirement(state: RequirementStatus.verified).acceptsUpload,
        isFalse,
      );
    });

    test('an unrecognised status fails closed', () {
      const unknown = ResidentRequirement(
        code: 'X',
        label: 'Something new',
        obligation: ServerValue<RequirementObligation>(
          raw: 'required',
          known: RequirementObligation.required,
        ),
        status: ServerValue<RequirementStatus>(
          raw: 'awaiting_notarisation',
          known: null,
        ),
      );

      expect(unknown.acceptsUpload, isFalse);
      expect(unknown.isOutstanding, isFalse);
    });

    test(
      'the checklist counts what is outstanding, and offers no percentage',
      () {
        final list = checklist(<ResidentRequirement>[
          requirement(),
          requirement(code: 'ID', state: RequirementStatus.verified),
          requirement(code: 'PROOF', state: RequirementStatus.needsReplacement),
        ]);

        expect(list.outstandingCount, 2);
        // The absence of a completion meter is asserted where it would actually
        // be visible — see "an outstanding count is shown, never a percentage".
      },
    );
  });

  group('access — acceptance for a verified-only surface', () {
    testWidgets('a guest is sent to sign in', (tester) async {
      await bootRequirements(tester, level: AccessLevel.guest);
      expect(currentLocation(tester), AppRoute.signIn.path);
    });

    testWidgets('an unverified resident is sent to verification', (
      tester,
    ) async {
      await bootRequirements(tester, level: AccessLevel.unverified);
      expect(currentLocation(tester), AppRoute.verification.path);
    });

    test('the capability and its route agree on verified', () {
      expect(
        ResidentCapability.submitRequirements.requirement,
        AccessRequirement.verified,
      );
      expect(
        AppRoute.requestRequirements.requirement,
        AccessRequirement.verified,
      );
    });
  });

  group('the resident-facing surface', () {
    testWidgets('submitted and verified read differently — acceptance 3', (
      tester,
    ) async {
      await bootRequirements(
        tester,
        list: checklist(<ResidentRequirement>[
          requirement(state: RequirementStatus.submitted),
          requirement(
            code: 'ID',
            label: 'Valid ID',
            state: RequirementStatus.verified,
          ),
        ]),
      );

      expect(find.text('Sent — not checked yet'), findsOneWidget);
      expect(find.text('Checked and accepted'), findsOneWidget);
    });

    testWidgets('an outstanding count is shown, never a percentage', (
      tester,
    ) async {
      await bootRequirements(
        tester,
        list: checklist(<ResidentRequirement>[
          requirement(),
          requirement(code: 'ID', state: RequirementStatus.verified),
        ]),
      );

      expect(
        find.text('Taytay LGU is waiting for 1 document.'),
        findsOneWidget,
      );
      expect(renderedText(tester), isNot(contains('%')));
      expect(renderedText(tester), isNot(contains('complete')));
    });

    testWidgets('a document being checked cannot be replaced', (tester) async {
      await bootRequirements(
        tester,
        list: checklist(<ResidentRequirement>[
          requirement(state: RequirementStatus.underVerification),
        ]),
      );

      expect(find.text('Send this document'), findsNothing);
      expect(find.text('Replace this document'), findsNothing);
      expect(find.textContaining('while it is being checked'), findsOneWidget);
    });

    testWidgets('a reviewer message is shown when the office sent one', (
      tester,
    ) async {
      await bootRequirements(
        tester,
        list: checklist(<ResidentRequirement>[
          requirement(
            state: RequirementStatus.needsReplacement,
            reviewerMessage: 'The date of issue is not readable.',
          ),
        ]),
      );

      expect(find.text('What the office said'), findsOneWidget);
      expect(find.text('The date of issue is not readable.'), findsOneWidget);
      expect(find.text('Replace this document'), findsOneWidget);
    });

    testWidgets('an absent backend explains itself and offers no upload', (
      tester,
    ) async {
      await bootRequirements(
        tester,
        repositoryOverride: const PlannedRequirementRepository(),
      );

      expect(find.textContaining('not switched on'), findsOneWidget);
      expect(find.text('Send this document'), findsNothing);
    });

    testWidgets('preview, send and confirmation run end to end', (
      tester,
    ) async {
      await bootRequirements(
        tester,
        list: checklist(<ResidentRequirement>[requirement()]),
        document: captured(),
      );

      await tester.tap(find.text('Send this document'));
      await tester.pumpAndSettle();

      // Choose → preview.
      await tester.tap(find.text('Take a photo'));
      await tester.pumpAndSettle();
      expect(find.text('Send to Taytay LGU'), findsOneWidget);

      await tester.tap(find.text('Send to Taytay LGU'));
      await tester.pumpAndSettle();

      expect(find.text('Taytay LGU has your document'), findsOneWidget);
      // The sentence acceptance 3 turns on.
      expect(find.textContaining('has not been checked yet'), findsOneWidget);
    });

    testWidgets('a device with no picker says so instead of offering one', (
      tester,
    ) async {
      await bootRequirements(
        tester,
        list: checklist(<ResidentRequirement>[requirement()]),
        pickerAvailable: false,
      );

      await tester.tap(find.text('Send this document'));
      await tester.pumpAndSettle();

      expect(find.text('This device cannot pick a document'), findsOneWidget);
      expect(find.text('Take a photo'), findsNothing);
    });

    testWidgets('no staff vocabulary appears on the checklist', (tester) async {
      await bootRequirements(
        tester,
        list: checklist(<ResidentRequirement>[
          requirement(instruction: 'Issued by your barangay hall.'),
        ]),
      );

      final text = renderedText(tester).toLowerCase();
      for (final forbidden in <String>[
        'caseworker',
        'assessment',
        'internal note',
        'audit',
        'approve',
        'reject',
      ]) {
        expect(text, isNot(contains(forbidden)));
      }
    });

    testWidgets('the checklist survives a 200% text scale', (tester) async {
      await bootRequirements(
        tester,
        list: checklist(<ResidentRequirement>[
          requirement(
            instruction: 'Issued by your barangay hall within the last year.',
            lastSubmittedAt: DateTime.utc(2026, 8, 1),
          ),
        ]),
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 4000),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Barangay clearance'), findsOneWidget);
    });
  });
}
