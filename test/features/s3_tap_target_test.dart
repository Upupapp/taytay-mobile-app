import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/features/home/domain/home_content.dart';
import 'package:taytay_resident/features/home/presentation/home_canvas.dart';
import 'package:taytay_resident/features/home/presentation/hotlines_screen.dart';
import 'package:taytay_resident/features/mock_data/data/mock/resident_record_mock.dart';
import 'package:taytay_resident/features/notifications/presentation/notification_centre.dart';
import 'package:taytay_resident/features/shell/presentation/shell_tab_bar.dart';
import 'package:taytay_resident/features/verification/presentation/profile_wizard_page.dart';
import 'package:taytay_resident/features/verification/presentation/unverified_gate_sheet.dart';
import 'package:taytay_resident/features/verification/presentation/verification_status_pages.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';

import '../support/unverified_gate_specimen.dart';

void _noop() {}

void _onTab(int index) {}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
      home: child,
    ),
  );
  await tester.pump();
}

void main() {
  test('verification presentation does not nudge text', () {
    final offenders = <String>[];
    for (final entity in Directory(
      'lib/features/verification',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains('Transform.translate')) {
        offenders.add(entity.path);
      }
      if (source.contains('juana.delacruz@example.com') ||
          source.contains('Oct 20, 2026') ||
          source.contains('(sample)')) {
        offenders.add('${entity.path} sample');
      }
    }
    expect(offenders, isEmpty);
  });

  testWidgets('S3 controls are at least 48 dp', (tester) async {
    const record = MockResidentRecordRepository.sampleRecord;
    final pages = <Widget>[
      const PendingStatusPage(onBack: _noop),
      const VerifiedStatusPage(onBack: _noop, onHome: _noop, completeness: 60),
      const NeedsCorrectionPage(
        onBack: _noop,
        onResubmit: _noop,
        onCheckName: _noop,
      ),
      const UnverifiedStatusPage(onBack: _noop, onStart: _noop),
      const UnverifiedGatePreview(),
      const UnverifiedGateSheet(
        action: VerifiedOnlyAction.message,
        onContinue: _noop,
        onDismiss: _noop,
      ),
      const ProfileWizardPage(
        step: ProfileWizardStep.overview,
        record: record,
        onBack: _noop,
        onPersonal: _noop,
      ),
      const ProfileWizardPage(
        step: ProfileWizardStep.personal,
        record: record,
        onBack: _noop,
        onContinue: _noop,
      ),
      const ProfileWizardPage(
        step: ProfileWizardStep.household,
        record: record,
        onBack: _noop,
        onContinue: _noop,
      ),
      const ProfileWizardPage(
        step: ProfileWizardStep.review,
        record: record,
        onBack: _noop,
        onContinue: _noop,
        onEditPersonal: _noop,
        certified: true,
      ),
      ProfileWizardPage(
        step: ProfileWizardStep.submitted,
        record: record,
        submittedAt: MockResidentRecordRepository.sampleSubmittedAt,
        onBack: _noop,
        onContinue: _noop,
      ),
    ];

    for (final page in pages) {
      await _pump(tester, page);
      final undersized = <String>[];
      for (final element
          in find
              .byWidgetPredicate(
                (widget) =>
                    widget is IconButton ||
                    widget is FilledButton ||
                    widget is OutlinedButton ||
                    widget is TextButton ||
                    widget is InkWell ||
                    widget is GestureDetector,
              )
              .evaluate()) {
        final size = element.size;
        if (size == null) continue;
        if (size.height == 0 || size.width == 0) continue;
        if (size.height + 0.01 < A11y.minTapTarget ||
            size.width + 0.01 < A11y.minTapTarget) {
          undersized.add(
            '${element.widget.runtimeType} ${size.width}x${size.height}',
          );
        }
      }
      expect(undersized, isEmpty, reason: page.runtimeType.toString());
    }
  });

  test('S4 shell and home do not nudge text', () {
    final offenders = <String>[];
    const roots = <String>[
      'lib/features/home',
      'lib/features/shell',
      'lib/features/notifications',
      'lib/shared/widgets/blue_header.dart',
    ];
    for (final root in roots) {
      final entities = File(root).existsSync()
          ? <FileSystemEntity>[File(root)]
          : Directory(root).listSync(recursive: true);
      for (final entity in entities) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity
            .readAsStringSync()
            .split('\n')
            .where((line) => !line.trimLeft().startsWith('///'))
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');
        if (source.contains('Transform.translate')) {
          offenders.add(entity.path);
        }
      }
    }
    expect(offenders, isEmpty);
  });

  testWidgets('S4 controls are at least 48 dp', (tester) async {
    const slides = <HomeSlide>[
      HomeSlide(
        eyebrow: 'BALITA',
        title: 'First',
        body: 'Body',
        action: 'Read Balita',
        photoAsset: 'assets/photos/municipal_hall.jpg',
        credit: 'Photo credit',
        routeName: 'news',
      ),
    ];
    final pages = <Widget>[
      const HomeCanvas(
        greeting: 'Magandang gabi, Bisita!',
        status: HomeStatusKind.guest,
        slides: slides,
      ),
      const HomeCanvas(
        greeting: 'Magandang gabi, Juana!',
        initials: 'JD',
        bellCount: 2,
        status: HomeStatusKind.pending,
        slides: slides,
        news: <HomeNewsItem>[
          HomeNewsItem(
            id: 'n1',
            eyebrow: 'ADVISORY',
            title: 'Advisory',
            alert: false,
          ),
        ],
        hotline: HomeHotline(
          id: 'sagip',
          name: 'Sagip Taytay Command Center',
          number: '0985-488-3352',
          category: 'municipal',
        ),
      ),
      const HomeCanvas(
        greeting: 'Magandang gabi, Juana!',
        initials: 'JD',
        refreshing: true,
        slides: slides,
      ),
      const HotlinesCanvas(
        lines: <HomeHotline>[
          HomeHotline(
            id: 'sagip',
            name: 'Sagip Taytay Command Center',
            number: '0985-488-3352',
            category: 'municipal',
          ),
          HomeHotline(
            id: 'san-juan',
            name: 'San Juan',
            number: '0917-000-0000',
            category: 'barangay',
          ),
        ],
        onBack: _noop,
      ),
      const ShellTabBar(selectedIndex: 0, onSelected: _onTab),
      const NotificationCentre(
        sections: <NoticeSection>[
          NoticeSection(
            heading: 'Recent',
            rows: <NoticeRow>[
              NoticeRow(
                eyebrow: 'MESSAGE',
                title: 'New reply',
                when: '9:05 AM',
                unread: true,
                tone: Color(0xFF0B3D91),
                tile: Color(0xFFEAF0FB),
                icon: Icons.circle,
              ),
            ],
          ),
        ],
        onMarkAllRead: _noop,
      ),
    ];

    for (final page in pages) {
      await _pump(tester, page);
      final undersized = <String>[];
      for (final element
          in find
              .byWidgetPredicate(
                (widget) =>
                    widget is IconButton ||
                    widget is FilledButton ||
                    widget is OutlinedButton ||
                    widget is TextButton ||
                    widget is InkWell ||
                    widget is GestureDetector,
              )
              .evaluate()) {
        final size = element.size;
        if (size == null) continue;
        if (size.height == 0 || size.width == 0) continue;
        if (size.height + 0.01 < A11y.minTapTarget ||
            size.width + 0.01 < A11y.minTapTarget) {
          undersized.add(
            '${element.widget.runtimeType} ${size.width.toStringAsFixed(1)}'
            'x${size.height.toStringAsFixed(1)}',
          );
        }
      }
      expect(undersized, isEmpty, reason: page.runtimeType.toString());
      if (find.byKey(ShellTabBar.discKey).evaluate().isNotEmpty) {
        expect(
          tester.getSize(find.byKey(ShellTabBar.discKey)).shortestSide,
          greaterThanOrEqualTo(A11y.minTapTarget),
        );
      }
    }
  });
}
