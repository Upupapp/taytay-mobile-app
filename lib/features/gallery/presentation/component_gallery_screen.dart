import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../shared/widgets/taytay_arch_photo.dart';
import '../../../shared/widgets/taytay_back_button.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_headers.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_rows.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../../../shared/widgets/taytay_step_thread.dart';
import '../../../shared/widgets/taytay_text_field.dart';

/// Every shared component, on the light theme, in a dev build only.
///
/// The route guard refuses this page outside dev. What it shows is sample
/// chrome, marked SAMPLE, and it does not call the LGU API.
class ComponentGalleryScreen extends StatelessWidget {
  const ComponentGalleryScreen({this.behavior, super.key});

  /// Present when the composition root built dev mocks. The switch changes
  /// the next repository call.
  final MockBehaviorController? behavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const TaytayBackButton(),
        title: const Text('Components'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Spacing.xxl),
          children: <Widget>[
            const WovenHeader(),
            const Padding(
              padding: EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SampleTag(),
                  SizedBox(height: Spacing.sm),
                  Text(
                    'Frozen sample clock: 20 Oct 2026, 09:05',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontWeight: AppTypography.body,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
            if (behavior != null) _MockSwitch(behavior: behavior!),
            const _Heading('Headers'),
            // The page's own back button is the route control. This specimen
            // shows the bar without a second one.
            const InAppHeader(
              title: 'Emergency hotlines',
              subtitle: 'Bayan ng Taytay · Rizal',
              showBack: false,
              showBell: true,
              bellCount: 2,
            ),
            const _Heading('Buttons'),
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
            const _Heading('Fields'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Column(
                children: <Widget>[
                  TaytayTextField(label: 'Mobile number', hint: '09XX'),
                  SizedBox(height: Spacing.sm),
                  TaytayTextField(
                    label: 'Email or mobile number',
                    hint: 'name@example.com',
                    state: TaytayFieldState.focused,
                  ),
                  SizedBox(height: Spacing.sm),
                  TaytayTextField(
                    label: 'Code',
                    state: TaytayFieldState.error,
                    message: 'That code does not match.',
                  ),
                  SizedBox(height: Spacing.sm),
                  TaytayTextField(
                    label: 'Email',
                    state: TaytayFieldState.success,
                    message: 'Looks right.',
                  ),
                ],
              ),
            ),
            const _Heading('Rows and chips'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: <Widget>[
                  StatusChip(label: 'Advisory', tone: StatusTone.amber),
                  StatusChip(label: 'Open', tone: StatusTone.green),
                  StatusChip(label: 'Closed', tone: StatusTone.red),
                  StatusChip(label: 'Info', tone: StatusTone.blue),
                  StatusChip(label: 'Draft', tone: StatusTone.grey),
                  StatusChip(label: 'Official', tone: StatusTone.gold),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: ListRow(
                title: 'Sagip Taytay Command Center',
                subtitle: 'SAMPLE · 0900-000-0000',
                icon: TaytayIcons.siren,
                iconLabel: 'Hotline',
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(Spacing.lg),
              child: ActionRow(
                onCall: _noop,
                onDirections: _noop,
                onMessage: _noop,
              ),
            ),
            const _Heading('Steps'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: StepThread(step: 2, total: 4),
            ),
            const _Heading('Photo'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: ArchPhoto(
                caption: 'Taytay Municipal Hall',
                credit: 'Photo credit required. No hall photograph is bundled.',
              ),
            ),
            const _Heading('States'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Column(
                children: <Widget>[
                  SectionCard(
                    child: Text('A section card holds related content.'),
                  ),
                  SizedBox(height: Spacing.md),
                  SkeletonBlock(height: 18),
                  SizedBox(height: Spacing.md),
                  EmptyState(
                    title: 'Nothing here yet',
                    message: 'SAMPLE empty state. No record was expected.',
                  ),
                  SizedBox(height: Spacing.md),
                  OfflineError(onRetry: _noop),
                ],
              ),
            ),
            const _Heading('Icon'),
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
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
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
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: Spacing.sm,
                children: <Widget>[
                  for (final mode in MockFailureMode.values)
                    ChoiceChip(
                      label: Text(_failureLabel(mode)),
                      selected: behavior.failure == mode,
                      onSelected: (_) => behavior.setFailure(mode),
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
