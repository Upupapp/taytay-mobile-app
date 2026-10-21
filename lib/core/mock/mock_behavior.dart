import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../result/result.dart';

/// Latency and failure for dev mocks. The gallery can change it; repositories
/// read it on each call so a switch takes effect on the next request.
class MockBehaviorController extends ChangeNotifier {
  MockBehaviorController({
    required Duration latency,
    required MockFailureMode failure,
  }) : _latency = latency,
       _failure = failure;

  factory MockBehaviorController.fromConfig(AppConfig config) {
    return MockBehaviorController(
      latency: config.mockLatency,
      failure: config.mockFailure,
    );
  }

  Duration _latency;
  MockFailureMode _failure;

  Duration get latency => _latency;
  MockFailureMode get failure => _failure;

  void setLatency(Duration value) {
    if (value == _latency) return;
    _latency = value;
    notifyListeners();
  }

  void setFailure(MockFailureMode value) {
    if (value == _failure) return;
    _failure = value;
    notifyListeners();
  }

  /// Applies the current latency and, when asked, a synthetic failure.
  ///
  /// The failure carries no resident-facing server message. Screens map the
  /// failure kind themselves.
  Future<Result<T>> respond<T>(T value) async {
    if (_latency > Duration.zero) {
      await Future<void>.delayed(_latency);
    }
    return switch (_failure) {
      MockFailureMode.offline => Err<T>(
        const NetworkFailure(debugMessage: 'Dev mock is set to offline.'),
      ),
      MockFailureMode.server => Err<T>(
        const ServerFailure(
          isTemporary: true,
          debugMessage: 'Dev mock is set to a server failure.',
        ),
      ),
      MockFailureMode.none => Ok<T>(value),
    };
  }
}
