import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/l10n/core_copy.dart';
import '../../../core/live/live_message.dart';
import '../../../core/live/live_refresh.dart';
import '../../../core/result/result.dart';
import '../../../core/router/deep_link.dart';
import '../../../core/session/resident_capability.dart';
import '../../../core/time/manila_time.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/header_search_field.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/outcome_feedback.dart';
import '../../../shared/widgets/pills.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../domain/notification_filter.dart';
import '../domain/notification_repository.dart';
import 'notification_centre.dart';
import 'notification_inbox_controller.dart';

/// Everything Taytay LGU has sent this resident.
///
/// ---
///
/// **Tapping opens a place; it never acts.** A notification target is resolved
/// through [DeepLink], which refuses any payload naming an action and any
/// payload carrying a personal key. The screen it lands on fetches its own
/// detail under the live session — so the message is a pointer, and the
/// authorization happens where it always does.
///
/// **A message whose target this build cannot resolve still reads.** The title
/// and body are the LGU's words to this resident; dropping the row because the
/// destination is unknown would hide the message as well as the link.
///
/// **She can narrow it (D-238)**, as the console's Notifications page does:
/// All / Unread, a Category of only the kinds she has, When (any time, today,
/// the last 7 or 30 days, or a day she picks), and a search for words in a
/// notice. Each is a view over what the app has read; nothing is sent.
class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen>
    with LiveRefresh<NotificationInboxScreen> {
  NotificationInboxController? _controller;
  final TextEditingController _search = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;

    final dependencies = AppDependencies.of(context);
    _controller =
        NotificationInboxController(
            repository: dependencies.notificationRepository,
            clock: dependencies.clock,
          )
          ..addListener(_onChanged)
          ..refresh();
    // A message the office sends arrives in the list without a pull (D-218).
    listenLive(dependencies.live, const <String>{
      LiveTopics.notifications,
    }, () => _controller?.refreshQuietly());
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_onChanged)
      ..dispose();
    _search.dispose();
    super.dispose();
  }

  /// Clears Category, When and the search field together.
  void _clearFilters() {
    _search.clear();
    _controller?.clearFilters();
  }

  /// The Category picker: every kind, then the kinds she has, each with its
  /// count (DL-291).
  Future<void> _pickKind() async {
    final NotificationInboxController? controller = _controller;
    if (controller == null) return;
    final NoticeKind? current = controller.filter.kind;
    final _KindPick? picked = await AppSheet.show<_KindPick>(
      context: context,
      title: AppStrings.of(context).inboxCategoryTitle,
      builder: (BuildContext sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PickerChoiceRow(
            rowKey: const Key('inbox-kind-all'),
            label: _counted(
              AppStrings.of(sheetContext).inboxCategoryAll,
              controller.totalCount,
            ),
            selected: current == null,
            onTap: () => Navigator.of(sheetContext).pop(const _KindPick(null)),
          ),
          for (final NoticeKindCount entry in controller.kinds)
            PickerChoiceRow(
              rowKey: Key('inbox-kind-${_kindKey(entry.kind)}'),
              label: _counted(
                _kindLabel(sheetContext, entry.kind),
                entry.count,
              ),
              selected: entry.kind == current,
              onTap: () =>
                  Navigator.of(sheetContext).pop(_KindPick(entry.kind)),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    controller.chooseKind(picked.kind);
  }

  /// The When picker. "On a date…" goes on to a calendar; closing the
  /// calendar without a day keeps what was chosen before.
  Future<void> _pickPeriod() async {
    final NotificationInboxController? controller = _controller;
    if (controller == null) return;
    final NotificationPeriod current = controller.filter.period;
    final NotificationPeriod? picked = await AppSheet.show<NotificationPeriod>(
      context: context,
      title: AppStrings.of(context).inboxWhenTitle,
      builder: (BuildContext sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final NotificationPeriod period in NotificationPeriod.values)
            PickerChoiceRow(
              rowKey: Key('inbox-when-${period.name}'),
              label: _periodLabel(AppStrings.of(sheetContext), period),
              selected: period == current,
              onTap: () => Navigator.of(sheetContext).pop(period),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    if (picked != NotificationPeriod.onDay) {
      controller.choosePeriod(picked);
      return;
    }
    final DateTime? day = await _pickDay(controller);
    if (day == null || !mounted) return;
    controller.choosePeriod(NotificationPeriod.onDay, day: day);
  }

  /// A Manila calendar day, from the oldest notice she has to today: a day
  /// outside that range can hold no notice.
  Future<DateTime?> _pickDay(NotificationInboxController controller) async {
    final DateTime today = manilaDayOf(AppDependencies.of(context).clock());
    var first = today;
    for (final ResidentNotification item in controller.items) {
      final DateTime? sent = item.sentAt;
      if (sent == null) continue;
      final DateTime day = manilaDayOf(sent);
      if (day.isBefore(first)) first = day;
    }
    var initial = controller.filter.day ?? today;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(today)) initial = today;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _calendarDay(initial),
      firstDate: _calendarDay(first),
      lastDate: _calendarDay(today),
      helpText: AppStrings.of(context).inboxWhenPickDay,
    );
    if (picked == null) return null;
    return DateTime.utc(picked.year, picked.month, picked.day);
  }

  Future<void> _open(ResidentNotification notification) async {
    final controller = _controller;
    if (controller == null) return;

    // Read first, so the badge clears even if the destination is unknown.
    await controller.markRead(notification.id);
    if (!mounted || !notification.hasTarget) return;

    final resolved = DeepLink.resolve(notification.target);
    switch (resolved) {
      case DeepLinkResolved(:final target):
        // The guard re-evaluates access on the way in, exactly as it would for
        // a tap — including on an expired session, where it lands on sign-in
        // rather than on a screen with nothing in it.
        context.goNamed(
          target.route.routeName,
          pathParameters: target.arguments,
        );
      case DeepLinkRejected(:final reason):
        Outcome.problem(context, deepLinkRejectionMessage(context, reason));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    // The search shows once there is something to search, and stays while it
    // holds words, so a live re-read can never take the field from under her.
    final bool searchable =
        controller != null &&
        (controller.items.isNotEmpty || _search.text.isNotEmpty);

    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BlueHeader(
            title: AppStrings.of(context).inboxTitle,
            subtitle: 'Bayan ng Taytay · Rizal',
            showBack: true,
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed('home');
              }
            },
            bottom: searchable
                ? HeaderSearchField(
                    hint: AppStrings.of(context).inboxSearchHint,
                    fieldKey: const Key('inbox-search'),
                    controller: _search,
                    onChanged: controller.search,
                  )
                : null,
          ),
          Expanded(
            child: CapabilityGate(
              capability: ResidentCapability.readNotifications,
              child: controller == null
                  ? const _Loading()
                  : _Inbox(
                      controller: controller,
                      onOpen: _open,
                      onPickKind: _pickKind,
                      onPickPeriod: _pickPeriod,
                      onClearFilters: _clearFilters,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A Category choice; [kind] null is every kind. Wrapped so the sheet's
/// "nothing chosen" (null) and "All categories" are not the same answer.
final class _KindPick {
  const _KindPick(this.kind);

  final NoticeKind? kind;
}

/// The day a Manila calendar day names, as the date picker takes it.
DateTime _calendarDay(DateTime manilaDay) =>
    DateTime(manilaDay.year, manilaDay.month, manilaDay.day);

/// A choice with how many notices it holds.
String _counted(String label, int count) => '$label · $count';

/// A test key for a kind: its wire value, or `other`.
String _kindKey(NoticeKind kind) => kind.category?.wireValue ?? 'other';

/// What the Category filter calls [kind]: the inbox row's own category name,
/// or "Other updates" for a notice whose type this build does not know.
String _kindLabel(BuildContext context, NoticeKind kind) =>
    switch (kind.category) {
      final NotificationCategory category => notificationCategoryLabel(
        context,
        category,
      ),
      null => AppStrings.of(context).inboxCategoryOther,
    };

String _periodLabel(AppStrings strings, NotificationPeriod period) =>
    switch (period) {
      NotificationPeriod.anyTime => strings.inboxWhenAnyTime,
      NotificationPeriod.today => strings.inboxWhenToday,
      NotificationPeriod.lastWeek => strings.inboxWhenLastWeek,
      NotificationPeriod.lastMonth => strings.inboxWhenLastMonth,
      NotificationPeriod.onDay => strings.inboxWhenOnDay,
    };

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: <Widget>[
        LoadingSkeleton(
          count: 5,
          semanticLabel: AppStrings.of(context).inboxLoading,
        ),
      ],
    );
  }
}

class _Inbox extends StatelessWidget {
  const _Inbox({
    required this.controller,
    required this.onOpen,
    required this.onPickKind,
    required this.onPickPeriod,
    required this.onClearFilters,
  });

  final NotificationInboxController controller;
  final void Function(ResidentNotification) onOpen;
  final VoidCallback onPickKind;
  final VoidCallback onPickPeriod;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingFirstPage) return const _Loading();

    // `GET notifications` is served: a failure is a failure, with Try again,
    // never "not switched on" (DESIGN_SYSTEM.md §5).
    if (controller.failure case final AppFailure failure) {
      return FailureView(
        failure: failure,
        environment: AppDependencies.of(context).config.environment,
        onRetry: controller.refresh,
      );
    }

    final AppStrings strings = AppStrings.of(context);
    if (controller.isEmptyAndHealthy) {
      return ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: <Widget>[
          EmptyState(
            title: strings.inboxEmptyTitle,
            message: strings.inboxEmptyBody,
            boxed: true,
          ),
        ],
      );
    }

    final List<NoticeRow> earlier = <NoticeRow>[];
    NoticeSection? current;
    for (final InboxSection section in controller.sections) {
      final List<NoticeRow> rows = <NoticeRow>[
        for (final ResidentNotification item in section.items)
          NoticeRow(
            eyebrow: _eyebrow(context, item),
            title: item.title,
            body: item.body,
            when: switch (item.sentAt) {
              final DateTime sent => ManilaTime.formatDateTime(
                sent,
                languageCode: Localizations.localeOf(context).languageCode,
              ),
              null => '',
            },
            unread: item.isUnread,
            tone: _tone(item),
            tile: _tile(item),
            icon: _icon(item),
            onTap: () => onOpen(item),
            // The dot marks it read where it is, without opening it.
            onMarkRead: () => controller.markRead(item.id),
          ),
      ];
      if (section.group == InboxGroup.today) {
        current = NoticeSection(
          heading: section.group.labelIn(strings),
          rows: rows,
        );
      } else {
        earlier.addAll(rows);
      }
    }

    final NotificationFilter filter = controller.filter;
    final NoticeKind? kind = filter.kind;
    final String kindLabel = kind == null
        ? strings.inboxCategoryAll
        : _kindLabel(context, kind);
    final String whenLabel = switch ((filter.period, filter.day)) {
      (NotificationPeriod.onDay, final DateTime day) => manilaDate(
        context,
        day,
      ),
      (final NotificationPeriod period, _) => _periodLabel(strings, period),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: NotificationCentre(
            sections: <NoticeSection>[
              ?current,
              if (earlier.isNotEmpty)
                NoticeSection(heading: strings.inboxEarlier, rows: earlier),
            ],
            allCount: controller.totalCount,
            unreadCount: controller.unreadCount,
            unreadOnly: filter.unreadOnly,
            onShowUnread: controller.showUnreadOnly,
            onMarkAllRead: controller.markAllRead,
            choosers: <Widget>[
              SoftChoiceChip(
                key: const Key('inbox-category'),
                label: kindLabel,
                semanticLabel: strings.inboxCategoryValue(kindLabel),
                selected: kind != null,
                chooser: true,
                onTap: onPickKind,
              ),
              SoftChoiceChip(
                key: const Key('inbox-when'),
                label: whenLabel,
                semanticLabel: strings.inboxWhenValue(whenLabel),
                selected: filter.period != NotificationPeriod.anyTime,
                chooser: true,
                onTap: onPickPeriod,
              ),
            ],
            onClearFilters: filter.isNarrowed ? onClearFilters : null,
            empty: _NoMatch(
              controller: controller,
              onClearFilters: onClearFilters,
            ),
          ),
        ),
        _Footer(controller: controller),
      ],
    );
  }
}

