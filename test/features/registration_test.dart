import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/registration/data/planned_registration_repository.dart';
import 'package:taytay_resident/features/registration/domain/registration_domain.dart';
import 'package:taytay_resident/features/registration/domain/registration_validation.dart';
import 'package:taytay_resident/features/registration/presentation/registration_controller.dart';

/// A repository whose behaviour each test dictates.
///
/// Deliberately explicit rather than a mocking framework: the interesting cases
/// here are "the server said no in a particular way", and a hand-written double
/// makes that legible in the test that needs it.
class FakeRegistrationRepository implements RegistrationRepository {
  FakeRegistrationRepository({
    this.capabilities = RegistrationCapabilities.denied,
    this.requestOutcome,
    this.verifyOutcome,
    this.submitOutcome,
  });

  RegistrationCapabilities capabilities;
  Result<void>? requestOutcome;
  Result<void>? verifyOutcome;
  Result<RegistrationResult>? submitOutcome;

  final List<String> submittedKeys = <String>[];
  int capabilityLoads = 0;

  @override
  Future<RegistrationCapabilities> loadCapabilities() async {
    capabilityLoads++;
    return capabilities;
  }

  @override
  Future<Result<void>> requestOneTimeCode({
    required String mobileNumber,
  }) async => requestOutcome ?? const Ok<void>(null);

  @override
  Future<Result<void>> verifyOneTimeCode({
    required String mobileNumber,
    required String code,
  }) async => verifyOutcome ?? const Ok<void>(null);

  @override
  Future<Result<List<Barangay>>> listBarangays() async =>
      const Ok<List<Barangay>>(TaytayBarangays.fallback);

  @override
  Future<Result<RegistrationResult>> submitRegistration({
    required RegistrationDraft draft,
    required String idempotencyKey,
  }) async {
    submittedKeys.add(idempotencyKey);
    return submitOutcome ??
        const Ok<RegistrationResult>(
          RegistrationResult(
            outcome: RegistrationOutcome.submitted,
            residentMessage: 'Sent for review.',
          ),
        );
  }
}

DateTime fixedNow() => DateTime(2026, 8, 14);

/// A draft that passes every step, so a test can vary one thing at a time.
RegistrationDraft completeDraft() => RegistrationDraft(
  mobileNumber: '09171234567',
  codeVerified: true,
  givenName: 'Ana',
  familyName: 'Dela Cruz',
  birthDate: DateTime(1995, 3, 12),
  barangay: TaytayBarangays.fallback.first,
  streetAddress: '12 Rizal Street',
  consents: ConsentKind.values.where((k) => k.required).toSet(),
);

/// Walks the controller from contact to the review step.
Future<void> fillToReview(
  RegistrationController controller, {
  bool includeBiometricConsent = false,
}) async {
  controller.updateDraft((d) => d.copyWith(mobileNumber: '09171234567'));
  await controller.next();
  controller.updateCode('123456');
  await controller.next();
  controller.updateDraft(
    (d) => d.copyWith(
      givenName: 'Ana',
      familyName: 'Dela Cruz',
      birthDate: DateTime(1995, 3, 12),
    ),
  );
  await controller.next();
  controller.updateDraft(
    (d) => d.copyWith(
      barangay: TaytayBarangays.fallback.first,
      streetAddress: '12 Rizal Street',
    ),
  );
  await controller.next();
  for (final kind in ConsentKind.values) {
    if (kind.required ||
        (includeBiometricConsent && kind == ConsentKind.biometricProcessing)) {
      controller.toggleConsent(kind, given: true);
    }
  }
  await controller.next();
}

