import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/l10n/profile_copy.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../core/session/session_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/error_state.dart';
import '../../profile/domain/profile_fields.dart';
import '../../profile/domain/resident_profile_detail.dart';
import '../../registration/domain/registration_domain.dart';
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
  AppFailure? _failure;
  ResidentProfileDetail? _detail;

  /// The office of the newest thread. Null until a thread was read: the
  /// Messages row then says "Office replies".
  String? _latestOffice;
  int _unread = 0;

  /// `GET /barangays`, to name the barangay `GET /me` gives as an id. Null
  /// until read, and when the read failed.
  List<Barangay>? _barangays;

  SessionController? _session;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _session = AppDependencies.of(context).session..addListener(_onSession);
    _load();
  }

  /// The tier can turn verified while this tab is open (an in-person check
  /// at the counter, read from `GET /me`): the verified home then reads its
  /// record, which it skipped while the account was not verified.
  void _onSession() {
    if (!mounted || _loading || _detail != null || _failed) return;
    _load();
  }

  @override
  void dispose() {
    _session?.removeListener(_onSession);
    super.dispose();
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
    final List<Barangay>? known = _barangays;
    final Result<List<Barangay>> barangays = known != null
        ? Ok<List<Barangay>>(known)
        : await dependencies.barangayDirectory.listBarangays();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (barangays case Ok(:final value) when value.isNotEmpty) {
        _barangays = value;
      }
      switch (result) {
        case Ok(:final value):
          _detail = value;
          _failed = false;
        case Err(:final failure):
          _detail = null;
          _failed = true;
          _failure = failure;
      }
      if (threads case Ok(:final value) when value.items.isNotEmpty) {
        final int unread = value.items.fold<int>(
          0,
          (int sum, thread) => sum + thread.unreadCount,
        );
        _unread = unread;
        _latestOffice = value.items.first.officeName;
      }
    });
  }

  Future<void> _signOut() async {
    final dependencies = AppDependencies.of(context);
    final AppStrings strings = AppStrings.of(context);
    final confirmed = await AppDialog.confirm(
      context: context,
      title: strings.acctSignOutTitle,
      message: strings.acctSignOutBody,
      confirmLabel: strings.actionSignOut,
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
          return _RecordUnavailable(
            failure: _failure ?? const UnexpectedFailure(),
            onRetry: _load,
          );
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
            AppStrings.of(context).acctVerifiedResident;
        // `GET /me` gives `barangay_id`; the name is the directory's. An id
        // the list does not name, or a list that could not be read, says the
        // town alone rather than a UUID (D-228).
        final Barangay? barangay = barangayFor(
          detail?.valueOf(ResidentProfileField.barangay),
          _barangays ?? const <Barangay>[],
        );
        final String location = barangay == null
            ? 'Taytay, Rizal'
            : 'Brgy. ${barangay.name}, Taytay, Rizal';
        return AccountCanvas(
          frame: AccountFrame.home,
          name: name,
          initials: _initials(name),
          location: location,
          verifiedLabel: AppStrings.of(context).verifyStageVerifiedLabel,
          menu: _menu(context),
          onBell: () => context.goNamed(AppRoute.notifications.routeName),
          onSignOut: _signOut,
          onDigitalId: () => context.pushNamed(AppRoute.digitalId.routeName),
        );
      },
    );
  }

  List<AccountMenuRow> _menu(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ResidentProfileDetail? detail = _detail;
    final String? decided = verificationDecisionDate(
      context,
      _detail?.verificationDecidedAt,
    );
    final String? office = _latestOffice;
    return <AccountMenuRow>[
      AccountMenuRow(
        title: strings.acctMenuProfile,
        subtitle: detail == null
            ? strings.acctMenuProfileDetail
            : strings.acctMenuProfileComplete(profileCompletionPercent(detail)),
        progress: detail == null
            ? null
            : profileCompletionPercent(detail) / 100,
        icon: TaytayIcons.idCard,
        tile: BrandColors.blue50,
        iconColor: BrandColors.blue,
        onTap: () => context.goNamed(AppRoute.profileEdit.routeName),
      ),
      // `/sectors` is a top-level route, pushed like documents and household
      // so back returns here (D-215).
      AccountMenuRow(
        title: strings.acctMenuSectors,
        // A general list, worded so it is not read as her own sectors
        // (D-231); the page itself shows which are on her record.
        subtitle: strings.accountSectorsSubtitle,
        icon: TaytayIcons.heart,
        tile: BrandColors.gold50,
        iconColor: BrandColors.goldInk,
        onTap: () => context.pushNamed(AppRoute.sectors.routeName),
      ),
      AccountMenuRow(
        title: strings.acctMessages,
        subtitle: office == null
            ? strings.notifSwitchOfficeReplies
            : _unread > 0
            ? strings.acctMessagesUnread(_unread, office)
            : strings.acctMessagesNoneUnread,
        icon: TaytayIcons.messageSquare,
        tile: BrandColors.blue50,
        iconColor: BrandColors.blue,
        badge: _unread > 0 ? '$_unread' : null,
        onTap: () => context.goNamed(AppRoute.messagesInbox.routeName),
      ),
      AccountMenuRow(
        title: strings.acctMenuVerification,
        subtitle: decided == null
            ? strings.verifyStageVerifiedLabel
            : strings.acctVerifiedOn(decided),
        icon: TaytayIcons.shield,
        tile: BrandColors.green50,
        iconColor: BrandColors.green,
        onTap: () => context.goNamed(AppRoute.verification.routeName),
      ),
      // `/my-requests`, `/documents` and `/household` are top-level routes,
      // so they are pushed: back returns here rather than to Home.
      AccountMenuRow(
        title: strings.myRequestsTitle,
        subtitle: strings.myRequestsSubtitle,
        icon: TaytayIcons.handHelping,
        tile: BrandColors.blue50,
        iconColor: BrandColors.blue,
        onTap: () => context.pushNamed(AppRoute.myRequests.routeName),
      ),
      AccountMenuRow(
        title: strings.acctMenuRequestDocuments,
        subtitle: strings.acctMenuRequestDocumentsDetail,
        icon: TaytayIcons.fileText,
        tile: BrandColors.blue50,
        iconColor: BrandColors.blue,
        onTap: () => context.pushNamed(AppRoute.issuanceCatalogue.routeName),
      ),
      AccountMenuRow(
        title: strings.acctMenuHousehold,
        subtitle: strings.acctMenuHouseholdDetail,
        icon: TaytayIcons.house,
        tile: BrandColors.blue50,
        iconColor: BrandColors.blue,
        onTap: () => context.pushNamed(AppRoute.household.routeName),
      ),
      AccountMenuRow(
        title: strings.acctMenuSettings,
        subtitle: strings.acctMenuSettingsDetail,
        icon: TaytayIcons.settings,
        tile: BrandColors.blue50,
        iconColor: BrandColors.blue,
        onTap: () => context.goNamed(AppRoute.profileSettings.routeName),
      ),
      AccountMenuRow(
        title: strings.acctMenuPrivacy,
        subtitle: strings.acctMenuPrivacyDetail,
        icon: TaytayIcons.lock,
        tile: BrandColors.blue50,
        iconColor: BrandColors.blue,
        onTap: () => context.goNamed(AppRoute.profileNotice.routeName),
      ),
      AccountMenuRow(
        title: strings.acctMenuCredits,
        subtitle: strings.acctMenuCreditsDetail,
        icon: TaytayIcons.image,
        tile: BrandColors.blue50,
        iconColor: BrandColors.blue,
        onTap: () => context.goNamed(AppRoute.photoCredits.routeName),
      ),
    ];
  }
}

/// Shown when `GET /me` fails. `GET /me` is served, so the failure is said in
/// the app's own words for its kind, with Try again when trying again could
/// work, never as a record the LGU has "not switched on" (D-220).
///
/// The tier is the session's, not the failed read's: the page still says the
/// resident is verified, and never asks them to verify again.
class _RecordUnavailable extends StatelessWidget {
  const _RecordUnavailable({required this.failure, required this.onRetry});

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final String? requestId = failure.requestId;
    return ColoredBox(
      color: BrandColors.background,
      child: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: <Widget>[
          const SizedBox(height: Spacing.xl),
          ErrorState(
            title: localisedResidentMessage(context, failure),
            icon: TaytayIcons.badgeCheck,
            offline: failure is NetworkFailure || failure is TimeoutFailure,
            onRetry: failure.affordance == FailureAffordance.retryNow
                ? onRetry
                : null,
            boxed: true,
            details: <Widget>[
              Text(strings.acctVerifiedByLgu),
              if (requestId != null)
                SelectableText(strings.applyFailureReference(requestId)),
            ],
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
