import '../result/result.dart';

/// Backend modules that the committed contract names as **planned**.
///
/// Taken verbatim from `docs/architecture/domain-boundary-map.md` at
/// `Taytay_Rizal_LGUIDS_Backend@7844859`. Only `Shared`, `AccessControl` and
/// `ServiceCatalog` are implemented; everything below is designed for and not
/// yet published.
enum PlannedModule {
  identity(
    'Identity',
    'accounts, sessions, tokens, devices, MFA, account lifecycle',
  ),
  residentProfile(
    'ResidentProfile',
    'resident master record, demographics, addresses, household links, '
        'verification tier',
  ),
  credential(
    'Credential',
    'LGU ID lifecycle, card artifacts, QR credential material',
  ),
  verification(
    'Verification',
    'verification attempts, scan events, verifier registry',
  ),
  serviceDelivery(
    'ServiceDelivery',
    'service applications and transactions against catalog entries',
  ),
  notification(
    'Notification',
    'notification dispatch, delivery receipts, channel preferences',
  );

  const PlannedModule(this.moduleName, this.owns);

  final String moduleName;

  /// What the committed boundary map says this module owns.
  final String owns;
}

/// The honest failure for an operation whose backend module does not exist.
///
/// ---
///
/// **Why decline rather than mock.** Three options were available for the five
/// unbuilt domains:
///
/// 1. Invent request and response schemas and code against them. Rejected: it
///    creates a contract the server never agreed to, discovered wrong only once
///    both sides are written, and the task instruction is explicit — do not
///    invent OpenAPI fields or endpoints.
/// 2. Return plausible fake data. Rejected: fixtures become the thing people
///    demo and review, and a screen that works against a mock is a screen nobody
///    has actually tested.
/// 3. **Decline with a temporary failure.** Chosen. It exercises the whole error
///    seam — `Result`, `AppFailure`, the resident-safe message, the retry rules —
///    and it tells the truth: the service is not available yet.
///
/// The failure is [ServerFailure] with `isTemporary: true`, so the resident sees
/// "temporarily unavailable, try again shortly" rather than a message implying
/// they did something wrong.
Err<T> plannedBackendFailure<T>(PlannedModule module, String operation) =>
    Err<T>(
      ServerFailure(
        isTemporary: true,
        debugMessage:
            '${module.moduleName} is not published by the backend yet, so '
            '"$operation" has no endpoint. The module owns: ${module.owns}.',
      ),
    );
