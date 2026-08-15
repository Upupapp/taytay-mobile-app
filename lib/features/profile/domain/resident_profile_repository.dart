import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import 'resident_profile_detail.dart';

/// What the server says about the resident's own record, in summary.
///
/// ---
///
/// **There is no completion percentage here, and adding one needs a contract.**
/// TAB 12 removed the field it used to carry. Two reasons, in order:
///
/// 1. **No authoritative definition exists.** The `ResidentProfile` module
///    publishes no endpoint and no notion of "complete", so any figure would be
///    computed from the fields *this build* happens to know — which drifts from
///    what the LGU actually requires the moment either changes, and would count
///    staff-only fields a resident will never be shown.
/// 2. **A number invites the wrong behaviour.** "Your profile is 60% complete"
///    reads as an instruction on a government service, and a resident who
///    chases it to 100% may be handing over data the LGU never asked them for —
///    the opposite of minimisation.
///
/// If the backend ever defines completeness, it arrives as a server-supplied
/// field here and the app renders what it is told. Until then the screen shows
/// what is on file and what is not, which is the same information without the
/// false precision.
@immutable
class ResidentProfileSummary {
  const ResidentProfileSummary({
    required this.verificationTier,
    this.outstandingSections = const <String>[],
  });

  /// The server's verification tier string, unmapped. `AccessLevel
  /// .fromVerificationTier` is the only thing that interprets it, and it fails
  /// closed.
  final String verificationTier;

  /// Sections the server says still need input, by its own identifiers.
  final List<String> outstandingSections;
}

/// The resident's own master record.
///
/// **Read-your-own-record only.** There is no method here that takes another
/// resident's identifier: the backend's `ResidentProfile` module owns the master
/// record and a resident may only ever reach their own (backend CLAUDE.md
/// Article 5.3). An API that cannot express "fetch someone else" cannot be
/// misused into doing so.
///
/// **Fields are not modelled here yet, on purpose.** The module is *planned* in
/// the committed boundary map — it owns "resident master record, demographics,
/// addresses, household links, verification tier" — but publishes no endpoint
/// and no schema. Modelling demographics now would mean inventing field names.
/// What is modelled is the *summary* the app needs to route and explain, which
/// is derivable from concepts the committed map already names.
///
/// When the module ships, detail types are added here and mapped in `data/`.
/// Screens fetch the section they display; nothing is cached in session state
/// (CLAUDE.md Article 5.1).
abstract interface class ResidentProfileRepository {
  /// The signed-in resident's own profile summary.
  Future<Result<ResidentProfileSummary>> loadOwnSummary();

  /// The signed-in resident's own record, field by field.
  ///
  /// Takes no identifier, and cannot: the endpoint is `/me/profile` and
  /// ownership is structural rather than a filter someone could forget to
  /// apply. There is no overload that fetches somebody else, so no caller can
  /// be talked into one (acceptance 3).
  Future<Result<ResidentProfileDetail>> loadOwnDetail();

  /// Changes the contact details the resident owns.
  ///
  /// Maps to `PATCH /api/v1/me/profile`, which the committed matrix restricts
  /// to **contact fields only** with the note *"a citizen may not edit their own
  /// eligibility-bearing fields"*. [ContactDetailsUpdate] can express nothing
  /// else, so this method cannot be used to attempt a canonical change even by
  /// mistake — the restriction is in the type, not only in the server.
  ///
  /// [idempotencyKey] is required: a contact change is a state change a mobile
  /// client will retry on a dropped connection.
  Future<Result<void>> updateContactDetails({
    required ContactDetailsUpdate update,
    required String idempotencyKey,
  });

  /// Submits a correction or completion to the resident's own record.
  ///
  /// [idempotencyKey] is required, not optional: a profile submission is a
  /// state change a mobile client will retry on a dropped connection, and the
  /// contract's replay guarantee is what stops that becoming two submissions
  /// (conventions §7).
  Future<Result<void>> submitOwnUpdate({
    required Map<String, Object?> changes,
    required String idempotencyKey,
  });
}
