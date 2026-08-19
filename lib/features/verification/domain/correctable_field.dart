/// The fields `POST me/profile/corrections` will actually accept.
///
/// ## Why this exists (F23)
///
/// The two sides key corrections differently and always have. A KYC reviewer
/// flags **categories** a resident recognises — "your details", "your address" —
/// and the server adjudicates **named fields**. Before TAB 04 the app bridged
/// that by mapping each category to at most one field and declining the rest, so
/// a resident correcting their barangay filed a `street_address` correction and
/// a resident correcting a document was told, after typing it, that nothing
/// could be sent.
///
/// Neither half of that is acceptable. A correction filed against the wrong
/// field is worse than one not filed — the office reads it, finds nothing wrong
/// with the field named, and the resident believes they have been heard. And a
/// refusal that arrives *after* the typing is a refusal disguised as a form.
///
/// So the app now models the server's vocabulary directly, asks which detail
/// when a category spans several, and refuses **before** the input when a
/// category maps to none.
///
/// ## Where the list comes from
///
/// `Modules\ResidentProfile\Contracts\CorrectableField` at the pinned baseline,
/// read from the backend rather than inferred from the category names.
/// `tool/check_correctable_fields.sh` fails in **both** directions — a field the
/// server gained and this app has not, and one this app names that the server
/// will refuse.
///
/// The wire values are the contract. The labels are this app's, because the
/// server's field names are operator-facing and a resident has never seen
/// `purok_or_sitio`.
enum CorrectableField {
  firstName('first_name'),
  middleName('middle_name'),
  lastName('last_name'),
  suffix('suffix'),
  birthDate('birth_date'),
  sex('sex'),
  civilStatus('civil_status'),
  barangayId('barangay_id'),
  streetAddress('street_address'),
  purokOrSitio('purok_or_sitio'),
  mobileNumber('mobile_number'),
  email('email');

  const CorrectableField(this.wireValue);

  /// Exactly as the server names it. Sent; never shown.
  final String wireValue;
}
