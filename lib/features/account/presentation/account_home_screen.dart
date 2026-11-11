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
import '../../../shared/widgets/error_state.dart';
import '../../profile/domain/profile_fields.dart';
import '../../profile/domain/resident_profile_detail.dart';
import '../../profile/domain/verification_decision.dart';
import '../domain/profile_completion.dart';
import 'account_canvas.dart';
import 'account_copy.dart';

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
  int _unread = 0;

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
      if (threads case Ok(:final value) when value.items.isNotEmpty) {
        final int unread = value.items.fold<int>(
          0,
          (int sum, thread) => sum + thread.unreadCount,
        );
        _unread = unread;
        final office = value.items.first.officeName;
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
      title: AccountCopy.signOutTitle,
      message: AccountCopy.signOut,
      confirmLabel: AccountCopy.signOutAction,
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
        if (_failed) {
          return _RecordUnavailable(onRetry: _load);
        }
        if (_loading && _detail == null) {
          return AccountCanvas(
            frame: AccountFrame.home,
            loading: true,
            onBell: () => context.goNamed(AppRoute.notifications.routeName),
          );
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
          menu: _menu(context),
          onBell: () => context.goNamed(AppRoute.notifications.routeName),
          onSignOut: _signOut,
          onDigitalId: () => context.pushNamed(AppRoute.digitalId.routeName),
        );
      },
    );
  }

  List<AccountMenuRow> _menu(BuildContext context) {
    final ResidentProfileDetail? detail = _detail;
    final String? decided = manilaDecisionDate(_detail?.verificationDecidedAt);
    return <AccountMenuRow>[
      AccountMenuRow(
        title: 'Resident Profile',
        subtitle: detail == null
            ? 'Name, contact, barangay'
            : '${profileCompletionPercent(detail)}% complete',
        progress: detail == null
            ? null
            : profileCompletionPercent(detail) / 100,
        icon: TaytayIcons.idCard,
        tile: BrandColors.blue50,
        iconColor: BrandColors.blue,
        onTap: () => context.goNamed(AppRoute.profileEdit.routeName),
      ),
      AccountMenuRow(
        title: 'Messages',
        subtitle: _messagesLine,
        icon: TaytayIcons.messageSquare,
        tile: BrandColors.blue50,
        iconColor: BrandColors.blue,
        badge: _unread > 0 ? '$_unread' : null,
        onTap: () => context.goNamed(AppRoute.messagesInbox.routeName),
      ),
      AccountMenuRow(
        title: 'Verification status',
        subtitle: decided == null ? 'Verified' : 'Verified · $decided',
        icon: TaytayIcons.shield,
        tile: BrandColors.green50,
        iconColor: BrandColors.green,
        onTap: () => context.goNamed(AppRoute.verification.routeName),
      ),
      // `/documents` and `/household` are top-level routes, so they are
      // pushed: back returns here rather than to Home.
      AccountMenuRow(
        title: 'Request documents',
        subtitle: 'Certificates and copies from offices',
        icon: TaytayIcons.fileText,
        tile: BrandColors.blue50,
        iconColor: BrandColors.blue,
        onTap: () => context.pushNamed(AppRoute.issuanceCatalogue.routeName),
      ),
      AccountMenuRow(
        title: 'Household',
        subtitle: 'Address and your place in it',
        icon: TaytayIcons.house,
        tile: BrandColors.blue50,
        iconColor: BrandColors.blue,
        onTap: () => context.pushNamed(AppRoute.household.routeName),
      ),
      AccountMenuRow(
        title: 'Settings',
        subtitle: 'Notifications, language',
        icon: TaytayIcons.settings,
        tile: BrandColors.blue50,
        iconColor: BrandColors.blue,
        onTap: () => context.goNamed(AppRoute.profileSettings.routeName),
      ),
      AccountMenuRow(
        title: 'Privacy & data',
        subtitle: 'Privacy Notice, your data rights',
        icon: TaytayIcons.lock,
        tile: BrandColors.blue50,
        iconColor: BrandColors.blue,
        onTap: () => context.goNamed(AppRoute.profileNotice.routeName),
      ),
      AccountMenuRow(
        title: 'Photo credits & about',
        subtitle: 'Licences, app version',
        icon: TaytayIcons.image,
        tile: BrandColors.blue50,
        iconColor: BrandColors.blue,
        onTap: () => context.goNamed(AppRoute.photoCredits.routeName),
      ),
    ];
  }
}

/// Shown when `GET /me` fails. The words are the same ones the resident
/// record uses, so a missing record is not described as the resident's fault.
class _RecordUnavailable extends StatelessWidget {
  const _RecordUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: BrandColors.background,
      child: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: <Widget>[
          const SizedBox(height: Spacing.xl),
          ErrorState(
            title: 'Not available in this app yet',
            message:
                'Taytay LGU has not switched on your record in this app yet. '
                'The municipal hall can tell you what is on file.',
            icon: TaytayIcons.badgeCheck,
            onRetry: onRetry,
            boxed: true,
            details: const <Widget>[Text('Verified by Taytay LGU')],
          ),
        ],
      ),
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
