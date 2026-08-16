import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/push/push_service.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/notifications/data/planned_notification_repository.dart';
import 'package:taytay_resident/features/notifications/domain/notification_repository.dart';
import 'package:taytay_resident/features/notifications/presentation/notification_inbox_controller.dart';

// ─── Fixtures ───────────────────────────────────────────────────────────────
//
// Obviously synthetic. No real resident, case or reference.

ServerValue<NotificationCategory> categoryOf(NotificationCategory value) =>
    ServerValue<NotificationCategory>(raw: value.wireValue, known: value);

/// A fixed "now" so grouping is deterministic. 12:00 UTC = 8 PM Manila.
final DateTime fixedNow = DateTime.utc(2026, 8, 16, 12);

ResidentNotification notification({
  String id = 'n-1',
  String title = 'Your application moved',
  String body = 'Taytay LGU is checking your documents.',
  DateTime? sentAt,
  DateTime? readAt,
  NotificationCategory category = NotificationCategory.assistanceStatus,
  Map<String, String> target = const <String, String>{},
}) => ResidentNotification(
  id: id,
  title: title,
  body: body,
  sentAt: sentAt ?? fixedNow.subtract(const Duration(hours: 2)),
  readAt: readAt,
  category: categoryOf(category),
  target: target,
);

NotificationPreferences preferences({
  Map<NotificationCategory, bool> categories =
      const <NotificationCategory, bool>{},
}) => NotificationPreferences(
  push: true,
  sms: true,
  email: false,
  categories: categories,
);

class ScriptedNotificationRepository implements NotificationRepository {
  ScriptedNotificationRepository({this.items, this.prefs});

  List<ResidentNotification>? items;
  NotificationPreferences? prefs;

  bool markReadFails = false;
  bool markAllFails = false;
  bool updateFails = false;

  final List<String> markedRead = <String>[];
  final List<String> registeredTokens = <String>[];
  final List<NotificationPreferences> saved = <NotificationPreferences>[];
  int markAllCalls = 0;

  @override
  Future<Result<Paginated<ResidentNotification>>> listOwn({
    int page = 1,
    int perPage = 25,
  }) async {
    final value = items;
    return value == null
        ? const Err<Paginated<ResidentNotification>>(
            ServerFailure(isTemporary: true),
          )
        : Ok<Paginated<ResidentNotification>>(
            Paginated<ResidentNotification>.single(value),
          );
  }

  @override
  Future<Result<void>> markRead(String id) async {
    markedRead.add(id);
    return markReadFails
        ? const Err<void>(NetworkFailure())
        : const Ok<void>(null);
  }

  @override
  Future<Result<void>> markAllRead() async {
    markAllCalls++;
    return markAllFails
        ? const Err<void>(NetworkFailure())
        : const Ok<void>(null);
  }

  @override
  Future<Result<NotificationPreferences>> loadPreferences() async {
    final value = prefs;
    return value == null
        ? const Err<NotificationPreferences>(ServerFailure(isTemporary: true))
        : Ok<NotificationPreferences>(value);
  }

  @override
  Future<Result<void>> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    saved.add(preferences);
    return updateFails
        ? const Err<void>(NetworkFailure())
        : const Ok<void>(null);
  }

  @override
  Future<Result<void>> registerPushToken(String token) async {
    registeredTokens.add(token);
    return const Ok<void>(null);
  }

  @override
  Future<Result<void>> unregisterPushToken() async => const Ok<void>(null);
}

// ─── Harness ────────────────────────────────────────────────────────────────

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

typedef BootedInbox = ({
  AppDependencies dependencies,
  ScriptedNotificationRepository notifications,
});

