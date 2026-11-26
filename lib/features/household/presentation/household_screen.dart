import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/button_styles.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/live/live_message.dart';
import '../../../core/live/live_refresh.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/resident_capability.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/network_status_views.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_states.dart';
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

class _HouseholdScreenState extends State<HouseholdScreen>
    with LiveRefresh<HouseholdScreen> {
  bool _started = false;
  bool _loading = false;
  HouseholdSummary? _summary;

  /// `GET /households/current` answered 404: the account is in no household.
  bool _none = false;

  /// Any other failure of that read.
  AppFailure? _failure;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
    // A member added, removed or changed by the household or the office
    // shows without a pull (D-218, D-221).
    listenLive(AppDependencies.of(context).live, const <String>{
      LiveTopics.households,
    }, () => unawaited(_load(quiet: true)));
  }

  /// [quiet] is a re-read for a change (D-218): no loading state, and only a
  /// household read back replaces the one on screen; anything else keeps it
  /// and says nothing.
  Future<void> _load({bool quiet = false}) async {
    if (quiet && (_loading || _summary == null)) return;
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

    if (quiet) {
      final result = await dependencies.householdRepository.loadOwnHousehold();
      if (!mounted || _loading) return;
      if (result case Ok(:final value)) setState(() => _summary = value);
      return;
    }

    setState(() {
      _loading = true;
      _failure = null;
    });

    final result = await dependencies.householdRepository.loadOwnHousehold();
    if (!mounted) return;
    setState(() {
      _loading = false;
      // A 404 is an answer, not a fault: this account has not set up or
      // joined a household. Anything else is a failed read, said with Try
      // again. The server's own message is operator-facing and is never
      // rendered.
      _summary = result.valueOrNull;
      _none = result.failureOrNull is NotFoundFailure;
      _failure = _none ? null : result.failureOrNull;
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BlueHeader(title: strings.hhTitle, showBack: true),
          const OfflineBanner(),
          Expanded(
            child: CapabilityGate(
              capability: ResidentCapability.viewHouseholdSummary,
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.lg,
                    Spacing.lg,
                    Spacing.xl + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: <Widget>[
                    if (_loading)
                      LoadingSkeleton(
                        count: 4,
                        semanticLabel: strings.hhLoading,
                      )
                    else if (summary == null) ...<Widget>[
                      // `GET /households/current` is served: a failure other
                      // than a 404 is said as itself, with Try again, never
                      // as records the LGU has "not switched on"
                      // (DESIGN_SYSTEM.md §5).
                      if (_none)
                        const _NoHousehold()
                      else
                        FailureView(
                          failure: _failure ?? const UnexpectedFailure(),
                          environment: AppDependencies.of(
                            context,
                          ).config.environment,
                          onRetry: _load,
                        ),
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
        ],
      ),
    );
  }
}

/// Where the LGU believes this home is, and how large it is (Account.dc
/// list rows: the label over the value, no chevron — nothing here is a link).
class _HouseholdSection extends StatelessWidget {
  const _HouseholdSection({required this.summary});

  final HouseholdSummary summary;

  @override
  Widget build(BuildContext context) {
    final String? label = summary.label;
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsSectionTitle(strings.hhSectionHousehold),
        SettingsList(
          children: <Widget>[
            if (label != null)
              _Row(
                icon: TaytayIcons.house,
                label: strings.hhRowHousehold,
                value: label,
              ),
            _Row(
              icon: TaytayIcons.landmark,
              label: strings.profileFieldBarangay,
              value: summary.barangay,
            ),
            _Row(
              icon: TaytayIcons.mapPin,
              label: strings.profileFieldStreetAddress,
              value: summary.streetAddress,
            ),
            _Row(
              icon: TaytayIcons.users,
              label: strings.hhRowPeople,
              // An aggregate, and the only thing shown about the others. It
              // lets a resident notice the office is serving the wrong number
              // of people while naming nobody.
              value: summary.memberCount == null
                  ? null
                  : '${summary.memberCount}',
            ),
          ],
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
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsSectionTitle(strings.hhSectionFamily),
        SoftCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SettingsIcon(icon: TaytayIcons.user),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      householdRoleLabel(context, summary.role),
                      style: AppTypography.listTitle.copyWith(
                        color: BrandColors.ink,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      switch (summary.role) {
                        HouseholdRole.head => strings.hhRoleHeadBody,
                        HouseholdRole.member => strings.hhRoleMemberBody,
                      },
                      style: AppTypography.bodyStyle.copyWith(
                        color: BrandColors.text,
                      ),
                    ),
                  ],
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
    final strings = AppStrings.of(context);
    return SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SettingsIcon(icon: TaytayIcons.shield, tone: SettingsTone.gold),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    strings.hhHiddenTitle,
                    style: AppTypography.listTitle.copyWith(
                      color: BrandColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  strings.hhHiddenBody,
                  style: AppTypography.bodyStyle.copyWith(
                    color: BrandColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The server answered that this account belongs to no household. The app
/// cannot create one or answer an invitation, and says so.
class _NoHousehold extends StatelessWidget {
  const _NoHousehold();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return EmptyState(
      title: strings.hhNoneTitle,
      message: strings.hhNoneBody,
      boxed: true,
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
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsSectionTitle(strings.hhCorrectionHeading),
        Text(
          strings.hhCorrectionLead,
          style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
        ),
        const SizedBox(height: Spacing.md),
        FilledButton(
          style: TaytayButtonStyles.soft(),
          onPressed: () =>
              context.goNamed(AppRoute.householdCorrection.routeName),
          child: Text(strings.hhReportError),
        ),
      ],
    );
  }
}

/// One labelled row. Absent values say which kind of absent they are.
class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final String? value = this.value;
    final bool known = value != null && value.isNotEmpty;

    return SettingsRow(
      icon: icon,
      title: label,
      // Never a blank or a dash: an empty row on a government record reads as
      // data loss, and a resident cannot tell it from a screen that failed.
      detail: known ? value : AppStrings.of(context).hhNotOnFile,
      detailStyle: AppTypography.bodyStyle.copyWith(
        color: known ? BrandColors.ink : BrandColors.muted,
        fontStyle: known ? null : FontStyle.italic,
      ),
      showChevron: false,
    );
  }
}
