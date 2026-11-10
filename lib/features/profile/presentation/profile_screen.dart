import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../core/session/access_policy.dart';
import '../../../core/session/resident_capability.dart';
import '../../../core/session/session_state.dart';
import '../../../shared/widgets/access_gate_sheet.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/surface_cards.dart';
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
  const ProfileScreen({this.showBack = false, super.key});

  /// True when this screen is not the My Account root. The root has no back
  /// control. The resident record, reached from Edit profile, does.
  final bool showBack;

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

        final bool glass = !widget.showBack;
        final bool personal = CapabilityService.canOpen(
          session: session,
          capability: ResidentCapability.manageAccount,
        );
        final Widget body = Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _IdentityCard(session: session, glass: glass),
              const SizedBox(height: Spacing.xl),
              // The same question the read asks, from the same service, so a
              // section can never be shown that its own fetch refused.
              if (personal) ...<Widget>[
                ProfileFieldList(
                  ownership: FieldOwnership.accountOwned,
                  detail: _detail,
                  loading: _loading,
                  unavailable: _failure != null,
                  glass: glass,
                  onEdit: () =>
                      context.goNamed(AppRoute.profileContact.routeName),
                ),
                const SizedBox(height: Spacing.xl),
                ProfileFieldList(
                  ownership: FieldOwnership.lguVerified,
                  detail: _detail,
                  loading: _loading,
                  unavailable: _failure != null,
                  glass: glass,
                ),
                const SizedBox(height: Spacing.xl),
              ],
              _ShortcutSection(session: session, glass: glass),
              const SizedBox(height: Spacing.xl),
            ],
          ),
        );
        final Widget header = BlueHeader(
          leading: widget.showBack ? null : const HeaderSeal(),
          showBack: widget.showBack,
          title: widget.showBack ? 'Profile' : 'My Account',
          subtitle: 'Bayan ng Taytay · Rizal',
          overlap: glass,
        );
        final Widget list = RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              header,
              if (glass)
                GlassOverlap(child: body)
              else ...<Widget>[const SizedBox(height: Spacing.lg), body],
            ],
          ),
        );
        return Scaffold(
          backgroundColor: glass
              ? BrandColors.glassBackground
              : BrandColors.background,
          body: KeyedSubtree(
            key: profileScreenKey,
            child: glass ? GlassBackground(child: list) : list,
          ),
        );
      },
    );
  }
}

/// Marks the Profile body, so a test can find this screen's own list among
/// the shell's live branches. It stays in the tree however far the list
/// scrolls, unlike the header, which scrolls away.
const Key profileScreenKey = Key('profile-screen');

/// Who the resident is to this app, and the verification badge.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.session, required this.glass});

  final SessionState session;
  final bool glass;

  @override
  Widget build(BuildContext context) {
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
        'Sign in with your mobile number to hold your digital ID. '
            'Browsing stays open either way. Programme pages are information '
            'only.',
        'Sign in',
        AppRoute.signIn,
      ),
      AccessLevel.unverified => (
        name ?? 'Your account',
        'Taytay LGU has not confirmed your identity yet. Verifying unlocks '
            'your digital ID. Programme pages are information only.',
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

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            title,
            style: AppTypography.pageTitle.copyWith(color: BrandColors.ink),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        const VerificationBadge(),
        const SizedBox(height: Spacing.md),
        Text(
          body,
          style: AppTypography.bodyStyle.copyWith(color: BrandColors.muted),
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
    );
    return glass ? GlassCard(child: content) : SoftCard(child: content);
  }
}

/// Everything else the account centre links to.
class _ShortcutSection extends StatelessWidget {
  const _ShortcutSection({required this.session, required this.glass});

  final SessionState session;
  final bool glass;

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
    (ResidentCapability.completeVerification, null, TaytayIcons.shieldCheck),
    (
      ResidentCapability.holdDigitalId,
      ResidentIntentKind.viewDigitalId,
      TaytayIcons.idCard,
    ),
    (ResidentCapability.trackAssistanceRequests, null, TaytayIcons.handHelping),
    (ResidentCapability.viewHouseholdSummary, null, TaytayIcons.users),
    (
      ResidentCapability.manageAccount,
      ResidentIntentKind.manageNotifications,
      TaytayIcons.settings,
    ),
    (ResidentCapability.manageSecurity, null, TaytayIcons.shield),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SettingsSectionTitle('Your account'),
        SettingsList(
          glass: glass,
          children: <Widget>[
            for (final entry in _entries)
              _CapabilityTile(
                capability: entry.$1,
                intent: entry.$2,
                icon: entry.$3,
              ),
            _MessageOfficeTile(session: session),
            _DocumentRequestTile(session: session),
          ],
        ),
        const SizedBox(height: Spacing.xl),
        const SettingsSectionTitle('Privacy and help'),
        SettingsList(
          glass: glass,
          children: <Widget>[
            SettingsRow(
              icon: TaytayIcons.lock,
              title: 'Privacy and your data',
              detail: 'What Taytay LGU holds, why, and your rights over it.',
              onTap: () => context.goNamed(AppRoute.profilePrivacy.routeName),
            ),
            SettingsRow(
              icon: TaytayIcons.info,
              title: 'Help and support',
              detail: 'Trouble signing in, and where to get help.',
              onTap: () => context.goNamed(AppRoute.signInHelp.routeName),
            ),
          ],
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

    return SettingsRow(
      icon: icon,
      title: capabilityLabel(context, capability),
      // States the requirement instead of hiding the row. A resident can see
      // what the app offers and what it would take to reach it.
      detail: requirement,
      onTap: () => _open(context, verdict),
    );
  }
}

/// Document requests. The catalogue is public, so the tile always opens it;
/// the catalogue itself says what it takes to send a request. The subtitle
/// says it first, so nobody taps expecting a form they cannot reach.
class _DocumentRequestTile extends StatelessWidget {
  const _DocumentRequestTile({required this.session});

  final SessionState session;

  @override
  Widget build(BuildContext context) {
    final AccessDecision decision = AccessPolicy.evaluate(
      session: session,
      requirement: AccessRequirement.verified,
    );
    return SettingsRow(
      key: const Key('profile-document-requests'),
      icon: TaytayIcons.fileText,
      title: 'Request documents',
      detail: decision is AccessAllowed
          ? null
          : 'Sending a request needs a verified account',
      onTap: () => context.pushNamed(AppRoute.issuanceCatalogue.routeName),
    );
  }
}

/// Message an office. The same unverified gate as the digital ID.
class _MessageOfficeTile extends StatelessWidget {
  const _MessageOfficeTile({required this.session});

  final SessionState session;

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      icon: TaytayIcons.messageSquare,
      title: 'Message an office',
      onTap: () {
        final decision = AccessPolicy.evaluate(
          session: session,
          requirement: AccessRequirement.verified,
        );
        if (decision is AccessAllowed) {
          context.goNamed(AppRoute.messagesInbox.routeName);
          return;
        }
        AccessGateSheet.show(
          context: context,
          decision: decision,
          intent: ResidentIntentKind.messageOffice,
        );
      },
    );
  }
}
