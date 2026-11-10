import 'package:flutter/material.dart';

import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/consent_check_card.dart';
import '../../../shared/widgets/detail_page.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/feed_row.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/network_status_views.dart';
import '../../../shared/widgets/notice_panel.dart';
import '../../../shared/widgets/photo_carousel.dart';
import '../../../shared/widgets/pill_button_row.dart';
import '../../../shared/widgets/pills.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/status_line.dart';
import '../../../shared/widgets/success_screen.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_glyph.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../../../shared/widgets/wave_header.dart';

/// The redesign's shared widgets (MOBILE_TASK Phase 2), for the dev gallery.
///
/// Every specimen is placeholder copy for this dev-only page; the widgets
/// themselves take all their data from the caller. The status line is drawn
/// against specimen hours on the gallery's frozen clock — a real screen
/// passes hours from the API, or null.
class SharedWidgetsGallerySection extends StatelessWidget {
  const SharedWidgetsGallerySection({super.key});

  /// The gallery's frozen sample clock: 20 Oct 2026, 09:05 Manila (a Tuesday).
  static final DateTime sampleNow = DateTime.utc(2026, 10, 20, 1, 5);

  /// Specimen hours: weekdays, 8:00 AM to 5:00 PM.
  static const WeeklyHours sampleHours = WeeklyHours(<int, DayHours>{
    DateTime.monday: DayHours.of(8, 0, 17, 0),
    DateTime.tuesday: DayHours.of(8, 0, 17, 0),
    DateTime.wednesday: DayHours.of(8, 0, 17, 0),
    DateTime.thursday: DayHours.of(8, 0, 17, 0),
    DateTime.friday: DayHours.of(8, 0, 17, 0),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _Heading('BlueHeader'),
        BlueHeader(
          title: 'Page title',
          subtitle: 'Subtitle',
          leading: const HeaderSeal(),
          includeSafeArea: false,
          actions: <Widget>[
            HeaderIconButton(
              icon: TaytayIcons.bell,
              semanticLabel: 'Notifications, 2 unread',
              badgeCount: 2,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        BlueHeader(
          title: 'Detail title',
          showBack: true,
          onBack: () {},
          includeSafeArea: false,
        ),
        const _Heading('WaveHeader'),
        WaveHeader(
          title: 'Form title',
          subtitle: 'One sentence on what this step asks for.',
          showBack: true,
          onBack: () {},
          stepLabel: 'Step 2 of 6',
          progress: 2 / 6,
          progressSemanticLabel: 'Progress',
          includeSafeArea: false,
        ),
        const _Heading('SoftCard and GlassCard'),
        const _Padded(
          SoftCard(child: Text('SoftCard: white, radius 20, no border.')),
        ),
        const SizedBox(height: Spacing.md),
        const _Padded(
          SoftCard(filled: true, child: Text('SoftCard(filled: true).')),
        ),
        const SizedBox(height: Spacing.md),
        const GlassBackground(
          child: Padding(
            padding: EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                GlassCard(child: Text('GlassCard on GlassBackground.')),
                SizedBox(height: Spacing.md),
                GlassCard(pinned: true, child: Text('GlassCard(pinned).')),
              ],
            ),
          ),
        ),
        const _Heading('IconTile.glyph — six tones, three sizes'),
        _Padded(
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              for (final TileTone tone in TileTone.values)
                IconTile.glyph(glyph: TaytayGlyph.bank, tone: tone),
              for (final IconTileSize size in IconTileSize.values)
                IconTile.glyph(glyph: TaytayGlyph.heart, tileSize: size),
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),
        _Padded(
          Wrap(
            spacing: Spacing.md,
            runSpacing: Spacing.md,
            children: <Widget>[
              for (final TaytayGlyph glyph in TaytayGlyph.values)
                GlyphIcon(glyph, color: BrandColors.blue),
            ],
          ),
        ),
        const _Heading('PillButtonRow'),
        PillButtonRow(
          actions: <PillAction>[
            PillAction(
              label: 'Call',
              glyph: TaytayGlyph.phone,
              primary: true,
              onPressed: () {},
            ),
            PillAction(
              label: 'Directions',
              glyph: TaytayGlyph.pin,
              onPressed: () {},
            ),
            PillAction(
              label: 'Message',
              glyph: TaytayGlyph.chat,
              onPressed: () {},
            ),
            PillAction(
              label: 'Website',
              glyph: TaytayGlyph.globe,
              onPressed: () {},
            ),
          ],
        ),
        const _Heading('StatusLine (specimen hours, frozen clock)'),
        _Padded(StatusLine(hours: sampleHours, now: sampleNow)),
        const SizedBox(height: Spacing.sm),
        _Padded(
          StatusLine(
            hours: sampleHours,
            now: DateTime.utc(2026, 10, 24, 2),
            compact: true,
          ),
        ),
        const _Heading('FeedRow'),
        _Padded(
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Column(
              children: <Widget>[
                FeedRow(
                  category: 'CATEGORY · OFFICE',
                  categoryTone: CategoryTone.green,
                  title: 'Story title from the API',
                  dateLabel: 'Date label',
                  placeholderGlyph: TaytayGlyph.megaphone,
                  onTap: () {},
                ),
                FeedRow(
                  category: 'CATEGORY',
                  title: 'A row without a thumbnail runs the full width',
                  dateLabel: 'Date label',
                  divider: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
        const _Heading('PhotoCarousel'),
        const _Padded(
          PhotoCarousel(
            height: 180,
            photos: <CarouselPhoto>[
              CarouselPhoto.provider(
                AssetImage('assets/photos/municipal_hall.jpg'),
                semanticLabel: 'Photo: Taytay Municipal Hall',
              ),
              CarouselPhoto.provider(
                AssetImage('assets/photos/parish_church.jpg'),
                semanticLabel: 'Photo: St. John the Baptist Parish Church',
              ),
            ],
          ),
        ),
        const _Heading('ConsentCheckCard'),
        const _Padded(_ConsentSpecimen()),
        const _Heading('SoftNote'),
        const _Padded(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SoftNote(message: 'Context to read before acting.'),
              SizedBox(height: Spacing.sm),
              SoftNote(
                tone: NoteTone.warning,
                title: 'Waiting. ',
                message: 'Something to watch.',
              ),
              SizedBox(height: Spacing.sm),
              SoftNote(
                tone: NoteTone.error,
                title: 'Failed. ',
                message: 'What to fix.',
              ),
              SizedBox(height: Spacing.sm),
              SoftNote(tone: NoteTone.success, message: 'Done.'),
            ],
          ),
        ),
        const _Heading('SettingsList, SettingsRow, SettingsSwitchRow'),
        _Padded(
          SettingsList(
            children: <Widget>[
              SettingsRow(
                icon: TaytayIcons.idCard,
                title: 'Row title',
                detail: 'Row detail',
                progress: 0.6,
                onTap: () {},
              ),
              SettingsRow(
                icon: TaytayIcons.messageSquare,
                title: 'Row with a count',
                detail: 'The count comes from the API',
                badgeCount: 1,
                onTap: () {},
              ),
              SettingsSwitchRow(
                icon: TaytayIcons.bell,
                title: 'Switch row',
                detail: 'Detail',
                value: true,
                onChanged: (_) {},
              ),
              SettingsRow(
                icon: TaytayIcons.logOut,
                title: 'Sign out',
                destructive: true,
                onTap: () {},
              ),
            ],
          ),
        ),
        const _Heading('NoticePanel'),
        const _Padded(
          NoticePanel(
            title: 'Notice title',
            subtitle: 'Source line',
            icon: TaytayIcons.shieldCheck,
            badge: DraftPill('DRAFT · text to be inserted'),
            intro: 'One paragraph of introduction.',
            points: <NoticePoint>[
              NoticePoint(title: 'Point title', body: 'Point body.'),
              NoticePoint(title: 'Second point', body: 'Point body.'),
            ],
          ),
        ),
        const _Heading('EmptyState, ErrorState, OfflineNotice'),
        const _Padded(
          EmptyState(
            title: 'Nothing found',
            message: 'Say what is empty and what to do next.',
            actionLabel: 'Action',
          ),
        ),
        _Padded(
          ErrorState(
            title: 'Could not load this',
            message: 'Say what failed and what to try.',
            offline: true,
            boxed: true,
            onRetry: () {},
          ),
        ),
        const SizedBox(height: Spacing.md),
        _Padded(
          OfflineNotice(
            title: 'Offline title',
            message: 'What is shown instead',
            retryLabel: 'Try again',
            onRetry: () {},
          ),
        ),
        const _Heading('LoadingSkeleton'),
        const _Padded(LoadingSkeleton(count: 2)),
        const SizedBox(height: Spacing.md),
        const _Padded(LoadingSkeleton(layout: SkeletonLayout.feed, count: 2)),
        const _Heading('DetailHero, DetailSheet, DetailFactRow'),
        MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DetailHero(
                onBack: () {},
                credit: 'Photo credit',
                photo: const ColoredBox(color: BrandColors.blue100),
              ),
              const GlassOverlap(
                amount: Radii.sheetLarge,
                child: DetailSheet(
                  children: <Widget>[
                    Text('Sheet title'),
                    DetailFactRow(
                      icon: TaytayIcons.mapPin,
                      label: 'Fact label',
                      value: 'Fact value',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const _Heading('SoftChoiceChip, StatusPill'),
        _Padded(
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SoftChoiceChip(label: 'In force', selected: true, onTap: () {}),
              SoftChoiceChip(label: 'Other', selected: false, onTap: () {}),
              const StatusPill(label: 'Status'),
              const StatusPill(label: 'Done', tone: PillTone.green),
              const StatusPill(label: 'Waiting', tone: PillTone.gold),
            ],
          ),
        ),
        const _Heading('HeaderChoiceChip'),
        ColoredBox(
          color: BrandColors.blue,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Wrap(
              spacing: Spacing.sm,
              children: <Widget>[
                HeaderChoiceChip(
                  label: 'In force',
                  selected: true,
                  onTap: () {},
                ),
                HeaderChoiceChip(label: 'Other', selected: false, onTap: () {}),
              ],
            ),
          ),
        ),
        const _Heading('SuccessScreen'),
        SizedBox(
          height: 720,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeBottom: true,
            child: SuccessScreen(
              title: 'Done title',
              message: 'One sentence on what happens next.',
              details: const <SuccessDetail>[
                SuccessDetail(label: 'Label', value: 'Value'),
                SuccessDetail(label: 'Another label', value: 'Value'),
              ],
              note: 'A note under the perforation.',
              primaryLabel: 'Primary action',
              onPrimary: () {},
              secondaryLabel: 'Secondary link',
              onSecondary: () {},
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsentSpecimen extends StatefulWidget {
  const _ConsentSpecimen();

  @override
  State<_ConsentSpecimen> createState() => _ConsentSpecimenState();
}

class _ConsentSpecimenState extends State<_ConsentSpecimen> {
  bool _ticked = true;

  @override
  Widget build(BuildContext context) {
    return ConsentCheckCard(
      value: _ticked,
      onChanged: (value) => setState(() => _ticked = value),
      label: 'A statement the resident agrees to.',
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.xl,
        Spacing.lg,
        Spacing.sm,
      ),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _Padded extends StatelessWidget {
  const _Padded(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: child,
    );
  }
}
