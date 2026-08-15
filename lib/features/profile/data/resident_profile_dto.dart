import '../domain/profile_fields.dart';
import '../domain/resident_profile_detail.dart';

/// Decodes the resident's own profile, by naming what may come in.
///
/// ---
///
/// **An allow-list, not a deny-list**, for the same reason TAB 08's verification
/// decoder is one. The committed client-visibility matrix says a citizen
/// projection is built *"by naming the fields to include, never by taking the
/// staff projection and removing some"*, and a deny-list is one forgotten key
/// away from rendering a caseworker's note. An allow-list cannot leak a field
/// nobody wrote a line for.
///
/// **The keys below are provisional.** The `ResidentProfile` module is `planned`
/// and publishes no schema, so these are this app's reading of the categories
/// the boundary map names, in the conventions' `snake_case`. They are the one
/// thing in this file most likely to change when the module ships — and changing
/// them is a one-line edit per field, because nothing above the data layer knows
/// a wire key exists.
///
/// **[forbiddenKeys] is documentation with teeth.** Those fields have nowhere to
/// arrive — [ResidentProfileDetail] has no property any of them could occupy —
/// so the set exists to be asserted against in a test, and to state plainly what
/// this app must never render about a resident or about anybody else.
abstract final class ResidentProfileDto {
  /// Wire keys this app reads, mapped onto the fields it names.
  static const Map<String, ResidentProfileField> allowedKeys =
      <String, ResidentProfileField>{
        'mobile_number': ResidentProfileField.mobileNumber,
        'email': ResidentProfileField.emailAddress,
        'full_name': ResidentProfileField.fullName,
        'birth_date': ResidentProfileField.birthDate,
        'sex': ResidentProfileField.sex,
        'civil_status': ResidentProfileField.civilStatus,
        'barangay': ResidentProfileField.barangay,
        'street_address': ResidentProfileField.streetAddress,
      };

  /// The only non-field key read: the tier, which routing depends on.
  static const String verificationTierKey = 'verification_tier';

  /// Keys that must never reach a resident's screen.
  ///
  /// Four groups, each for a different reason:
  ///
  /// * **Registry internals** (`resident_id`, `record_number`, `psgc_code`) —
  ///   identifiers a resident cannot use and support will not ask for, whose
  ///   only effect on screen is to invite someone to quote them somewhere.
  /// * **Staff and review material** (`assessment`, `internal_notes`,
  ///   `reviewed_by`, `risk_score`) — never in a citizen response, in any
  ///   endpoint, ever.
  /// * **Other people** (`household_members`, `relatives`, `dependents`) —
  ///   another resident's personal data, which this resident has no standing to
  ///   receive from an app.
  /// * **Audit and lifecycle metadata** (`audit_trail`, `created_by`,
  ///   `deactivation_reason`) — the record's history, not the resident's.
  static const Set<String> forbiddenKeys = <String>{
    'resident_id',
    'record_number',
    'household_id',
    'psgc_code',
    'philsys_number',
    'assessment',
    'internal_notes',
    'remarks',
    'reviewed_by',
    'reviewer_name',
    'risk_score',
    'fraud_score',
    'sector_flags',
    'household_members',
    'relatives',
    'dependents',
    'audit_trail',
    'status_changes',
    'created_by',
    'updated_by',
    'deactivation_reason',
  };

  /// Decodes a `GET /api/v1/me/profile` payload.
  ///
  /// Anything not in [allowedKeys] is ignored — unknown fields are never a
  /// rejection (API conventions §1), and a server that starts sending a new
  /// column must not crash a released app.
  static ResidentProfileDetail decode(Object? payload) {
    if (payload is! Map<String, dynamic>) {
      return const ResidentProfileDetail();
    }

    final values = <ResidentProfileField, String>{};
    allowedKeys.forEach((key, field) {
      final raw = payload[key];
      // Strings only. A nested object under an allowed key would be a shape
      // this app did not agree to, and flattening it is how a household list
      // ends up rendered as an address.
      if (raw is String && raw.trim().isNotEmpty) {
        values[field] = raw.trim();
      }
    });

    final tier = payload[verificationTierKey];

    return ResidentProfileDetail(
      values: values,
      verificationTier: tier is String && tier.isNotEmpty ? tier : null,
    );
  }

  /// Builds the body for `PATCH /api/v1/me/profile`.
  ///
  /// Only contact fields can be expressed, because only contact fields exist on
  /// [ContactDetailsUpdate]. There is no branch here that could add another.
  static Map<String, Object?> encodeContactUpdate(ContactDetailsUpdate update) {
    return <String, Object?>{
      if (update.mobileNumber != null && update.mobileNumber!.isNotEmpty)
        'mobile_number': update.mobileNumber,
      if (update.emailAddress != null && update.emailAddress!.isNotEmpty)
        'email': update.emailAddress,
    };
  }
}