/// What the inbox says when it holds notices and the filters leave none:
/// "nothing matches" with Clear filters, or, when only Unread narrows it,
/// "nothing unread" with Show all (DL-291). Never the empty inbox's words,
/// which would say she has no notices at all.
class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.controller, required this.onClearFilters});

  final NotificationInboxController controller;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    if (controller.filter.isNarrowed) {
      return EmptyState(
        title: strings.inboxNoMatchTitle,
        message: strings.inboxNoMatchBody,
        boxed: true,
        actionLabel: strings.inboxClearFilters,
        actionKey: const Key('inbox-no-match-clear'),
        onAction: onClearFilters,
      );
    }
    return EmptyState(
      title: strings.inboxNoUnreadTitle,
      message: strings.inboxNoUnreadBody,
      boxed: true,
      actionLabel: strings.inboxShowAll,
      actionKey: const Key('inbox-no-unread-show-all'),
      onAction: () => controller.showUnreadOnly(false),
    );
  }
}

String _eyebrow(BuildContext context, ResidentNotification item) {
  final category = item.category?.known;
  if (category == null) {
    return AppStrings.of(context).inboxEyebrowUpdate.toUpperCase();
  }
  return notificationCategoryLabel(context, category).toUpperCase();
}

/// The category's ink. Its icon and its label carry the same meaning in
/// words, so colour is never the only signal.
///
/// A verification notice is drawn by what it says was decided, never as
/// pending: `verification_decided` is only ever sent for a decision, and an
/// hourglass on "approved" read as still waiting (D-231). Each notice keeps
/// its own `outcome`, so an old "not accepted" stays that after a later
/// approval; a notice with no outcome this build knows draws a neutral
/// shield (D-232).
Color _tone(ResidentNotification item) {
  return switch (item.category?.known) {
    NotificationCategory.publicAdvisory => BrandColors.redInk,
    NotificationCategory.accountSecurity => BrandColors.goldInk,
    NotificationCategory.verificationUpdate =>
      switch (item.verificationOutcome) {
        VerificationNoticeOutcome.verified => BrandColors.green,
        VerificationNoticeOutcome.notAccepted => BrandColors.redInk,
        null => BrandColors.blue,
      },
    _ => BrandColors.blue,
  };
}

