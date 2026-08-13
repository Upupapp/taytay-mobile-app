import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';

/// Result of the backend liveness probe.
///
/// The server's health endpoint is contractually limited to service name, status
/// and API version — it must never expose environment names, dependency versions
/// or configuration (`docs/api/conventions.md` §8). This type mirrors that
/// limit exactly, so a future server change that leaked more would have nowhere
/// to land.
@immutable
class ServiceHealth {
  const ServiceHealth({
    required this.service,
    required this.status,
    required this.apiVersion,
  });

  final String service;
  final String status;
  final String apiVersion;

  bool get isHealthy => status.toLowerCase() == 'ok';
}

/// Platform-level queries that belong to no single resident.
abstract interface class PlatformRepository {
  /// Unauthenticated liveness probe. Used to tell "the LGU service is down" from
  /// "your connection is down" — two problems with very different advice.
  Future<Result<ServiceHealth>> checkHealth();
}
