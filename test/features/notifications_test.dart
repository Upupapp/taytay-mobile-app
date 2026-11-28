import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/design/taytay_icons.dart';
import 'package:taytay_resident/core/design/typography.dart';
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
import 'package:taytay_resident/features/notifications/domain/notification_filter.dart';
import 'package:taytay_resident/features/notifications/domain/notification_repository.dart';
import 'package:taytay_resident/features/notifications/presentation/notification_centre.dart';
import 'package:taytay_resident/features/notifications/presentation/notification_inbox_controller.dart';
import 'package:taytay_resident/shared/widgets/taytay_icon.dart';

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
  VerificationNoticeOutcome? verificationOutcome,
}) => ResidentNotification(
  id: id,
  title: title,
  body: body,
  sentAt: sentAt ?? fixedNow.subtract(const Duration(hours: 2)),
  readAt: readAt,
  category: categoryOf(category),
  target: target,
  verificationOutcome: verificationOutcome,
);

/// A `verification_decided` row as the inbox receives it (D-231).
ResidentNotification verificationNotice({
  String id = 'n-v',
  required String body,
  VerificationNoticeOutcome? outcome,
}) => notification(
  id: id,
  title: 'Verification update',
  body: body,
  category: NotificationCategory.verificationUpdate,
  target: const <String, String>{
    'type': 'verification_decided',
    'target': 'verification',
  },
  verificationOutcome: outcome,
);

/// A [TaytayIcon] drawing [icon] anywhere on screen.
Finder rowIcon(IconData icon) =>
    find.byWidgetPredicate((Widget w) => w is TaytayIcon && w.icon == icon);

NotificationPreferences preferences({
  List<ChannelPreference> channels = const <ChannelPreference>[],
}) => NotificationPreferences(
  push: true,
  sms: true,
  email: false,
  channels: channels,
);

/// The resident-facing name of each switch, in the order the screen draws them.
const Map<NotificationSwitch, String> switchLabels =
    <NotificationSwitch, String>{
      NotificationSwitch.verificationDecided: 'Identity verification',
      NotificationSwitch.assistanceRequestUpdated: 'Assistance updates',
      NotificationSwitch.issuanceRequestUpdated: 'Document requests',
      NotificationSwitch.eventRegistrationUpdated: 'Event registrations',
      NotificationSwitch.sectorApplicationDecided: 'Sector applications',
      NotificationSwitch.registryRecordUpdated:
          'Changes to your record at the office',
      NotificationSwitch.messageReceived: 'Office replies',
    };

class ScriptedNotificationRepository implements NotificationRepository {
  ScriptedNotificationRepository({this.items, this.prefs});

  List<ResidentNotification>? items;
  NotificationPreferences? prefs;

  bool markReadFails = false;
  bool markAllFails = false;
  bool updateFails = false;

  /// What a failed update answers with.
  AppFailure updateFailure = const NetworkFailure();

  final List<String> markedRead = <String>[];
  final List<String> registeredTokens = <String>[];

  @override
  Future<Result<int>> unreadCount() async => Ok<int>(
    (items ?? const <ResidentNotification>[])
        .where((ResidentNotification item) => item.isUnread)
        .length,
  );
  final List<NotificationPreferences> saved = <NotificationPreferences>[];
  int markAllCalls = 0;

  @override
  Future<Result<Paginated<ResidentNotification>>> listOwn({
    int page = 1,
    int perPage = 25,
    String? cursor,
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
    return updateFails ? Err<void>(updateFailure) : const Ok<void>(null);
  }

  @override
  Future<Result<String>> registerPushToken(String token) async {
    registeredTokens.add(token);
    return const Ok<String>('device-1');
  }
}

/// A page of [items] whose next page is [next], or the last page.
Paginated<ResidentNotification> pageOf(
  List<ResidentNotification> items, {
  String? next,
}) => Paginated<ResidentNotification>(
  items: items,
  page: 1,
  perPage: 25,
  total: 0,
  totalPages: 0,
  hasMore: next != null,
  nextCursor: next,
);

/// An inbox longer than the controller reads at once: every page names a
/// next one. [failAt] makes that page (1-based) fail.
class EndlessNotificationRepository extends ScriptedNotificationRepository {
  EndlessNotificationRepository({this.failAt});

