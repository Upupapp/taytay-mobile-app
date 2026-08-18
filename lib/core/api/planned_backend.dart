import '../result/result.dart';

/// Backend modules that the committed contract names as **planned**.
///
/// Re-derived from `docs/architecture/domain-boundary-map.md` at
/// `Upupapp/taytay-backend@api-baseline-2026-08` (`eec71e6`). See
/// `docs/integration/backend-baseline.md` for the full two-axis status table
/// and the guard that keeps this list honest.
///
/// ---
///
/// **This enum shrank from six members to two, and that is the point.** It was
/// first written against backend `7844859` and named `Identity`,
/// `ResidentProfile`, `Credential` and `Notification` as planned. All four have
/// since shipped. Because the belief was compiled into a Dart enum, nothing
/// ever said so: the app went on declining roughly seventy endpoints that were
/// serving, including every route a resident needs to sign in.
///
/// Two members remain, and they are the only two. A module belongs here when
/// the backend has not built it — never when the backend has built it and this
/// app has not yet called it. For that, and it is now the common case, see
/// `UnwiredRepository` in `unwired_repository.dart`: it is a different
/// statement about a different party, and collapsing the two is what produced
/// the condition this file exists to end.
enum PlannedModule {
  verification(
    'Verification',
    'verification attempts, scan events, verifier registry, '
        'offline-verification key distribution',
  ),
  serviceDelivery(
    'ServiceDelivery',
    'service applications and transactions against catalog entries '
        '(dokumento, buwis, kalusugan, trabaho, national referrals), their '
        'state machines and attachments',
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
/// **Why decline rather than mock.** Three options were available for the
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
/// That reasoning was sound and survives the re-baseline; only its *inputs* were
/// wrong. A future planned module can use this on its first day.
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
