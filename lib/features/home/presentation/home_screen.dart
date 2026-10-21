import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/paginated.dart';
import '../../../core/links/external_link_service.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../core/session/session_state.dart';
import '../../../shared/widgets/outcome_feedback.dart';
import '../../citizen_api/domain/citizen_contract.dart';
import '../../news/domain/announcement_repository.dart';
import '../../notifications/domain/notification_repository.dart';
import '../data/home_catalogue.dart';
import '../domain/home_content.dart';
import '../domain/home_greeting.dart';
import 'home_canvas.dart';

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

class _HomeScreenState extends State<HomeScreen> {
  bool _started = false;
  bool _refreshing = false;
  int _bellCount = 0;
  List<HomeSlide> _slides = const <HomeSlide>[];
  List<HomeNewsItem> _news = const <HomeNewsItem>[];
  HomeHotline? _hotline;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load(initial: true);
  }

  Future<void> _load({required bool initial}) async {
    final AppDependencies dependencies = AppDependencies.of(context);
    if (!initial) {
      setState(() => _refreshing = true);
    }
    final SessionState session = dependencies.session.state;
    final bool guest = session is! AuthenticatedSession;
    final List<HomeSlide> bundled = await HomeCatalogue.slides();
    final Result<HomeFeed> home = await dependencies.citizenApi.loadHome();
    final List<HomeSlide> slides = home.fold(
      onOk: (HomeFeed feed) => HomeCatalogue.withBanners(bundled, feed.banners),
      onErr: (_) => bundled,
    );
    final List<HomeNewsItem> news = await _newsFrom(dependencies);
    final HomeHotline? hotline = await _hotlineFrom(home, dependencies);
    var bell = 0;
    if (!guest) {
      final Result<Paginated<ResidentNotification>> page = await dependencies
          .notificationRepository
          .listOwn(page: 1, perPage: 20);
      bell = page.fold(
        onOk: (Paginated<ResidentNotification> inbox) => inbox.items
            .where((ResidentNotification item) => item.isUnread)
            .length,
        onErr: (_) => 0,
      );
    }
    if (!mounted) return;
    setState(() {
      _slides = slides;
      _news = news;
      _hotline = hotline;
      _bellCount = bell;
      _refreshing = false;
    });
  }

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
      onOk: (HomeFeed feed) =>
          feed.hotlines.where((MunicipalHotline row) => row.active).toList(),
      onErr: (_) => const <MunicipalHotline>[],
    );
    if (rows.isNotEmpty) {
      final MunicipalHotline first = rows.first;
      return HomeHotline(
        id: first.id,
        name: first.name,
        number: first.number,
        category: first.category,
      );
    }
    if (!dependencies.config.usesMockData) return null;
    final feed = await HomeCatalogue.mockFeed();
    if (feed.hotlines.isEmpty) return null;
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
        final String? name = session.residentOrNull?.displayName;
        final HomeStatusKind status = switch (session.accessLevel) {
          AccessLevel.guest => HomeStatusKind.guest,
          AccessLevel.unverified => HomeStatusKind.pending,
          AccessLevel.verified => HomeStatusKind.none,
        };
        return Scaffold(
          backgroundColor: const Color(0xFFF3F5FA),
          body: HomeCanvas(
            greeting: HomeGreeting.line(
              dependencies.clock(),
              name: name,
              guest: guest,
            ),
            initials: guest ? '' : HomeGreeting.initials(name),
            bellCount: guest ? 0 : _bellCount,
            status: status,
            slides: _slides,
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
