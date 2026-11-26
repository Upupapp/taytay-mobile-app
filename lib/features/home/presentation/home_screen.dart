import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/paginated.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/links/external_link_service.dart';
import '../../../core/live/live_message.dart';
import '../../../core/live/live_refresh.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../core/session/access_policy.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/session/session_state.dart';
import '../../../shared/widgets/outcome_feedback.dart';
import '../../citizen_api/domain/citizen_contract.dart';
import '../../news/domain/announcement_repository.dart';
import '../../profile/domain/profile_fields.dart';
import '../../profile/domain/resident_profile_detail.dart';
import '../data/home_catalogue.dart';
import '../domain/home_content.dart';
import '../domain/home_greeting.dart';
import 'home_canvas.dart';

/// The status card for an account that is not verified, from the
/// `verification_status` `GET /me` reports (D-228). Null (not read yet, or
/// the read failed) and a word this build does not know say only that the
/// account is not yet verified: the card never guesses that an ID was sent.
HomeStatusKind homeStatusForTier(String? tier) => switch (tier) {
  'unverified' => HomeStatusKind.notSent,
  'pending' => HomeStatusKind.pending,
  'rejected' => HomeStatusKind.rejected,
  'verified' => HomeStatusKind.none,
  _ => HomeStatusKind.unknown,
};

