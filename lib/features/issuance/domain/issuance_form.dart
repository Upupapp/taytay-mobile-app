/// What the form checks before anything leaves the phone.
///
/// The server checks the same things and its answer is the one that counts.
/// These are here so a resident learns what is missing now, on the screen they
/// are on, instead of after an upload over a prepaid connection.
library;

import '../../../core/documents/document_capture.dart';
import 'issuance_type.dart';

/// The server trims, then counts: 10 to 300 characters.
const int issuancePurposeMin = 10;
const int issuancePurposeMax = 300;

/// The server trims, then counts: up to 1000 characters.
const int issuanceNoteMax = 1000;

/// Why a purpose cannot be sent.
enum PurposeProblem { empty, tooShort, tooLong }

PurposeProblem? checkPurpose(String text) {
  final int length = text.trim().length;
  if (length == 0) return PurposeProblem.empty;
  if (length < issuancePurposeMin) return PurposeProblem.tooShort;
  if (length > issuancePurposeMax) return PurposeProblem.tooLong;
  return null;
}

String purposeProblemText(PurposeProblem problem) => switch (problem) {
  PurposeProblem.empty =>
    'Say what the document is for, for example "for a school enrolment".',
  PurposeProblem.tooShort =>
    'Say a little more: at least $issuancePurposeMin characters.',
  PurposeProblem.tooLong =>
    'Keep it to $issuancePurposeMax characters or fewer.',
};

/// The required files that have not been chosen yet, in the type's order.
List<IssuanceRequirement> missingRequiredFiles(
  IssuanceType type,
  Map<String, CapturedDocument> chosen,
) => <IssuanceRequirement>[
  for (final IssuanceRequirement requirement in type.requirements)
    if (requirement.required && !chosen.containsKey(requirement.code))
      requirement,
];

/// Everything wrong with a request before it is sent, or empty when it can go.
///
/// Each file was already checked against the type's `accepts` block when it
/// was chosen (`DocumentCapturePolicy.inspect`), so only its presence is
/// checked here.
({PurposeProblem? purpose, List<IssuanceRequirement> missing}) checkRequest(
  IssuanceType type, {
  required String purpose,
  required Map<String, CapturedDocument> files,
}) => (
  purpose: checkPurpose(purpose),
  missing: missingRequiredFiles(type, files),
);

/// Whether a resubmission carries anything: the server needs a file or a note.
bool resubmissionHasContent({
  required String note,
  required Map<String, CapturedDocument> files,
}) => note.trim().isNotEmpty || files.isNotEmpty;
