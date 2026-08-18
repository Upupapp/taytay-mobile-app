import '../../../core/api/backend_gap.dart';
import '../../../core/result/result.dart';
import '../domain/registration_domain.dart';

/// The registration repository this build ships with.
///
/// ---
///
/// **Re-baselined at `backend@api-baseline-2026-08`, and the reason changed.**
/// This file used to say every row it needs was `planned` at
/// `Taytay_Rizal_LGUIDS_Backend@896cec9` and that `Identity` was absent from
/// `modules/`. `Identity` has been implemented since backend TAB 05; the older
/// statement was two backends out of date and pinned to a third commit, which is
/// how a belief compiled into source goes wrong without anybody noticing.
///
/// The methods still decline, and the true reason is worse than the old one.
/// There is **no self-registration endpoint at all** — see [BackendGap] `F15`.
/// The public `Identity` surface is sign-in only; citizen accounts are created
/// by staff on the admin console. Onboarding on this platform is staff-mediated
/// by construction, so this is a product question for the LGU rather than a
/// wiring task, and it is the one place in the app where the screens and the
/// server disagree about what the product is.
///
/// **Why not a mock that succeeds.** A registration flow that appears to work
/// is the single most dangerous placeholder in this app: it would tell a
/// resident their identity documents had been sent to the LGU when nothing left
/// the device, and it is exactly the screen that gets demonstrated to a
/// municipal officer as evidence the system works.
///
/// [loadCapabilities] is the load-bearing one: it returns
/// [RegistrationCapabilities.denied], so the document and selfie steps are
/// skipped entirely. That is the fail-closed outcome — this client never
/// collects a government ID or a photograph of a resident's face on its own
/// initiative.
class PlannedRegistrationRepository implements RegistrationRepository {
  const PlannedRegistrationRepository();

  /// Sign-in codes exist; codes that enrol a new resident do not, and no issued
  /// code is delivered on any channel either (`F16`).
  static const BackendGap _selfRegistration =
      BackendGap.residentSelfRegistration;
  static const BackendGap _barangays = BackendGap.barangayDirectory;

  @override
  Future<Result<void>> requestOneTimeCode({
    required String mobileNumber,
  }) async => backendGapFailure<void>(_selfRegistration, 'requestOneTimeCode');

  @override
  Future<Result<void>> verifyOneTimeCode({
    required String mobileNumber,
    required String code,
  }) async => backendGapFailure<void>(_selfRegistration, 'verifyOneTimeCode');

  /// Always denied.
  ///
  /// Note the signature: this returns capabilities directly rather than a
  /// `Result`, because there is no failure mode a caller should handle
  /// differently. An unreachable server and a server that says "nothing more is
  /// needed" both mean *do not collect anything*, and forcing every call site to
  /// remember that is how one of them eventually gets it wrong.
  @override
  Future<RegistrationCapabilities> loadCapabilities() async =>
      RegistrationCapabilities.denied;

  @override
  Future<Result<List<Barangay>>> listBarangays() async =>
      backendGapFailure<List<Barangay>>(_barangays, 'listBarangays');

  @override
  Future<Result<RegistrationResult>> submitRegistration({
    required RegistrationDraft draft,
    required String idempotencyKey,
  }) async => backendGapFailure<RegistrationResult>(
    _selfRegistration,
    'submitRegistration',
  );
}

/// The barangays of Taytay, Rizal, used until `GET /api/v1/barangays` exists.
///
/// ---
///
/// **Names only. No PSGC codes, ever, from this file.**
///
/// The staff console leaves `psgcCode: null` for all five with a comment that a
/// wrong code is worse than an absent one, because DSWD reporting keys off it;
/// the backend repeats this as gap **G-11** and resolves it by loading the
/// authoritative PSA dataset server-side. This client is in no position to
/// improve on that, so it carries the names a resident needs to recognise their
/// barangay and nothing that could be mistaken for a statutory identifier.
///
/// The `id` values are local selection keys, not municipal identifiers. When the
/// endpoint lands, the server's list replaces this one wholesale.
abstract final class TaytayBarangays {
  /// Source: `Taytay_Rizal_Social_Welfare_Angular@c470960`,
  /// `src/app/domain/geography/barangay.ts`.
  static const List<Barangay> fallback = <Barangay>[
    Barangay(id: 'dolores', name: 'Dolores'),
    Barangay(id: 'muzon', name: 'Muzon'),
    Barangay(id: 'san-isidro', name: 'San Isidro'),
    Barangay(id: 'san-juan', name: 'San Juan'),
    Barangay(id: 'santa-ana', name: 'Santa Ana'),
  ];
}
