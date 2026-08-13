import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';

/// The LGU ID lifecycle.
///
/// Taken from the committed boundary map, which states the `Credential` module
/// owns "LGU ID lifecycle (application → review → approval → issuance → active →
/// suspended → expired/revoked)".
///
/// **No wire values are assigned.** The states are committed evidence; their
/// serialised spellings are not published, and guessing them would be inventing
/// schema. Mapping happens in `data/` when the module ships, and unrecognised
/// values will be preserved with the same `ServerValue` pattern the catalogue
/// uses.
enum CredentialLifecycleState {
  applied,
  underReview,
  approved,
  issued,
  active,
  suspended,
  expired,
  revoked;

  /// Whether a credential in this state is one the resident can present.
  ///
  /// A *presentation* question — what to render — not a validity verdict. The
  /// backend decides validity cryptographically; this app may display a
  /// credential but never decides one is genuine (CLAUDE.md Article 5.8).
  bool get isPresentable =>
      this == CredentialLifecycleState.active ||
      this == CredentialLifecycleState.issued;
}

/// A credential as the server described it.
///
/// Holds no signing material, no private key and no QR payload secret. The
/// `Credential` module owns "QR credential material"; this app receives whatever
/// artifact the server issues and renders it. It never assembles a credential
/// from profile fields, and never derives one.
@immutable
class ResidentCredential {
  const ResidentCredential({
    required this.id,
    required this.state,
    required this.rawState,
    this.issuedAt,
    this.expiresAt,
  });

  final String id;

  /// `null` when this build does not recognise [rawState].
  final CredentialLifecycleState? state;

  /// Exactly what the server sent, preserved for support and logging.
  final String rawState;

  final DateTime? issuedAt;
  final DateTime? expiresAt;

  /// Redacted: a credential identifier is pseudonymous and does not belong in a
  /// log line alongside anything else.
  @override
  String toString() => 'ResidentCredential(state: $rawState)';
}

/// The resident's own LGU digital ID.
///
/// Backed by the `Credential` module, which the committed boundary map lists as
/// planned. No endpoint exists.
abstract interface class CredentialRepository {
  /// The signed-in resident's own credential, if the LGU has issued one.
  Future<Result<ResidentCredential?>> loadOwnCredential();

  /// Requests a fresh presentation artifact — the short-lived payload a verifier
  /// scans.
  ///
  /// Modelled as a **server call rather than a local render** because the
  /// artifact must be verifiable and revocable. A QR the device generates from
  /// stored data is a QR that keeps working after the LGU revokes the
  /// credential, which is the failure mode a verification system exists to
  /// prevent.
  Future<Result<String>> requestPresentationArtifact();
}
