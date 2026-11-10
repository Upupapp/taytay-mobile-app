import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/core/api/server_value.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/design/taytay_icons.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/features/programs/presentation/program_detail_screen.dart';
import 'package:taytay_resident/features/programs/presentation/programs_screen.dart';
import 'package:taytay_resident/features/services/domain/assistance_history.dart';
import 'package:taytay_resident/features/services/presentation/release_and_referral.dart';
import 'package:taytay_resident/features/tulong/domain/social_service.dart';
import 'package:taytay_resident/features/tulong/presentation/tulong_canvas.dart';
import 'package:taytay_resident/shared/widgets/blue_header.dart';
import 'package:taytay_resident/shared/widgets/detail_page.dart';
import 'package:taytay_resident/shared/widgets/error_state.dart';
import 'package:taytay_resident/shared/widgets/loading_skeleton.dart';
import 'package:taytay_resident/shared/widgets/pill_button_row.dart';
import 'package:taytay_resident/shared/widgets/pills.dart';
import 'package:taytay_resident/shared/widgets/surface_cards.dart';
import 'package:taytay_resident/shared/widgets/taytay_states.dart';

import '../support/layout_matrix.dart';

/// Redesign P3d: Tulong, assistance requests, programmes and events at
/// 360 / 375 / 430 dp and 100% / 200% text, plus the content rules the
/// restyle must keep.
void main() {
  group('Tulong frames', () {
    final Map<String, TulongCanvas Function()> frames =
        <String, TulongCanvas Function()>{
          'list': () => TulongCanvas(
            frame: TulongFrame.list,
            services: _services,
            onOpen: (_) {},
            onBell: () {},
          ),
          'loading': () => const TulongCanvas(frame: TulongFrame.loading),
          'empty': () => const TulongCanvas(frame: TulongFrame.list),
          'no match': () => const TulongCanvas(
            frame: TulongFrame.list,
            emptyMessage: 'No programmes match that search.',
          ),
          'offline with saved pages': () => TulongCanvas(
            frame: TulongFrame.offline,
            saved: _services,
            offlineSubtitle: TulongCanvas.listSubtitle,
            onRetry: () {},
          ),
          'offline, nothing saved': () =>
              TulongCanvas(frame: TulongFrame.offline, onRetry: () {}),
          'service page': () => TulongCanvas(
            frame: TulongFrame.detail,
            service: _detailed,
            onBack: () {},
            onCall: () {},
            onDirections: () {},
            onMessage: () {},
            onOffice: () {},
          ),
          'service page with a photo': () => TulongCanvas(
            frame: TulongFrame.detail,
            service: _photographed,
            onBack: () {},
            loadHero: (String slug) async => Ok<Uint8List?>(_pixel),
          ),
          'featured page': () => TulongCanvas(
            frame: TulongFrame.detail,
            service: _featured,
            onBack: () {},
            onShare: () {},
          ),
        };
    for (final MapEntry<String, TulongCanvas Function()> entry
        in frames.entries) {
      testWidgets('${entry.key} lays out cleanly', (WidgetTester tester) async {
        await expectCleanLayouts(tester, entry.value, scrollable: false);
      });
    }
  });

  group('Tulong content', () {
    Future<void> pump(WidgetTester tester, Widget canvas) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(390, 1600);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(layoutHost(canvas, scrollable: false));
      await tester.pump();
    }

    testWidgets('the tab is the glass pattern with the seal and the bell', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const TulongCanvas(frame: TulongFrame.list, services: _services),
      );
      expect(find.byType(GlassBackground), findsOneWidget);
      expect(find.byType(HeaderSeal), findsOneWidget);
      expect(find.byKey(const Key('tulong-bell')), findsOneWidget);
      expect(find.text('Tulong'), findsOneWidget);
      expect(find.text(TulongCanvas.listSubtitle), findsOneWidget);
      expect(
        find.textContaining('These are information pages, not applications'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('tulong-open-sample-one')), findsOneWidget);
    });

    testWidgets('loading is a skeleton, empty and no-match are states', (
      WidgetTester tester,
    ) async {
      await pump(tester, const TulongCanvas(frame: TulongFrame.loading));
      expect(find.byType(LoadingSkeleton), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);

      await pump(tester, const TulongCanvas(frame: TulongFrame.list));
      expect(find.text('No programmes listed yet'), findsOneWidget);

      await pump(
        tester,
        const TulongCanvas(
          frame: TulongFrame.list,
          emptyMessage: 'No programmes match that search.',
        ),
      );
      expect(find.text('No programmes match that search.'), findsOneWidget);
    });

    testWidgets('offline offers Try again and the saved pages', (
      WidgetTester tester,
    ) async {
      var retried = 0;
      await pump(
        tester,
        TulongCanvas(
          frame: TulongFrame.offline,
          saved: _services,
          onRetry: () => retried += 1,
        ),
      );
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Programme pages need a connection'), findsOneWidget);
      expect(find.text('Saved pages'), findsOneWidget);
      expect(find.text('Showing what was saved on this phone'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retried, 1);
    });

    testWidgets('a service page is the Office pattern without an apply', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        TulongCanvas(
          frame: TulongFrame.detail,
          service: _detailed,
          onOffice: () {},
        ),
      );
      expect(find.byType(DetailSheet), findsOneWidget);
      expect(find.byType(PillButtonRow), findsOneWidget);
      expect(find.byType(BlueHeader), findsOneWidget);
      expect(find.byType(DetailHero), findsNothing);
      expect(find.text('Who can avail'), findsOneWidget);
      expect(find.text('Requirements (information only)'), findsOneWidget);
      expect(find.byKey(const Key('tulong-office')), findsOneWidget);
      expect(find.textContaining('Apply'), findsNothing);
      expect(find.textContaining('Submit'), findsNothing);
    });

    testWidgets('the photo replaces the blue header once it arrives', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        TulongCanvas(
          frame: TulongFrame.detail,
          service: _photographed,
          loadHero: (String slug) async => Ok<Uint8List?>(_pixel),
        ),
      );
      await tester.pump();
      expect(find.byType(DetailHero), findsOneWidget);
      expect(find.byType(BlueHeader), findsNothing);
    });

    testWidgets('the featured page keeps How to claim and Share', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const TulongCanvas(frame: TulongFrame.detail, service: _featured),
      );
      expect(find.text('How to claim'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.byKey(const Key('tulong-share')), findsOneWidget);
      expect(find.text('Step one, in words.'), findsOneWidget);
    });
  });

  group('shared detail widgets', () {
    testWidgets('DetailHero, DetailSheet and DetailFactRow lay out', (
      WidgetTester tester,
    ) async {
      await expectCleanLayouts(
        tester,
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DetailHero(
              onBack: () {},
              credit: 'A photo credit that is long enough to wrap',
              photo: const ColoredBox(color: BrandColors.blue100),
            ),
            GlassOverlap(
              amount: Radii.sheetLarge,
              child: DetailSheet(
                children: <Widget>[
                  const DetailFactRow(
                    icon: TaytayIcons.mapPin,
                    label: 'Label',
                    value: 'A value that runs long enough to wrap twice',
                  ),
                  DetailFactRow(
                    icon: TaytayIcons.handHeart,
                    label: 'Office',
                    value: 'Tappable office row',
                    onTap: () {},
                    tapKey: const Key('fact-tap'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });

    testWidgets('a tappable fact is one 48 dp button with a label', (
      WidgetTester tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        layoutHost(
          DetailFactRow(
            icon: TaytayIcons.handHeart,
            label: 'Office',
            value: 'Sample office',
            onTap: () => taps += 1,
            tapKey: const Key('fact-tap'),
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(const Key('fact-tap'))).height,
        greaterThanOrEqualTo(A11y.minTapTarget),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('fact-tap'))),
        isSemantics(
          label: 'Office, Sample office',
          isButton: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.byKey(const Key('fact-tap')));
      expect(taps, 1);
    });
  });

  group('assistance request parts', () {
    testWidgets('release and referral panels lay out', (
      WidgetTester tester,
    ) async {
      await expectCleanLayouts(
        tester,
        () => Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ReleaseCard(
                release: ReleaseDetail(
                  amountDescription: 'One sack of rice, 25 kg',
                  scheduledAt: DateTime.utc(2026, 7, 20),
                  location: 'Sample hall, window 4',
                  instructions: 'Bring a valid ID and your reference number.',
                  acknowledgement: const ServerValue<ReleaseAcknowledgement>(
                    raw: 'awaiting_resident',
                    known: ReleaseAcknowledgement.awaitingResident,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              const ReferralCard(
                referral: ReferralDetail(
                  destination: 'Sample Provincial Office',
                  serviceRequested: 'A synthetic service',
                  contact: '555-0100',
                  instructions: 'A synthetic instruction.',
                ),
              ),
            ],
          ),
        ),
      );
    });

    testWidgets('scope chips and status pills lay out and say their state', (
      WidgetTester tester,
    ) async {
      await expectCleanLayouts(
        tester,
        () => Wrap(
          children: <Widget>[
            SoftChoiceChip(label: 'Open', selected: true, onTap: () {}),
            SoftChoiceChip(label: 'Past', selected: false, onTap: () {}),
            const StatusPill(label: 'Being checked'),
          ],
        ),
      );
      await tester.pumpWidget(
        layoutHost(SoftChoiceChip(label: 'Open', selected: true, onTap: () {})),
      );
      expect(
        tester.getSize(find.byType(SoftChoiceChip)).height,
        greaterThanOrEqualTo(A11y.minTapTarget),
      );
      expect(
        tester.getSemantics(find.byType(SoftChoiceChip)),
        isSemantics(
          label: 'Open',
          isButton: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
    });
  });

  group('programme redirects', () {
    Future<void> pumpRedirect(
      WidgetTester tester,
      Widget stub, {
      double width = 375,
      double scale = 1,
    }) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = Size(width, 800);
      addTearDown(tester.view.reset);
      final GoRouter router = GoRouter(
        routes: <RouteBase>[
          GoRoute(path: '/', builder: (context, state) => stub),
          GoRoute(
            path: '/programs',
            name: AppRoute.programs.routeName,
            builder: (context, state) => const Text('Tulong list'),
            routes: <RouteBase>[
              GoRoute(
                path: ':programId',
                name: AppRoute.programDetail.routeName,
                builder: (context, state) =>
                    Text('Programme ${state.pathParameters['programId']}'),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );
    }

    for (final double width in layoutWidths) {
      for (final double scale in layoutTextScales) {
        testWidgets('the old pages wait with a skeleton at $width × $scale', (
          WidgetTester tester,
        ) async {
          await pumpRedirect(
            tester,
            const ProgramsScreen(),
            width: width,
            scale: scale,
          );
          expect(find.byType(LoadingSkeleton), findsOneWidget);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpAndSettle();
          expect(find.text('Tulong list'), findsOneWidget);

          await pumpRedirect(
            tester,
            const ProgramDetailScreen(programId: 'sample-programme'),
            width: width,
            scale: scale,
          );
          expect(find.byType(LoadingSkeleton), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpAndSettle();
          expect(find.text('Programme sample-programme'), findsOneWidget);
        });
      }
    }
  });

  test('restyled files use tokens: no raw colours, sizes or shadows', () {
    final List<String> offenders = <String>[];
    for (final String path in _restyled) {
      final List<String> lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final String line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (RegExp(
          r'Color\(0x|BoxShadow|elevation:|fontSize:|Color\(value',
        ).hasMatch(line)) {
          offenders.add('$path:${i + 1}: $line');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}

const List<String> _restyled = <String>[
  'lib/shared/widgets/detail_page.dart',
  'lib/shared/widgets/pills.dart',
  'lib/features/programs/presentation/programs_screen.dart',
  'lib/features/programs/presentation/program_detail_screen.dart',
  'lib/features/services/presentation/assistance_requests_screen.dart',
  'lib/features/services/presentation/assistance_case_screen.dart',
  'lib/features/services/presentation/release_and_referral.dart',
  'lib/features/tulong/presentation/tulong_canvas.dart',
  'lib/features/tulong/presentation/tulong_screen.dart',
  'lib/features/tulong/presentation/service_info_screen.dart',
];

/// A 1 × 1 PNG.
final Uint8List _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

const List<SocialService> _services = <SocialService>[
  SocialService(
    id: '11111111-1111-4111-8111-111111111101',
    name: 'Sample Programme One With A Long Name That Wraps',
    slug: 'sample-one',
    summary: 'A synthetic summary that is long enough to need two lines',
    details: 'Synthetic details.',
    iconKey: 'accessibility',
    tileColor: 0xFF0F7A4D,
  ),
  SocialService(
    id: '11111111-1111-4111-8111-111111111102',
    name: 'Sample Programme Two',
    slug: 'sample-two',
    summary: 'Another synthetic summary',
    details: 'Synthetic details.',
    iconKey: 'usersRound',
    tileColor: 0xFF7A5E0C,
  ),
];

const SocialService _detailed = SocialService(
  id: '11111111-1111-4111-8111-111111111103',
  name: 'Sample Assistance Programme',
  slug: 'sample-assistance',
  summary: 'Synthetic summary',
  details: 'Synthetic details that describe the programme in a sentence.',
  eligibility: 'Synthetic residents who meet a synthetic rule.',
  requirements: <ServiceRequirement>[
    ServiceRequirement(text: 'A synthetic document'),
    ServiceRequirement(
      text: 'A second synthetic document with a long name',
      sample: true,
    ),
  ],
  contacts: <ServiceContact>[
    ServiceContact(
      type: ServiceContactType.hotline,
      label: 'Hotline',
      value: '555-0100',
    ),
  ],
  locations: <ServiceLocation>[
    ServiceLocation(name: 'Where', address: 'Sample hall, ground floor'),
  ],
  officeSlug: 'sample-office',
  officeName: 'Sample Social Welfare Office',
  officeShortName: 'SSWO',
  officeHours: 'Weekdays, office hours',
  legalBasis: 'Source: a synthetic ordinance.',
);

const SocialService _photographed = SocialService(
  id: '11111111-1111-4111-8111-111111111104',
  name: 'Sample Photographed Programme',
  slug: 'sample-photo',
  summary: 'Synthetic summary',
  details: 'Synthetic details.',
  heroUrl: 'https://api.example.test/services/sample-photo/hero',
);

const SocialService _featured = SocialService(
  id: '11111111-1111-4111-8111-111111111105',
  name: 'Sample Featured Programme',
  slug: 'sample-featured',
  summary: 'Synthetic summary',
  details: 'Synthetic details for the featured page.',
  featured: true,
  featuredHeadline: 'A synthetic headline that is long enough to wrap',
  claimSteps: <String>['Step one, in words.', 'Step two, in more words.'],
  schedule: 'A synthetic schedule',
  badge: 'Sample badge',
);
