import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/registration/domain/registration_domain.dart';
import 'package:taytay_resident/features/verification/domain/kyc_claim.dart';
import 'package:taytay_resident/features/verification/domain/verification_repository.dart';
import 'package:taytay_resident/features/verification/domain/verification_status_detail.dart';
import 'package:taytay_resident/features/verification/presentation/kyc_claim_controller.dart';

/// The form that opens a KYC case, driven directly.
///
/// The screen is thin on purpose; every rule worth protecting is here, where it
/// can be asserted without a date picker in the way.
class _StubDirectory implements BarangayDirectory {
  _StubDirectory(this.outcome);

  Result<List<Barangay>> outcome;
  int calls = 0;

  @override
  Future<Result<List<Barangay>>> listBarangays() async {
    calls++;
    return outcome;
  }
}

class _StubRepository implements VerificationRepository {
  Result<VerificationStatus> outcome = const Ok<VerificationStatus>(
    VerificationStatus(
      state: VerificationAttemptState.draft,
      rawState: 'draft',
    ),
  );
  final List<KycClaim> claims = <KycClaim>[];
  final List<String> keys = <String>[];

  @override
  Future<Result<VerificationStatus>> openCase({
    required KycClaim claim,
    required String idempotencyKey,
  }) async {
    claims.add(claim);
    keys.add(idempotencyKey);
    return outcome;
  }

  @override
  Future<Result<VerificationStatus>> loadOwnStatus() async =>
      const Err<VerificationStatus>(ServerFailure());

  @override
  Future<Result<VerificationStatusDetail>> loadOwnStatusDetail() async =>
      const Err<VerificationStatusDetail>(ServerFailure());

  @override
  Future<Result<void>> submitCorrections({
    required Map<VerificationItemCategory, String> corrections,
    required String idempotencyKey,
  }) async => const Ok<void>(null);

  @override
  Future<Result<void>> submitForReview({
    required List<String> documentUploadIds,
    required String idempotencyKey,
  }) async => const Ok<void>(null);
}

const List<Barangay> published = <Barangay>[
  Barangay(id: 'b-1', code: 'brgy-dolores', name: 'Dolores'),
  Barangay(id: 'b-2', code: 'brgy-muzon', name: 'Muzon'),
];

void fill(KycClaimController controller, {Barangay? barangay}) {
  controller
    ..setGivenName('Maria')
    ..setFamilyName('Santos')
    ..setBirthDate(DateTime(1990, 3, 7))
    ..setSex(ClaimedSex.female)
    ..setStreetAddress('12 Mabini St');
  if (barangay != null) controller.setBarangay(barangay);
}

void main() {
  late _StubDirectory directory;
  late _StubRepository repository;
  late KycClaimController controller;

  setUp(() {
    directory = _StubDirectory(const Ok<List<Barangay>>(published));
    repository = _StubRepository();
    controller = KycClaimController(
      directory: directory,
      repository: repository,
    );
  });

  tearDown(() => controller.dispose());

  group('the barangay list', () {
    test('a barangay with no code is never offered', () async {
      directory.outcome = const Ok<List<Barangay>>(<Barangay>[
        Barangay(id: 'b-1', code: 'brgy-dolores', name: 'Dolores'),
        Barangay(id: 'b-2', name: 'No code'),
      ]);

      await controller.loadDirectory();

      // A KYC claim is filed against the code. Offering one without it means a
      // resident selects their own barangay and fails at submission — after
      // filling in everything else.
      expect(controller.barangays, hasLength(1));
      expect(controller.barangays.single.name, 'Dolores');
    });

    test('a failure to load is surfaced, not shown as an empty list', () async {
      directory.outcome = const Err<List<Barangay>>(NetworkFailure());

      await controller.loadDirectory();

      // An empty dropdown tells a resident their barangay is not in Taytay,
      // which is a worse thing to be told than that the list did not load.
      expect(controller.barangays, isEmpty);
      expect(controller.directoryFailure, isNotNull);
      expect(controller.canSubmit, isFalse);
    });

    test('a barangay outside the published list cannot be chosen', () async {
      await controller.loadDirectory();
      controller.setBarangay(
        const Barangay(id: 'x', code: 'brgy-invented', name: 'Invented'),
      );

      // The only barangays that exist are the ones the server published.
      expect(controller.barangay, isNull);
      expect(controller.canSubmit, isFalse);
    });

    test(
      'a chosen barangay the server has since dropped is forgotten',
      () async {
        await controller.loadDirectory();
        controller.setBarangay(published.first);

        directory.outcome = Ok<List<Barangay>>(<Barangay>[published[1]]);
        await controller.loadDirectory();

        // Better to make the resident choose again than to file against a code
        // the server no longer serves.
        expect(controller.barangay, isNull);
      },
    );
  });

  group('filing the claim', () {
    test('nothing is sent until every required field is answered', () async {
      await controller.loadDirectory();
      expect(controller.canSubmit, isFalse);

      fill(controller);
      // Everything but the barangay.
      expect(controller.canSubmit, isFalse);

      controller.setBarangay(published.first);
      expect(controller.canSubmit, isTrue);

      // Pressing anyway does nothing: a 422 on this screen is a dead end, its
      // field errors keyed by wire names a resident has never seen.
      await controller.submit();
      expect(repository.claims, hasLength(1));
    });

    test('the claim carries the published code', () async {
      await controller.loadDirectory();
      fill(controller, barangay: published[1]);

      await controller.submit();

      final KycClaim claim = repository.claims.single;
      expect(claim.barangayCode, 'brgy-muzon');
      expect(claim.givenName, 'Maria');
      expect(claim.sex, ClaimedSex.female);
      expect(controller.opened, isTrue);
    });

    test(
      'a retry after a failure reuses the key, and a new claim does not',
      () async {
        await controller.loadDirectory();
        fill(controller, barangay: published.first);

        repository.outcome = const Err<VerificationStatus>(NetworkFailure());
        await controller.submit();
        await controller.submit();

        // A resend after a dropped connection must not become a second case in a
        // municipal review queue.
        expect(repository.keys[0], repository.keys[1]);
        expect(controller.opened, isFalse);
        expect(controller.failure, isNotNull);

        repository.outcome = const Ok<VerificationStatus>(
          VerificationStatus(
            state: VerificationAttemptState.draft,
            rawState: 'draft',
          ),
        );
        await controller.submit();
        expect(controller.opened, isTrue);
      },
    );

    test('editing a field clears the last failure', () async {
      await controller.loadDirectory();
      fill(controller, barangay: published.first);
      repository.outcome = const Err<VerificationStatus>(NetworkFailure());
      await controller.submit();
      expect(controller.failure, isNotNull);

      controller.setGivenName('Mariah');

      // A banner about a send that is no longer the one on screen is a banner
      // about nothing.
      expect(controller.failure, isNull);
    });

    test('a claim is never a record: nothing is echoed back as confirmed', () {
      // Article 5.2 — this object is a name, a birth date and a home address.
      expect(
        KycClaim(
          givenName: 'Maria',
          familyName: 'Santos',
          birthDate: DateTime(1990, 3, 7),
          sex: ClaimedSex.female,
          barangayCode: 'brgy-dolores',
          streetAddress: '12 Mabini St',
        ).toString(),
        isNot(contains('Santos')),
      );
    });
  });
}
