import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';

/// One step of the guided registration flow.
///
/// ---
///
/// ## Why a wizard and not one long form
///
/// Registration asks a resident for their identity. A single screen carrying
/// name, birth date, address, consent checkboxes and two file pickers is
/// abandoned at a far higher rate than the same fields staged, and — more
/// importantly here — it presents consent as one more checkbox in a wall of
/// inputs rather than as a decision. Under RA 10173 consent must be *informed*;
/// it cannot be informed if the explanation arrives as fine print beside twelve
/// other controls.
///
/// ## Why these steps, in this order
///
/// The order follows the committed backend contract
/// (`Taytay_Rizal_LGUIDS_Backend@896cec9`, `docs/contracts/frontend-endpoint-matrix.md`),
/// which has **no account-creation endpoint**. A citizen account comes into
/// existence through the one-time-code exchange; identity details are then
/// carried by a *verification submission*, not by an account payload:
///
/// * `POST /api/v1/auth/otp` `{mobile_number}` → `202`
/// * `POST /api/v1/auth/otp/verify` `{mobile_number,code}` → `{token,…}`
/// * `GET /api/v1/me/verification` → tier + outstanding steps
/// * `POST /api/v1/me/verification/submissions` → `202`
///
/// So contact comes first because it is what creates the account; personal
/// details and address come next because they are what the LGU matches a
/// resident record on; consent comes before anything sensitive is collected;
/// and the document and selfie steps come last because they are optional,
/// server-gated, and the most intrusive.
enum RegistrationStep {
  /// Mobile number — the account identifier the contract authenticates on.
  contact('Contact details', 'How Taytay LGU reaches you'),

  /// One-time code. Present because the committed contract authenticates
  /// citizens this way; it is not an invention of this client.
  verifyCode('Confirm your number', 'Enter the code we sent'),

  /// The minimum needed to match an existing resident record.
  personalDetails('Your details', 'Only what is needed to find your record'),

  /// Barangay and street address within Taytay.
  address('Your address', 'Where in Taytay you live'),

  /// Terms of Use, Privacy Notice and explicit acknowledgements.
  consent('Terms and privacy', 'What you are agreeing to'),

  /// Government ID. Shown only when the server says it is required.
  identityDocument('Proof of identity', 'A valid government-issued ID'),

  /// Selfie / liveness. Shown only when the server says it is required **and**
  /// biometric consent was given.
  faceCapture('Photo of you', 'Confirms the ID belongs to you'),

  /// Everything collected, before anything is sent.
  review('Review', 'Check before you submit'),

  /// The submission itself.
  submitting('Submitting', 'Sending to Taytay LGU'),

  /// Outcome and next step.
  status('Status', 'What happens next');

  const RegistrationStep(this.title, this.subtitle);

  final String title;
  final String subtitle;

  /// Steps a resident actively fills in — the ones counted in "step 3 of 7".
  ///
  /// `submitting` and `status` are outcomes, not inputs, so counting them would
  /// tell a resident there is more to do than there is.
  bool get isInputStep =>
      this != RegistrationStep.submitting && this != RegistrationStep.status;
}

/// Which optional steps this build may show.
///
/// ---
///
/// **Deny by default, and only the server may widen it.**
///
/// Every flag is `false` unless a server response says otherwise. Two reasons.
/// A document or selfie step that this client decides to show on its own is
/// this client deciding to collect biometric data — the most sensitive artifact
/// in the system (backend gap **G-18**) — without the LGU having asked for it.
/// And whether a given resident needs a document at all is a matching decision
/// only the server can make: someone already in the resident register may need
/// nothing.
///
/// The authoritative source is `GET /api/v1/me/verification`, which the
/// committed matrix describes as returning "tier + outstanding steps". That
/// endpoint is `planned`, so today every flag stays false and both steps are
/// skipped — which is the correct fail-closed behaviour, not a placeholder.
@immutable
class RegistrationCapabilities {
  const RegistrationCapabilities({
    this.requiresIdentityDocument = false,
    this.requiresFaceCapture = false,
    this.acceptsSubmissions = false,
  });

  /// Nothing optional is collected and nothing can be submitted.
  static const RegistrationCapabilities denied = RegistrationCapabilities();

  /// The server asked for a government ID.
  final bool requiresIdentityDocument;

  /// The server asked for a selfie / liveness capture.
  final bool requiresFaceCapture;

  /// The verification submission endpoint is available to this build.
  final bool acceptsSubmissions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RegistrationCapabilities &&
          other.requiresIdentityDocument == requiresIdentityDocument &&
          other.requiresFaceCapture == requiresFaceCapture &&
          other.acceptsSubmissions == acceptsSubmissions);

  @override
  int get hashCode => Object.hash(
    requiresIdentityDocument,
    requiresFaceCapture,
    acceptsSubmissions,
  );

  @override
  String toString() =>
      'RegistrationCapabilities(doc: $requiresIdentityDocument, '
      'face: $requiresFaceCapture, submissions: $acceptsSubmissions)';
}