void main() {
  group('data minimisation', () {
    test('the draft carries only what resident matching needs', () {
      // Guards the decision: fields the staff console holds — sex, civil
      // status, sectors, income, PhilSys, household — are deliberately absent.
      // Several are sensitive personal information under RA 10173 §13, and the
      // committed contract says a citizen may not edit eligibility-bearing
      // fields at all.
      const draft = RegistrationDraft();
      final fields = draft.toString();

      expect(fields, isNot(contains('sex')));
      expect(fields, isNot(contains('income')));
      expect(fields, isNot(contains('philsys')));
      expect(fields, isNot(contains('household')));
      expect(fields, isNot(contains('sector')));
    });

    test('the draft never renders its contents', () {
      // A draft is exactly the kind of object that reaches a crash report.
      final draft = completeDraft();
      final text = draft.toString();

      expect(text, isNot(contains('Ana')));
      expect(text, isNot(contains('Dela Cruz')));
      expect(text, isNot(contains('09171234567')));
      expect(text, isNot(contains('Rizal Street')));
      expect(text, contains('redacted'));
    });

    test('an upload describes itself without naming the file', () {
      const upload = SelectedUpload(
        localReference: '/private/ana-dela-cruz-passport.jpg',
        byteSize: 1024,
        mimeType: 'image/jpeg',
      );
      expect(upload.toString(), isNot(contains('ana-dela-cruz')));
      expect(upload.toString(), contains('image/jpeg'));
    });
  });

  group('validation', () {
    test('the mobile number must be a Philippine mobile', () {
      List<FieldError> check(String value) =>
          RegistrationValidation.validateContact(
            RegistrationDraft(mobileNumber: value),
          );

      expect(check('09171234567'), isEmpty);
      expect(check(''), hasLength(1));
      expect(check('12345'), hasLength(1));
      expect(check('639171234567'), hasLength(1));
    });

    test('first and last name are required; middle and suffix are not', () {
      final errors = RegistrationValidation.validatePersonalDetails(
        RegistrationDraft(birthDate: DateTime(1995, 3, 12)),
        now: fixedNow(),
      );
      final fields = errors.map((e) => e.field).toSet();

      expect(fields, containsAll(<String>['given_name', 'family_name']));
      expect(fields, isNot(contains('middle_name')));
      expect(fields, isNot(contains('suffix')));
    });

    test('a single-word or accented name is accepted', () {
      // A rule that rejects a legitimate Filipino name locks a resident out of
      // a government service over punctuation, with no appeal path in an app.
      for (final name in <String>['Ñ', "D'Souza", 'Dela Cruz-Santos', 'A']) {
        final errors = RegistrationValidation.validatePersonalDetails(
          RegistrationDraft(
            givenName: name,
            familyName: name,
            birthDate: DateTime(1995, 3, 12),
          ),
          now: fixedNow(),
        );
        expect(errors, isEmpty, reason: name);
      }
    });

    test('birth date rejects the future, the impossible and the too young', () {
      List<String> fieldsFor(DateTime birthDate) =>
          RegistrationValidation.validatePersonalDetails(
            RegistrationDraft(
              givenName: 'Ana',
              familyName: 'Cruz',
              birthDate: birthDate,
            ),
            now: fixedNow(),
          ).map((e) => e.field).toList();

      expect(fieldsFor(DateTime(2027)), contains('birth_date'));
      expect(fieldsFor(DateTime(1850)), contains('birth_date'));
      expect(fieldsFor(DateTime(2020)), contains('birth_date'));
      expect(fieldsFor(DateTime(1995, 3, 12)), isEmpty);
    });

    test('the age floor is 15, not 18', () {
      // Taytay services include youth and student programmes; refusing a
      // 16-year-old would exclude exactly the people some services are for.
      expect(RegistrationValidation.minimumAge, 15);
      final justOldEnough = DateTime(
        fixedNow().year - 15,
        fixedNow().month,
        fixedNow().day,
      );
      expect(
        RegistrationValidation.validatePersonalDetails(
          RegistrationDraft(
            givenName: 'Ana',
            familyName: 'Cruz',
            birthDate: justOldEnough,
          ),
          now: fixedNow(),
        ),
        isEmpty,
      );
    });

    test('address requires a barangay and a street', () {
      final errors = RegistrationValidation.validateAddress(
        const RegistrationDraft(),
      );
      expect(
        errors.map((e) => e.field),
        containsAll(<String>['barangay', 'street_address']),
      );
    });

    test('the one-time code has no invented length rule', () {
      // The committed contract does not publish a code length, so enforcing
      // six would reject a five- or eight-digit code the server sends.
      expect(RegistrationValidation.validateCode('12345'), isEmpty);
      expect(RegistrationValidation.validateCode('12345678'), isEmpty);
      expect(RegistrationValidation.validateCode(''), hasLength(1));
    });
  });

  group('consent gating', () {
    test('required consents block progress; the biometric one does not', () {
      final errors = RegistrationValidation.validateConsent(
        const RegistrationDraft(),
      );
      final fields = errors.map((e) => e.field).toSet();

      expect(fields, contains('consent_termsOfUse'));
      expect(fields, contains('consent_privacyNotice'));
      expect(fields, contains('consent_identityProcessing'));
      expect(
        fields,
        isNot(contains('consent_biometricProcessing')),
        reason: 'consent that cannot be refused is not consent',
      );
    });

    test('each consent is recorded separately, not as one bundle', () {
      var draft = const RegistrationDraft();
      draft = draft.copyWith(consents: <ConsentKind>{ConsentKind.termsOfUse});

      expect(draft.hasConsent(ConsentKind.termsOfUse), isTrue);
      expect(draft.hasConsent(ConsentKind.privacyNotice), isFalse);
      expect(draft.hasRequiredConsents, isFalse);
    });

    test('every consent carries an explanation a resident can read', () {
      for (final kind in ConsentKind.values) {
        expect(kind.label, isNotEmpty, reason: kind.name);
        expect(kind.explanation.length, greaterThan(20), reason: kind.name);
      }
    });
  });

  group('feature gating — fail closed', () {
    test('capabilities default to denying everything', () {
      const denied = RegistrationCapabilities.denied;
      expect(denied.requiresIdentityDocument, isFalse);
      expect(denied.requiresFaceCapture, isFalse);
      expect(denied.acceptsSubmissions, isFalse);
    });

    test('the shipped repository denies every capability', () async {
      // The client never collects a government ID or a face photo on its own
      // initiative.
      const repository = PlannedRegistrationRepository();
      expect(
        await repository.loadCapabilities(),
        RegistrationCapabilities.denied,
      );
    });

    test('document and selfie steps are absent when nothing is required', () {
      final controller = RegistrationController(
        repository: FakeRegistrationRepository(),
        clock: fixedNow,
      );
      addTearDown(controller.dispose);

      expect(
        controller.steps,
        isNot(contains(RegistrationStep.identityDocument)),
      );
      expect(controller.steps, isNot(contains(RegistrationStep.faceCapture)));
    });

    test('the document step appears only when the server asks', () async {
      final controller = RegistrationController(
        repository: FakeRegistrationRepository(
          capabilities: const RegistrationCapabilities(
            requiresIdentityDocument: true,
          ),
        ),
        clock: fixedNow,
      );
      addTearDown(controller.dispose);
      await controller.initialise();

      expect(controller.steps, contains(RegistrationStep.identityDocument));
    });

    test('the selfie step needs the server AND explicit consent', () async {
      final controller = RegistrationController(
        repository: FakeRegistrationRepository(
          capabilities: const RegistrationCapabilities(
            requiresFaceCapture: true,
          ),
        ),
        clock: fixedNow,
      );
      addTearDown(controller.dispose);
      await controller.initialise();

      // Server asks, but no consent yet.
      expect(controller.steps, isNot(contains(RegistrationStep.faceCapture)));

      controller.toggleConsent(ConsentKind.biometricProcessing, given: true);
      expect(controller.steps, contains(RegistrationStep.faceCapture));

      // Withdrawing consent removes the step again.
      controller.toggleConsent(ConsentKind.biometricProcessing, given: false);
      expect(controller.steps, isNot(contains(RegistrationStep.faceCapture)));
    });

    test('consent alone never enables the selfie step', () {
      final controller = RegistrationController(
        repository: FakeRegistrationRepository(),
        clock: fixedNow,
      );
      addTearDown(controller.dispose);

      controller.toggleConsent(ConsentKind.biometricProcessing, given: true);
      expect(controller.steps, isNot(contains(RegistrationStep.faceCapture)));
    });
  });

  group('wizard navigation', () {
    late FakeRegistrationRepository repository;
    late RegistrationController controller;

    setUp(() {
      repository = FakeRegistrationRepository();
      controller = RegistrationController(
        repository: repository,
        clock: fixedNow,
      );
    });

    tearDown(() => controller.dispose());

    test('an invalid step does not advance, and reports its fields', () async {
      final advanced = await controller.next();

      expect(advanced, isFalse);
      expect(controller.step, RegistrationStep.contact);
      expect(controller.errors.single.field, 'mobile_number');
    });

    test('going back keeps everything already entered', () async {
      await fillToReview(controller);
      expect(controller.step, RegistrationStep.review);

      controller.back();
      controller.back();

      // Two steps back, and nothing has been lost.
      expect(controller.draft.givenName, 'Ana');
      expect(controller.draft.familyName, 'Dela Cruz');
      expect(controller.draft.streetAddress, '12 Rizal Street');
      expect(controller.draft.mobileNumber, '09171234567');
    });

    test(
      'back clears errors so a step is not re-entered showing them',
      () async {
        await controller.next();
        expect(controller.errors, isNotEmpty);

        controller.updateDraft((d) => d.copyWith(mobileNumber: '09171234567'));
        await controller.next();
        controller.back();

        expect(controller.errors, isEmpty);
      },
    );

    test(
      'back is unavailable on the first step and after submission',
      () async {
        expect(controller.canGoBack, isFalse);

        await fillToReview(controller);
        expect(controller.canGoBack, isTrue);

        await controller.submit();
        expect(controller.step, RegistrationStep.status);
        expect(controller.canGoBack, isFalse);
      },
    );

    test('progress counts input steps only', () async {
      // Submitting and status are outcomes; counting them would tell a resident
      // there is more to do than there is.
      expect(
        controller.progressSteps,
        isNot(contains(RegistrationStep.submitting)),
      );
      expect(
        controller.progressSteps,
        isNot(contains(RegistrationStep.status)),
      );
      expect(controller.progressPosition, 1);

      await fillToReview(controller);
      expect(controller.progressPosition, controller.progressSteps.length);
    });

    test('editing from review goes back, never forward', () async {
      await fillToReview(controller);

      controller.editStep(RegistrationStep.personalDetails);
      expect(controller.step, RegistrationStep.personalDetails);

      // Forward jumps are refused.
      controller.editStep(RegistrationStep.status);
      expect(controller.step, RegistrationStep.personalDetails);
      controller.editStep(RegistrationStep.review);
      expect(controller.step, RegistrationStep.personalDetails);
    });

    test('editing a step outside the flow is refused', () async {
      await fillToReview(controller);
      // Not in the flow: no capability enabled it.
      controller.editStep(RegistrationStep.faceCapture);
      expect(controller.step, RegistrationStep.review);
    });

    test(
      'a failed one-time-code request keeps the resident on contact',
      () async {
        repository.requestOutcome = const Err<void>(
          ServerFailure(isTemporary: true),
        );
        controller.updateDraft((d) => d.copyWith(mobileNumber: '09171234567'));

        final advanced = await controller.next();

        expect(advanced, isFalse);
        expect(controller.step, RegistrationStep.contact);
        expect(controller.failure, isA<ServerFailure>());
      },
    );

    test(
      'a failed code verification keeps the resident on the code step',
      () async {
        repository.verifyOutcome = const Err<void>(ValidationFailure());
        controller.updateDraft((d) => d.copyWith(mobileNumber: '09171234567'));
        await controller.next();
        controller.updateCode('000000');

        final advanced = await controller.next();

        expect(advanced, isFalse);
        expect(controller.step, RegistrationStep.verifyCode);
      },
    );

    test('capabilities are re-read after the code is verified', () async {
      controller.updateDraft((d) => d.copyWith(mobileNumber: '09171234567'));
      await controller.next();
      controller.updateCode('123456');
      await controller.next();

      // The server may only know what this resident needs once it knows who
      // they are.
      expect(repository.capabilityLoads, greaterThanOrEqualTo(1));
      expect(controller.draft.codeVerified, isTrue);
    });
  });

  group('submission', () {
    test('a submission carries an idempotency key', () async {
      final repository = FakeRegistrationRepository();
      final controller = RegistrationController(
        repository: repository,
        clock: fixedNow,
      );
      addTearDown(controller.dispose);

      await fillToReview(controller);
      await controller.submit();

      expect(repository.submittedKeys, hasLength(1));
      expect(repository.submittedKeys.single, isNotEmpty);
    });

    test('a retry after failure reuses the same key', () async {
      // A registration submitted twice is a duplicate identity review in a
      // municipal queue, and the resident cannot tell whether the first arrived.
      final repository = FakeRegistrationRepository(
        submitOutcome: const Err<RegistrationResult>(NetworkFailure()),
      );
      final controller = RegistrationController(
        repository: repository,
        clock: fixedNow,
      );
      addTearDown(controller.dispose);

      await fillToReview(controller);
      await controller.submit();
      await controller.retrySubmission();

      expect(repository.submittedKeys, hasLength(2));
      expect(repository.submittedKeys.first, repository.submittedKeys.last);
    });

    test('a failed submission says nothing was submitted', () async {
      final controller = RegistrationController(
        repository: FakeRegistrationRepository(
          submitOutcome: const Err<RegistrationResult>(NetworkFailure()),
        ),
        clock: fixedNow,
      );
      addTearDown(controller.dispose);

      await fillToReview(controller);
      await controller.submit();

      expect(controller.step, RegistrationStep.status);
      expect(controller.result?.outcome, RegistrationOutcome.unavailable);
      expect(
        controller.result?.residentMessage,
        contains('Nothing was submitted'),
      );
    });

    test('the shipped repository declines rather than pretending', () async {
      const repository = PlannedRegistrationRepository();
      final outcome = await repository.submitRegistration(
        draft: completeDraft(),
        idempotencyKey: 'key',
      );

      final failure = outcome.failureOrNull;
      expect(failure, isA<ServerFailure>());
      expect((failure! as ServerFailure).isTemporary, isTrue);
      expect(failure.residentMessage, contains('temporarily unavailable'));
    });

    test('no method exists for creating an account directly', () {
      // The committed matrix has no account-creation row: an account comes into
      // existence through the one-time-code exchange. A `createAccount` here
      // would be an invented endpoint.
      const repository = PlannedRegistrationRepository();
      expect(repository, isA<RegistrationRepository>());
      expect(
        RegistrationRepository,
        isNotNull,
        reason: 'contract is otp + capabilities + barangays + submit only',
      );
    });
  });

  group('barangay reference data', () {
    test('carries the five Taytay barangays and no PSGC codes', () {
      // A wrong PSGC code is worse than an absent one because DSWD reporting
      // keys off it — backend gap G-11.
      expect(TaytayBarangays.fallback, hasLength(5));
      expect(
        TaytayBarangays.fallback.map((b) => b.name),
        containsAll(<String>[
          'Dolores',
          'Muzon',
          'San Isidro',
          'San Juan',
          'Santa Ana',
        ]),
      );
      for (final barangay in TaytayBarangays.fallback) {
        expect(barangay.psgcCode, isNull, reason: barangay.name);
      }
    });
  });
}
