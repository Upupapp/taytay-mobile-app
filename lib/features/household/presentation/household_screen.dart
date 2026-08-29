import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/resident_capability.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../domain/household_summary.dart';

/// Household and family — what Taytay LGU records about the resident's home.
///
/// ---
///
/// ## Two summaries, one destination
///
/// The screen carries a **household** summary (where the LGU believes this home
/// is, and how many people it serves there) and a **family** summary (the
/// resident's own place in it, and what that means for services). They are
/// separate sections because they answer different questions and can be wrong
/// independently — but not separate screens, because a second route whose entire
/// content is one sentence is worse navigation than a heading.
///
/// ## What is not here, and why
///
/// **No names.** The committed client-visibility matrix names
/// `Household.members` among the things a citizen never receives — *"Any other
/// resident's data … Cross-resident access is a critical defect"* — while
/// granting a citizen `household` membership *"own household only"*. A resident
/// may know that they belong to a household and see its address; who else is in
/// it is those people's data, not theirs. The app has no type that could hold a
/// member, so this screen has nothing to render one from.
///
/// **No vulnerability signals, no casework, no other members' cases.** `sectors`
/// — where `vawc-survivor` and `cicl` live — is suppressed server-side rather
/// than masked, and this app has no field for a sector, a score, a note or a
/// case. The screen says so out loud, because a resident who cannot see any of
/// it should know that is deliberate rather than broken.
///
/// **No household identifier anywhere**, including in the route. A registry
/// number is not useful to a resident and its only effect on screen is to invite
/// someone to pass it around.
class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  bool _started = false;
  bool _loading = false;
  HouseholdSummary? _summary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final dependencies = AppDependencies.of(context);

    // The read is the disclosure, so the read is gated — not the widget that
    // would have drawn it. Household data is the most sensitive collection a
    // resident can reach, and it must never be fetched speculatively.
    if (!CapabilityService.canOpen(
      session: dependencies.session.state,
      capability: ResidentCapability.viewHouseholdSummary,
    )) {
      return;
    }

    setState(() => _loading = true);

    final result = await dependencies.householdRepository.loadOwnHousehold();
    if (!mounted) return;
    setState(() {
      _loading = false;
      // A failure and an absent record land in the same place: the record is
      // not readable here, and the municipal hall is the answer either way. The
      // server's own message is operator-facing and is never rendered.
      _summary = result.valueOrNull;
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(title: const Text('Household and family')),
      body: SafeArea(
        child: CapabilityGate(
          capability: ResidentCapability.viewHouseholdSummary,
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(Spacing.lg),
              children: <Widget>[
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: Spacing.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (summary == null) ...<Widget>[
                  const _Unavailable(),
                ] else ...<Widget>[
                  _HouseholdSection(summary: summary),
                  const SizedBox(height: Spacing.xl),
                  _FamilySection(summary: summary),
                ],
                const SizedBox(height: Spacing.xl),
                const _WhatIsNotShown(),
                const SizedBox(height: Spacing.xl),
                _CorrectionEntry(hasRecord: summary != null),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Where the LGU believes this home is, and how large it is.
class _HouseholdSection extends StatelessWidget {
  const _HouseholdSection({required this.summary});

  final HouseholdSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text('Your household', style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: Spacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              if (summary.label != null)
                _Row(label: 'Household', value: summary.label!),
              _Row(label: 'Barangay', value: summary.barangay),
              _Row(label: 'Street address', value: summary.streetAddress),
              _Row(
                label: 'People recorded here',
                // An aggregate, and the only thing shown about the others. It
                // lets a resident notice the office is serving the wrong number
                // of people while naming nobody.
                value: summary.memberCount == null
                    ? null
                    : '${summary.memberCount}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The resident's own place in the household.
class _FamilySection extends StatelessWidget {
  const _FamilySection({required this.summary});

  final HouseholdSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text('Your family record', style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: Spacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.person_outline,
                    color: theme.colorScheme.primary,
                    size: IconSizes.md,
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      householdRoleLabel(context, summary.role),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                switch (summary.role) {
                  HouseholdRole.head =>
                    'Taytay LGU records you as the person who answers for this '
                        'household. Some services are applied for once for the '
                        'whole household, and the office will speak to you '
                        'about those.',
                  HouseholdRole.member =>
                    'Taytay LGU records you as part of this household. You '
                        'apply for services in your own name; some are counted '
                        'once per household.',
                },
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Says out loud what this screen will not show, so its absence reads as a
/// decision rather than as a fault.
class _WhatIsNotShown extends StatelessWidget {
  const _WhatIsNotShown();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              'Why you cannot see the other people here',
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'The details of everyone else in your household belong to them, not '
            'to your account — so this app does not show their names, their '
            'situation or anything they have applied for. Taytay LGU staff can '
            'go through the household record with you in person.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The record is not readable in this app yet.
class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    return AppBanner(
      tone: BannerTone.info,
      title: 'Not available in this app yet',
      message:
          'Taytay LGU has not switched on household records here. Your '
          'household record still exists at the municipal hall, and staff can '
          'go through it with you.',
      action: AppButton(
        label: 'Report an error',
        variant: AppButtonVariant.secondary,
        fullWidth: false,
        onPressed: () =>
            context.goNamed(AppRoute.householdCorrection.routeName),
      ),
    );
  }
}

/// Entry point to the correction flow.
class _CorrectionEntry extends StatelessWidget {
  const _CorrectionEntry({required this.hasRecord});

  final bool hasRecord;

  @override
  Widget build(BuildContext context) {
    if (!hasRecord) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'Is something wrong?',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Tell Taytay LGU what looks wrong and they will check the record. '
          'Nothing changes until staff review it.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: 'Report an error',
            variant: AppButtonVariant.secondary,
            fullWidth: false,
            onPressed: () =>
                context.goNamed(AppRoute.householdCorrection.routeName),
          ),
        ),
      ],
    );
  }
}

/// One labelled row. Absent values say which kind of absent they are.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final known = value != null && value!.isNotEmpty;

    return ListTile(
      title: Text(label),
      subtitle: Text(
        // Never a blank or a dash: an empty row on a government record reads as
        // data loss, and a resident cannot tell it from a screen that failed.
        known ? value! : 'Not on file',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: known
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
          fontStyle: known ? null : FontStyle.italic,
        ),
      ),
    );
  }
}