Color _tile(ResidentNotification item) {
  return switch (item.category?.known) {
    NotificationCategory.publicAdvisory => BrandColors.red50,
    NotificationCategory.accountSecurity => BrandColors.gold50,
    NotificationCategory.verificationUpdate =>
      switch (item.verificationOutcome) {
        VerificationNoticeOutcome.verified => BrandColors.green50,
        VerificationNoticeOutcome.notAccepted => BrandColors.red50,
        null => BrandColors.blue50,
      },
    _ => BrandColors.blue50,
  };
}

IconData _icon(ResidentNotification item) {
  return switch (item.category?.known) {
    NotificationCategory.publicAdvisory => TaytayIcons.siren,
    // The verification page's own marks: verified, and "not accepted".
    NotificationCategory.verificationUpdate =>
      switch (item.verificationOutcome) {
        VerificationNoticeOutcome.verified => TaytayIcons.badgeCheck,
        VerificationNoticeOutcome.notAccepted => TaytayIcons.triangleAlert,
        null => TaytayIcons.shield,
      },
    NotificationCategory.assistanceStatus => TaytayIcons.handHelping,
    NotificationCategory.documentRequest => TaytayIcons.fileText,
    NotificationCategory.sectorApplication => TaytayIcons.idCard,
    NotificationCategory.registryRecord => TaytayIcons.circleUser,
    NotificationCategory.eventRegistration => TaytayIcons.calendar,
    _ => TaytayIcons.messageCircle,
  };
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final NotificationInboxController controller;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    if (controller.pageFailure != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.sm,
          Spacing.lg,
          Spacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SoftNote(
              tone: NoteTone.warning,
              heading: strings.inboxLoadMoreFailed,
              message: strings.eventsSeenStillHere,
            ),
            AuthLink(strings.actionTryAgain, onPressed: controller.loadMore),
          ],
        ),
      );
    }
    if (controller.isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        child: LoadingSkeleton(
          count: 1,
          semanticLabel: strings.inboxLoadingOlder,
        ),
      );
    }
    if (controller.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: AuthLink(strings.inboxLoadOlder, onPressed: controller.loadMore),
      );
    }
    return const SizedBox(height: Spacing.sm);
  }
}

