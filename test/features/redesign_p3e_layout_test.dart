import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/documents/upload_policy.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/auth/presentation/app_lock_screen.dart';
import 'package:taytay_resident/features/auth/presentation/sign_in_help_screen.dart';
import 'package:taytay_resident/features/auth/presentation/too_many_attempts_screen.dart';
import 'package:taytay_resident/features/household/presentation/household_correction_screen.dart';
import 'package:taytay_resident/features/household/presentation/household_screen.dart';
import 'package:taytay_resident/features/issuance/domain/issuance_type.dart';
import 'package:taytay_resident/features/issuance/presentation/issuance_catalogue_screen.dart';
import 'package:taytay_resident/features/issuance/presentation/issuance_request_controller.dart';
import 'package:taytay_resident/features/issuance/presentation/issuance_request_detail_screen.dart';
import 'package:taytay_resident/features/issuance/presentation/issuance_request_form_screen.dart';
import 'package:taytay_resident/features/issuance/presentation/issuance_type_screen.dart';
import 'package:taytay_resident/features/issuance/presentation/my_issuance_requests_screen.dart';
import 'package:taytay_resident/features/mock_data/data/mock/resident_record_mock.dart';
import 'package:taytay_resident/features/notifications/presentation/notification_centre.dart';
import 'package:taytay_resident/features/notifications/presentation/notification_inbox_screen.dart';
import 'package:taytay_resident/features/platform/presentation/blocking_notice_screen.dart';
import 'package:taytay_resident/features/profile/domain/name_lock.dart';
import 'package:taytay_resident/features/requirements/presentation/requirements_screen.dart';
import 'package:taytay_resident/features/shell/presentation/shell_tab_bar.dart';
import 'package:taytay_resident/features/verification/domain/resident_record.dart';
import 'package:taytay_resident/features/verification/presentation/kyc_claim_screen.dart';
import 'package:taytay_resident/features/verification/presentation/profile_wizard_page.dart';
import 'package:taytay_resident/features/verification/presentation/verification_status_pages.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/blue_header.dart';
import 'package:taytay_resident/shared/widgets/detail_page.dart';
import 'package:taytay_resident/shared/widgets/header_search_field.dart';
import 'package:taytay_resident/shared/widgets/success_screen.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';
import 'package:taytay_resident/shared/widgets/upload_slot.dart';
import 'package:taytay_resident/shared/widgets/wave_header.dart';

import '../support/layout_matrix.dart';
import '../support/unverified_gate_specimen.dart';

