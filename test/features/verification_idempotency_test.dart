import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_controller.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/features/verification/domain/kyc_claim.dart';
import 'package:taytay_resident/features/verification/domain/verification_repository.dart';
import 'package:taytay_resident/features/verification/domain/verification_status_detail.dart';
import 'package:taytay_resident/features/verification/presentation/verification_controller.dart';

/// One key per attempt to open a verification request, the same on every
/// retry of that attempt, a new one when what is sent changes (D-213).
void main() {
  final RegExp uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  VerificationImagePart photo([int byte = 1]) => VerificationImagePart(
    bytes: Uint8List.fromList(<int>[byte, 2, 3]),
    fileName: 'sample.jpg',
    mimeType: 'image/jpeg',
  );

  Future<(VerificationController, _Recorder)> open(
    List<Result<VerificationStatus>> answers,
  ) async {
    final _Recorder repository = _Recorder(answers);
    final SessionController session = SessionController(
      store: InMemorySessionStore(),
    );
    await session.signIn(
      resident: const ResidentSession(
        accountId: 'acct-1',
        accessLevel: AccessLevel.unverified,
      ),
      accessToken: 'token',
    );
    final VerificationController controller = VerificationController(
      repository: repository,
      session: session,
    );
    await controller.refresh();
    addTearDown(controller.dispose);
    return (controller, repository);
  }

  const Result<VerificationStatus> lost = Err<VerificationStatus>(
    TimeoutFailure(),
  );
  const Result<VerificationStatus> opened = Ok<VerificationStatus>(
    VerificationStatus(
      state: VerificationAttemptState.underReview,
      rawState: 'pending',
    ),
  );

  test('a retry of the same send carries the same UUID v4 key', () async {
    final (VerificationController controller, _Recorder repository) =
        await open(<Result<VerificationStatus>>[lost, lost, opened]);
    final VerificationImagePart front = photo();
    final VerificationImagePart selfie = photo(9);

    for (var i = 0; i < 3; i++) {
      await controller.startVerification(
        idType: 'passport',
        front: front,
        selfie: selfie,
      );
    }
    expect(repository.keys, hasLength(3));
    expect(repository.keys.toSet(), hasLength(1));
    expect(uuidV4.hasMatch(repository.keys.first ?? ''), isTrue);
  });

  test(
    'the same bytes rebuilt into new parts are still the same send',
    () async {
      final (VerificationController controller, _Recorder repository) =
          await open(<Result<VerificationStatus>>[lost, lost]);
      final Uint8List front = Uint8List.fromList(<int>[1, 2]);
      final Uint8List selfie = Uint8List.fromList(<int>[3, 4]);
      VerificationImagePart part(Uint8List bytes) => VerificationImagePart(
        bytes: bytes,
        fileName: 'sample.jpg',
        mimeType: 'image/jpeg',
      );
      // The screen builds new parts from the photos it holds on each press.
      for (var i = 0; i < 2; i++) {
        await controller.startVerification(
          idType: 'philid',
          front: part(front),
          selfie: part(selfie),
        );
      }
      expect(repository.keys.toSet(), hasLength(1));
    },
  );

  test('a new photo or another ID type is a new send with a new key', () async {
    final (VerificationController controller, _Recorder repository) =
        await open(<Result<VerificationStatus>>[lost, lost, lost, lost]);
    final VerificationImagePart front = photo();
    final VerificationImagePart selfie = photo(9);

    await controller.startVerification(
      idType: 'passport',
      front: front,
      selfie: selfie,
    );
    // A selfie taken again, even of the same bytes, is another photo.
    await controller.startVerification(
      idType: 'passport',
      front: front,
      selfie: photo(9),
    );
    await controller.startVerification(
      idType: 'umid',
      front: front,
      selfie: selfie,
    );
    await controller.startVerification(
      idType: 'umid',
      front: front,
      back: photo(5),
      selfie: selfie,
    );
    expect(repository.keys.toSet(), hasLength(4));
  });

  test('a key answered with 409 is never sent again', () async {
    final (
      VerificationController controller,
      _Recorder repository,
    ) = await open(<Result<VerificationStatus>>[
      const Err<VerificationStatus>(ConflictFailure()),
      lost,
    ]);
    final VerificationImagePart front = photo();
    final VerificationImagePart selfie = photo(9);
    await controller.startVerification(
      idType: 'passport',
      front: front,
      selfie: selfie,
    );
    repository.reopen();
    await controller.refresh();
    await controller.startVerification(
      idType: 'passport',
      front: front,
      selfie: selfie,
    );
    expect(repository.keys, hasLength(2));
    expect(repository.keys.first, isNot(repository.keys.last));
  });

  test('a send that opened the request lets the key go', () async {
    final (VerificationController controller, _Recorder repository) =
        await open(<Result<VerificationStatus>>[opened, lost]);
    final VerificationImagePart front = photo();
    final VerificationImagePart selfie = photo(9);
    await controller.startVerification(
      idType: 'passport',
      front: front,
      selfie: selfie,
    );
    repository.reopen();
    await controller.refresh();
    await controller.startVerification(
      idType: 'passport',
      front: front,
      selfie: selfie,
    );
    expect(repository.keys.first, isNot(repository.keys.last));
  });
}

/// Records every key a start carries, answering in order.
class _Recorder implements VerificationRepository {
  _Recorder(this.answers);

  final List<Result<VerificationStatus>> answers;
  final List<String?> keys = <String?>[];
  String _raw = '';

  /// The request is gone again, so the next refresh offers Start.
  void reopen() => _raw = '';

  @override
  Future<Result<VerificationStatusDetail>> loadOwnStatusDetail() async =>
      Ok<VerificationStatusDetail>(
        VerificationStatusDetail(
          stage: ResidentVerificationStage.notStarted,
          rawState: _raw,
        ),
      );

  @override
  Future<Result<VerificationStatus>> submitVerification({
    required String idType,
    required VerificationImagePart front,
    VerificationImagePart? back,
    required VerificationImagePart selfie,
    String? idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    return answers.isEmpty ? opened : answers.removeAt(0);
  }

  static const Result<VerificationStatus> opened = Ok<VerificationStatus>(
    VerificationStatus(
      state: VerificationAttemptState.underReview,
      rawState: 'pending',
    ),
  );

  @override
  Future<Result<List<KycDocument>>> loadDocuments() async =>
      const Ok<List<KycDocument>>(<KycDocument>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
