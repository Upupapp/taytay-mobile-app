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
  /// Maps a server `status`, failing closed.
  ///
  /// An unrecognised state is `null` and therefore not presentable. A credential
  /// this build cannot interpret must never be rendered as a working ID: the
  /// resident would find out at a counter, in front of a clerk, that the app had
  /// guessed.
  static CredentialLifecycleState? fromWire(String? value) {
    if (value == null) return null;
    for (final CredentialLifecycleState state
        in CredentialLifecycleState.values) {
      if (state.name.toLowerCase() == value.toLowerCase()) return state;
    }
    return null;
  }

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
/// A QR payload and the moment it stops being worth showing.
///
/// **The expiry is carried, not discarded.** This method used to return a bare
/// string, which meant the screen had no way to know when the code it was
/// holding had died — and a QR that will not scan is discovered by a resident
/// standing in front of a clerk, at the front of a queue. The server mints it
/// with a TTL and says so; the app honours that and re-requests rather than
/// keeping one.
///
/// **Never written to disk.** A QR credential cached to storage is a credential
/// that can be lifted out of a device backup, and it is short-lived precisely so
/// that it does not need to be.
@immutable
class PresentationArtifact {
  const PresentationArtifact({required this.payload, this.expiresAt});

  final String payload;
  final DateTime? expiresAt;

  /// Whether this is still worth putting in front of a scanner.
  ///
  /// Read against the device clock, which is the one place that is acceptable:
  /// the consequence of being wrong is re-requesting a code, and the server
  /// checks it again anyway. Nothing is *granted* on the strength of this.
  bool isLive(DateTime now) {
    final DateTime? expiry = expiresAt;
    return expiry == null || now.toUtc().isBefore(expiry.toUtc());
  }

  /// Redacted: this is credential material (Article 5.2).
  @override
  String toString() => 'PresentationArtifact(expiresAt: $expiresAt)';
}

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
  Future<Result<PresentationArtifact>> requestPresentationArtifact();
}