/// Redesign P3e: document requests, requirements, household, verification,
/// notifications and the notice screens at 360 / 375 / 430 dp and 100% /
/// 200% text, plus the content rules the restyle must keep.
void main() {
  group('shared widgets added in P3e', () {
    testWidgets('the header search field lays out on blue', (tester) async {
      Widget header() => BlueHeader(
        title: 'Page title',
        showBack: true,
        includeSafeArea: false,
        bottom: HeaderSearchField(
          fieldKey: const Key('search'),
          hint: 'Search documents',
          controller: TextEditingController(),
        ),
      );
      await expectCleanLayouts(tester, header);
      await tester.pumpWidget(layoutHost(header()));
      expect(
        tester.getSize(find.byKey(const Key('search'))).height,
        greaterThanOrEqualTo(ComponentSizes.fieldHeight),
      );
    });

    testWidgets('the upload slot and the attached file lay out', (
      tester,
    ) async {
      Widget slots() => Padding(
        padding: const EdgeInsets.all(Spacing.formGutter),
        child: Column(
          children: <Widget>[
            UploadSlot(label: 'Add file', onPressed: () {}),
            const SizedBox(height: Spacing.md),
            const UploadSlot(label: 'Add file', onPressed: null, error: true),
            const SizedBox(height: Spacing.md),
            AttachedFileCard(
              title: 'A long requirement label that wraps at 200% text',
              status: 'PDF added · 120 KB',
              actionLabel: 'Remove',
              onAction: () {},
            ),
          ],
        ),
      );
      await expectCleanLayouts(tester, slots);
      await tester.pumpWidget(layoutHost(slots()));
      expect(
        tester.getSize(find.byType(UploadSlot).first).height,
        greaterThanOrEqualTo(UploadSlot.minHeight),
      );
    });
  });

  group('document requests', () {
    testWidgets('the catalogue lays out for a guest and a verified resident', (
      tester,
    ) async {
      for (final AccessLevel level in <AccessLevel>[
        AccessLevel.guest,
        AccessLevel.verified,
      ]) {
        final AppDependencies dependencies = await _dependencies(level);
        await _expectCleanScreen(
          tester,
          dependencies,
          () => const IssuanceCatalogueScreen(),
        );
      }
      expect(find.byType(BlueHeader), findsOneWidget);
      expect(find.byKey(const Key('issuance-my-requests')), findsOneWidget);
    });

    testWidgets('a document type is the detail sheet', (tester) async {
      final AppDependencies dependencies = await _dependencies(
        AccessLevel.verified,
      );
      await _expectCleanScreen(
        tester,
        dependencies,
        () => const IssuanceTypeScreen(typeId: 'dt-sample-birth'),
      );
      expect(find.byType(DetailSheet), findsOneWidget);
      expect(find.byKey(const Key('issuance-start-request')), findsOneWidget);
    });

    testWidgets('the request form is the wave-header form', (tester) async {
      final AppDependencies dependencies = await _dependencies(
        AccessLevel.verified,
      );
      await _expectCleanScreen(
        tester,
        dependencies,
        () => const IssuanceRequestFormScreen(typeId: 'dt-sample-birth'),
      );
      expect(find.byType(WaveHeader), findsOneWidget);
      expect(find.byType(UploadSlot), findsWidgets);
      expect(find.text('Step 1 of 2'), findsOneWidget);
    });

    testWidgets('my requests and two requests lay out', (tester) async {
      final AppDependencies dependencies = await _dependencies(
        AccessLevel.verified,
      );
      await _expectCleanScreen(
        tester,
        dependencies,
        () => const MyIssuanceRequestsScreen(),
      );
      expect(find.text('Ready to claim'), findsOneWidget);
      for (final String id in <String>[
        'dr-sample-needs-info',
        'dr-sample-ready',
      ]) {
        await _expectCleanScreen(
          tester,
          dependencies,
          () => IssuanceRequestDetailScreen(requestId: id),
        );
        expect(find.byType(DetailSheet), findsOneWidget);
      }
    });

    testWidgets('the review and the result lay out', (tester) async {
      final AppDependencies dependencies = await _dependencies(
        AccessLevel.verified,
        picker: _Camera(),
      );
      final IssuanceType? type =
          (await dependencies.issuanceRepository.loadType(
            'dt-sample-birth',
          )).valueOrNull;
      if (type == null) fail('the mock has no birth-record type');
      final IssuanceRequestController controller = IssuanceRequestController(
        repository: dependencies.issuanceRepository,
        picker: dependencies.documentPicker,
        type: type,
      );
      addTearDown(controller.dispose);
      controller.setPurpose('For a school enrolment requirement');
      await controller.choose('valid-id', DocumentSource.camera);
      controller.review();
      await _expectCleanScreen(
        tester,
        dependencies,
        () => IssuanceRequestFormView(controller: controller),
      );
      expect(find.text('Review your request'), findsOneWidget);
      expect(find.text('Step 2 of 2'), findsOneWidget);

      await controller.submit();
      await _expectCleanScreen(
        tester,
        dependencies,
        () => IssuanceRequestFormView(controller: controller),
      );
      expect(find.text('The office has your request'), findsOneWidget);
      expect(find.byType(SuccessScreen), findsOneWidget);
    });
  });

  group('household', () {
    testWidgets('the household page and the report form lay out', (
      tester,
    ) async {
      final AppDependencies dependencies = await _dependencies(
        AccessLevel.verified,
      );
      await _expectCleanScreen(
        tester,
        dependencies,
        () => const HouseholdScreen(),
      );
      expect(find.text('Household and family'), findsOneWidget);
      await _expectCleanScreen(
        tester,
        dependencies,
        () => const HouseholdCorrectionScreen(),
      );
      expect(find.byType(WaveHeader), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('verification', () {
    const ResidentRecord record = MockResidentRecordRepository.sampleRecord;
    final Map<String, Widget Function()> pages = <String, Widget Function()>{
      'pending': () => const PendingStatusPage(
        onBack: _noop,
        accountCreated: '05 Nov 2026, 9:14 AM',
        email: 'sample@example.test',
        idType: 'Passport',
        submittedOn: '06 Nov 2026',
        residentMessage: 'A message the resident sent with a correction.',
        categories: <String>['Your details', 'ID photo'],
      ),
      'verified': () => const VerifiedStatusPage(
        onBack: _noop,
        onHome: _noop,
        onProfile: _noop,
        onRequestDocuments: _noop,
        verifiedOn: '07 Nov 2026',
        completeness: 60,
      ),
      'needs correction': () => const NeedsCorrectionPage(
        onBack: _noop,
        onResubmit: _noop,
        onCheckName: _noop,
        reason: 'The photo of the ID is blurred. Send a clearer one.',
        reviewedOn: '07 Nov 2026',
        submittedOn: '06 Nov 2026',
        notice: 'Could not send the new photo. Nothing was replaced.',
        categories: <String>['ID photo'],
      ),
      'unverified': () => const UnverifiedStatusPage(
        onBack: _noop,
        onStart: _noop,
        below: NameCheckNote(onCheckName: _noop),
      ),
      'gate sheet': () => const UnverifiedGatePreview(),
      'profile overview': () => const ProfileWizardPage(
        step: ProfileWizardStep.overview,
        record: record,
        onBack: _noop,
        onPersonal: _noop,
      ),
      'profile personal': () => const ProfileWizardPage(
        step: ProfileWizardStep.personal,
        record: record,
        onBack: _noop,
        onContinue: _noop,
      ),
      'profile household': () => const ProfileWizardPage(
        step: ProfileWizardStep.household,
        record: record,
        onBack: _noop,
        onContinue: _noop,
      ),
      'profile review': () => ProfileWizardPage(
        step: ProfileWizardStep.review,
        record: record,
        onBack: _noop,
        onContinue: _noop,
        onEditPersonal: _noop,
        onCertified: (_) {},
      ),
      'profile submitted': () => ProfileWizardPage(
        step: ProfileWizardStep.submitted,
        record: record,
        submittedAt: MockResidentRecordRepository.sampleSubmittedAt,
        onBack: _noop,
        onContinue: _noop,
      ),
    };
    for (final MapEntry<String, Widget Function()> page in pages.entries) {
      testWidgets('${page.key} lays out cleanly', (tester) async {
        await expectCleanLayouts(tester, page.value, scrollable: false);
      });
    }

    testWidgets('the rejection reason and the name-on-ID statement stay', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(
          const NeedsCorrectionPage(
            onBack: _noop,
            onResubmit: _noop,
            onCheckName: _noop,
          ),
          scrollable: false,
        ),
      );
      expect(find.text('REASON FROM TAYTAY LGU'), findsOneWidget);
      expect(find.text(NameCheckCopy.beforeSending), findsOneWidget);
      expect(find.text('Needs correction'), findsNWidgets(2));
      expect(find.byType(BlueHeader), findsOneWidget);
    });

    testWidgets('the identity claim is the wave-header form', (tester) async {
      final AppDependencies dependencies = await _dependencies(
        AccessLevel.unverified,
      );
      await _expectCleanScreen(
        tester,
        dependencies,
        () => const KycClaimScreen(),
      );
      expect(find.byType(WaveHeader), findsOneWidget);
    });
  });

  group('notifications', () {
    testWidgets('the inbox and the settings lay out', (tester) async {
      final AppDependencies dependencies = await _dependencies(
        AccessLevel.verified,
      );
      await _expectCleanScreen(
        tester,
        dependencies,
        () => const NotificationInboxScreen(),
      );
      expect(find.byType(BlueHeader), findsOneWidget);
      await _expectCleanScreen(
        tester,
        dependencies,
        () => const NotificationPreferencesScreen(),
      );
      expect(find.text('Always sent'), findsOneWidget);
    });

    testWidgets('the centre lays out with long rows and a long title', (
      tester,
    ) async {
      await expectCleanLayouts(
        tester,
        () => NotificationCentre(
          sections: <NoticeSection>[
            NoticeSection(
              heading: 'Recent',
              rows: <NoticeRow>[
                for (var i = 0; i < 3; i++)
                  NoticeRow(
                    eyebrow: 'ASSISTANCE UPDATES',
                    title:
                        'A long notification title that wraps over two or '
                        'three lines at 200% text',
                    when: '11 Nov 2026, 9:05 AM PHT',
                    unread: i.isEven,
                    tone: BrandColors.blue,
                    tile: BrandColors.blue50,
                    icon: NoticeIcons.message,
                    onTap: () {},
                  ),
              ],
            ),
          ],
          onMarkAllRead: () {},
        ),
        scrollable: false,
      );
    });
  });

  group('notices', () {
    testWidgets('blocking notices, the lock, help and the hold lay out', (
      tester,
    ) async {
      final AppDependencies dependencies = await _dependencies(
        AccessLevel.verified,
      );
      final Map<String, Widget Function()>
      screens = <String, Widget Function()>{
        'update required': () =>
            const BlockingNoticeScreen(kind: BlockingNoticeKind.updateRequired),
        'maintenance': () =>
            const BlockingNoticeScreen(kind: BlockingNoticeKind.maintenance),
        'app lock': () => AppLockScreen(
          lock: dependencies.appLock,
          onUnlock: () async {},
          onSignOut: () async {},
        ),
        'sign-in help': () => const SignInHelpScreen(),
        'hold waiting': () =>
            const TooManyAttemptsScreen(fixture: TooManyFixture.waiting),
        'hold over': () =>
            const TooManyAttemptsScreen(fixture: TooManyFixture.ready),
      };
      for (final MapEntry<String, Widget Function()> screen
          in screens.entries) {
        await _expectCleanScreen(tester, dependencies, screen.value);
        expect(find.byType(WaveHeader), findsOneWidget, reason: screen.key);
        // The lock and the blocking notices offer no way back.
        if (!screen.key.startsWith('sign-in') &&
            !screen.key.startsWith('hold')) {
          expect(find.byType(TaytayBackButton), findsNothing);
        }
      }
    });
  });

  group('bottom navigation', () {
    testWidgets('the tab bar fits 320 to 430 dp at 100% and 200% text', (
      tester,
    ) async {
      for (var i = 0; i < 5; i++) {
        await expectCleanLayouts(
          tester,
          () => Localizations(
            locale: const Locale('en'),
            delegates: AppStrings.localizationsDelegates,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ShellTabBar(selectedIndex: i, onSelected: (_) {}),
            ),
          ),
          widths: const <double>[320, 360, 375, 430],
          scrollable: false,
        );
      }
    });
  });

  group('requirements', () {
    testWidgets('the checklist lays out', (tester) async {
      final AppDependencies dependencies = await _dependencies(
        AccessLevel.verified,
      );
      await _expectCleanScreen(
        tester,
        dependencies,
        () => const RequirementsScreen(requestId: 'req-sample-1'),
      );
      expect(find.byType(BlueHeader), findsOneWidget);
    });

    testWidgets('a bad id is the unavailable state, not a crash', (
      tester,
    ) async {
      final AppDependencies dependencies = await _dependencies(
        AccessLevel.verified,
      );
      await _expectCleanScreen(
        tester,
        dependencies,
        () => const RequirementsScreen(requestId: '../../etc'),
      );
      expect(find.text('Documents are not available here yet'), findsOneWidget);
      expect(find.text('See my requests'), findsOneWidget);
    });
  });

  test('restyled screens use tokens: no raw colours, sizes or shadows', () {
    final List<String> offenders = <String>[];
    for (final String path in _restyled) {
      final List<String> lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final String line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (RegExp(
          r'Color\(0x|BoxShadow|elevation:|fontSize:|MunicipalHeader|InAppHeader|StatusView\(|AppBanner\(|AppCard\(',
        ).hasMatch(line)) {
          offenders.add('$path:${i + 1}: $line');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('the attached file never draws the file back', () {
    final String source = File(
      'lib/shared/widgets/upload_slot.dart',
    ).readAsStringSync();
    expect(source.contains('Image.memory'), isFalse);
    expect(source.contains('TaytayIcons.circleCheck'), isTrue);
  });
}

void _noop() {}

const List<String> _restyled = <String>[
  'lib/shared/widgets/header_search_field.dart',
  'lib/features/platform/presentation/blocking_notice_screen.dart',
  'lib/features/platform/presentation/consent_update_screen.dart',
  'lib/features/auth/presentation/app_lock_screen.dart',
  'lib/features/auth/presentation/sign_in_help_screen.dart',
  'lib/features/auth/presentation/too_many_attempts_screen.dart',
  'lib/features/shell/presentation/shell_tab_bar.dart',
  'lib/features/notifications/presentation/notification_centre.dart',
  'lib/features/notifications/presentation/notification_inbox_screen.dart',
  'lib/shared/widgets/upload_slot.dart',
  'lib/features/issuance/presentation/issuance_widgets.dart',
  'lib/features/issuance/presentation/issuance_catalogue_screen.dart',
  'lib/features/issuance/presentation/issuance_type_screen.dart',
  'lib/features/issuance/presentation/issuance_request_form_screen.dart',
  'lib/features/issuance/presentation/issuance_request_detail_screen.dart',
  'lib/features/issuance/presentation/my_issuance_requests_screen.dart',
  'lib/features/issuance/presentation/issuance_file_slot.dart',
  'lib/features/requirements/presentation/requirements_screen.dart',
  'lib/features/household/presentation/household_screen.dart',
  'lib/features/household/presentation/household_correction_screen.dart',
  'lib/features/verification/presentation/s3_chrome.dart',
  'lib/features/verification/presentation/verification_status_pages.dart',
  'lib/features/verification/presentation/verification_screen.dart',
  'lib/features/verification/presentation/kyc_claim_screen.dart',
  'lib/features/verification/presentation/profile_wizard_screen.dart',
  'lib/features/verification/presentation/profile_wizard_page.dart',
  'lib/features/verification/presentation/unverified_gate_sheet.dart',
];

/// A photo of a document, as the camera would hand it back. Only the JPEG
/// signature is real; the rest is zeros.
class _Camera implements DocumentPicker {
  @override
  Future<CapturedDocument?> pick(
    DocumentSource source,
    UploadPolicy policy,
  ) async => CapturedDocument(
    bytes: Uint8List(4096)..setRange(0, 3, <int>[0xFF, 0xD8, 0xFF]),
    fileName: 'photo.jpg',
    mimeType: 'image/jpeg',
    source: source,
  );

  @override
  bool supports(DocumentSource source) => true;
}

/// The dev mock, with a session at [level] already restored.
Future<AppDependencies> _dependencies(
  AccessLevel level, {
  DocumentPicker? picker,
}) async {
  final InMemorySecretStore secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  final InMemorySessionStore store = InMemorySessionStore();
  if (level != AccessLevel.guest) {
    await store.write(
      StoredSession(
        resident: ResidentSession(
          accountId: 'acct-sample',
          accessLevel: level,
          displayName: 'Sample',
        ),
        accessToken: 'token-sample',
      ),
    );
  }
  final AppDependencies dependencies = AppDependencies.build(
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
  addTearDown(dependencies.dispose);
  await dependencies.session.restore();
  return dependencies;
}

Widget _host(
  AppDependencies dependencies,
  Widget child, {
  double textScale = 1,
}) {
  return AppDependenciesScope(
    dependencies: dependencies,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppLocales.supported,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child,
        ),
      ),
    ),
  );
}

/// [expectCleanLayouts] for a screen that needs the app's dependencies and
/// strings: every width and text scale, failing on any error.
Future<void> _expectCleanScreen(
  WidgetTester tester,
  AppDependencies dependencies,
  Widget Function() build,
) async {
  addTearDown(tester.view.reset);
  for (final double width in layoutWidths) {
    for (final double scale in layoutTextScales) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        _host(
          dependencies,
          KeyedSubtree(key: UniqueKey(), child: build()),
          textScale: scale,
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final Object? error = tester.takeException();
      expect(error, isNull, reason: '$width dp at ${scale}x: $error');
    }
  }
  // Leave the screen at 375 dp and 100% text for the caller's content checks.
  tester.view.physicalSize = const Size(375, 800);
  await tester.pumpWidget(
    _host(dependencies, KeyedSubtree(key: UniqueKey(), child: build())),
  );
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
