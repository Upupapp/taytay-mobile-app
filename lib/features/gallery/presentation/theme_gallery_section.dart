import 'package:flutter/material.dart';

import '../../../core/design/brand_gradients.dart';
import '../../../core/design/button_styles.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/taytay_icon.dart';

/// The redesign's tokens and the themed Material components, for the dev
/// gallery. Everything here is drawn from `lib/core/design/`; nothing is
/// styled locally, so the gallery shows what a screen gets for free.
class ThemeGallerySection extends StatelessWidget {
  const ThemeGallerySection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Heading('Colours'),
        _Swatches(),
        _Heading('Gradients'),
        _HeaderSpecimen(),
        SizedBox(height: Spacing.md),
        _WaveSpecimen(),
        SizedBox(height: Spacing.md),
        _Tiles(),
        SizedBox(height: Spacing.md),
        _GlassSpecimen(),
        _Heading('Type'),
        _TypeScale(),
        _Heading('Card and list rows'),
        _CardSpecimen(),
        _Heading('Filled fields'),
        _FieldSpecimens(),
        _Heading('Material buttons'),
        _ButtonSpecimens(),
        _Heading('Chips'),
        _ChipSpecimens(),
        _Heading('Navigation bar'),
        _NavigationSpecimen(),
        _Heading('Dialog and bottom sheet'),
        _PopupSpecimens(),
      ],
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

class _Gutter extends StatelessWidget {
  const _Gutter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: child,
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches();

