import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';

/// What the backend and LGU policy actually allow a resident to do to their own
/// account.
///
/// ---
///
/// **Every flag defaults to false, and the UI shows nothing it cannot honour.**
/// The Master Command is explicit — deletion, consent withdrawal and correction
/// paths exist "only if backend/policy supports" — and the acceptance criterion
/// is that no unsupported legal promise is invented in the UI.
///
/// That is stricter than it sounds. A "Delete my account" button on a government
/// app is a statement about what the LGU will do with a civil record, and the
/// answer is genuinely not the app's to give: retention of a resident record is
/// set by law and by the municipality's own rules, not by a client. Showing the
/// button and hoping the server refuses would be the app making a promise on the
/// LGU's behalf.
@immutable
class AccountControls {
  const AccountControls({
    this.canRequestDataCorrection = false,
    this.canRequestDeactivation = false,
    this.canRequestDeletion = false,
    this.canWithdrawConsent = false,
    this.requiresReauthentication = false,
    this.deletionPolicyNote,
  });

  /// Nothing offered. What an absent block decodes to, and the default.
  static const AccountControls none = AccountControls();

  /// Asking the office to correct a canonical field.
  final bool canRequestDataCorrection;

  /// Asking for the account to be switched off, leaving the civil record.
  final bool canRequestDeactivation;

  /// Asking for erasure. Separate from deactivation because they are different
  /// requests with different legal answers, and an app that conflates them
  /// tells a resident they asked for something they did not.
  final bool canRequestDeletion;

  final bool canWithdrawConsent;

  /// Whether the server wants the resident to prove who they are again before a
  /// sensitive account action.
  ///
  /// **The server's demand, not the app's idea.** Re-authentication is a
  /// security control the backend owns; a client that decided when to ask would
  /// be inventing an authorization step, and one that never asked would be
  /// ignoring one.
  final bool requiresReauthentication;

  /// What the office says about retention, in its own words.
  ///
  /// Rendered verbatim when present, and **nothing is written in its place when
  /// absent** — a retention period this app guessed would be a legal statement
  /// nobody authorised.
  final String? deletionPolicyNote;

  bool get hasAnyAccountRequest =>
      canRequestDataCorrection || canRequestDeactivation || canRequestDeletion;

  @override
  String toString() =>
      'AccountControls(correction: $canRequestDataCorrection, '
      'deletion: $canRequestDeletion)';
}

/// One thing the resident agreed to, and when.
///
/// ---
///
/// **A consent record is evidence.** Under RA 10173 the LGU has to be able to
/// show what a data subject agreed to and when; this is the resident's view of
/// that same record, which is what makes the transparency real rather than a
/// paragraph in a privacy notice.
@immutable
class ConsentRecord {
  const ConsentRecord({
    required this.key,
    required this.label,
    required this.statement,
    this.grantedAt,
    this.withdrawnAt,
    this.isWithdrawable = false,
    this.withheldReason,
  });

  final String key;
  final String label;

  /// The full sentence the resident agreed to, as the office wrote it.
  final String statement;

  final DateTime? grantedAt;

  /// Set once withdrawn. A withdrawn consent stays in the list — the record is
  /// the point, and removing the row would erase the evidence it exists to
  /// provide.
  final DateTime? withdrawnAt;

  /// Whether this one may be withdrawn from the app.
  ///
  /// False for consents the LGU cannot operate without — processing a resident's
  /// own application, for instance. Those are shown with [withheldReason] rather
  /// than a switch that would fail.
  final bool isWithdrawable;

  /// Why it cannot be withdrawn, in the office's words.
  final String? withheldReason;

  bool get isActive => withdrawnAt == null;

  /// Redacted of the statement: it is long, and this type is reachable from a
  /// log line.
  @override
  String toString() => 'ConsentRecord($key, active: $isActive)';
}

/// The resident's own account controls and consent history.
///
/// **Requests, never commands.** Every method here asks the office for
/// something; none of them changes a civil record directly. The naming is
/// deliberate — `requestDeletion`, not `deleteAccount` — because a client that
/// reads as though it deletes will eventually be believed.
abstract interface class AccountControlsRepository {
  /// What this resident may ask for, according to backend and policy.
  Future<Result<AccountControls>> loadControls();

  /// The consent history the LGU holds for this resident.
  Future<Result<List<ConsentRecord>>> listConsents();

  /// Withdraws one consent.
  ///
  /// Idempotency-keyed: withdrawing twice through a dropped connection should
  /// record one withdrawal, not two entries in a legal history.
  Future<Result<ConsentRecord>> withdrawConsent({
    required String key,
    required String idempotencyKey,
  });

  /// Asks the office to correct something it holds.
  Future<Result<void>> requestDataCorrection({
    required String detail,
    required String idempotencyKey,
  });

  /// Asks for the account to be deactivated or erased.
  ///
  /// One method with a [permanent] flag rather than two, because the server
  /// decides what each means and the app must not imply a difference the office
  /// has not defined.
  Future<Result<void>> requestAccountClosure({
    required bool permanent,
    required String reason,
    required String idempotencyKey,
  });
}
