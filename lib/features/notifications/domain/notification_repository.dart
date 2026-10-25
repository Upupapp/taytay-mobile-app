import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import '../../services/domain/lgu_service.dart';

export '../../../core/api/server_value.dart';

/// What a notification is about.
///
/// ---
///
/// **The categories are the ones a resident would switch off separately.** They
/// come from the Master Command's list, and each maps to a workflow the LGU
/// actually runs — which is what makes a preference toggle meaningful rather
/// than a wall of switches nobody reads.
///
/// [isCritical] marks the ones this app will not offer to silence. A resident
/// can turn off event reminders; they cannot turn off a security notice about
/// their own account, and an emergency public advisory is the reason a
/// municipality has a notification channel at all.
enum NotificationCategory {
  verificationUpdate('verification_update', 'Identity verification'),
  assistanceStatus('assistance_status', 'Assistance updates'),
  missingRequirement('missing_requirement', 'Documents needed'),
  releaseInstruction('release_instruction', 'Collecting assistance'),
  referralUpdate('referral_update', 'Referrals'),
  eventRegistration('event_registration', 'Event registrations'),
  eventReminder('event_reminder', 'Event reminders'),
  publicAdvisory('public_advisory', 'Public advisories', isCritical: true),
  accountSecurity('account_security', 'Account and security', isCritical: true);

  const NotificationCategory(
    this.wireValue,
    this.label, {
    this.isCritical = false,
  });

  final String wireValue;

  /// Resident-facing name, used on the preference row.
  final String label;

  /// Whether this app refuses to offer a switch for it.
  final bool isCritical;
}

/// A message the LGU sent to this resident.
@immutable
class ResidentNotification {
  const ResidentNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.sentAt,
    required this.readAt,
    this.category,
    this.target = const <String, String>{},
  });

  final String id;

  /// Copy composed by the LGU for the resident. Rendered as sent — unlike an
  /// operator-facing error `message`, this is addressed to them.
  final String title;
  final String body;

  final DateTime? sentAt;

  /// `null` while unread.
  final DateTime? readAt;

  final ServerValue<NotificationCategory>? category;

  /// Where tapping it goes, as a `DeepLink` payload.
  ///
  /// **A destination, not content.** It carries a target name and at most an
  /// opaque id; `DeepLink.resolve` rejects a payload with a personal key rather
  /// than sanitising it, and the screen it opens fetches the detail itself under
  /// the live session. That is the Master Command's rule — authorized detail is
  /// fetched after the tap, never read from the message.
  final Map<String, String> target;

  bool get isUnread => readAt == null;

  bool get hasTarget => target.isNotEmpty;

  /// Redacted: a notification body can name a service a resident applied for,
  /// which is personal data.
  @override
  String toString() => 'ResidentNotification($id, unread: $isUnread)';
}

/// One row of `GET /me/notification-preferences`.
///
/// The spec publishes `verification_decided`, `message_received`, `balita`, and
/// `emergency`. Each has `in_app` and `push`. SMS and email are not on this
/// contract. A missing row is on: both flags default to true.
@immutable
class ChannelPreference {
  const ChannelPreference({
    required this.type,
    required this.inApp,
    required this.push,
  });

  final String type;
  final bool inApp;
  final bool push;

  @override
  String toString() => 'ChannelPreference($type, inApp: $inApp, push: $push)';
}

/// Types `GET /me/notification-preferences` publishes, in wire order.
const List<String> preferenceTypes = <String>[
  'verification_decided',
  'message_received',
  'balita',
  'emergency',
];

/// Whether [type] is on. An absent row is on.
bool preferenceEnabled(List<ChannelPreference> channels, String type) {
  for (final ChannelPreference channel in channels) {
    if (channel.type == type) return channel.push;
  }
  return true;
}

/// A copy of [channels] with [type] set.
///
/// [pushOnly] keeps `in_app` when the row already exists. Balita and emergency
/// write both flags, because the settings row is the whole preference.
List<ChannelPreference> writePreference(
  List<ChannelPreference> channels, {
  required String type,
  required bool on,
  bool pushOnly = false,
}) {
  var found = false;
  final List<ChannelPreference> next = <ChannelPreference>[
    for (final ChannelPreference channel in channels)
      if (channel.type == type)
        ChannelPreference(
          type: type,
          inApp: pushOnly ? channel.inApp : on,
          push: on,
        )
      else
        channel,
  ];
  for (final ChannelPreference channel in next) {
    if (channel.type == type) found = true;
  }
  if (!found) {
    next.add(
      ChannelPreference(type: type, inApp: pushOnly ? true : on, push: on),
    );
  }
  return next;
}

