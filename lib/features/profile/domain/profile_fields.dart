/// Who owns a field on the resident's record, and therefore who may change it.
///
/// ---
///
/// **This distinction is the whole point of the screen** (acceptance 1). A
/// resident looking at "Ana Dela Cruz, born 3 March 1990, Barangay San Juan"
/// alongside "0917 123 4567" sees one list of facts about themselves and has no
/// way to know that changing the last one is a setting and changing the first
/// would be a claim against a municipal registry.
///
/// The committed contract draws the line explicitly. `PATCH /api/v1/me/profile`
/// takes **"contact fields only"**, with the sensitivity note *"a citizen may
/// not edit their own eligibility-bearing fields"*. So the split below is the
/// server's, not this app's invention — and the app's job is to make it visible
/// rather than to discover it at a `403`.
enum FieldOwnership {
  /// The resident owns it. It is how the LGU reaches them, it bears on nothing
  /// they are entitled to, and they may change it here.
  accountOwned(
    'Your account details',
    'You can change these yourself. They are how Taytay LGU contacts you.',
  ),

  /// Taytay LGU owns it. It was checked against documents, other services rely
  /// on it, and only the LGU can change it.
  lguVerified(
    'Confirmed by Taytay LGU',
    'Taytay LGU checked these against your documents. They decide what you are '
        'entitled to, so only the LGU can change them.',
  );

  const FieldOwnership(this.sectionTitle, this.sectionExplanation);

  /// Heading a resident reads above the group.
  final String sectionTitle;

  /// One sentence saying who may change it and why.
  final String sectionExplanation;

  /// Whether this app may offer a form for it.
  ///
  /// **The single gate on editing.** No screen decides for itself; every editor
  /// asks this, and a test asserts nothing eligibility-bearing answers true.
  bool get isEditableInApp => this == FieldOwnership.accountOwned;
}

/// One field on the resident's record, as this app talks about it.
///
/// ---
///
/// **These are the app's own names, not a wire schema.** The `ResidentProfile`
/// module is `planned` and publishes no field list, so nothing here is claimed
/// to match a server key. What each entry does carry is the *category* — which
/// the committed boundary map already names ("demographics, addresses, household
/// links") and which the registration wizard already collects. When the module
/// ships, the data layer maps wire keys onto these; this list does not move.
enum ResidentProfileField {
  // --- Account-owned: the two things `PATCH /me/profile` authorises. ---------
  mobileNumber(
    'Mobile number',
    FieldOwnership.accountOwned,
    hint: 'How Taytay LGU sends your one-time codes and updates.',
    wireName: 'mobile_number',
  ),
  emailAddress(
    'Email address',
    FieldOwnership.accountOwned,
    hint: 'Optional. Used for copies of what the LGU sends you.',
    wireName: 'email',
  ),

  // --- LGU-verified: everything a benefit or a credential rests on. ---------
  fullName(
    'Full name',
    FieldOwnership.lguVerified,
    isEligibilityBearing: true,
    hint: 'As it appears on the ID you presented.',
  ),
  birthDate(
    'Date of birth',
    FieldOwnership.lguVerified,
    isEligibilityBearing: true,
    hint: 'Decides age-based services such as senior citizen benefits.',
    wireName: 'birth_date',
  ),
  sex(
    'Sex',
    FieldOwnership.lguVerified,
    isEligibilityBearing: true,
    wireName: 'sex',
  ),
  civilStatus(
    'Civil status',
    FieldOwnership.lguVerified,
    isEligibilityBearing: true,
    wireName: 'civil_status',
  ),
  barangay(
    'Barangay',
    FieldOwnership.lguVerified,
    isEligibilityBearing: true,
    hint: 'Decides which barangay office serves you.',
    wireName: 'barangay_id',
  ),
  streetAddress(
    'Street address',
    FieldOwnership.lguVerified,
    isEligibilityBearing: true,
    hint: 'Your registered address in Taytay.',
    wireName: 'street_address',
  );

  const ResidentProfileField(
    this.label,
    this.ownership, {
    this.hint,
    this.isEligibilityBearing = false,
    this.wireName,
  });

  /// The field's name on `me/profile`, when the server publishes it under one.
  ///
  /// Null for anything this app composes rather than reads — [fullName] is three
  /// wire fields joined for a screen, so there is no single name to send a
  /// correction against and no property here pretending otherwise.
  final String? wireName;

  /// Resident-facing name. Fixed copy, never composed from server data.
  final String label;

  final FieldOwnership ownership;

  /// One line saying what the field is for. Optional.
  final String? hint;

  /// Whether what a resident is entitled to depends on this value.
  ///
  /// Every such field is [FieldOwnership.lguVerified] — asserted by a test.
  /// A resident who could edit their own birth date could grant themselves a
  /// senior citizen benefit, and a resident who could edit their own barangay
  /// could move themselves into a different office's caseload. Neither is a
  /// hypothetical: they are the two most common fraud patterns in municipal
  /// assistance, and the reason the backend refuses the edit rather than
  /// trusting the client not to offer it.
  final bool isEligibilityBearing;

  bool get isEditableInApp => ownership.isEditableInApp;

  static List<ResidentProfileField> ownedBy(FieldOwnership ownership) => values
      .where((field) => field.ownership == ownership)
      .toList(growable: false);
}

/// What a resident can do about a field they cannot edit.
///
/// ---
///
/// **There is no resident-initiated correction endpoint, so this app does not
/// pretend there is one.** The committed matrix has `PATCH /me/profile` (contact
/// only) and, for canonical data, `PATCH /api/v1/residents/{resident_id}` —
/// which requires the `resident.update` permission under a staff role scope. A
/// citizen app must never hold that permission (CLAUDE.md Article 0), and
/// inventing a `/me/profile/corrections` route would ship a form whose
/// submission has nowhere to go.
///
/// So the honest safe next step is the counter, and the copy says exactly what
/// to bring. A form that silently fails is worse than a sentence that works:
/// the resident who read the sentence gets their record fixed.
abstract final class CanonicalCorrection {
  /// What the resident is told when they tap an LGU-verified field.
  static const String title = 'Taytay LGU keeps this correct';

  static const String explanation =
      'This detail was checked against your documents, and other Taytay '
      'services rely on it. Changing it is a decision Taytay LGU makes, so it '
      'cannot be edited in this app.';

  static const String nextStep =
      'If it is wrong, visit the Taytay municipal hall with a valid ID and the '
      'document that shows the correct detail. Staff can update your record '
      'directly. You do not need this app or your phone to do it.';

  /// Shown when a resident is mid-verification: the LGU is already asking them
  /// for information, and that is the cheaper route than a second trip.
  static const String duringVerification =
      'You are part-way through identity verification. If Taytay LGU asked you '
      'for a correction there, answering it is the quickest way to fix this.';
}