  static const Map<String, Color> _colours = <String, Color>{
    'blue': BrandColors.blue,
    'navy': BrandColors.navy,
    'sky': BrandColors.sky,
    'gold': BrandColors.gold,
    'red': BrandColors.red,
    'green': BrandColors.green,
    'ink': BrandColors.ink,
    'text': BrandColors.text,
    'muted': BrandColors.muted,
    'background': BrandColors.background,
    'soft fill': BrandColors.softFill,
    'divider': BrandColors.divider,
    'blue-50': BrandColors.blue50,
    'blue-100': BrandColors.blue100,
  };

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return _Gutter(
      child: Wrap(
        spacing: Spacing.sm,
        runSpacing: Spacing.sm,
        children: <Widget>[
          for (final MapEntry<String, Color> entry in _colours.entries)
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: entry.value,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: BrandColors.line2),
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(entry.key, style: text.labelSmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderSpecimen extends StatelessWidget {
  const _HeaderSpecimen();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: HeaderShapes.radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: BrandGradients.header.toLinearGradient(),
        ),
        // Grows with the text: a fixed height overflows at 200% text.
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: double.infinity,
            minHeight: 120,
          ),
          child: Stack(
            children: <Widget>[
              for (final HeaderCircle circle in HeaderShapes.circles)
                Positioned(
                  top: circle.top,
                  right: circle.right,
                  bottom: circle.bottom,
                  left: circle.left,
                  width: circle.diameter,
                  height: circle.diameter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: circle.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Header · 150°',
                      style: AppTypography.headerTitleLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      'Navy → blue → sky, two circles, corners 28',
                      style: AppTypography.headerSubtitle.copyWith(
                        color: BrandColors.onHeaderMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveSpecimen extends StatelessWidget {
  const _WaveSpecimen();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: BrandGradients.waveHeader.toLinearGradient(),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: double.infinity,
          minHeight: 130,
        ),
        child: Stack(
          children: <Widget>[
            Padding(
              // The wave takes the bottom 50.
              padding: const EdgeInsets.fromLTRB(
                Spacing.formGutter,
                Spacing.formGutter,
                Spacing.formGutter,
                58,
              ),
              child: Text(
                'Wave header',
                style: AppTypography.hero.copyWith(color: Colors.white),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              height: 50,
              child: CustomPaint(painter: WavePainter()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles();

  static const Map<TileTone, IconData> _icons = <TileTone, IconData>{
    TileTone.blue: TaytayIcons.landmark,
    TileTone.green: TaytayIcons.heartPulse,
    TileTone.gold: TaytayIcons.megaphone,
    TileTone.red: TaytayIcons.siren,
    TileTone.navy: TaytayIcons.idCard,
    TileTone.sky: TaytayIcons.users,
  };

  @override
  Widget build(BuildContext context) {
    return _Gutter(
      child: Wrap(
        spacing: Spacing.md,
        runSpacing: Spacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          for (final MapEntry<TileTone, IconData> entry in _icons.entries)
            _Tile(
              gradient: BrandGradients.tile(entry.key),
              icon: entry.value,
              label: '${entry.key.name} tile',
            ),
          const _Tile(
            gradient: BrandGradients.tileBlue,
            icon: TaytayIcons.house,
            label: 'small tile',
            size: ComponentSizes.tileSmall,
            radius: Radii.tileSmall,
          ),
          const _Tile(
            gradient: BrandGradients.tileBlue,
            icon: TaytayIcons.house,
            label: 'large tile',
            size: ComponentSizes.tileLarge,
            radius: Radii.tileLarge,
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.gradient,
    required this.icon,
    required this.label,
    this.size = ComponentSizes.tile,
    this.radius = Radii.tile,
  });

  final BrandGradient gradient;
  final IconData icon;
  final String label;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: gradient.toLinearGradient(),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: TaytayIcon(
        icon: icon,
        semanticLabel: label,
        size: IconSizes.sm + 2,
        color: gradient.onColor,
      ),
    );
  }
}

class _GlassSpecimen extends StatelessWidget {
  const _GlassSpecimen();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: ColoredBox(color: GlassTokens.pageColor),
          ),
          for (final GlassBlob blob in GlassTokens.pageBlobs)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      blob.center.dx * 2 - 1,
                      blob.center.dy * 2 - 1,
                    ),
                    radius: 0.9,
                    colors: <Color>[
                      blob.color,
                      blob.color.withValues(alpha: 0),
                    ],
                    stops: const <double>[0, 0.7],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.cardLarge),
              child: BackdropFilter(
                filter: GlassTokens.backdropFilter(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: GlassTokens.fill,
                    borderRadius: BorderRadius.circular(Radii.cardLarge),
                    border: Border.all(
                      color: GlassTokens.border,
                      width: GlassTokens.borderWidth,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Glass card',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  @override
  Widget build(BuildContext context) {
    final List<(String, TextStyle)> roles = <(String, TextStyle)>[
      ('Hero 22 / 700', AppTypography.hero),
      ('Header 20 / 700', AppTypography.headerTitleLarge),
      ('Page title 18 / 700', AppTypography.pageTitle),
      ('Section 15 / 600', AppTypography.sectionTitle),
      ('Header with back 15 / 600', AppTypography.headerTitle),
      (
        'Body 13.5 / 500 — a full sentence wraps here.',
        AppTypography.bodyStyle,
      ),
      ('List title 13.5 / 600', AppTypography.listTitle),
      ('List detail 12.5 / 500', AppTypography.listDetail),
      ('Button 14 / 600', AppTypography.button),
      ('Field 14 / 600', AppTypography.fieldValue),
      ('Field label 12.5 / 600', AppTypography.label),
      ('Chip 13.5 / 600', AppTypography.chip),
      ('Small 11.5 / 500', AppTypography.small),
      ('Nav label 11', AppTypography.navLabel),
      ('CATEGORY · 10.5 / 800', AppTypography.category),
    ];
    return _Gutter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final (String label, TextStyle style) in roles)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Text(label, style: style.copyWith(color: BrandColors.ink)),
            ),
        ],
      ),
    );
  }
}

class _CardSpecimen extends StatelessWidget {
  const _CardSpecimen();

  @override
  Widget build(BuildContext context) {
    return const _Gutter(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: <Widget>[
            ListTile(
              leading: _Tile(
                gradient: BrandGradients.tileBlue,
                icon: TaytayIcons.landmark,
                label: 'Office',
              ),
              title: Text('List row title'),
              subtitle: Text('Supporting detail, 12.5'),
              trailing: TaytayIcon(
                icon: TaytayIcons.chevronRight,
                semanticLabel: 'Open',
                size: IconSizes.sm,
                color: BrandColors.chevron,
              ),
              onTap: _noop,
            ),
            Divider(indent: 72, endIndent: Spacing.lg),
            ListTile(
              leading: _Tile(
                gradient: BrandGradients.tileGreen,
                icon: TaytayIcons.heartPulse,
                label: 'Health',
              ),
              title: Text('A second row'),
              subtitle: Text('Rows are 64 high, tiles 44'),
              onTap: _noop,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldSpecimens extends StatelessWidget {
  const _FieldSpecimens();

  @override
  Widget build(BuildContext context) {
    final TextStyle label = AppTypography.label.copyWith(
      color: BrandColors.text,
    );
    return _Gutter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'At rest (tap to focus: white, blue border, ring)',
            style: label,
          ),
          const SizedBox(height: Spacing.sm),
          const TextField(decoration: InputDecoration(hintText: 'Placeholder')),
          const SizedBox(height: Spacing.formGap),
          Text('With an icon', style: label),
          const SizedBox(height: Spacing.sm),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: TaytayIcon(
                icon: TaytayIcons.search,
                semanticLabel: 'Search',
                size: IconSizes.sm,
              ),
            ),
          ),
          const SizedBox(height: Spacing.formGap),
          Text('In error', style: label),
          const SizedBox(height: Spacing.sm),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Mobile number',
              errorText: 'Enter an 11-digit mobile number.',
            ),
          ),
          const SizedBox(height: Spacing.formGap),
          Text('Disabled', style: label),
          const SizedBox(height: Spacing.sm),
          const TextField(
            enabled: false,
            decoration: InputDecoration(hintText: 'Not editable'),
          ),
        ],
      ),
    );
  }
}

class _ButtonSpecimens extends StatelessWidget {
  const _ButtonSpecimens();

  @override
  Widget build(BuildContext context) {
    return _Gutter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const FilledButton(onPressed: _noop, child: Text('Primary')),
          const SizedBox(height: Spacing.sm),
          const FilledButton.tonal(
            onPressed: _noop,
            child: Text('Soft secondary (tonal)'),
          ),
          const SizedBox(height: Spacing.sm),
          const OutlinedButton(
            onPressed: _noop,
            child: Text('Outlined is soft too'),
          ),
          const SizedBox(height: Spacing.sm),
          FilledButton(
            style: TaytayButtonStyles.gold(),
            onPressed: _noop,
            child: const Text('Gold'),
          ),
          const SizedBox(height: Spacing.sm),
          const FilledButton(onPressed: null, child: Text('Disabled')),
          const SizedBox(height: Spacing.sm),
          const Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: _noop, child: Text('Text link')),
          ),
        ],
      ),
    );
  }
}

