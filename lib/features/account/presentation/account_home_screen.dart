import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../profile/domain/profile_fields.dart';
import '../../profile/domain/resident_profile_detail.dart';
import '../../profile/domain/verification_decision.dart';
import '../domain/profile_completion.dart';
import 'account_canvas.dart';

/// My Account.
///
/// A guest and an unverified resident keep the account centre: it is the
/// sign-in prompt and the verification card, and it fetches nothing for a
/// guest. A verified resident sees the 08-01 home. The name and the tier come
/// from the server. The fill ratio and the decision date are computed from
/// the profile the screen just loaded.
class AccountHomeScreen extends StatefulWidget {
  const AccountHomeScreen({super.key});

  @override
  State<AccountHomeScreen> createState() => _AccountHomeScreenState();
}

class _AccountHomeScreenState extends State<AccountHomeScreen> {
  bool _started = false;
  bool _loading = false;
  bool _failed = false;
  ResidentProfileDetail? _detail;
  String _messagesLine = 'Office replies';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final dependencies = AppDependencies.of(context);
    final AccessDecision decision = AccessPolicy.evaluate(
      session: dependencies.session.state,
      requirement: AccessRequirement.verified,
    );
    if (decision is! AccessAllowed) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final result = await dependencies.residentProfileRepository.loadOwnDetail();
    if (!mounted) return;
    final threads = await dependencies.officeMessagingRepository.listThreads();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Ok(:final value):
          _detail = value;
          _failed = false;
        case Err():
          _detail = null;
          _failed = true;
      }
      if (threads case Ok(:final value) when value.isNotEmpty) {
        final unread = value.where((thread) => thread.unreadCount > 0).length;
        final office = value.first.officeName;
        _messagesLine = unread > 0
            ? '$unread new ${unread == 1 ? 'reply' : 'replies'} from $office'
            : 'No new replies';
      }
    });
  }

  Future<void> _signOut() async {
    final dependencies = AppDependencies.of(context);
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Sign out of this device?',
      message:
          'You will need a new one-time code to sign in again. You can still '
          'browse Taytay services, offices and announcements as a guest.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    await dependencies.authRepository.signOut();
    await dependencies.session.signOut();
    if (!mounted) return;
    await AppHaptics.fire(
      HapticIntent.warning,
      suppressed: Motion.reduced(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    return AnimatedBuilder(
      animation: dependencies.session,
      builder: (context, _) {
        final session = dependencies.session.state;
        final AccessDecision decision = AccessPolicy.evaluate(
          session: session,
          requirement: AccessRequirement.verified,
        );
        if (decision is! AccessAllowed) return const SizedBox.shrink();
        if (_failed) return const _RecordUnavailable();
        if (_loading && _detail == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final detail = _detail;
        final String name =
            detail?.valueOf(ResidentProfileField.fullName) ??
            session.residentOrNull?.displayName ??
            'Verified resident';
        final String? barangay = detail?.valueOf(ResidentProfileField.barangay);
        final String location = barangay == null || barangay.isEmpty
            ? 'Taytay, Rizal'
            : 'Brgy. $barangay, Taytay, Rizal';
        return AccountCanvas(
          frame: AccountFrame.home,
          name: name,
          initials: _initials(name),
          location: location,
          verifiedLabel: 'Verified',
          sample: false,
          menu: _menu(context),
          onBell: () => context.goNamed(AppRoute.notifications.routeName),
          onSignOut: _signOut,
        );
      },
    );
  }

  List<AccountMenuRow> _menu(BuildContext context) {
    final String? decided = manilaDecisionDate(_detail?.verificationDecidedAt);
    return <AccountMenuRow>[
      AccountMenuRow(
        title: 'Resident Profile',
        subtitle: _detail == null
            ? 'Name, contact, barangay'
            : '${profileCompletionPercent(_detail!)}% complete',
        icon: TaytayIcons.user,
        tile: BrandColors.chipBlueBg,
        iconColor: BrandColors.taytayBlue,
        onTap: () => context.goNamed(AppRoute.profileEdit.routeName),
      ),
      AccountMenuRow(
        title: 'Messages',
        subtitle: _messagesLine,
        icon: TaytayIcons.messageSquare,
        tile: BrandColors.chipGreenBg,
        iconColor: BrandColors.success,
        onTap: () => context.goNamed(AppRoute.messagesInbox.routeName),
      ),
      AccountMenuRow(
        title: 'Verification status',
        subtitle: decided == null ? 'Verified' : 'Verified · $decided',
        icon: TaytayIcons.badgeCheck,
        tile: BrandColors.chipAmberBg,
        iconColor: BrandColors.warning,
        onTap: () => context.goNamed(AppRoute.verification.routeName),
      ),
      AccountMenuRow(
        title: 'Settings',
        subtitle: 'Notifications, language',
        icon: TaytayIcons.settings,
        tile: BrandColors.chipBlueBg,
        iconColor: BrandColors.taytayBlue,
        onTap: () => context.goNamed(AppRoute.profileSettings.routeName),
      ),
      AccountMenuRow(
        title: 'Privacy & data',
        subtitle: 'Privacy Notice, your data rights',
        icon: TaytayIcons.shield,
        tile: BrandColors.chipGreenBg,
        iconColor: BrandColors.success,
        onTap: () => context.goNamed(AppRoute.profileNotice.routeName),
      ),
      AccountMenuRow(
        title: 'Photo credits & about',
        subtitle: 'Licences, app version',
        icon: TaytayIcons.image,
        tile: BrandColors.chipAmberBg,
        iconColor: BrandColors.warning,
        onTap: () => context.goNamed(AppRoute.photoCredits.routeName),
      ),
    ];
  }
}

/// Shown when `GET /me` fails. The words are the same ones the resident
/// record uses, so a missing record is not described as the resident's fault.
class _RecordUnavailable extends StatelessWidget {
  const _RecordUnavailable();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const Align(alignment: Alignment.centerLeft, child: _VerifiedBadge()),
        const SizedBox(height: 16),
        Text(
          'Not available in this app yet',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Taytay LGU has not switched on your record in this app yet. '
          'The municipal hall can tell you what is on file.',
        ),
      ],
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.verified_outlined,
          color: theme.colorScheme.onSecondaryContainer,
        ),
        const SizedBox(width: 8),
        const Text('Verified by Taytay LGU'),
      ],
    );
  }
}

String _initials(String name) {
  final List<String> parts = name
      .split(RegExp(r'\s+'))
      .where((String part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return '•';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