  final int? failAt;
  final List<String?> cursors = <String?>[];

  @override
  Future<Result<Paginated<ResidentNotification>>> listOwn({
    int page = 1,
    int perPage = 25,
    String? cursor,
  }) async {
    cursors.add(cursor);
    final int number = cursors.length;
    if (number == failAt) {
      return const Err<Paginated<ResidentNotification>>(NetworkFailure());
    }
    return Ok<Paginated<ResidentNotification>>(
      pageOf(<ResidentNotification>[
        notification(id: 'p$number'),
      ], next: 'after-$number'),
    );
  }
}

/// Holds every page until the test answers it, so a test can say in which
/// order pages arrive.
class HeldNotificationRepository extends ScriptedNotificationRepository {
  final List<Completer<Result<Paginated<ResidentNotification>>>> held =
      <Completer<Result<Paginated<ResidentNotification>>>>[];

  @override
  Future<Result<Paginated<ResidentNotification>>> listOwn({
    int page = 1,
    int perPage = 25,
    String? cursor,
  }) {
    final Completer<Result<Paginated<ResidentNotification>>> completer =
        Completer<Result<Paginated<ResidentNotification>>>();
    held.add(completer);
    return completer.future;
  }
}

/// Lets every pending future and microtask run.
Future<void> settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

List<String> idsOf(Iterable<ResidentNotification> notices) =>
    notices.map((ResidentNotification n) => n.id).toList();

/// The nearest [Material] around [text]: a notice row's fill.
Color? rowFill(WidgetTester tester, String text) => tester
    .widget<Material>(
      find.ancestor(of: find.text(text), matching: find.byType(Material)).first,
    )
    .color;

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
  // The fixture clock reaches the real widget tree through the composition root.
  // Without this, a test pinned to `fixedNow` groups its messages against
  // today's date and every recency assertion in this file rots on the calendar.
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
    network: base.network,
    telemetry: base.telemetry,
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
    documentPicker: base.documentPicker,
    shareService: base.shareService,
    externalLinks: base.externalLinks,
    accountControlsRepository: base.accountControlsRepository,
    clock: () => fixedNow,
    notificationRepository: repositoryOverride ?? notifications,
    registrationRepository: base.registrationRepository,
    barangayDirectory: base.barangayDirectory,
    platform: base.platform,
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