class _ChipSpecimens extends StatefulWidget {
  const _ChipSpecimens();

  @override
  State<_ChipSpecimens> createState() => _ChipSpecimensState();
}

class _ChipSpecimensState extends State<_ChipSpecimens> {
  static const List<String> _labels = <String>['All', 'Health', 'Social'];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return _Gutter(
      child: Wrap(
        spacing: Spacing.sm,
        runSpacing: Spacing.sm,
        children: <Widget>[
          for (var i = 0; i < _labels.length; i++)
            ChoiceChip(
              label: Text(_labels[i]),
              selected: _selected == i,
              onSelected: (_) => setState(() => _selected = i),
            ),
          const ChoiceChip(label: Text('Disabled'), selected: false),
        ],
      ),
    );
  }
}

class _NavigationSpecimen extends StatefulWidget {
  const _NavigationSpecimen();

  @override
  State<_NavigationSpecimen> createState() => _NavigationSpecimenState();
}

class _NavigationSpecimenState extends State<_NavigationSpecimen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (int value) => setState(() => _index = value),
      destinations: const <Widget>[
        NavigationDestination(
          icon: TaytayIcon(
            icon: TaytayIcons.house,
            semanticLabel: 'Home',
            excludeSemantics: true,
          ),
          label: 'Home',
        ),
        NavigationDestination(
          icon: TaytayIcon(
            icon: TaytayIcons.newspaper,
            semanticLabel: 'Balita',
            excludeSemantics: true,
          ),
          label: 'Balita',
        ),
        NavigationDestination(
          icon: TaytayIcon(
            icon: TaytayIcons.user,
            semanticLabel: 'Account',
            excludeSemantics: true,
          ),
          label: 'Account',
        ),
      ],
    );
  }
}

/// The two popups (DESIGN_SYSTEM.md §8 rule 3): a centred panel dialog for
/// anything that explains, warns, confirms or decides (`AppDialog.show`), and
/// a bottom sheet only for a picker — a list of choices.
class _PopupSpecimens extends StatelessWidget {
  const _PopupSpecimens();

  @override
  Widget build(BuildContext context) {
    return _Gutter(
      child: Row(
        children: <Widget>[
          Expanded(
            child: FilledButton.tonal(
              onPressed: () => AppDialog.show<void>(
                context: context,
                title: 'Centred dialog',
                builder: (BuildContext dialog) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Flat, white, radius 22. The scrim is the only depth. '
                      'Gates, notices, confirmations and decisions open here.',
                    ),
                    const SizedBox(height: Spacing.xl),
                    AppButton(
                      label: 'Close',
                      onPressed: () => Navigator.of(dialog).pop(),
                    ),
                  ],
                ),
              ),
              child: const Text('Dialog'),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: FilledButton.tonal(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (BuildContext sheet) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.formGutter,
                    0,
                    Spacing.formGutter,
                    Spacing.xl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Picker sheet: white, top corners 28, no shadow. '
                        'Only a list of choices opens here.',
                      ),
                      for (final String choice in const <String>[
                        'First choice',
                        'Second choice',
                      ])
                        ListTile(
                          title: Text(choice),
                          onTap: () => Navigator.of(sheet).pop(),
                        ),
                    ],
                  ),
                ),
              ),
              child: const Text('Sheet'),
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}