/// A barangay of Taytay, Rizal.
///
/// [psgcCode] is deliberately nullable and currently always `null`. The staff
/// console records the reason in its own model and the backend repeats it as
/// gap **G-11**: *a wrong PSGC code is worse than an absent one, because DSWD
/// reporting keys off it*. This client therefore never invents one, and the
/// authoritative list arrives from `GET /api/v1/barangays` when that lands.
@immutable
class Barangay {
  const Barangay({
    required this.id,
    required this.name,
    this.code,
    this.psgcCode,
  });

  /// Server-issued UUID.
  final String id;

  /// The stable slug — `brgy-san-juan` — and **the value `POST me/kyc` accepts**.
  ///
  /// Two identifiers rather than one because the server has two and they answer
  /// different questions: the UUID names the row, and the code is what a
  /// resident's KYC claim is filed against. The auto-increment primary key is
  /// neither, is published by nothing, and is the reason this list did not exist
  /// until the backend added `GET barangays` — an applicant was asked for a key
  /// no endpoint gave out.
  final String? code;

  final String name;
  final String? psgcCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Barangay && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Barangay($name)';
}

/// The consents a resident gives, each recorded separately.
///
/// Bundling them into one "I agree" is what makes consent unfree: a resident who
/// wants a municipal service but not biometric processing has no way to express
/// that, and the LGU cannot show which specific processing was agreed to.
/// RA 10173 requires consent to be freely given, specific and informed.
enum ConsentKind {
  termsOfUse('Terms of Use', 'The rules for using this app.', required: true),
  privacyNotice(
    'Privacy Notice',
    'What Taytay LGU collects, why, how long it is kept and who may see it.',
    required: true,
  ),
  identityProcessing(
    'Processing of my identity information',
    'Lets Taytay LGU match what you enter against the municipal resident '
        'register to confirm you are a resident.',
    required: true,
  ),
  biometricProcessing(
    'Processing of my photo for identity checking',
    'Lets Taytay LGU compare your photo with your ID. Biometric information '
        'is sensitive personal information under the Data Privacy Act.',
    required: false,
  );

  const ConsentKind(this.label, this.explanation, {required this.required});

  final String label;
  final String explanation;

  /// Whether registration can proceed without it.
  ///
  /// [biometricProcessing] is **not** required: it is only asked for when the
  /// server requires a face capture, and a resident who declines it simply does
  /// not take that route. Consent that cannot be refused is not consent.
  final bool required;
}

/// A file the resident chose, described without its bytes.
///
/// The bytes stay where the picker put them. This type carries a local
/// reference, a size and a declared kind so the review step can describe what
/// will be sent — nothing here is loggable and nothing here is the image.
@immutable
class SelectedUpload {
  const SelectedUpload({
    required this.localReference,
    required this.byteSize,
    required this.mimeType,
  });

  /// Opaque local handle. Never a resident-visible path, never logged.
  final String localReference;

  final int byteSize;
  final String mimeType;

  /// Redacted: even a file name can carry a person's name.
  @override
  String toString() => 'SelectedUpload($mimeType, $byteSize bytes)';
}

/// Everything the wizard has collected so far.
///
/// ---
///
/// **Data minimisation is the shape of this class.** It holds the smallest set
/// that lets the LGU match a person to an existing resident record:
///
/// * given, middle and family name, plus suffix;
/// * date of birth;
/// * barangay, and street address within it;
/// * the mobile number the account authenticates on.
///
/// Fields the staff console's own `Resident` model carries are deliberately
/// **absent**: `sex`, `civilStatus`, `sectors`, `monthlyIncome`,
/// `philsysLastFour`, `householdId`. None of them narrows a name-and-birth-date
/// match, several are sensitive personal information under RA 10173 §13, and the
/// committed contract is explicit that a citizen *may not edit their own
/// eligibility-bearing fields* (`PATCH /api/v1/me/profile` — "contact fields
/// only"). Collecting them here would be collecting data this client has no
/// endpoint for and no purpose for.
@immutable
class RegistrationDraft {
  const RegistrationDraft({
    this.mobileNumber = '',
    this.codeVerified = false,
    this.givenName = '',
    this.middleName = '',
    this.familyName = '',
    this.suffix = '',
    this.birthDate,
    this.barangay,
    this.streetAddress = '',
    this.consents = const <ConsentKind>{},
    this.identityDocument,
    this.faceCapture,
  });

  final String mobileNumber;

  /// Set only after the server accepted a one-time code.
  final bool codeVerified;

  final String givenName;

  /// Optional: many Filipino records carry one, some do not.
  final String middleName;

  final String familyName;

  /// Optional: Jr, Sr, III.
  final String suffix;

  final DateTime? birthDate;

  final Barangay? barangay;
  final String streetAddress;

  final Set<ConsentKind> consents;

  final SelectedUpload? identityDocument;
  final SelectedUpload? faceCapture;

  bool hasConsent(ConsentKind kind) => consents.contains(kind);

