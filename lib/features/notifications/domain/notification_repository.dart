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
  });

  final bool push;
  final bool sms;
  final bool email;

  /// Per-category switches, where the backend supports them.
  final Map<NotificationCategory, bool> categories;

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
  }) => NotificationPreferences(
    push: push ?? this.push,
    sms: sms ?? this.sms,
    email: email ?? this.email,
    categories: categories ?? this.categories,
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

  /// Registers this device so the LGU can reach it.
  ///
  /// The token is a stable device identifier: it is sent here and **never**
  /// logged, cached or put in an analytics event.
  Future<Result<void>> registerPushToken(String token);

  /// Stops notifications to this device — on sign-out, or when a resident turns
  /// push off.
  Future<Result<void>> unregisterPushToken();
}
