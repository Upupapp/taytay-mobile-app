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

/// Which text a consent was given to (`kind` on `POST /me/consents`, backend
/// `6c82f32`).
///
/// The Terms of Use and the Privacy Notice are two acts, each kept with its own
/// version and time, and the selfie's biometric consent is a third (backend
/// `44cae1b`). [unspecified] is a row an older app recorded under one tick for
/// both texts, or any row from before kinds existed: it never counts as any of
/// the three (D-208).
enum ConsentKind {
  terms('terms'),
  privacy('privacy'),
  biometric('biometric'),
  unspecified('unspecified');

  const ConsentKind(this.wireValue);

  /// The value on the wire.
  final String wireValue;

  /// What a row is called on the consents screen.
  String get label => switch (this) {
    ConsentKind.terms => 'Terms of Use',
    ConsentKind.privacy => 'Privacy Notice',
    ConsentKind.biometric => 'Selfie consent',
    ConsentKind.unspecified => 'Terms and Privacy Notice (earlier agreement)',
  };

  /// The sentence a row of this kind shows, under [version] when the server
  /// named one.
  String statement(String? version) {
    final String under = version ?? 'in force at the time';
    return switch (this) {
      ConsentKind.terms => 'Agreed to the Terms of Use, version $under',
      ConsentKind.privacy => 'Acknowledged the Privacy Notice, version $under',
      ConsentKind.biometric =>
        'Agreed that Taytay LGU may use your selfie, version $under',
      // An older app asked for both texts under one tick. The row is kept as
      // evidence; it is not agreement to either text now (D-208).
      ConsentKind.unspecified =>
        'Agreed to the Terms and the Privacy Notice together, version $under',
    };
  }

  /// An unknown or missing kind is [unspecified]: it is then asked for again,
  /// never taken as agreement to a text it may not name.
  static ConsentKind parse(Object? raw) {
    for (final ConsentKind kind in values) {
      if (kind.wireValue == raw) return kind;
    }
    return unspecified;
  }
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
    this.kind = ConsentKind.unspecified,
    this.grantedAt,
    this.withdrawnAt,
    this.isWithdrawable = false,
    this.withheldReason,
  });

  final String key;
  final String label;

  /// The text this consent was given to. A withdrawal names it, so that
  /// withdrawing the Terms never withdraws the selfie consent, or the reverse.
  final ConsentKind kind;

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
  String toString() =>
      'ConsentRecord(${kind.wireValue}, $key, active: $isActive)';
}

/// Where the account stands on one published text (`GET /me/consents/current`).
@immutable
class ConsentStanding {
  const ConsentStanding({
    this.publishedVersion,
    this.consent,
    this.upToDate = false,
  });

  /// Nothing published and nothing standing: what a missing block decodes to.
  static const ConsentStanding none = ConsentStanding();

  /// The version residents are asked to accept now. Null when none is
  /// published (for the biometric text: while it is the placeholder).
  final String? publishedVersion;

  /// The newest consent of this kind still standing, whatever its version.
  final ConsentRecord? consent;

  /// The server's verdict: a version is published and the standing consent
  /// names it. The app never works this out for itself.
  final bool upToDate;

  @override
  String toString() =>
      'ConsentStanding(published: ${publishedVersion != null}, '
      'upToDate: $upToDate)';
}

/// The account's standing on every text, as the server judged it.
@immutable
class ConsentState {
  const ConsentState({
    this.terms = ConsentStanding.none,
    this.privacy = ConsentStanding.none,
    this.biometric = ConsentStanding.none,
    this.unspecified = const <ConsentRecord>[],
  });

  /// The standings keyed by the kind they are for, as the server keys them.
  factory ConsentState.byKind(
    Map<ConsentKind, ConsentStanding> standings, {
    List<ConsentRecord> unspecified = const <ConsentRecord>[],
  }) => ConsentState(
    terms: standings[ConsentKind.terms] ?? ConsentStanding.none,
    privacy: standings[ConsentKind.privacy] ?? ConsentStanding.none,
    biometric: standings[ConsentKind.biometric] ?? ConsentStanding.none,
    unspecified: unspecified,
  );

  final ConsentStanding terms;
  final ConsentStanding privacy;
  final ConsentStanding biometric;

  /// Standing rows an older app recorded without naming the text. They make
  /// neither text up to date: those apps asked under one tick.
  final List<ConsentRecord> unspecified;

