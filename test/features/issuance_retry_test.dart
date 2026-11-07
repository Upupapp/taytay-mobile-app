import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/api/request_context.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/documents/upload_policy.dart';
import 'package:taytay_resident/core/mock/mock_behavior.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/issuance/data/mock_issuance_repository.dart';
import 'package:taytay_resident/features/issuance/domain/issuance_repository.dart';
import 'package:taytay_resident/features/issuance/domain/issuance_request.dart';
import 'package:taytay_resident/features/issuance/domain/issuance_type.dart';
import 'package:taytay_resident/features/issuance/presentation/issuance_failure_copy.dart';
import 'package:taytay_resident/features/issuance/presentation/issuance_request_controller.dart';
import 'package:taytay_resident/features/issuance/presentation/issuance_send_key.dart';

final RegExp _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// Answers each submit from a script and records the key it was sent with.
class _Scripted implements IssuanceRepository {
  _Scripted(this.type);

  final IssuanceType type;
  final List<Result<IssuanceRequestDetail>> answers =
      <Result<IssuanceRequestDetail>>[];
  final List<String> keys = <String>[];

  @override
  Future<Result<IssuanceRequestDetail>> submit({
    required String typeId,
    required String purpose,
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    return answers.removeAt(0);
  }

  @override
  Future<Result<List<IssuanceType>>> listTypes() async =>
      Ok<List<IssuanceType>>(<IssuanceType>[type]);

  @override
  Future<Result<IssuanceType>> loadType(String typeId) async =>
      Ok<IssuanceType>(type);

  @override
  Future<Result<Paginated<IssuanceRequestSummary>>> listOwn({String? cursor}) =>
      throw UnimplementedError();

  @override
  Future<Result<IssuanceRequestDetail>> loadOwn(String requestId) =>
      throw UnimplementedError();

  @override
  Future<Result<IssuanceRequestDetail>> cancel(
    String requestId, {
    String? reason,
    required String idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<Result<IssuanceRequestDetail>> resubmit(
    String requestId, {
    String? note,
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<Result<Uint8List>> loadAttachmentImage(
    String requestId,
    String attachmentId,
  ) => throw UnimplementedError();
}

class _Picker implements DocumentPicker {
  @override
  Future<CapturedDocument?> pick(
    DocumentSource source,
    UploadPolicy policy,
  ) async => CapturedDocument(
    bytes: Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46, 1, 2, 3]),
    fileName: 'scan.pdf',
    mimeType: 'application/pdf',
    source: DocumentSource.file,
  );

  @override
  bool supports(DocumentSource source) => true;
}

IssuanceRequestDetail _filed() => const IssuanceRequestDetail(
  summary: IssuanceRequestSummary(
    id: 'dr-1',
    referenceNumber: 'DR-2026-000140',
    status: null,
    typeName: 'Certificate of indigency',
    officeName: 'MSWDO',
  ),
  purpose: 'For a hospital bill discount.',
  requirements: <IssuanceRequirement>[],
  attachments: <IssuanceAttachment>[],
  history: <IssuanceHistoryEntry>[],
  canCancel: false,
  canResubmit: false,
);

Future<IssuanceRequestController> _readyToSend(_Scripted repository) async {
  final IssuanceRequestController controller = IssuanceRequestController(
    repository: repository,
    picker: _Picker(),
    type: repository.type,
  );
  controller.setPurpose('For a hospital bill discount.');
  for (final IssuanceRequirement requirement in repository.type.requirements) {
    await controller.choose(requirement.code, DocumentSource.file);
  }
  expect(controller.review(), isTrue);
  return controller;
}

Future<IssuanceType> _type() async {
  final MockIssuanceRepository mock = MockIssuanceRepository(
    MockBehaviorController(
      latency: Duration.zero,
      failure: MockFailureMode.none,
    ),
  );
  return (await mock.loadType('dt-sample-birth')).valueOrNull!;
}

void main() {
  group('an idempotency key', () {
    test('is a version 4 UUID, as the Node API requires', () {
      final Set<String> keys = <String>{
        for (int i = 0; i < 200; i++) generateIdempotencyKey(),
      };
      expect(keys, hasLength(200));
      for (final String key in keys) {
        expect(key, matches(_uuidV4));
      }
    });

    test('is held across a lost answer and let go once the act is over', () {
      int minted = 0;
      final IssuanceSendKey key = IssuanceSendKey(mint: () => 'k-${++minted}');

      final String first = key.take();
      key.settle(const Err<Object?>(TimeoutFailure()));
      expect(key.take(), first);
      key.settle(const Err<Object?>(NetworkFailure()));
      expect(key.take(), first);
      // A refusal claimed nothing; keeping the key costs nothing.
      key.settle(const Err<Object?>(ForbiddenFailure()));
      expect(key.take(), first);

      key.settle(const Ok<Object?>(null));
      expect(key.take(), isNot(first));

      // A 409 refused the key itself; sending it again would only repeat that.
      final String second = key.take();
      key.settle(const Err<Object?>(ConflictFailure()));
      expect(key.take(), isNot(second));

      final String third = key.take();
      key.reset();
      expect(key.take(), isNot(third));
    });
  });

  group('sending a request again after a timeout', () {
    test('reuses the key, so the office files it once', () async {
      final _Scripted repository = _Scripted(await _type());
      repository.answers.addAll(<Result<IssuanceRequestDetail>>[
        const Err<IssuanceRequestDetail>(TimeoutFailure()),
        const Err<IssuanceRequestDetail>(NetworkFailure()),
        Ok<IssuanceRequestDetail>(_filed()),
      ]);
      final IssuanceRequestController controller = await _readyToSend(
        repository,
      );

      await controller.submit();
      expect(controller.failure, isA<TimeoutFailure>());
      await controller.submit();
      expect(controller.failure, isA<NetworkFailure>());
      await controller.submit();

      expect(controller.stage, IssuanceFormStage.done);
      expect(repository.keys, hasLength(3));
      expect(repository.keys.toSet(), hasLength(1));
      expect(repository.keys.first, matches(_uuidV4));
      controller.dispose();
    });

    test('an edited request is a new act with a new key', () async {
      final _Scripted repository = _Scripted(await _type());
      repository.answers.addAll(<Result<IssuanceRequestDetail>>[
        const Err<IssuanceRequestDetail>(TimeoutFailure()),
        Ok<IssuanceRequestDetail>(_filed()),
      ]);
      final IssuanceRequestController controller = await _readyToSend(
        repository,
      );

      await controller.submit();
      controller.backToEditing();
      controller.setPurpose('For a hospital bill discount, second copy.');
      expect(controller.review(), isTrue);
      await controller.submit();

      expect(repository.keys, hasLength(2));
      expect(repository.keys.first, isNot(repository.keys.last));
      controller.dispose();
    });

    test('a 409 on a send is a fault of ours, said generically', () async {
      final _Scripted repository = _Scripted(await _type());
      const String serverText =
          'That idempotency key was already used for a different act.';
      repository.answers.addAll(<Result<IssuanceRequestDetail>>[
        const Err<IssuanceRequestDetail>(
          ConflictFailure(debugMessage: serverText),
        ),
        Ok<IssuanceRequestDetail>(_filed()),
      ]);
      final IssuanceRequestController controller = await _readyToSend(
        repository,
      );

      await controller.submit();
      final AppFailure failure = controller.failure!;
      final ({String title, String body, bool offerVerification}) copy =
          issuanceSendFailure(failure, act: IssuanceAct.submit);
      expect(copy.title, 'It did not go through');
      expect(copy.body, contains('Open My document requests'));
      expect(copy.body, isNot(contains('moved on')));
      expect('${copy.title} ${copy.body}', isNot(contains(serverText)));
      // Nothing personal travels in the failure's own description.
      expect(failure.toString(), isNot(contains('hospital')));

      // The refused key is let go; the next press sends under a new one.
      await controller.submit();
      expect(repository.keys.first, isNot(repository.keys.last));
      controller.dispose();
    });
  });
}