/// Home for a guest, an unverified resident, and a verified resident.
///
/// The canvas is the same. The status card and the avatar change with the
/// session. A guest's bell opens sign-in and this screen does not call a
/// `/me/` route for them. Hotline numbers come from `GET /home`. News titles
/// come from the announcements feed. Hero slides come from the bundled
/// catalogue, with titles and routes from `GET /home` when that feed has
/// banners. A dev mock fills hotlines and news when those calls are empty.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with LiveRefresh<HomeScreen> {
  bool _started = false;
  bool _refreshing = false;
  int _bellCount = 0;
  List<HomeSlide> _slides = const <HomeSlide>[];
  List<HomeNewsItem> _news = const <HomeNewsItem>[];
  HomeHotline? _hotline;

  /// `verification_status` from `GET /me`, and the account it was read for.
  /// Read only for a signed-in account that is not verified (D-228).
  String? _tier;
  String? _tierAccount;
  SessionController? _session;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final AppDependencies dependencies = AppDependencies.of(context);
    _session = dependencies.session..addListener(_onSession);
    _load(initial: true);
    // Banners, news, the hotline and the bell count follow the office
    // without a pull (D-218). The account's verification is heard too, so
    // the status card follows a decision made while Home is open.
    listenLive(dependencies.live, const <String>{
      LiveTopics.home,
      LiveTopics.news,
      LiveTopics.events,
      LiveTopics.notifications,
      LiveTopics.hotlines,
      LiveTopics.account,
      LiveTopics.verification,
    }, () => unawaited(_load(initial: false, quiet: true)));
  }

  @override
  void dispose() {
    _session?.removeListener(_onSession);
    super.dispose();
  }

  /// Signed in and not yet verified, as the one access policy decides it.
  static bool _awaitsVerification(SessionState state) =>
      AccessPolicy.evaluate(
            session: state,
            requirement: AccessRequirement.verified,
          )
          is AccessNeedsVerification;

  /// A resident who signs in, or whose account changes, while Home is open
  /// gets the card for that account, not the last one's.
  void _onSession() {
    final SessionState? state = _session?.state;
    final ResidentSession? resident = state?.residentOrNull;
    if (!mounted || state == null || resident == null) return;
    if (!_awaitsVerification(state)) return;
    if (_tierAccount == resident.accountId) return;
    unawaited(_loadTier(quiet: false));
  }

  /// Reads where the account's verification stands, for an account that is
  /// not verified. The tier is the server's word, so the session takes it as
  /// well; a failed read keeps what the card said, or says only "not yet
  /// verified" when it said nothing yet.
  Future<void> _loadTier({required bool quiet}) async {
    final AppDependencies dependencies = AppDependencies.of(context);
    final SessionState state = dependencies.session.state;
    final ResidentSession? resident = state.residentOrNull;
    if (resident == null || !_awaitsVerification(state)) return;
    final Result<ResidentProfileDetail> me = await dependencies
        .residentProfileRepository
        .loadOwnDetail();
    if (!mounted) return;
    switch (me) {
      case Ok<ResidentProfileDetail>(:final value):
        setState(() {
          _tier = value.verificationTier;
          _tierAccount = resident.accountId;
        });
        final String? tier = value.verificationTier;
        if (tier != null && tier.isNotEmpty) {
          dependencies.session.applyVerificationTier(tier);
        }
        dependencies.session.applyGreetingName(
          value.valueOf(ResidentProfileField.fullName),
        );
      case Err<ResidentProfileDetail>():
        if (quiet && _tierAccount == resident.accountId) return;
        setState(() {
          _tier = null;
          _tierAccount = resident.accountId;
        });
    }
  }

  /// Reads everything Home shows.
  ///
  /// [quiet] is a re-read for a change (D-218): no refreshing state, and each
  /// part that fails keeps what it showed rather than falling back to the
  /// bundled slides or an empty list.
  Future<void> _load({required bool initial, bool quiet = false}) async {
    final AppDependencies dependencies = AppDependencies.of(context);
    if (quiet && _refreshing) return;
    if (!initial && !quiet) {
      setState(() => _refreshing = true);
    }
    final SessionState session = dependencies.session.state;
    final bool guest = session is! AuthenticatedSession;
    if (!guest) unawaited(_loadTier(quiet: quiet));
    final List<HomeSlide> bundled = await HomeCatalogue.slides();
    final Result<HomeFeed> home = await dependencies.citizenApi.loadHome();
    if (quiet && !home.isOk) {
      await _loadQuietParts(dependencies, guest: guest);
      return;
    }
    final List<HomeSlide> slides = home.fold(
      onOk: (HomeFeed feed) => HomeCatalogue.withBanners(bundled, feed.banners),
      onErr: (_) => bundled,
    );
    final List<HomeNewsItem> news = quiet
        ? await _newsQuietly(dependencies) ?? _news
        : await _newsFrom(dependencies);
    final HomeHotline? hotline = await _hotlineFrom(home, dependencies);
    final int bell = guest
        ? 0
        : await _bell(dependencies) ?? (quiet ? _bellCount : 0);
    if (!mounted) return;
    if (quiet && _refreshing) return;
    setState(() {
      _slides = slides;
      _news = news;
      _hotline = hotline;
      _bellCount = bell;
      _refreshing = false;
    });
  }

  /// With `GET home` failing, a quiet re-read still refreshes the news and
  /// the bell, and keeps the banners and the hotline it had.
  Future<void> _loadQuietParts(
    AppDependencies dependencies, {
    required bool guest,
  }) async {
    final List<HomeNewsItem>? news = await _newsQuietly(dependencies);
    final int? bell = guest ? 0 : await _bell(dependencies);
    if (!mounted || _refreshing) return;
    if (news == null && bell == null) return;
    setState(() {
      if (news != null) _news = news;
      if (bell != null) _bellCount = bell;
    });
  }

  /// The unread count, or `null` when the inbox could not be read.
  Future<int?> _bell(AppDependencies dependencies) async {
    // The server's count: the unread rows of one page stop at the page's
    // size (D-236).
    final Result<int> unread = await dependencies.notificationRepository
        .unreadCount();
    return unread.fold(onOk: (int count) => count, onErr: (_) => null);
  }

  /// The two newest articles, or `null` when they could not be read.
  Future<List<HomeNewsItem>?> _newsQuietly(AppDependencies dependencies) async {
    final Result<Paginated<Announcement>> result = await dependencies
        .announcementRepository
        .listAnnouncements(perPage: 2);
    return result.fold(
      onOk: (Paginated<Announcement> page) => <HomeNewsItem>[
        for (final Announcement item in page.items) _newsItem(item),
      ],
      onErr: (_) => null,
    );
  }

  HomeNewsItem _newsItem(Announcement item) => HomeNewsItem(
    id: item.id,
    eyebrow: _eyebrow(item),
    title: item.title,
    alert: item.advisoryLevel?.raw == 'emergency',
  );

  Future<List<HomeNewsItem>> _newsFrom(AppDependencies dependencies) async {
    final Result<Paginated<Announcement>> result = await dependencies
        .announcementRepository
        .listAnnouncements(perPage: 2);
    final List<HomeNewsItem> live = result.fold(
      onOk: (Paginated<Announcement> page) => <HomeNewsItem>[
        for (final Announcement item in page.items)
          HomeNewsItem(
            id: item.id,
            eyebrow: _eyebrow(item),
            title: item.title,
            alert: item.advisoryLevel?.raw == 'emergency',
          ),
      ],
      onErr: (_) => const <HomeNewsItem>[],
    );
    if (live.isNotEmpty) return live;
    if (!dependencies.config.usesMockData) return const <HomeNewsItem>[];
    final feed = await HomeCatalogue.mockFeed();
    return feed.news;
  }

  Future<HomeHotline?> _hotlineFrom(
    Result<HomeFeed> home,
    AppDependencies dependencies,
  ) async {
    final List<MunicipalHotline> rows = home.fold(
      onOk: (HomeFeed feed) => feed.hotlines,
      onErr: (_) => const <MunicipalHotline>[],
    );
    // The command center by `kind` when the office marked one, else the first
    // active line as before (D-214).
    final MunicipalHotline? line = homeEmergencyHotline(rows);
    if (line != null) {
      return HomeHotline(
        id: line.id,
        name: line.name,
        number: line.number,
        category: line.category,
        kind: line.kind,
      );
    }
    if (!dependencies.config.usesMockData) return null;
    final feed = await HomeCatalogue.mockFeed();
    if (feed.hotlines.isEmpty) return null;
    for (final HomeHotline mock in feed.hotlines) {
      if (mock.kind == HotlineKind.commandCenter) return mock;
    }
    return feed.hotlines.first;
  }

  String _eyebrow(Announcement item) {
    final List<String> parts = <String>[
      if (item.category != null && item.category!.isNotEmpty) item.category!,
      if (item.author != null && item.author!.isNotEmpty) item.author!,
    ];
    return parts.join(' · ').toUpperCase();
  }

  void _open(String routeName) {
    context.goNamed(routeName);
  }

  Future<void> _dial(String number) async {
    final LinkOutcome outcome = await AppDependencies.of(
      context,
    ).externalLinks.dial(number);
    if (!mounted) return;
    if (outcome == LinkOutcome.unavailable) {
      Outcome.problem(context, 'This phone has no app that can place a call.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppDependencies dependencies = AppDependencies.of(context);
    return AnimatedBuilder(
      animation: dependencies.session,
      builder: (BuildContext context, Widget? _) {
        final SessionState session = dependencies.session.state;
        final bool guest = session is! AuthenticatedSession;
        final ResidentSession? resident = session.residentOrNull;
        final String? name = resident?.displayName;
        final HomeStatusKind status = switch (session.accessLevel) {
          AccessLevel.guest => HomeStatusKind.guest,
          // The card says what `GET /me` says, never "reviewing your ID"
          // for an account that sent none (D-228).
          AccessLevel.unverified => homeStatusForTier(
            _tierAccount == resident?.accountId ? _tier : null,
          ),
          AccessLevel.verified => HomeStatusKind.none,
        };
        return Scaffold(
          backgroundColor: BrandColors.glassBackground,
          body: HomeCanvas(
            greeting: HomeGreeting.line(
              dependencies.clock(),
              name: name,
              guest: guest,
            ),
            initials: guest ? '' : HomeGreeting.initials(name),
            signedIn: !guest,
            bellCount: guest ? 0 : _bellCount,
            status: status,
            slides: _slides,
            loadBanner: dependencies.config.usesMockData
                ? null
                : dependencies.mediaBytes.homeBanner,
            news: _news,
            hotline: _hotline,
            refreshing: _refreshing,
            onRefresh: () => _load(initial: false),
            onBell: () => context.goNamed(
              guest
                  ? AppRoute.signIn.routeName
                  : AppRoute.notifications.routeName,
            ),
            onAvatar: guest
                ? null
                : () => context.goNamed(AppRoute.profile.routeName),
            onSignIn: () => context.goNamed(AppRoute.signIn.routeName),
            onCreateAccount: () => context.goNamed(AppRoute.register.routeName),
            onVerify: () => context.goNamed(AppRoute.verification.routeName),
            onSlide: (HomeSlide slide) => _open(slide.routeName),
            onNews: (HomeNewsItem item) => context.goNamed(
              AppRoute.newsPost.routeName,
              pathParameters: <String, String>{'postId': item.id},
            ),
            onSeeAllNews: () => context.goNamed(AppRoute.news.routeName),
            onAllHotlines: () => context.goNamed(AppRoute.hotlines.routeName),
            onCall: _hotline == null ? null : () => _dial(_hotline!.number),
            onQuickAction: _open,
          ),
        );
      },
    );
  }
}