  group('switches and preferences', () {
    test('there is one switch per notice the server sends and honours', () {
      expect(
        NotificationSwitch.values.map((kind) => kind.preferenceType),
        <String>[
          'verification_decided',
          'assistance_request_updated',
          'issuance_request_updated',
          'event_registration_updated',
          'sector_application_decided',
          'registry_record_updated',
          'message_received',
        ],
        reason:
            'A switch with no server notice behind it leaves a resident '
            'believing she silenced something (D-224).',
      );
    });

    test('a switch with no row is on', () {
      // An absent row means it has not been chosen, and the server sends it;
      // reporting it off would say she silenced something she did not.
      for (final kind in NotificationSwitch.values) {
        expect(preferences().isOn(kind), isTrue, reason: '$kind');
      }
    });

    test('switching one writes both channels of its row and nothing else', () {
      for (final kind in NotificationSwitch.values) {
        final prefs = preferences().withSwitch(kind, on: false);

        expect(prefs.isOn(kind), isFalse, reason: '$kind');
        final row = prefs.channels.singleWhere(
          (channel) => channel.type == kind.preferenceType,
        );
        expect(row.inApp, isFalse);
        expect(row.push, isFalse);
        for (final other in NotificationSwitch.values) {
          if (other != kind) expect(prefs.isOn(other), isTrue);
        }
        expect(prefs.withSwitch(kind, on: true).isOn(kind), isTrue);
      }
    });

    test('a row with one channel still on reads on', () {
      // An older app's push-only switch left in_app on: she is still told in
      // the app, so the switch does not say she is not.
      final prefs = preferences(
        channels: const <ChannelPreference>[
          ChannelPreference(type: 'message_received', inApp: true, push: false),
        ],
      );
      expect(prefs.isOn(NotificationSwitch.messageReceived), isTrue);
      final off = prefs.withSwitch(
        NotificationSwitch.messageReceived,
        on: false,
      );
      expect(off.channels.single.inApp, isFalse);
      expect(off.channels.single.push, isFalse);
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

    test(
      'marking read keeps what a verification notice said (D-231)',
      () async {
        final repository = ScriptedNotificationRepository(
          items: <ResidentNotification>[
            verificationNotice(
              body: 'Your identity review was approved.',
              outcome: VerificationNoticeOutcome.verified,
            ),
          ],
        );
        final controller = controllerFor(repository);
        addTearDown(controller.dispose);
        await controller.refresh();

        await controller.markRead('n-v');

        expect(controller.items.single.isUnread, isFalse);
        expect(
          controller.items.single.verificationOutcome,
          VerificationNoticeOutcome.verified,
        );
      },
    );

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

      expect(find.textContaining('ASSISTANCE UPDATES'), findsOneWidget);
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

      // My requests (D-223).
      expect(currentLocation(tester), '/my-requests/req-1');
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

    // `verification_decided` has no subject_id: its target was only its
    // type, so a tap said "That link could not be opened" (D-228).
    testWidgets('a verification decision opens the verification screen', (
      tester,
    ) async {
      await bootInbox(
        tester,
        level: AccessLevel.unverified,
        items: <ResidentNotification>[
          notification(
            category: NotificationCategory.verificationUpdate,
            target: const <String, String>{
              'type': 'verification_decided',
              'target': 'verification',
            },
          ),
        ],
      );

      await tester.tap(find.text('Your application moved'));
      await tester.pumpAndSettle();

      expect(currentLocation(tester), '/verification');
    });

    testWidgets('a notice whose type opens nowhere is read, and no link is '
        'said to have failed', (tester) async {
      final booted = await bootInbox(
        tester,
        items: <ResidentNotification>[
          notification(
            target: const <String, String>{'type': 'message_received'},
          ),
        ],
      );
      await tester.tap(find.text('Your application moved'));
      await tester.pumpAndSettle();

      expect(currentLocation(tester), '/notifications');
      expect(booted.notifications.markedRead.single, 'n-1');
      expect(find.textContaining('could not be opened'), findsNothing);
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

      expect(find.text('Mark all as read'), findsNothing);
    });

    // An approved notice kept the pending hourglass (D-231).
    testWidgets('a verification notice is drawn by what it says was decided', (
      tester,
    ) async {
      await bootInbox(
        tester,
        items: <ResidentNotification>[
          verificationNotice(
            id: 'n-ok',
            body: 'Your identity review was approved.',
            outcome: VerificationNoticeOutcome.verified,
          ),
          verificationNotice(
            id: 'n-no',
            body: 'Your identity review was rejected.',
            outcome: VerificationNoticeOutcome.notAccepted,
          ),
          verificationNotice(id: 'n-new', body: 'Some other wording.'),
        ],
      );

      expect(rowIcon(TaytayIcons.hourglass), findsNothing);
      expect(rowIcon(TaytayIcons.badgeCheck), findsOneWidget);
      expect(rowIcon(TaytayIcons.triangleAlert), findsOneWidget);
      // Words it does not know are a decision all the same, never pending.
      expect(rowIcon(TaytayIcons.shield), findsOneWidget);
      // The words say it too, so the icon is never the only signal: every
      // verification notice has the same title.
      expect(find.text('Your identity review was approved.'), findsOneWidget);
      expect(find.text('Your identity review was rejected.'), findsOneWidget);
      expect(find.text('Verification update'), findsNWidgets(3));
    });

    testWidgets('a notice keeps what it said, whatever the account is now', (
      tester,
    ) async {
      // An approval the account has since lost (signed in unverified here)
      // still reads as the approval it was.
      await bootInbox(
        tester,
        level: AccessLevel.unverified,
        items: <ResidentNotification>[
          verificationNotice(
            id: 'n-old',
            body: 'Your identity review was approved.',
            outcome: VerificationNoticeOutcome.verified,
          ),
        ],
      );
      expect(rowIcon(TaytayIcons.badgeCheck), findsOneWidget);
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
          verificationNotice(
            body: 'Your identity was verified in person at the office.',
            outcome: VerificationNoticeOutcome.verified,
          ),
        ],
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 6000),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Today'), findsOneWidget);
    });
  });

