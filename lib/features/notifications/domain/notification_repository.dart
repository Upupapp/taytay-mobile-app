import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import '../../services/domain/lgu_service.dart';

export '../../../core/api/server_value.dart';

/// What a notification in the inbox is about: its eyebrow, icon and ink.
///
/// ---
///
/// **A category is not a switch.** These name what a row is about, from the
/// Master Command's list; several have no notice the server sends (documents
/// needed, collecting assistance, referrals, event reminders). What a resident
/// can silence is [NotificationSwitch], one per notice the server sends and
/// honours (D-224). Public advisories and account security have no switch at
/// all: they are how the LGU reaches her in an emergency, or tells her somebody
/// signed in as her.
enum NotificationCategory {
  verificationUpdate('verification_update', 'Identity verification'),
  assistanceStatus('assistance_status', 'Assistance updates'),
  missingRequirement('missing_requirement', 'Documents needed'),
  releaseInstruction('release_instruction', 'Collecting assistance'),
  referralUpdate('referral_update', 'Referrals'),
  eventRegistration('event_registration', 'Event registrations'),
  eventReminder('event_reminder', 'Event reminders'),
  publicAdvisory('public_advisory', 'Public advisories'),
  accountSecurity('account_security', 'Account and security'),

  // The four below are notice types the API sends under their own `type`
  // (D-236). Before them they fell through to no category, so a document
  // request, a sector decision, a change to her office record and an office
  // reply all read "UPDATE" under the same chat bubble.
  documentRequest('issuance_request_updated', 'Document requests'),
  sectorApplication('sector_application_decided', 'Sector applications'),
  registryRecord(
    'registry_record_updated',
    'Changes to your record at the office',
  ),
  officeReply('message_received', 'Office replies');

  const NotificationCategory(this.wireValue, this.label);

  final String wireValue;

  /// Resident-facing name, the fallback for `notificationCategoryLabel`.
  final String label;
}

/// A notice the server sends a resident, and the one switch that silences it
/// (D-224).
///
/// ---
///
/// **Every value is a notice type the API both sends and honours.** Each is a
/// row of `me/notification-preferences` with the notice's own `type`, and the
/// server reads that row where the notice is made: `in_app` off writes no feed
/// row, `push` off sends no push (backend `0068`). A switch with no notice
/// behind it is not offered: it would leave a resident believing she silenced
/// something that was never going to be sent, or that will be sent anyway.
///
/// `balita` and `emergency` are preference types the API still accepts and
/// gates nothing with — nothing sends either — so they are not here, and this
/// app neither reads nor writes them.
///
/// The screen draws the switches in this order.
enum NotificationSwitch {
  verificationDecided('verification_decided'),
  assistanceRequestUpdated('assistance_request_updated'),
  issuanceRequestUpdated('issuance_request_updated'),
  eventRegistrationUpdated('event_registration_updated'),
  sectorApplicationDecided('sector_application_decided'),

  /// The office linked the account to its registry record, unlinked it, or
  /// corrected that record's name, sex, birth date or barangay (backend ADR
  /// 0016, D-235). In the app only, never pushed: only `in_app` decides it.
  registryRecordUpdated('registry_record_updated'),
  messageReceived('message_received');

  const NotificationSwitch(this.preferenceType);

  /// The `type` of its preference row, which is the notice's own `type`.
  final String preferenceType;
}

/// What a `verification_decided` notice says was decided (D-231, D-232).
///
/// ---
///
/// **The notice's own outcome, not the account's state today.** An old notice
/// that said "rejected" still says so after a later approval, so its icon is
/// never read from where the account stands now. The API sends it as the
/// notice's `outcome` (`approved`, `rejected`, `verified-in-person`); an
/// absent or unknown value is no outcome, drawn as a neutral identity notice,
/// never as pending: a `verification_decided` notice is a decision by its
/// type.
enum VerificationNoticeOutcome {
  /// Approved from the app, or verified in person at the office.
  verified,

  /// The review did not accept the ID.
  notAccepted,
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
    this.verificationOutcome,
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