/// Where a resident chooses what to be told about: the one place the app
/// offers notification switches (D-224).
///
/// ---
///
/// **One switch per notice the server sends and honours** ([NotificationSwitch]),
/// each saved to its own server type. A category with no notice behind it has
/// no switch: a switch that does nothing leaves a resident believing she
/// silenced something.
///
/// **Public advisories and account security have no switch, and the screen
/// says why.** A security notice about somebody's own account and an emergency
/// public advisory are the reason a municipality has a notification channel at
/// all; offering to silence them would be offering a setting the LGU must then
/// ignore.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _loading = true;
  NotificationPreferences? _preferences;

  /// Why the last change did not save, or null.
  AppFailure? _saveFailure;
  AppFailure? _loadFailure;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preferences == null && _loading) _load();
  }

  void _retry() {
    setState(() {
      _loading = true;
      _loadFailure = null;
    });
    _load();
  }

  Future<void> _load() async {
    final repository = AppDependencies.of(context).notificationRepository;
    final result = await repository.loadPreferences();
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold(
        onOk: (preferences) {
          _preferences = preferences;
          _loadFailure = null;
        },
        onErr: (AppFailure failure) {
          _preferences = null;
          _loadFailure = failure;
        },
      );
    });
  }

  Future<void> _set(NotificationSwitch kind, {required bool on}) async {
    final current = _preferences;
    if (current == null) return;

    final next = current.withSwitch(kind, on: on);
    setState(() {
      _preferences = next;
      _saveFailure = null;
    });

    final repository = AppDependencies.of(context).notificationRepository;
    final result = await repository.updatePreferences(next);
    if (!mounted) return;

    result.fold(
      onOk: (_) {},
      // Put the switch back. A preference that appeared to save and did not is
      // how a resident ends up believing they turned something off.
      onErr: (AppFailure failure) => setState(() {
        _preferences = current;
        _saveFailure = failure;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences;
    final AppStrings strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BlueHeader(title: strings.inboxSettingsTitle, showBack: true),
          Expanded(
            child: CapabilityGate(
              capability: ResidentCapability.readNotifications,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.lg,
                  Spacing.lg,
                  Spacing.xl + MediaQuery.paddingOf(context).bottom,
                ),
                children: switch ((_loading, preferences)) {
                  (true, _) => <Widget>[
                    LoadingSkeleton(
                      count: 4,
                      semanticLabel: strings.inboxSettingsLoading,
                    ),
                  ],
                  // `GET me/notification-preferences` is served: a failed
                  // read is said as one, with Try again.
                  (_, null) => <Widget>[
                    FailureView(
                      failure: _loadFailure ?? const UnexpectedFailure(),
                      environment: AppDependencies.of(
                        context,
                      ).config.environment,
                      onRetry: _retry,
                    ),
                  ],
                  (_, final NotificationPreferences loaded) => <Widget>[
                    if (_saveFailure case final AppFailure failure) ...<Widget>[
                      // The whole set is sent each time, so setting it again
                      // is safe. After a timeout the office may already have
                      // the change, and "unchanged" would be a guess.
                      if (failure.outcomeUnknown)
                        SoftNote(
                          tone: NoteTone.error,
                          heading: strings.inboxSaveUnconfirmedTitle,
                          message: strings.inboxSaveUnconfirmedBody,
                        )
                      else
                        SoftNote(
                          tone: NoteTone.error,
                          heading: strings.inboxSaveFailedTitle,
                          message: strings.inboxSaveFailedBody,
                        ),
                      const SizedBox(height: Spacing.lg),
                    ],

                    Text(
                      strings.inboxSettingsIntro,
                      style: AppTypography.bodyStyle.copyWith(
                        color: BrandColors.text,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),

                    SettingsList(
                      children: <Widget>[
                        for (final kind in NotificationSwitch.values)
                          SettingsSwitchRow(
                            title: notificationSwitchLabel(context, kind),
                            icon: TaytayIcons.bell,
                            value: loaded.isOn(kind),
                            onChanged: (on) => _set(kind, on: on),
                          ),
                      ],
                    ),

                    const SizedBox(height: Spacing.lg),
                    SoftNote(
                      live: false,
                      heading: strings.inboxAlwaysSentTitle,
                      message: strings.inboxAlwaysSentBody,
                    ),
                  ],
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
