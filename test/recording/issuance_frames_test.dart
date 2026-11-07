@Tags(<String>['recording'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/documents/upload_policy.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/issuance/domain/issuance_type.dart';
import 'package:taytay_resident/features/issuance/presentation/issuance_catalogue_screen.dart';
import 'package:taytay_resident/features/issuance/presentation/issuance_request_controller.dart';
import 'package:taytay_resident/features/issuance/presentation/issuance_request_detail_screen.dart';
import 'package:taytay_resident/features/issuance/presentation/issuance_request_form_screen.dart';
import 'package:taytay_resident/features/issuance/presentation/issuance_type_screen.dart';
import 'package:taytay_resident/features/issuance/presentation/my_issuance_requests_screen.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';

/// Stills of the document-request screens at 390×844 @3×, for the owner.
/// Synthetic sample data from the dev mock only. Not part of `flutter test`.
///
/// ```
/// TAYTAY_FRAMES_DIR=/path/to/frames flutter test --tags recording \
///   --run-skipped test/recording/issuance_frames_test.dart
/// ```
Future<void> _loadFonts() async {
  final FontLoader jakarta = FontLoader('Plus Jakarta Sans');
  for (final String file in <String>[
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Regular.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Medium.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-SemiBold.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Bold.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-ExtraBold.ttf',
  ]) {
    jakarta.addFont(rootBundle.load(file));
  }
  await jakarta.load();
  final FontLoader lucide = FontLoader('Lucide')
    ..addFont(rootBundle.load('assets/fonts/lucide/lucide.ttf'));
  await lucide.load();
}

const ValueKey<String> _frame = ValueKey<String>('issuance-frame');

/// A photo of an ID, as the camera would hand it back. Only the JPEG
/// signature is real; the rest is zeros.
class _Camera implements DocumentPicker {
  @override
  Future<CapturedDocument?> pick(
    DocumentSource source,
    UploadPolicy policy,
  ) async => CapturedDocument(
    bytes: Uint8List(431000)..setRange(0, 3, <int>[0xFF, 0xD8, 0xFF]),
    fileName: 'photo.jpg',
    mimeType: 'image/jpeg',
    source: source,
  );

  @override
  bool supports(DocumentSource source) => true;
}

Future<AppDependencies> _dependencies(WidgetTester tester) async {
  final InMemorySessionStore store = InMemorySessionStore();
  late final AppDependencies dependencies;
  await tester.runAsync(() async {
    await store.write(
      const StoredSession(
        resident: ResidentSession(
          accountId: 'acct-sample',
          accessLevel: AccessLevel.verified,
          displayName: 'Ana',
        ),
        accessToken: 'token-sample',
      ),
    );
    dependencies = AppDependencies.build(
      config: AppConfig.from(
        rawEnvironment: 'dev',
        rawApiBaseUrl: '',
        isReleaseBuild: false,
        rawDataMode: 'mock',
        rawMockLatencyMs: '0',
      ),
      secrets: InMemorySecretStore(),
      sessionStore: store,
      localAuthenticator: const UnavailableLocalAuthenticator(),
      documentPicker: _Camera(),
    );
    await dependencies.session.restore();
  });
  addTearDown(dependencies.dispose);
  return dependencies;
}

Future<void> _show(
  WidgetTester tester,
  AppDependencies dependencies,
  Widget child,
) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  await tester.pumpWidget(
    AppDependenciesScope(
      dependencies: dependencies,
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          textScaler: TextScaler.noScaling,
          disableAnimations: true,
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          localizationsDelegates: AppStrings.localizationsDelegates,
          supportedLocales: AppStrings.supportedLocales,
          builder: (BuildContext context, Widget? navigator) =>
              RepaintBoundary(key: _frame, child: navigator),
          home: child,
        ),
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _capture(WidgetTester tester, String path) async {
  final RenderRepaintBoundary boundary =
      tester.renderObject(find.byKey(_frame)) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    File(path).writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('document request frames for the owner', (tester) async {
    addTearDown(tester.view.reset);
    final String? configured = Platform.environment['TAYTAY_FRAMES_DIR'];
    final Directory out = Directory(
      configured != null && configured.isNotEmpty
          ? configured
          : '${Directory.systemTemp.path}/taytay_issuance_frames',
    );
    out.createSync(recursive: true);

    debugDisableShadows = false;
    try {
      final AppDependencies dependencies = await _dependencies(tester);

      await _show(tester, dependencies, const IssuanceCatalogueScreen());
      expect(find.text('Certificate of indigency'), findsOneWidget);
      await _capture(tester, '${out.path}/01-catalogue.png');

      await _show(
        tester,
        dependencies,
        const IssuanceTypeScreen(typeId: 'dt-sample-birth'),
      );
      expect(find.text('Request this document'), findsOneWidget);
      await _capture(tester, '${out.path}/02-type-detail.png');

      final Result<IssuanceType> type = await dependencies.issuanceRepository
          .loadType('dt-sample-birth');
      final IssuanceRequestController controller = IssuanceRequestController(
        repository: dependencies.issuanceRepository,
        picker: dependencies.documentPicker,
        type: type.valueOrNull!,
      );
      addTearDown(controller.dispose);
      controller.setPurpose('For a school enrolment requirement');
      await controller.choose('valid-id', DocumentSource.camera);
      await _show(
        tester,
        dependencies,
        IssuanceRequestFormView(controller: controller),
      );
      expect(find.text('Photo added · 421 KB'), findsOneWidget);
      await _capture(tester, '${out.path}/03-request-form.png');

      controller.review();
      await tester.pump();
      await _capture(tester, '${out.path}/04-review.png');

      await controller.submit();
      await tester.pump();
      expect(find.text('The office has your request'), findsOneWidget);
      await _capture(tester, '${out.path}/05-done.png');

      await _show(tester, dependencies, const MyIssuanceRequestsScreen());
      expect(find.text('Ready to claim'), findsWidgets);
      await _capture(tester, '${out.path}/06-my-requests.png');

      await _show(
        tester,
        dependencies,
        const IssuanceRequestDetailScreen(requestId: 'dr-sample-ready'),
      );
      expect(find.byKey(const Key('issuance-claim-details')), findsOneWidget);
      await _capture(tester, '${out.path}/07-detail-ready-for-pickup.png');

      await _show(
        tester,
        dependencies,
        const IssuanceRequestDetailScreen(requestId: 'dr-sample-needs-info'),
      );
      expect(find.byKey(const Key('issuance-needs-info')), findsOneWidget);
      await _capture(tester, '${out.path}/08-detail-needs-info.png');
    } finally {
      debugDisableShadows = true;
    }

    expect(
      out.listSync().whereType<File>().where(
        (File f) => f.path.endsWith('.png'),
      ),
      hasLength(greaterThanOrEqualTo(8)),
    );
  });
}
