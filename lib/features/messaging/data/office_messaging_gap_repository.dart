import '../../../core/api/backend_gap.dart';
import '../../../core/result/result.dart';
import '../domain/office_messaging_repository.dart';

/// Live stand-in. Declines every call because no endpoint exists (F31).
///
/// It does not invent a thread. A screen that needs data in dev uses the mock
/// repository selected at the composition root.
class OfficeMessagingGapRepository implements OfficeMessagingRepository {
  const OfficeMessagingGapRepository();

  @override
  Future<Result<List<OfficeThread>>> listThreads() async {
    return backendGapFailure<List<OfficeThread>>(
      BackendGap.officeMessaging,
      'list office threads',
    );
  }

  @override
  Future<Result<OfficeThread>> loadThread(String threadId) async {
    return backendGapFailure<OfficeThread>(
      BackendGap.officeMessaging,
      'load office thread',
    );
  }

  @override
  Future<Result<OfficeMessage>> send({
    required String officeId,
    required String topic,
    required String body,
  }) async {
    return backendGapFailure<OfficeMessage>(
      BackendGap.officeMessaging,
      'send office message',
    );
  }
}