  ConsentStanding of(ConsentKind kind) => switch (kind) {
    ConsentKind.terms => terms,
    ConsentKind.privacy => privacy,
    ConsentKind.biometric => biometric,
    ConsentKind.unspecified => ConsentStanding.none,
  };

  @override
  String toString() =>
      'ConsentState(terms: ${terms.upToDate}, privacy: ${privacy.upToDate}, '
      'biometric: ${biometric.upToDate})';
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

  /// Where the account stands on each published text, as the server judges
  /// it (`GET /me/consents/current`).
  Future<Result<ConsentState>> loadConsentState();

  /// Withdraws the consent of [kind] given under version [key].
  ///
  /// Idempotency-keyed: withdrawing twice through a dropped connection should
  /// record one withdrawal, not two entries in a legal history. Withdrawing the
  /// [ConsentKind.biometric] consent also erases the account's selfies, in
  /// the same act on the server.
  Future<Result<ConsentRecord>> withdrawConsent({
    required String key,
    required String idempotencyKey,
    required ConsentKind kind,
  });

  /// Accepts [version] of the [kind] text. One call per text, even when two
  /// texts share a version string: each is its own act. The server clears
  /// `withdrawn_at` on a version accepted again.
  Future<Result<ConsentRecord>> acceptConsent({
    required String version,
    required ConsentKind kind,
  });

  /// Asks the office to correct something it holds.
  Future<Result<void>> requestDataCorrection({
    required String detail,
    required String idempotencyKey,
  });

  /// Closes the account (`POST /me/close`). It is not a request: the API
  /// closes it at once — sign-in disabled, profile details cleared, the
  /// digital ID revoked, device registrations and verification images
  /// removed — and the offices keep their own records (D-235,
  /// [AccountClosureCopy]).
  ///
  /// [permanent], [reason] and [idempotencyKey] stay off the wire: the route
  /// takes no body, and a second call is `409`.
  Future<Result<void>> requestAccountClosure({
    required bool permanent,
    required String reason,
    required String idempotencyKey,
  });
}

/// What the resident reads about closing her account, before the button, in
/// the confirmation and after it (D-235).
///
/// ---
///
/// **What `POST /me/close` does, and nothing it does not** (backend
/// `src/modules/users/routes.ts` and `repository.ts`, `docs/api/endpoints.md`).
/// It closes the account at once: the identity provider disables the sign-in;
/// the name, birth date, sex, mobile, email, address and profile photo are
/// cleared; a current digital ID is revoked; the ID photos and selfies sent
/// for verification are discarded; this and every other phone stop getting
/// notices; a household she heads in the app is removed, as is her place or
/// invitation in another. The account row itself stays, and the records the
/// offices keep about her are not touched. Nobody from the office calls: the
/// old words "the office will contact you" promised a step that does not
/// exist.
abstract final class AccountClosureCopy {
  static const String action = 'Close my account';

  /// Said on the page, before the button.
  static const String effects =
      'Closing your account takes effect at once, and you cannot sign in to '
      'it again. Your name, birth date, contact details, address and profile '
      'photo are removed from it, your digital ID is cancelled, and the ID '
      'photos and selfies you sent are deleted. Your phones stop getting '
      'notices from this app. If you head a household in the app, that '
      'household is removed. Records that Taytay LGU offices keep about you, '
      'such as your record at the MSWDO office and the requests you filed, '
      'stay with those offices. This cannot be undone in the app.';

  static const String confirmTitle = 'Close your account?';

  /// The confirmation's consequence.
  static const String confirm =
      'Your account closes now and you cannot sign in to it again. Your digital '
      'ID is cancelled, and your details, photos and ID pictures are removed '
      'from the account. Records that Taytay LGU offices keep about you stay '
      'with them. This cannot be undone in the app.';

  /// After the API answered that it closed.
  static const String closed =
      'Your account is closed. You cannot sign in to it again, and your '
      'digital ID is cancelled. Records that Taytay LGU offices keep about you '
      'stay with them.';

  /// A `409`: it was closed already, by an earlier try.
  static const String alreadyClosed =
      'Your account is already closed. You cannot sign in to it again.';

  /// A timeout or a dropped connection after sending.
  static const String notConfirmed =
      'We could not confirm that your account was closed. Trying again is '
      'safe: an account is closed only once.';

  static const String notClosed =
      'Your account was not closed. Nothing has changed, and you can try '
      'again.';
}
