import '../../../core/session/access_level.dart';

/// Which verification screen a resident is looking at.
///
/// Chosen from the server's tier string and nothing the app invents.
/// [AccessLevel.fromVerificationTier] is the only door into [verified]: any
/// other string, including one this build has never heard of, stays on an
/// unverified face.
enum VerificationFace { pending, verified, needsCorrection, unverified }

/// Maps a server tier onto a status screen.
///
/// [fieldNotes] is the office's per-field correction list. It can open the
/// needs-correction face only for a tier that is already unverified and has
/// been named as rejected. An unknown tier never becomes verified, and it
/// does not become a correction task either — a word this build does not know
/// is the unverified face.
VerificationFace verificationFaceFor(
  String? tier, {
  bool fieldNotes = false,
}) {
  if (AccessLevel.fromVerificationTier(tier) == AccessLevel.verified) {
    return VerificationFace.verified;
  }
  switch (tier) {
    case 'pending':
      return VerificationFace.pending;
    case 'rejected':
      return VerificationFace.needsCorrection;
    case 'unverified':
      return fieldNotes
          ? VerificationFace.needsCorrection
          : VerificationFace.unverified;
    default:
      return VerificationFace.unverified;
  }
}