/// Which channels a resident wants to be contacted on, and about what.
///
/// ---
///
/// **Preferences live on the server, not on the device.** A resident who
/// silences SMS on one phone expects it silenced everywhere, and a device-local
/// preference would keep the LGU sending messages the resident asked it to stop
/// sending.
///
/// **A category absent from [categories] is treated as on.** The backend is the
/// source of truth for what a resident chose; an absent entry means it has not
/// been set, and defaulting a municipal advisory to off because a field was
/// missing is the wrong failure.
@immutable
class NotificationPreferences {
  const NotificationPreferences({
    required this.push,
    required this.sms,
    required this.email,
    this.categories = const <NotificationCategory, bool>{},
    this.channels = const <ChannelPreference>[],
  });

  final bool push;
  final bool sms;
  final bool email;

  /// Per-category switches, where the backend supports them.
  final Map<NotificationCategory, bool> categories;

  /// The spec list. Empty until `GET /me/notification-preferences` answers.
  final List<ChannelPreference> channels;

  /// Whether [category] is currently on.
  ///
  /// Always true for a critical category — the app does not offer to silence a
  /// security notice or an emergency advisory, so it does not report one as
  /// silenced either.
  bool isEnabled(NotificationCategory category) {
    if (category.isCritical) return true;
    return categories[category] ?? true;
  }

  /// The categories a resident may actually switch.
  static List<NotificationCategory> get switchable => NotificationCategory
      .values
      .where((category) => !category.isCritical)
      .toList(growable: false);

  NotificationPreferences copyWith({
    bool? push,
    bool? sms,
    bool? email,
    Map<NotificationCategory, bool>? categories,
    List<ChannelPreference>? channels,
  }) => NotificationPreferences(
    push: push ?? this.push,
    sms: sms ?? this.sms,
    email: email ?? this.email,
    categories: categories ?? this.categories,
    channels: channels ?? this.channels,
  );

  /// A copy with one category switched.
  ///
  /// Refuses to record a critical category as off — the UI does not offer it,
  /// and a caller that tried would be writing a preference the LGU must ignore.
  NotificationPreferences withCategory(
    NotificationCategory category, {
    required bool enabled,
  }) {
    if (category.isCritical) return this;
    return copyWith(
      categories: <NotificationCategory, bool>{
        ...categories,
        category: enabled,
      },
    );
  }

  @override
  String toString() => 'NotificationPreferences(push: $push)';
}

/// The resident's own notifications and channel preferences.
///
/// The `Notification` module owns "outbound notification dispatch, delivery
/// receipts, per-resident channel preferences" and explicitly does **not** own
/// "why a notification was triggered" — so this app never asks it for the reason
/// behind a message, and never infers one.
abstract interface class NotificationRepository {
  Future<Result<Paginated<ResidentNotification>>> listOwn({
    int page,
    int perPage,
  });

  /// Marks one of the resident's own notifications as read.
  ///
  /// Naturally idempotent — marking a read notification read again is a no-op —
  /// so no idempotency key is required.
  Future<Result<void>> markRead(String id);

  /// Marks everything read.
  ///
  /// Idempotent for the same reason, and offered because a resident returning
  /// after a week should not have to tap through forty rows to clear a badge.
  Future<Result<void>> markAllRead();

  Future<Result<NotificationPreferences>> loadPreferences();

  Future<Result<void>> updatePreferences(NotificationPreferences preferences);

  /// Registers this device so the LGU can reach it, returning the server's own
  /// id for the registration.
  ///
  /// **The id is the whole point of the return value.** Before TAB 02 this
  /// returned nothing and the response was discarded, so the app created a
  /// registration it had no way to name afterwards — and therefore no way to
  /// withdraw. That was F27, and it read as "the API has no route for this"
  /// when the API had one all along and this client was throwing away its
  /// argument.
  ///
  /// The caller passes the id to `SessionController.rememberDeviceRegistration`,
  /// which holds it for exactly as long as the token that can revoke it.
  ///
  /// The push token is a stable device identifier: it is sent here and **never**
  /// logged, cached or put in an analytics event.
  Future<Result<String>> registerPushToken(String token);
}