Future<BootedInbox> bootInbox(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.verified,
  List<ResidentNotification>? items,
  NotificationPreferences? prefs,
  NotificationRepository? repositoryOverride,
  String location = '/notifications',
  Size size = const Size(400, 4000),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');

  final sessionStore = InMemorySessionStore();
  if (level != AccessLevel.guest) {
    await sessionStore.write(
      StoredSession(
        resident: ResidentSession(
          accountId: 'acct-1',
          accessLevel: level,
          displayName: 'Ana',
        ),
        accessToken: 'token',
      ),
    );
  }

  final notifications = ScriptedNotificationRepository(
    items: items,
    prefs: prefs,
  );

  final base = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: sessionStore,
    localAuthenticator: const UnavailableLocalAuthenticator(),
    documentPicker: const UnavailableDocumentPicker(),
  );
  final dependencies = AppDependencies(
    config: base.config,
    session: base.session,
    launch: base.launch,
    intents: base.intents,
    appLock: base.appLock,
    apiClient: base.apiClient,
    cache: base.cache,
    authRepository: base.authRepository,
    deviceSessionRepository: base.deviceSessionRepository,
    platformRepository: base.platformRepository,
    serviceCatalogRepository: base.serviceCatalogRepository,
    programRepository: base.programRepository,
    announcementRepository: base.announcementRepository,
    eventRepository: base.eventRepository,
    residentProfileRepository: base.residentProfileRepository,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: base.verificationRepository,
    serviceRequestRepository: base.serviceRequestRepository,
    requirementRepository: base.requirementRepository,
    documentPicker: base.documentPicker,
    shareService: base.shareService,
    externalLinks: base.externalLinks,
    notificationRepository: repositoryOverride ?? notifications,
    registrationRepository: base.registrationRepository,
    onDispose: base.onDispose,
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(
        tester.view,
      ).copyWith(textScaler: textScaler),
      child: TaytayResidentApp(dependencies: dependencies),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();

  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();

  return (dependencies: dependencies, notifications: notifications);
}

NotificationInboxController controllerFor(
  ScriptedNotificationRepository repository,
) => NotificationInboxController(repository: repository, clock: () => fixedNow);

String currentLocation(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(Scaffold).first),
).routerDelegate.currentConfiguration.uri.path;

