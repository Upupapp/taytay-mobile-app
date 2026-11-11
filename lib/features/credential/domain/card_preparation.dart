import 'package:flutter/foundation.dart';

import '../../profile/domain/resident_profile_detail.dart';
import '../../verification/domain/verification_status_detail.dart';

/// What the app already knows about a verified resident's way to a card, for
/// the "being prepared" page (design `IDStatus.dc.html`, D-207).
///
/// Every field is a timestamp or a value the server sent, read from the same
/// two places the verification screen reads them: `GET /me` and the current
/// verification request. A missing one is null, and its step is drawn without
/// a date. Nothing here is a card state: `GET /me/digital-id` sends only
/// `active`, `suspended` and `revoked`, and "being prepared" is this app's
/// reading of no card at all.
@immutable
class CardPreparation {
  const CardPreparation({
    this.accountCreatedAt,
    this.sentAt,
    this.idType,
    this.verifiedAt,
  });

  /// Builds the steps' dates from what was read, either of which may be
  /// missing.
  ///
  /// The request's dates and ID type are used only when that request is the
  /// verified one: a later or different request's `submitted_at` would date
  /// a step the resident did not take then.
  factory CardPreparation.from({
    ResidentProfileDetail? profile,
    VerificationStatusDetail? verification,
  }) {
    final bool approved = verification != null && verification.isVerified;
    final String idType = approved ? (verification.idType ?? '').trim() : '';
    return CardPreparation(
      accountCreatedAt: profile?.createdAt,
      sentAt: approved ? verification.submittedAt : null,
      idType: idType.isEmpty ? null : idType,
      verifiedAt: approved ? verification.reviewedAt : null,
    );
  }

  /// Nothing read: every step without a date.
  static const CardPreparation unknown = CardPreparation();

  /// `created_at` on `GET /me`.
  final DateTime? accountCreatedAt;

  /// `submitted_at` on the approved verification request.
  final DateTime? sentAt;

  /// `id_type` on the approved verification request, as the server sent it.
  /// A kind of document, never its number.
  final String? idType;

  /// `reviewed_at` on the approved verification request.
  final DateTime? verifiedAt;

  @override
  bool operator ==(Object other) =>
      other is CardPreparation &&
      other.accountCreatedAt == accountCreatedAt &&
      other.sentAt == sentAt &&
      other.idType == idType &&
      other.verifiedAt == verifiedAt;

  @override
  int get hashCode => Object.hash(accountCreatedAt, sentAt, idType, verifiedAt);

  /// Says which steps are dated, not when: the dates are the resident's own
  /// history and do not belong in a log line.
  @override
  String toString() =>
      'CardPreparation(created: ${accountCreatedAt != null}, '
      'sent: ${sentAt != null}, verified: ${verifiedAt != null})';
}