  /// Every required consent has been given.
  bool get hasRequiredConsents => ConsentKind.values
      .where((kind) => kind.required)
      .every(consents.contains);

  RegistrationDraft copyWith({
    String? mobileNumber,
    bool? codeVerified,
    String? givenName,
    String? middleName,
    String? familyName,
    String? suffix,
    DateTime? birthDate,
    Barangay? barangay,
    String? streetAddress,
    Set<ConsentKind>? consents,
    SelectedUpload? identityDocument,
    SelectedUpload? faceCapture,
  }) => RegistrationDraft(
    mobileNumber: mobileNumber ?? this.mobileNumber,
    codeVerified: codeVerified ?? this.codeVerified,
    givenName: givenName ?? this.givenName,
    middleName: middleName ?? this.middleName,
    familyName: familyName ?? this.familyName,
    suffix: suffix ?? this.suffix,
    birthDate: birthDate ?? this.birthDate,
    barangay: barangay ?? this.barangay,
    streetAddress: streetAddress ?? this.streetAddress,
    consents: consents ?? this.consents,
    identityDocument: identityDocument ?? this.identityDocument,
    faceCapture: faceCapture ?? this.faceCapture,
  );

  /// Redacted in full. Every field here is personal data, and a draft is exactly
  /// the sort of object that ends up in a crash report.
  @override
  String toString() => 'RegistrationDraft(step data redacted)';
}

/// What the server said about a submitted registration.
enum RegistrationOutcome {
  /// Accepted for review. The contract's `202` on
  /// `POST /api/v1/me/verification/submissions`.
  submitted,

  /// The server could not accept it. The resident is told what to do next,
  /// never why in terms that describe another record.
  rejected,

  /// Not attempted because the endpoint does not exist in this build.
  unavailable,
}

/// The result of a submission, in resident-facing terms.
@immutable
class RegistrationResult {
  const RegistrationResult({
    required this.outcome,
    required this.residentMessage,
    this.referenceId,
  });

  final RegistrationOutcome outcome;

  /// Copy this app composed. Never the server's operator-facing `message`.
  final String residentMessage;

  /// Opaque tracking reference a resident can quote. Not a record identifier.
  final String? referenceId;
}

/// The municipality's barangays.
///
/// ---
///
/// **Its own contract, narrower than [RegistrationRepository], because the list
/// outlived the reason it was first needed.** Registration asked for it, and so
/// does a KYC claim, a profile correction and a household address — none of
/// which are registration. Leaving it on the registration contract would mean a
/// screen that only needs an address list depending on a repository that also
/// creates accounts, which is exactly the shape that made this list unreachable
/// in the first place: the one method that worked sat behind a class that
/// declined everything.
///
/// Public: no account is needed, because the first thing onboarding asks for is
/// an address.
abstract interface class BarangayDirectory {
  /// Every barangay, in one page.
  Future<Result<List<Barangay>>> listBarangays();
}

/// The registration and identity-verification contract.
///
/// ---
///
/// **Every method here maps to a row in the committed endpoint matrix, and none
/// of them invents one.** Where the matrix marks a row `planned`, the
/// implementation declines rather than guessing a payload.
///
/// | Method | Contract row | Status |
/// | --- | --- | --- |
/// | [requestOneTimeCode] | `POST /api/v1/auth/otp` | planned |
/// | [verifyOneTimeCode] | `POST /api/v1/auth/otp/verify` | planned |
/// | [loadCapabilities] | `GET /api/v1/me/verification` | planned |
/// | [listBarangays] | `GET /api/v1/barangays` | planned |
/// | [submitRegistration] | `POST /api/v1/me/verification/submissions` | planned |
///
/// There is deliberately **no `createAccount`**. The committed matrix has no
/// account-creation row: a citizen account comes into existence through the
/// one-time-code exchange. Adding one here would be inventing an endpoint.
abstract interface class RegistrationRepository {
  /// Asks the server to send a one-time code.
  ///
  /// The response must not reveal whether the number is already registered —
  /// the matrix states this as a requirement of the row. That answer would let
  /// anyone test whether a given person is a Taytay resident.
  Future<Result<void>> requestOneTimeCode({required String mobileNumber});

  /// Exchanges a code for a session.
  Future<Result<void>> verifyOneTimeCode({
    required String mobileNumber,
    required String code,
  });

  /// What this resident still has to provide.
  ///
  /// Fails closed: any failure yields [RegistrationCapabilities.denied], so an
  /// unreachable server never results in the app collecting a document or a
  /// selfie on its own initiative.
  Future<RegistrationCapabilities> loadCapabilities();

  /// The barangays of Taytay.
  Future<Result<List<Barangay>>> listBarangays();

  /// Submits the completed registration for review.
  ///
  /// [idempotencyKey] is required, not optional. A registration submitted twice
  /// because a connection dropped is a duplicate identity review in a municipal
  /// queue, and the resident cannot tell whether the first one arrived.
  Future<Result<RegistrationResult>> submitRegistration({
    required RegistrationDraft draft,
    required String idempotencyKey,
  });
}