void main() {
  group('the push prompt waits for a meaningful moment', () {
    test('never on first frame — no moment, no prompt', () {
      expect(
        PushPromptPolicy.shouldPrompt(
          moment: null,
          permission: PushPermission.notRequested,
          hasPromptedBefore: false,
        ),
        isFalse,
      );
    });

    test('prompts after something the LGU will follow up on', () {
      expect(
        PushPromptPolicy.shouldPrompt(
          moment: PushMoment.submittedAssistanceRequest,
          permission: PushPermission.notRequested,
          hasPromptedBefore: false,
        ),
        isTrue,
      );
    });

    test('never asks twice', () {
      // The OS permission is one-shot; on iOS a refusal is permanent.
      expect(
        PushPromptPolicy.shouldPrompt(
          moment: PushMoment.registeredForEvent,
          permission: PushPermission.notRequested,
          hasPromptedBefore: true,
        ),
        isFalse,
      );
    });

    test('never re-asks after a decision either way', () {
      for (final decided in <PushPermission>[
        PushPermission.granted,
        PushPermission.denied,
        PushPermission.unsupported,
      ]) {
        expect(
          PushPromptPolicy.shouldPrompt(
            moment: PushMoment.submittedVerification,
            permission: decided,
            hasPromptedBefore: false,
          ),
          isFalse,
        );
      }
    });

    test('every moment has a reason that names what just happened', () {
      for (final moment in PushMoment.values) {
        final reason = PushPromptPolicy.reasonFor(moment);
        expect(reason, isNotEmpty);
        expect(reason, contains('Taytay LGU'));
      }
    });

    test(
      'the shipped push service reports unsupported and never prompts',
      () async {
        const service = UnavailablePushService();

        expect(await service.permission(), PushPermission.unsupported);
        expect(await service.requestPermission(), PushPermission.unsupported);
        expect(await service.token(), isNull);
      },
    );

    test('a push payload redacts itself entirely', () {
      const payload = PushPayload(<String, String>{
        'target': 'assistance_request',
        'id': 'req-1',
      });

      // Not even the keys: a payload that wrongly carried a personal field
      // would otherwise be copied into a log by the code meant to catch it.
      expect(payload.toString(), isNot(contains('assistance_request')));
      expect(payload.toString(), isNot(contains('req-1')));
    });
  });

  group('categories and preferences', () {
    test('critical categories cannot be switched off', () {
      final prefs = preferences();

      for (final category in NotificationCategory.values) {
        if (!category.isCritical) continue;
        expect(prefs.isEnabled(category), isTrue);
        expect(
          prefs.withCategory(category, enabled: false).isEnabled(category),
          isTrue,
          reason:
              'Offering to silence a security notice or an emergency '
              'advisory is offering a setting the LGU must then ignore.',
        );
      }
    });

    test('the switchable list excludes the critical ones', () {
      expect(
        NotificationPreferences.switchable.any((c) => c.isCritical),
        isFalse,
      );
      expect(
        NotificationPreferences.switchable,
        contains(NotificationCategory.eventReminder),
      );
    });

    test('an unset category defaults to on', () {
      // An absent entry means it has not been chosen; defaulting a municipal
      // message to off because a field was missing is the wrong failure.
      expect(
        preferences().isEnabled(NotificationCategory.assistanceStatus),
        isTrue,
      );
    });

    test('a switched-off category is reported off', () {
      final prefs = preferences().withCategory(
        NotificationCategory.eventReminder,
        enabled: false,
      );

      expect(prefs.isEnabled(NotificationCategory.eventReminder), isFalse);
      // And nothing else moved.
      expect(prefs.isEnabled(NotificationCategory.assistanceStatus), isTrue);
    });

    test('the shipped repository declines everything', () async {
      const repository = PlannedNotificationRepository();

      expect((await repository.listOwn()).isErr, isTrue);
      expect((await repository.markAllRead()).isErr, isTrue);
      expect((await repository.registerPushToken('t')).isErr, isTrue);
      expect((await repository.unregisterPushToken()).isErr, isTrue);
    });
  });

  group('the inbox groups by recency', () {
    test('groups fall into today, week, month and older', () {
      DateTime ago(Duration d) => fixedNow.subtract(d);

      expect(
        InboxGroup.of(ago(const Duration(hours: 2)), now: fixedNow),
        InboxGroup.today,
      );
      expect(
        InboxGroup.of(ago(const Duration(days: 3)), now: fixedNow),
        InboxGroup.thisWeek,
      );
      expect(
        InboxGroup.of(ago(const Duration(days: 20)), now: fixedNow),
        InboxGroup.thisMonth,
      );
      expect(
        InboxGroup.of(ago(const Duration(days: 200)), now: fixedNow),
        InboxGroup.older,
      );
      expect(InboxGroup.of(null, now: fixedNow), InboxGroup.undated);
    });

    test('grouping uses Manila days, not the device clock', () {
      // 20:00 UTC on the 16th is 04:00 on the 17th in Manila. Grouped against a
      // Manila "now" on the 17th, that is today — a message sent in Taytay
      // should not read as yesterday because a phone is set elsewhere.
      final manilaNow = DateTime.utc(2026, 8, 17, 2);
      expect(
        InboxGroup.of(DateTime.utc(2026, 8, 16, 20), now: manilaNow),
        InboxGroup.today,
      );
    });

    test('empty groups are omitted', () async {
      final repository = ScriptedNotificationRepository(
        items: <ResidentNotification>[notification()],
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.sections.length, 1);
      expect(controller.sections.single.group, InboxGroup.today);
    });

    test('the server order is kept inside a group', () async {
      final repository = ScriptedNotificationRepository(
        items: <ResidentNotification>[
          notification(id: 'a'),
          notification(id: 'b'),
          notification(id: 'c'),
        ],
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.sections.single.items.map((n) => n.id), <String>[
        'a',
        'b',
        'c',
      ]);
    });
  });

  group('reading is optimistic and reconciles', () {
    test('marking read clears the badge immediately', () async {
      final repository = ScriptedNotificationRepository(
        items: <ResidentNotification>[notification()],
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.refresh();

      expect(controller.unreadCount, 1);
      await controller.markRead('n-1');

      expect(controller.unreadCount, 0);
      expect(repository.markedRead.single, 'n-1');
    });

    test('a refused mark puts the unread state back', () async {
      final repository = ScriptedNotificationRepository(
        items: <ResidentNotification>[notification()],
      )..markReadFails = true;
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.refresh();

      await controller.markRead('n-1');

      expect(
        controller.unreadCount,
        1,
        reason:
            'A badge that cleared for something the server never recorded '
            'loses the resident track of what they have seen.',
      );
    });

    test('marking read twice does not call the server again', () async {
      final repository = ScriptedNotificationRepository(
        items: <ResidentNotification>[notification()],
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.refresh();

      await controller.markRead('n-1');
      await controller.markRead('n-1');

      expect(repository.markedRead.length, 1);
    });

    test('mark all read restores everything on failure', () async {
      final repository = ScriptedNotificationRepository(
        items: <ResidentNotification>[
          notification(id: 'a'),
          notification(id: 'b'),
        ],
      )..markAllFails = true;
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.refresh();

      await controller.markAllRead();

      expect(controller.unreadCount, 2);
    });

    test('mark all read is a no-op when nothing is unread', () async {
      final repository = ScriptedNotificationRepository(
        items: <ResidentNotification>[notification(readAt: fixedNow)],
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.refresh();

      await controller.markAllRead();

      expect(repository.markAllCalls, 0);
    });
  });

  group('the inbox screen', () {
    testWidgets('a guest is sent to sign in', (tester) async {
      await bootInbox(tester, level: AccessLevel.guest, items: const []);

      expect(currentLocation(tester), AppRoute.signIn.path);
    });

    testWidgets('an unverified resident reads their inbox', (tester) async {
      // Authenticated, not verified: somebody going through verification is
      // precisely who needs to be told when it completes.
      await bootInbox(
        tester,
        level: AccessLevel.unverified,
        items: <ResidentNotification>[notification()],
      );

      expect(currentLocation(tester), '/notifications');
      expect(find.text('Your application moved'), findsOneWidget);
    });

    testWidgets('an absent backend explains rather than showing nothing', (
      tester,
    ) async {
      await bootInbox(
        tester,
        repositoryOverride: const PlannedNotificationRepository(),
      );

      expect(find.text('Notifications are not available yet'), findsOneWidget);
      expect(find.text('Nothing yet'), findsNothing);
    });

    testWidgets('an empty inbox says so, distinctly', (tester) async {
      await bootInbox(tester, items: const <ResidentNotification>[]);

      expect(find.text('Nothing yet'), findsOneWidget);
      expect(find.text('Notifications are not available yet'), findsNothing);
    });

    testWidgets('a message shows its category and Manila time', (tester) async {
      await bootInbox(
        tester,
        items: <ResidentNotification>[
          notification(sentAt: DateTime.utc(2026, 8, 16, 2)),
        ],
      );

      expect(find.textContaining('Assistance updates'), findsOneWidget);
      expect(find.textContaining('PHT'), findsOneWidget);
    });

    testWidgets('tapping a targeted message opens that place', (tester) async {
      await bootInbox(
        tester,
        items: <ResidentNotification>[
          notification(
            target: const <String, String>{
              'target': 'assistance_request',
              'id': 'req-1',
            },
          ),
        ],
      );

      await tester.tap(find.text('Your application moved'));
      await tester.pumpAndSettle();

      expect(currentLocation(tester), '/requests/req-1');
    });

    testWidgets('a payload naming an action is refused, not followed', (
      tester,
    ) async {
      final booted = await bootInbox(
        tester,
        items: <ResidentNotification>[
          notification(
            target: const <String, String>{'target': 'cancel_request'},
          ),
        ],
      );

      await tester.tap(find.text('Your application moved'));
      await tester.pumpAndSettle();

      expect(currentLocation(tester), '/notifications');
      // It still counted as read: the message was seen even though the link
      // was refused.
      expect(booted.notifications.markedRead.single, 'n-1');
    });

    testWidgets('a payload carrying personal data is refused', (tester) async {
      await bootInbox(
        tester,
        items: <ResidentNotification>[
          notification(
            target: const <String, String>{
              'target': 'assistance_request',
              'id': 'req-1',
              'full_name': 'Ana Dela Cruz',
            },
          ),
        ],
      );

      await tester.tap(find.text('Your application moved'));
      await tester.pumpAndSettle();

      // Rejected outright rather than sanitised — a payload carrying a name has
      // already been mishandled server-side.
      expect(currentLocation(tester), '/notifications');
    });

    testWidgets('a message with no target still reads', (tester) async {
      await bootInbox(tester, items: <ResidentNotification>[notification()]);

      await tester.tap(find.text('Your application moved'));
      await tester.pumpAndSettle();

      expect(currentLocation(tester), '/notifications');
      expect(find.text('Your application moved'), findsOneWidget);
    });

    testWidgets('mark all read appears only when something is unread', (
      tester,
    ) async {
      await bootInbox(
        tester,
        items: <ResidentNotification>[notification(readAt: fixedNow)],
      );

      expect(find.text('Mark all read'), findsNothing);
    });

    testWidgets('the inbox survives a 200% text scale', (tester) async {
      await bootInbox(
        tester,
        items: <ResidentNotification>[
          notification(),
          notification(
            id: 'n-2',
            sentAt: fixedNow.subtract(const Duration(days: 40)),
            category: NotificationCategory.publicAdvisory,
          ),
        ],
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 6000),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Today'), findsOneWidget);
    });
  });

  group('the preferences screen', () {
    testWidgets('critical categories have no switch, and it says why', (
      tester,
    ) async {
      await bootInbox(
        tester,
        prefs: preferences(),
        location: '/notifications/settings',
      );

      expect(find.text('Event reminders'), findsOneWidget);
      expect(find.text('Public advisories'), findsNothing);
      expect(find.text('Always sent'), findsOneWidget);
    });

    testWidgets('turning a category off saves it', (tester) async {
      final booted = await bootInbox(
        tester,
        prefs: preferences(),
        location: '/notifications/settings',
      );

      await tester.tap(find.widgetWithText(SwitchListTile, 'Event reminders'));
      await tester.pumpAndSettle();

      expect(
        booted.notifications.saved.single.isEnabled(
          NotificationCategory.eventReminder,
        ),
        isFalse,
      );
    });

    testWidgets('a failed save puts the switch back and says so', (
      tester,
    ) async {
      final booted = await bootInbox(
        tester,
        prefs: preferences(),
        location: '/notifications/settings',
      );
      booted.notifications.updateFails = true;

      await tester.tap(find.widgetWithText(SwitchListTile, 'Event reminders'));
      await tester.pumpAndSettle();

      expect(find.text('That change was not saved'), findsOneWidget);
      final tile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Event reminders'),
      );
      expect(
        tile.value,
        isTrue,
        reason:
            'A preference that appeared to save and did not is how a '
            'resident ends up believing they turned something off.',
      );
    });

    testWidgets('an absent backend explains', (tester) async {
      await bootInbox(
        tester,
        repositoryOverride: const PlannedNotificationRepository(),
        location: '/notifications/settings',
      );

      expect(
        find.text('Notification settings are not available yet'),
        findsOneWidget,
      );
    });
  });
}
