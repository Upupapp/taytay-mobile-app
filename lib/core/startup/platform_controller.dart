import 'package:flutter/foundation.dart';

import '../../features/platform/domain/app_bootstrap.dart';
import '../../features/platform/domain/platform_repository.dart';
import '../config/app_version.dart';
import '../result/result.dart';

/// What the server said at startup, and what the app must do about it.
///
/// ---
///
/// ## Two gates, from two different sources, on purpose
///
/// **Force-upgrade comes from `app/bootstrap`.** The server publishes the oldest
/// build it will serve; this app compares its own version to it, because only it
/// knows what that is. That answer is stable for the life of a release, so
/// reading it once at startup is right.
///
/// **Maintenance does not, because the contract has no field for it.** TAB 01
/// asks for a maintenance screen driven by bootstrap; the published payload
/// carries `service`, `api_version`, `server_time`, `timezone`, `client`,
/// `features`, `support` and `conventions`, and nothing about maintenance
/// (recorded as F18). Rather than ask the backend for a field, this app takes
/// the signal it already has: a live `503 SERVICE_UNAVAILABLE`.
///
/// That is the better design regardless of the gap, and it is worth saying why
/// so nobody "fixes" it later by adding the field. Maintenance is a condition
/// that changes minute to minute. A flag read once at startup would announce
/// maintenance for the rest of a session after it ended, and would miss one that
/// began while the app was open — and a client that caches it to survive a cold
/// start is caching the most perishable fact the server has. A 503 is the server
/// saying so, at the moment it is true, on the request that just failed.
///
/// ## Startup never blocks on the network
///
/// [refresh] is fired and not awaited by anything that draws. Until it answers,
/// [bootstrap] is [AppBootstrap.unknown] — permissive about versions, closed
/// about features — so a resident on a dead connection gets the app rather than
/// a spinner, and a failure to reach the server never locks anybody out of a
/// build that works.
class PlatformController extends ChangeNotifier {
  PlatformController({
    required PlatformRepository repository,
    String version = appVersion,
  }) : _repository = repository,
       _version = version;

  final PlatformRepository _repository;
  final String _version;

  AppBootstrap _bootstrap = AppBootstrap.unknown;
  bool _hasAnswered = false;
  bool _isInMaintenance = false;

  AppBootstrap get bootstrap => _bootstrap;

  /// Whether the server has answered at all. Distinct from the values, because
  /// "we do not know yet" and "the server said no flags" render differently.
  bool get hasAnswered => _hasAnswered;

  /// Server-declared rendering hints. Never authorization (Article 3.4).
  FeatureFlags get features => _bootstrap.features;

  /// Where to send a resident when nothing else is reachable.
  SupportContact get support => _bootstrap.support;

  /// Whether this build is too old for the server to serve.
  ///
  /// Only ever `tooOld` on a published minimum that this build is genuinely
  /// below. Every uncertain case — no answer yet, empty minimum, unparseable
  /// version — resolves to supported. See [SupportedVersion.compare].
  SupportedVersion get supported => SupportedVersion.compare(
    appVersion: _version,
    minimum: _bootstrap.minimumVersion,
  );

  bool get mustUpgrade => supported == SupportedVersion.tooOld;

  /// The server answered `503` on the most recent request that reached it.
  bool get isInMaintenance => _isInMaintenance;

  /// Reads the startup contract. Never throws, never blocks a first frame.
  Future<void> refresh() async {
    final Result<AppBootstrap> result = await _repository.loadBootstrap();

    switch (result) {
      case Ok<AppBootstrap>(:final AppBootstrap value):
        _bootstrap = value;
        _hasAnswered = true;
        // Reaching bootstrap at all is proof the service is up. A maintenance
        // window that has ended clears itself on the next successful startup
        // rather than persisting until the app is killed.
        _isInMaintenance = false;
      case Err<AppBootstrap>():
        // Deliberately keeps the last known values. A failed refresh is not
        // evidence that the minimum version changed, and treating it as such
        // would let a flaky connection unlock a build the server refuses.
        break;
    }
    notifyListeners();
  }

  /// Observes every decoded response the app makes.
  ///
  /// Called from `ApiClient` with the verdict only — no path, no payload, no
  /// identifier. Maintenance is raised by a real `503 SERVICE_UNAVAILABLE` and
  /// cleared by any request that succeeds, so the screen follows the server
  /// rather than a timer.
  void observe(AppFailure? failure) {
    final bool maintenance = failure is ServerFailure && failure.isMaintenance;

    if (failure == null && _isInMaintenance) {
      _isInMaintenance = false;
      notifyListeners();
      return;
    }
    if (maintenance && !_isInMaintenance) {
      _isInMaintenance = true;
      notifyListeners();
    }
  }
}
