import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/pills.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_rows.dart';
import '../../../shared/widgets/taytay_states.dart';
import 'shared_widgets_gallery_section.dart';
import 'theme_gallery_section.dart';

/// Every shared component, on the light theme, in a dev build only.
///
/// The route guard refuses this page outside dev. What it shows is sample
/// chrome, marked SAMPLE, and it does not call the LGU API. Redesign Phase 4:
/// every specimen is a widget the screens use; the old woven / in-app
/// headers, outlined rows and arch photo are gone with the widgets.
class ComponentGalleryScreen extends StatelessWidget {
  const ComponentGalleryScreen({this.behavior, super.key});

  /// Present when the composition root built dev mocks. The switch changes
  /// the next repository call.
  final MockBehaviorController? behavior;

  @override
  Widget build(BuildContext context) {
    final MockBehaviorController? behavior = this.behavior;
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: ListView(
        padding: const EdgeInsets.only(bottom: Spacing.xxl),
        children: <Widget>[
          const BlueHeader(
            title: 'Components',
            subtitle: 'Dev build only',
            showBack: true,
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SampleTag(),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Frozen sample clock: 20 Oct 2026, 09:05',
                  style: AppTypography.bodyStyle.copyWith(
                    color: BrandColors.text,
                  ),
                ),
              ],
            ),
          ),
          if (behavior != null) _MockSwitch(behavior: behavior),
          // The redesign's tokens and themed Material components.
          const ThemeGallerySection(),
          // The redesign's shared widgets (Phase 2 onwards).
          const SharedWidgetsGallerySection(),
          const _Heading('PrimaryButton, SecondaryButton, GoldButton'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Column(
              children: <Widget>[
                PrimaryButton(label: 'Read Balita', onPressed: _noop),
                SizedBox(height: Spacing.sm),
                SecondaryButton(label: 'See all', onPressed: _noop),
                SizedBox(height: Spacing.sm),
                GoldButton(label: 'Next', onPressed: _noop),
              ],
            ),
          ),
          const _Heading('AuthField'),
          const _FieldSpecimens(),
          const _Heading('Icon and notice'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: TaytayIcon(
              icon: TaytayIcons.landmark,
              semanticLabel: 'Municipal hall',
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: PrimaryButton(
              label: 'Show a notice',
              onPressed: () => showTaytayToast(
                context,
                'SAMPLE notice. It is not from the LGU.',
              ),
            ),
          ),
          Text(
            'Light theme · Plus Jakarta Sans',
            style: AppTypography.small.copyWith(color: BrandColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

void _noop() {}

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
      child: Text(
        text,
        style: AppTypography.sectionTitle.copyWith(color: BrandColors.ink),
      ),
    );
  }
}

/// The form field every form page uses: plain, required with an icon and a
/// hint, and in error.
class _FieldSpecimens extends StatefulWidget {
  const _FieldSpecimens();

  @override
  State<_FieldSpecimens> createState() => _FieldSpecimensState();
}

class _FieldSpecimensState extends State<_FieldSpecimens> {
  final TextEditingController _plain = TextEditingController();
  final TextEditingController _icon = TextEditingController();
  final TextEditingController _error = TextEditingController();

  @override
  void dispose() {
    _plain.dispose();
    _icon.dispose();
    _error.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AuthField(
            label: 'Mobile number',
            controller: _plain,
            placeholder: '09XX XXX XXXX',
          ),
          const SizedBox(height: Spacing.formGap),
          AuthField(
            label: 'Email',
            controller: _icon,
            requiredField: true,
            icon: TaytayIcons.mail,
            hint: 'A hint under the field.',
          ),
          const SizedBox(height: Spacing.formGap),
          AuthField(
            label: 'Code',
            controller: _error,
            error: 'That code does not match.',
          ),
        ],
      ),
    );
  }
}

class _MockSwitch extends StatelessWidget {
  const _MockSwitch({required this.behavior});

  final MockBehaviorController behavior;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: behavior,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Mock failure: ${_failureLabel(behavior.failure)}',
                style: AppTypography.listTitle.copyWith(color: BrandColors.ink),
              ),
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: Spacing.sm,
                children: <Widget>[
                  for (final MockFailureMode mode in MockFailureMode.values)
                    SoftChoiceChip(
                      label: _failureLabel(mode),
                      selected: behavior.failure == mode,
                      onTap: () => behavior.setFailure(mode),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Words a developer reads in the gallery. The wire token stays off the screen.
String _failureLabel(MockFailureMode mode) {
  return switch (mode) {
    MockFailureMode.none => 'None',
    MockFailureMode.offline => 'Offline',
    MockFailureMode.server => 'Server',
  };
}
