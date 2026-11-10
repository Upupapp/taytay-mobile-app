import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/result/result.dart';
import '../../../core/router/deep_link.dart';
import '../../../core/session/resident_capability.dart';
import '../../../core/time/manila_time.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/outcome_feedback.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/taytay_states.dart';
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
class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  NotificationInboxController? _controller;

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
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_onChanged)
      ..dispose();
    super.dispose();
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
        Outcome.problem(context, reason.residentMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          BlueHeader(
            title: 'Notifications',
            subtitle: 'Bayan ng Taytay · Rizal',
            showBack: true,
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed('home');
              }
            },
          ),
          Expanded(
            child: CapabilityGate(
              capability: ResidentCapability.readNotifications,
              child: controller == null
                  ? const _Loading()
                  : _Inbox(controller: controller, onOpen: _open),
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: const <Widget>[
        LoadingSkeleton(count: 5, semanticLabel: 'Loading notifications'),
      ],
    );
  }
}

class _Inbox extends StatelessWidget {
  const _Inbox({required this.controller, required this.onOpen});

  final NotificationInboxController controller;
  final void Function(ResidentNotification) onOpen;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingFirstPage) return const _Loading();

    if (controller.failure != null) {
      return ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: <Widget>[
          EmptyState(
            title: 'Notifications are not available yet',
            message:
                'Taytay LGU has not switched on notifications in this app yet. '
                'Your requests and events still update inside the app.',
            illustration: TaytayIllustration.offline,
            actionLabel: 'Check again',
            onAction: controller.refresh,
            boxed: true,
          ),
        ],
      );
    }

    if (controller.isEmptyAndHealthy) {
      return ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: const <Widget>[
          EmptyState(
            title: 'Nothing yet',
            message:
                'Updates about your requests, documents and events will appear '
                'here.',
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
            when: switch (item.sentAt) {
              final DateTime sent => ManilaTime.formatDateTime(sent),
              null => '',
            },
            unread: item.isUnread,
            tone: _tone(item),
            tile: _tile(item),
            icon: _icon(item),
            onTap: () => onOpen(item),
          ),
      ];
      if (section.group == InboxGroup.today) {
        current = NoticeSection(
          heading: section.group.labelIn(AppStrings.of(context)),
          rows: rows,
        );
      } else {
        earlier.addAll(rows);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: NotificationCentre(
            sections: <NoticeSection>[
              ?current,
              if (earlier.isNotEmpty)
                NoticeSection(heading: 'Earlier', rows: earlier),
            ],
            onMarkAllRead: controller.markAllRead,
          ),
        ),
        _Footer(controller: controller),
      ],
    );
  }
}

String _eyebrow(BuildContext context, ResidentNotification item) {
  final category = item.category?.known;
  if (category == null) return 'UPDATE';
  return notificationCategoryLabel(context, category).toUpperCase();
}

/// The category's ink. Its icon and its label carry the same meaning in
/// words, so colour is never the only signal.
Color _tone(ResidentNotification item) {
  return switch (item.category?.known) {
    NotificationCategory.publicAdvisory => BrandColors.redInk,
    NotificationCategory.accountSecurity => BrandColors.goldInk,
    NotificationCategory.verificationUpdate => BrandColors.goldInk,
    _ => BrandColors.blue,
  };
}

Color _tile(ResidentNotification item) {
  return switch (item.category?.known) {
    NotificationCategory.publicAdvisory => BrandColors.red50,
    NotificationCategory.accountSecurity => BrandColors.gold50,
    NotificationCategory.verificationUpdate => BrandColors.gold50,
    _ => BrandColors.blue50,
  };
}

IconData _icon(ResidentNotification item) {
  return switch (item.category?.known) {
    NotificationCategory.publicAdvisory => TaytayIcons.siren,
    NotificationCategory.verificationUpdate => TaytayIcons.hourglass,
    NotificationCategory.assistanceStatus => TaytayIcons.handHelping,
    _ => TaytayIcons.messageCircle,
  };
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final NotificationInboxController controller;

  @override
  Widget build(BuildContext context) {
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
            const SoftNote(
              tone: NoteTone.warning,
              heading: 'Could not load more',
              message: 'What you have already seen is still here.',
            ),
            AuthLink('Try again', onPressed: controller.loadMore),
          ],
        ),
      );
    }
    if (controller.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        child: LoadingSkeleton(count: 1, semanticLabel: 'Loading older'),
      );
    }
    if (controller.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: AuthLink('Load older', onPressed: controller.loadMore),
      );
    }
    return const SizedBox(height: Spacing.sm);
  }
}

/// Where a resident chooses what to be told about.
///
/// ---
///
/// **Critical categories have no switch, and the screen says why.** A security
/// notice about somebody's own account and an emergency public advisory are the
/// reason a municipality has a notification channel at all; offering to silence
/// them would be offering a setting the LGU must then ignore.
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preferences == null && _loading) _load();
  }

  Future<void> _load() async {
    final repository = AppDependencies.of(context).notificationRepository;
    final result = await repository.loadPreferences();
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold(
        onOk: (preferences) => _preferences = preferences,
        onErr: (_) => _preferences = null,
      );
    });
  }

  Future<void> _set(NotificationCategory category, {required bool on}) async {
    final current = _preferences;
    if (current == null) return;

    final next = current.withCategory(category, enabled: on);
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

    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const BlueHeader(title: 'Notification settings', showBack: true),
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
                  (true, _) => const <Widget>[
                    LoadingSkeleton(
                      count: 4,
                      semanticLabel: 'Loading notification settings',
                    ),
                  ],
                  (_, null) => <Widget>[
                    EmptyState(
                      title: 'Notification settings are not available yet',
                      message:
                          'Taytay LGU has not switched these on in this app '
                          'yet.',
                      illustration: TaytayIllustration.offline,
                      actionLabel: 'Check again',
                      onAction: _load,
                      boxed: true,
                    ),
                  ],
                  (_, final NotificationPreferences loaded) => <Widget>[
                    if (_saveFailure case final AppFailure failure) ...<Widget>[
                      // The whole set is sent each time, so setting it again
                      // is safe. After a timeout the office may already have
                      // the change, and "unchanged" would be a guess.
                      if (failure.outcomeUnknown)
                        const SoftNote(
                          tone: NoteTone.error,
                          heading: 'Your change may not have been saved',
                          message:
                              'We could not confirm it. The switch shows your '
                              'setting before the change. Setting it again is '
                              'safe.',
                        )
                      else
                        const SoftNote(
                          tone: NoteTone.error,
                          heading: 'That change was not saved',
                          message:
                              'Your setting is unchanged. Check your '
                              'connection and try again.',
                        ),
                      const SizedBox(height: Spacing.lg),
                    ],

                    Text(
                      'Choose what Taytay LGU tells you about.',
                      style: AppTypography.bodyStyle.copyWith(
                        color: BrandColors.text,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),

                    SettingsList(
                      children: <Widget>[
                        for (final category
                            in NotificationPreferences.switchable)
                          SettingsSwitchRow(
                            title: notificationCategoryLabel(context, category),
                            icon: TaytayIcons.bell,
                            value: loaded.isEnabled(category),
                            onChanged: (on) => _set(category, on: on),
                          ),
                      ],
                    ),

                    const SizedBox(height: Spacing.lg),
                    const SoftNote(
                      live: false,
                      heading: 'Always sent',
                      message:
                          'Public advisories and messages about your account '
                          'and security are always sent. They are how Taytay '
                          'LGU reaches you in an emergency, or tells you if '
                          'somebody signs in as you.',
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
