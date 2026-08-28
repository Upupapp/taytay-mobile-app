import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../core/session/resident_capability.dart';
import '../../../core/session/session_state.dart';
import '../../../shared/widgets/access_gate_sheet.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../domain/profile_fields.dart';
import '../domain/resident_profile_detail.dart';
import 'profile_field_list.dart';

/// Profile — the resident's account centre.
///
/// ---
///
/// **Two kinds of fact about a person, kept visibly apart** (acceptance 1). The
/// screen has one section a resident owns and can change, and one Taytay LGU
/// owns and confirmed. They have different headings, different explanations and
/// different affordances: a chevron that opens an editor, or a lock that opens
/// the correction path. A resident should never have to discover the difference
/// by being refused.
///
/// **Nothing canonical can be overwritten from here** (acceptance 2). There is
/// no editor for an LGU-verified field, and there could not be: the only write
/// method takes a `ContactDetailsUpdate`, which has no property for one.
///
/// **Own record only** (acceptance 3). Every read is `/me/`-scoped and takes no
/// identifier, so no arrangement of this screen can fetch another resident.
/// Personal reads are additionally gated on `CapabilityService`, so a guest
/// issues none at all.
///
/// **Public for a guest, by design.** Profile is one of TAB 10's five fixed
/// destinations, so it must open for someone with no account — and for them it
/// is the explanation of what an account is for, not a locked door.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _started = false;
  bool _loading = false;
  AppFailure? _failure;
  ResidentProfileDetail? _detail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final dependencies = AppDependencies.of(context);

    // The read is the disclosure, so the read is what is gated — not the
    // widget that would have drawn it. A guest fetches nothing.
    if (!CapabilityService.canOpen(
      session: dependencies.session.state,
      capability: ResidentCapability.manageAccount,
    )) {
      return;
    }

    setState(() {
      _loading = true;
      _failure = null;
    });

    final result = await dependencies.residentProfileRepository.loadOwnDetail();
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold(
        onOk: (detail) => _detail = detail,
        onErr: (failure) => _failure = failure,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);

    return AnimatedBuilder(
      animation: dependencies.session,
      builder: (context, _) {
        final session = dependencies.session.state;

        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(Spacing.lg),
                children: <Widget>[
                  _IdentityCard(session: session),
                  const SizedBox(height: Spacing.xl),
                  // The same question the read asks, from the same service, so
                  // a section can never be shown that its own fetch refused.
                  if (CapabilityService.canOpen(
                    session: session,
                    capability: ResidentCapability.manageAccount,
                  )) ...<Widget>[
                    ProfileFieldList(
                      ownership: FieldOwnership.accountOwned,
                      detail: _detail,
                      loading: _loading,
                      unavailable: _failure != null,
                      onEdit: () =>
                          context.goNamed(AppRoute.profileContact.routeName),
                    ),
                    const SizedBox(height: Spacing.xl),
                    ProfileFieldList(
                      ownership: FieldOwnership.lguVerified,
                      detail: _detail,
                      loading: _loading,
                      unavailable: _failure != null,
                    ),
                    const SizedBox(height: Spacing.xl),
                  ],
                  _ShortcutSection(session: session),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Who the resident is to this app, and the verification badge.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.session});

  final SessionState session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // First name only. The session holds a greeting name, an opaque account id
    // and a level — nothing else — so there is nothing more here to show even
    // by mistake, and the account id is never rendered.
    final name = session.residentOrNull?.displayName;

    final (
      String title,
      String body,
      String? action,
      AppRoute? route,
    ) = switch (session.accessLevel) {
      AccessLevel.guest => (
        'You are browsing as a guest',
        'Sign in with your mobile number to hold your digital ID and to '
            'track anything you apply for. Browsing stays open either way.',
        'Sign in',
        AppRoute.signIn,
      ),
      AccessLevel.unverified => (
        name ?? 'Your account',
        'Taytay LGU has not confirmed your identity yet. Verifying unlocks '
            'your digital ID and service applications.',
        'Verify my identity',
        AppRoute.verification,
      ),
      AccessLevel.verified => (
        name ?? 'Verified resident',
        'Taytay LGU has confirmed your identity.',
        null,
        null,
      ),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: Spacing.sm),
          const VerificationBadge(),
          const SizedBox(height: Spacing.md),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null && route != null) ...<Widget>[
            const SizedBox(height: Spacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: action,
                fullWidth: false,
                onPressed: () => context.goNamed(route.routeName),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Everything else the account centre links to.
class _ShortcutSection extends StatelessWidget {
  const _ShortcutSection({required this.session});

  final SessionState session;

  /// Each entry names a capability, so the tile asks the central service what to
  /// render rather than comparing access levels itself.
  ///
  /// The **household shortcut is deliberately absent**: TAB 10 established that
  /// the only household row in the committed contract is a staff route, so the
  /// capability is declared unavailable and there is nowhere for a link to go.
  /// **Notification preferences are absent** for the same kind of reason — §11
  /// of the matrix has an inbox, mark-read and device registration, and no
  /// preferences row at all.
  static const List<(ResidentCapability, ResidentIntentKind?, IconData)>
  _entries = <(ResidentCapability, ResidentIntentKind?, IconData)>[
    (
      ResidentCapability.completeVerification,
      null,
      Icons.verified_user_outlined,
    ),
    (
      ResidentCapability.holdDigitalId,
      ResidentIntentKind.viewDigitalId,
      Icons.badge_outlined,
    ),
    (
      ResidentCapability.trackAssistanceRequests,
      null,
      Icons.assignment_outlined,
    ),
    (
      ResidentCapability.viewHouseholdSummary,
      null,
      Icons.family_restroom_outlined,
    ),
    (
      ResidentCapability.manageAccount,
      ResidentIntentKind.manageNotifications,
      Icons.manage_accounts_outlined,
    ),
    (ResidentCapability.manageSecurity, null, Icons.shield_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text('Your account', style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: Spacing.sm),
        for (final entry in _entries)
          _CapabilityTile(
            capability: entry.$1,
            intent: entry.$2,
            icon: entry.$3,
          ),
        const Divider(height: Spacing.xxl),
        Semantics(
          header: true,
          child: Text('Privacy and help', style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: Spacing.sm),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.privacy_tip_outlined,
            color: theme.colorScheme.primary,
          ),
          title: const Text('Privacy and your data'),
          subtitle: const Text(
            'What Taytay LGU holds, why, and your rights over it.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.goNamed(AppRoute.profilePrivacy.routeName),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.help_outline, color: theme.colorScheme.primary),
          title: const Text('Help and support'),
          subtitle: const Text('Trouble signing in, and where to get help.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.goNamed(AppRoute.signInHelp.routeName),
        ),
      ],
    );
  }
}

/// One shortcut, rendered from the central verdict rather than a local check.
class _CapabilityTile extends StatelessWidget {
  const _CapabilityTile({
    required this.capability,
    required this.icon,
    this.intent,
  });

  final ResidentCapability capability;
  final IconData icon;
  final ResidentIntentKind? intent;

  Future<void> _open(BuildContext context, CapabilityVerdict verdict) async {
    final route = capability.route;
    final session = AppDependencies.of(context).session.state;

    // Access decides whether it opens; availability only decides what the
    // screen then says. See `CapabilityService.canOpen`.
    if (route != null &&
        CapabilityService.canOpen(session: session, capability: capability)) {
      context.goNamed(route.routeName);
      return;
    }

    final held = intent;
    if (held != null) {
      await AccessGateSheet.showForCapability(
        context: context,
        verdict: verdict,
        intent: held,
      );
      return;
    }

    // Guaranteed non-null for every refusal — TAB 10, acceptance 2.
    final recovery = CapabilityService.recoveryRoute(verdict);
    if (recovery != null && context.mounted) {
      context.goNamed(recovery.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    final verdict = CapabilityService.evaluate(
      session: dependencies.session.state,
      capability: capability,
    );
    final requirement = capabilityRequirementLabel(context, verdict);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(capability.label),
      // States the requirement instead of hiding the row. A resident can see
      // what the app offers and what it would take to reach it.
      subtitle: requirement == null ? null : Text(requirement),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _open(context, verdict),
    );
  }
}
