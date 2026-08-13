import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';

/// How complete the resident's master record is, as the **server** reports it.
///
/// Deliberately not computed on the device. A completeness figure derived
/// client-side counts the fields this build knows about, which drifts from the
/// fields the LGU actually requires the moment either changes — and it would
/// count staff-only fields a resident will never be shown.
@immutable
class ResidentProfileSummary {
  const ResidentProfileSummary({
    required this.completionPercent,
    required this.verificationTier,
    this.outstandingSections = const <String>[],
  });

  /// 0–100, as supplied by the server.
  final int completionPercent;

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