  group('a failed read is a failure, not a feature switched off (D-220)', () {
    testWidgets('the inbox says the read failed and offers Try again', (
      tester,
    ) async {
      final booted = await bootInbox(tester);

      expect(find.text('Notifications are not available yet'), findsNothing);
      expect(find.textContaining('switched on'), findsNothing);
      expect(find.text('Try again'), findsOneWidget);

      booted.notifications.items = <ResidentNotification>[notification()];
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Your application moved'), findsOneWidget);
    });

    testWidgets('the settings say the read failed and offer Try again', (
      tester,
    ) async {
      final booted = await bootInbox(
        tester,
        location: '/notifications/settings',
      );

      expect(find.textContaining('switched these on'), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Event registrations'), findsNothing);

      booted.notifications.prefs = preferences();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Event registrations'), findsOneWidget);
    });
  });

  group('the preferences screen', () {
    testWidgets('it shows exactly the switches the server honours', (
      tester,
    ) async {
      await bootInbox(
        tester,
        prefs: preferences(),
        location: '/notifications/settings',
      );

      expect(find.byType(SwitchListTile), findsNWidgets(switchLabels.length));
      for (final label in switchLabels.values) {
        expect(
          find.widgetWithText(SwitchListTile, label),
          findsOneWidget,
          reason: label,
        );
      }
      // No notice is sent for these, so no switch is offered for them.
      for (final label in <String>[
        'Documents needed',
        'Collecting assistance',
        'Referrals',
        'Event reminders',
        'Balita & advisories',
        'Emergency alerts',
      ]) {
        expect(find.text(label), findsNothing, reason: label);
      }
      // Public advisories and account security are always sent, and it says so.
      expect(
        find.widgetWithText(SwitchListTile, 'Public advisories'),
        findsNothing,
      );
      expect(find.text('Always sent'), findsOneWidget);
      expect(find.textContaining('Public advisories'), findsOneWidget);
    });

    testWidgets('saving each switch sends its own server type', (tester) async {
      final booted = await bootInbox(
        tester,
        prefs: preferences(),
        location: '/notifications/settings',
      );

      for (final MapEntry<NotificationSwitch, String> entry
          in switchLabels.entries) {
        final tile = find.widgetWithText(SwitchListTile, entry.value);
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pumpAndSettle();

        final saved = booted.notifications.saved.last;
        final row = saved.channels.singleWhere(
          (channel) => channel.type == entry.key.preferenceType,
        );
        expect(row.inApp, isFalse, reason: entry.value);
        expect(row.push, isFalse, reason: entry.value);
        expect(
          tester.widget<SwitchListTile>(tile).value,
          isFalse,
          reason: entry.value,
        );
      }
      expect(booted.notifications.saved, hasLength(switchLabels.length));
      expect(
        booted.notifications.saved.last.channels.map((c) => c.type).toSet(),
        switchLabels.keys.map((kind) => kind.preferenceType).toSet(),
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

      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Event registrations'),
      );
      await tester.pumpAndSettle();

      expect(find.text('That change was not saved'), findsOneWidget);
      final tile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Event registrations'),
      );
      expect(
        tile.value,
        isTrue,
        reason:
            'A preference that appeared to save and did not is how a '
            'resident ends up believing they turned something off.',
      );
    });

    testWidgets('a save that timed out is not called unchanged', (
      tester,
    ) async {
      final booted = await bootInbox(
        tester,
        prefs: preferences(),
        location: '/notifications/settings',
      );
      booted.notifications
        ..updateFails = true
        ..updateFailure = const TimeoutFailure();

      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Event registrations'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your change may not have been saved'), findsOneWidget);
      expect(find.textContaining('Setting it again is safe'), findsOneWidget);
      expect(find.text('That change was not saved'), findsNothing);
      expect(find.textContaining('unchanged'), findsNothing);
    });
  });

  // ─── D-238: filters, counts and the unread row ────────────────────────────

  group('the controller filters what it has read (D-238)', () {
    test(
      'the counts and the kinds cover every notice, whatever is shown',
      () async {
        final repository = ScriptedNotificationRepository(
          items: <ResidentNotification>[
            notification(id: 'a'),
            notification(
              id: 'b',
              readAt: fixedNow,
              category: NotificationCategory.officeReply,
            ),
          ],
        );
        final controller = controllerFor(repository);
        addTearDown(controller.dispose);
        await controller.refresh();

        controller.chooseKind(
          const NoticeKind(NotificationCategory.officeReply),
        );

        expect(idsOf(controller.visibleItems), <String>['b']);
        expect(
          idsOf(controller.sections.expand((InboxSection s) => s.items)),
          <String>['b'],
        );
        expect(controller.totalCount, 2);
        expect(controller.unreadCount, 1);
        expect(
          controller.kinds.map((NoticeKindCount k) => k.kind).toList(),
          <NoticeKind>[
            const NoticeKind(NotificationCategory.assistanceStatus),
            const NoticeKind(NotificationCategory.officeReply),
          ],
        );
      },
    );

    test('a chosen kind the inbox no longer holds stays offered, at zero, '
        'and says nothing matches', () async {
      final repository = ScriptedNotificationRepository(
        items: <ResidentNotification>[notification()],
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.refresh();

      controller.chooseKind(
        const NoticeKind(NotificationCategory.publicAdvisory),
      );

      expect(
        controller.kinds.last.kind.category,
        NotificationCategory.publicAdvisory,
      );
      expect(controller.kinds.last.count, 0);
      expect(controller.hasNoMatch, isTrue);
      expect(controller.isEmptyAndHealthy, isFalse);
    });

    test(
      'Clear filters keeps Unread, and a filter survives a refresh',
      () async {
        final repository = ScriptedNotificationRepository(
          items: <ResidentNotification>[notification()],
        );
        final controller = controllerFor(repository);
        addTearDown(controller.dispose);
        await controller.refresh();

        controller
          ..showUnreadOnly(true)
          ..choosePeriod(NotificationPeriod.lastWeek)
          ..search('application');
        await controller.refresh();
        expect(controller.filter.words, 'application');

        controller.clearFilters();
        expect(controller.filter, const NotificationFilter(unreadOnly: true));
      },
    );

    test('marking one read from Unread takes it off the list', () async {
      final repository = ScriptedNotificationRepository(
        items: <ResidentNotification>[notification()],
      );
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);
      await controller.refresh();
      controller.showUnreadOnly(true);

      await controller.markRead('n-1');

      expect(controller.visibleItems, isEmpty);
      expect(controller.hasNoMatch, isTrue);
    });

    test('the refresh reads on past the first page, up to its limit', () async {
      final repository = EndlessNotificationRepository();
      final controller = controllerFor(repository);
      addTearDown(controller.dispose);

      await controller.refresh();

      const int limit = NotificationInboxController.pagesReadAtOnce;
      expect(controller.items, hasLength(limit));
      expect(repository.cursors.first, isNull);
      expect(repository.cursors[1], 'after-1');
      expect(controller.hasMore, isTrue);
      expect(controller.isLoadingMore, isFalse);

      // Beyond the limit, Load older reads one page at a time, as before.
      await controller.loadMore();
      expect(controller.items, hasLength(limit + 1));
    });

    test(
      'a page that fails stops the reading and keeps what arrived',
      () async {
        final repository = EndlessNotificationRepository(failAt: 3);
        final controller = controllerFor(repository);
        addTearDown(controller.dispose);

        await controller.refresh();

        expect(idsOf(controller.items), <String>['p1', 'p2']);
        expect(repository.cursors, hasLength(3));
        expect(controller.failure, isNull);
        expect(controller.pageFailure, isNotNull);
        expect(controller.hasMore, isTrue);
      },
    );

    test(
      'a page of a list a refresh replaced is dropped, not appended',
      () async {
        final repository = HeldNotificationRepository();
        final controller = controllerFor(repository);
        addTearDown(controller.dispose);

        final Future<void> first = controller.refresh();
        await settle();
        repository.held[0].complete(
          Ok<Paginated<ResidentNotification>>(
            pageOf(<ResidentNotification>[
              notification(id: 'old-1'),
            ], next: 'p2'),
          ),
        );
        await settle();
        expect(repository.held, hasLength(2));
        expect(controller.isLoadingMore, isTrue);

        final Future<void> second = controller.refresh();
        await settle();
        expect(repository.held, hasLength(3));

        // The old list's second page arrives after the new list asked again.
        repository.held[1].complete(
          Ok<Paginated<ResidentNotification>>(
            pageOf(<ResidentNotification>[notification(id: 'stale')]),
          ),
        );
        repository.held[2].complete(
          Ok<Paginated<ResidentNotification>>(
            pageOf(<ResidentNotification>[notification(id: 'new-1')]),
          ),
        );
        await first;
        await second;

        expect(idsOf(controller.items), <String>['new-1']);
        expect(controller.isLoadingMore, isFalse);
        expect(controller.isLoadingFirstPage, isFalse);
      },
    );
  });

  group('the inbox filters (D-238)', () {
    testWidgets('All and Unread carry the inbox counts, and Unread shows only '
        'unread', (tester) async {
      await bootInbox(
        tester,
        items: <ResidentNotification>[
          notification(id: 'a', title: 'Unread notice'),
          notification(id: 'b', title: 'Read notice', readAt: fixedNow),
        ],
      );

      expect(find.text('All · 2'), findsOneWidget);
      expect(find.text('Unread · 1'), findsOneWidget);
      expect(find.byKey(const Key('inbox-clear-filters')), findsNothing);

      await tester.tap(find.byKey(const Key('inbox-show-unread')));
      await tester.pumpAndSettle();

      expect(find.text('Unread notice'), findsOneWidget);
      expect(find.text('Read notice'), findsNothing);
      // The counts are the inbox's, not what is shown.
      expect(find.text('All · 2'), findsOneWidget);
      // Unread is its own control, so there is nothing to clear.
      expect(find.byKey(const Key('inbox-clear-filters')), findsNothing);
    });

    testWidgets('with everything read, Unread says so and Show all goes back', (
      tester,
    ) async {
      await bootInbox(
        tester,
        items: <ResidentNotification>[notification(readAt: fixedNow)],
      );

      await tester.tap(find.byKey(const Key('inbox-show-unread')));
      await tester.pumpAndSettle();

      expect(find.text('No unread notifications'), findsOneWidget);
      expect(find.text('Your application moved'), findsNothing);
      // Not the empty inbox's words: she has notices.
      expect(find.text('Nothing yet'), findsNothing);

      await tester.tap(find.byKey(const Key('inbox-no-unread-show-all')));
      await tester.pumpAndSettle();

      expect(find.text('Your application moved'), findsOneWidget);
      expect(find.text('No unread notifications'), findsNothing);
    });

    testWidgets('Category lists only the kinds she has, with counts, and '
        'Clear filters brings everything back', (tester) async {
      await bootInbox(
        tester,
        items: <ResidentNotification>[
          notification(id: 'a', title: 'Assistance one'),
          notification(id: 'b', title: 'Assistance two'),
          notification(
            id: 'c',
            title: 'Office answer',
            category: NotificationCategory.officeReply,
          ),
        ],
      );

      await tester.tap(find.byKey(const Key('inbox-category')));
      await tester.pumpAndSettle();

      expect(find.text('All categories · 3'), findsOneWidget);
      expect(find.text('Assistance updates · 2'), findsOneWidget);
      expect(find.text('Office replies · 1'), findsOneWidget);
      // A kind she has none of is not offered.
      expect(find.textContaining('Public advisories'), findsNothing);
      expect(find.textContaining('Identity verification'), findsNothing);

      await tester.tap(find.byKey(const Key('inbox-kind-message_received')));
      await tester.pumpAndSettle();

      expect(find.text('Office answer'), findsOneWidget);
      expect(find.text('Assistance one'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('inbox-category')),
          matching: find.text('Office replies'),
        ),
        findsOneWidget,
      );

      // The link sits at the start of its line, so tap the link itself.
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('inbox-clear-filters')),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assistance one'), findsOneWidget);
      expect(find.text('Office answer'), findsOneWidget);
      expect(find.byKey(const Key('inbox-clear-filters')), findsNothing);
    });

    testWidgets('When: Today keeps the Manila day only', (tester) async {
      await bootInbox(
        tester,
        items: <ResidentNotification>[
          notification(id: 'a', title: 'Sent this morning'),
          notification(
            id: 'b',
            title: 'Sent last week',
            sentAt: fixedNow.subtract(const Duration(days: 9)),
          ),
        ],
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('inbox-when')),
          matching: find.text('Any time'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('inbox-when')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inbox-when-today')));
      await tester.pumpAndSettle();

      expect(find.text('Sent this morning'), findsOneWidget);
      expect(find.text('Sent last week'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('inbox-when')),
          matching: find.text('Today'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('inbox-clear-filters')), findsOneWidget);
    });

    testWidgets('On a date… picks one day from a calendar', (tester) async {
      await bootInbox(
        tester,
        items: <ResidentNotification>[
          // 10 Aug and 12 Aug, 10 AM in Manila.
          notification(
            id: 'a',
            title: 'Sent on the tenth',
            sentAt: DateTime.utc(2026, 8, 10, 2),
          ),
          notification(
            id: 'b',
            title: 'Sent on the twelfth',
            sentAt: DateTime.utc(2026, 8, 12, 2),
          ),
        ],
      );

      await tester.tap(find.byKey(const Key('inbox-when')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inbox-when-onDay')));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Sent on the twelfth'), findsOneWidget);
      expect(find.text('Sent on the tenth'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('inbox-when')),
          matching: find.text('12 Aug 2026'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('closing the calendar without a day changes nothing', (
      tester,
    ) async {
      await bootInbox(
        tester,
        items: <ResidentNotification>[
          notification(sentAt: DateTime.utc(2026, 8, 10, 2)),
        ],
      );

      await tester.tap(find.byKey(const Key('inbox-when')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inbox-when-onDay')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Your application moved'), findsOneWidget);
      expect(find.byKey(const Key('inbox-clear-filters')), findsNothing);
    });

    testWidgets('a search finds words in a notice; nothing matching says so, '
        'with a way back', (tester) async {
      await bootInbox(
        tester,
        items: <ResidentNotification>[
          notification(id: 'a', title: 'Barangay clearance ready'),
          notification(
            id: 'b',
            title: 'Event reminder',
            body: 'See you at the plaza.',
          ),
        ],
      );
      final Finder field = find.byKey(const Key('inbox-search'));

      await tester.enterText(field, 'CLEARANCE');
      await tester.pumpAndSettle();
      expect(find.text('Barangay clearance ready'), findsOneWidget);
      expect(find.text('Event reminder'), findsNothing);

      await tester.enterText(field, 'plaza');
      await tester.pumpAndSettle();
      expect(find.text('Event reminder'), findsOneWidget);
      expect(find.text('Barangay clearance ready'), findsNothing);

      await tester.enterText(field, 'no such words');
      await tester.pumpAndSettle();
      expect(find.text('No notifications match'), findsOneWidget);
      expect(find.text('Nothing yet'), findsNothing);
      // The field stays while it holds words.
      expect(field, findsOneWidget);

      await tester.tap(find.byKey(const Key('inbox-no-match-clear')));
      await tester.pumpAndSettle();
      expect(find.text('Barangay clearance ready'), findsOneWidget);
      expect(find.text('Event reminder'), findsOneWidget);
      expect(tester.widget<TextField>(field).controller?.text, isEmpty);
    });

    testWidgets('an empty inbox offers no search and no filters', (
      tester,
    ) async {
      await bootInbox(tester, items: const <ResidentNotification>[]);

      expect(find.byKey(const Key('inbox-search')), findsNothing);
      expect(find.byKey(const Key('inbox-category')), findsNothing);
      expect(find.text('Nothing yet'), findsOneWidget);
    });

    testWidgets('the filters survive a 200% text scale on a narrow phone', (
      tester,
    ) async {
      await bootInbox(
        tester,
        items: <ResidentNotification>[
          notification(
            category: NotificationCategory.registryRecord,
            title: 'Your record at the office was updated',
          ),
        ],
        textScaler: const TextScaler.linear(2),
        size: const Size(360, 6000),
      );

      await tester.tap(find.byKey(const Key('inbox-category')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('inbox-kind-registry_record_updated')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('inbox-clear-filters')), findsOneWidget);
    });
  });

  group('an unread notice is a tinted row with a dot (D-238)', () {
    testWidgets('unread is tinted, bold and said in words; read is plain', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await bootInbox(
        tester,
        items: <ResidentNotification>[
          notification(id: 'a', title: 'Unread notice'),
          notification(id: 'b', title: 'Read notice', readAt: fixedNow),
        ],
      );

      expect(rowFill(tester, 'Unread notice'), BrandColors.blue100);
      expect(rowFill(tester, 'Read notice'), BrandColors.white);
      expect(
        tester.widget<Text>(find.text('Unread notice')).style?.fontWeight,
        AppTypography.strong,
      );
      expect(
        tester.widget<Text>(find.text('Read notice')).style?.fontWeight,
        AppTypography.medium,
      );
      expect(
        find.bySemanticsLabel(RegExp('Unread: Unread notice')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Mark as read: Unread notice'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('Mark as read: Read')), findsNothing);
      // No "Unread" tag and no per-row "Mark as read" button.
      expect(find.text('Unread'), findsNothing);
      expect(find.text('Mark as read'), findsNothing);
      semantics.dispose();
    });

    testWidgets('tapping the dot marks it read where it is, without opening '
        'it', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final booted = await bootInbox(
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
      expect(find.text('Unread · 1'), findsOneWidget);

      await tester.tap(
        find.bySemanticsLabel('Mark as read: Your application moved'),
      );
      await tester.pumpAndSettle();

      expect(booted.notifications.markedRead, <String>['n-1']);
      expect(currentLocation(tester), '/notifications');
      expect(find.text('Unread · 0'), findsOneWidget);
      expect(rowFill(tester, 'Your application moved'), BrandColors.white);
      expect(
        find.bySemanticsLabel('Mark as read: Your application moved'),
        findsNothing,
      );
      // With nothing unread, Mark all as read goes.
      expect(find.text('Mark all as read'), findsNothing);
      semantics.dispose();
    });

    testWidgets('opening its link marks it read too', (tester) async {
      final booted = await bootInbox(
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

      expect(booted.notifications.markedRead, <String>['n-1']);
      expect(currentLocation(tester), '/my-requests/req-1');
    });

    testWidgets('Mark all as read stays, and clears every dot', (tester) async {
      final booted = await bootInbox(
        tester,
        items: <ResidentNotification>[
          notification(id: 'a', title: 'First notice'),
          notification(id: 'b', title: 'Second notice'),
        ],
      );

      await tester.tap(find.text('Mark all as read'));
      await tester.pumpAndSettle();

      expect(booted.notifications.markAllCalls, 1);
      expect(find.text('Unread · 0'), findsOneWidget);
      expect(rowFill(tester, 'First notice'), BrandColors.white);
      expect(rowFill(tester, 'Second notice'), BrandColors.white);
    });

    test('every ink on an unread row keeps its contrast on the tint', () {
      final Color tint = unreadRowTint(unread: true);
      // Title, body, time, and each category's eyebrow ink.
      for (final Color ink in <Color>[
        BrandColors.ink,
        BrandColors.text,
        BrandColors.muted,
        BrandColors.blue,
        BrandColors.redInk,
        BrandColors.goldInk,
        BrandColors.green,
      ]) {
        expect(
          contrastRatio(ink, tint),
          greaterThanOrEqualTo(A11y.minBodyContrastRatio),
          reason: '$ink on the unread tint',
        );
      }
      // The dot is a meaningful graphic.
      expect(
        contrastRatio(BrandColors.blue, tint),
        greaterThanOrEqualTo(A11y.minLargeTextContrastRatio),
      );
    });
  });
}