  /// For a `verification_decided` notice, what its `outcome` says was
  /// decided; null for any other notice and for an outcome this build does
  /// not know (D-231, D-232).
  final VerificationNoticeOutcome? verificationOutcome;

  bool get isUnread => readAt == null;

  /// Whether tapping it opens a place: the map names a `target`
  /// (`DeepLink.targetKey`). A map holding only the notice's `type` is a
  /// routing hint this build could not turn into a place, so tapping it marks
  /// it read and opens nothing, rather than saying a link failed that was
  /// never there.
  bool get hasTarget => (target['target'] ?? '').trim().isNotEmpty;

  /// Redacted: a notification body can name a service a resident applied for,
  /// which is personal data.
  @override
  String toString() => 'ResidentNotification($id, unread: $isUnread)';
}

/// One row of `GET /me/notification-preferences`.
///
/// Each has `in_app` and `push`. SMS and email are not on this contract. A
/// missing row is on: both flags default to true.
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

/// The `me/notification-preferences` types this app reads and writes: one per
/// [NotificationSwitch], in its order. Any other row the server lists
/// (`balita`, `emergency`, a type a later API adds) is neither read nor sent.
final List<String> preferenceTypes = List<String>.unmodifiable(<String>[
  for (final NotificationSwitch kind in NotificationSwitch.values)
    kind.preferenceType,
]);

/// Which channels a resident wants to be contacted on, and about what.
///
/// ---
///
/// **Preferences live on the server, not on the device.** A resident who
/// silences SMS on one phone expects it silenced everywhere, and a device-local
/// preference would keep the LGU sending messages the resident asked it to stop
/// sending.
///
/// **A switch with no row is on.** The backend is the source of truth for what
/// a resident chose; an absent row means it has not been set, and the server
/// sends that notice. Reporting it off because a row was missing would say she
/// silenced something she did not.
@immutable
class NotificationPreferences {
  const NotificationPreferences({
    required this.push,
    required this.sms,
    required this.email,
    this.channels = const <ChannelPreference>[],
  });

  final bool push;
  final bool sms;
  final bool email;

  /// The server's rows for [preferenceTypes]. Empty until
  /// `GET /me/notification-preferences` answers.
  final List<ChannelPreference> channels;

  /// Whether the office still tells her of [kind]: on while either channel of
  /// its row is on, and when there is no row.
  ///
  /// A row with one channel off (an older app's push-only switch wrote one)
  /// reads on, because she is still told in the other. "Off" is said only when
  /// nothing of that notice reaches her.
  bool isOn(NotificationSwitch kind) {
    for (final ChannelPreference channel in channels) {
      if (channel.type == kind.preferenceType) {
        return channel.inApp || channel.push;
      }
    }
    return true;
  }

  /// A copy with [kind]'s row set to [on] in both channels — one switch
  /// silences the notice in the app and as a push — and every other row as it
  /// was.
  NotificationPreferences withSwitch(
    NotificationSwitch kind, {
    required bool on,
  }) {
    final ChannelPreference row = ChannelPreference(
      type: kind.preferenceType,
      inApp: on,
      push: on,
    );
    var found = false;
    final List<ChannelPreference> next = <ChannelPreference>[];
    for (final ChannelPreference channel in channels) {
      if (channel.type == kind.preferenceType) {
        found = true;
        next.add(row);
      } else {
        next.add(channel);
      }
    }
    if (!found) next.add(row);
    return copyWith(channels: List<ChannelPreference>.unmodifiable(next));
  }

  NotificationPreferences copyWith({
    bool? push,
    bool? sms,
    bool? email,
    List<ChannelPreference>? channels,
  }) => NotificationPreferences(
    push: push ?? this.push,
    sms: sms ?? this.sms,
    email: email ?? this.email,
    channels: channels ?? this.channels,
  );

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
    String? cursor,
  });

  /// How many of her notices are unread: `GET notifications/unread-count`.
  ///
  /// The server's count, never the unread rows of a first page — Home once
  /// counted the first 20 rows, so a resident with 30 unread saw a bell
  /// saying 20 or fewer (D-236).
  Future<Result<int>> unreadCount();

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
