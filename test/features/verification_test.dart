import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_controller.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/features/verification/data/verification_status_dto.dart';
import 'package:taytay_resident/features/verification/domain/kyc_claim.dart';
import 'package:taytay_resident/features/verification/domain/verification_repository.dart';
import 'package:taytay_resident/features/verification/domain/verification_status_detail.dart';
import 'package:taytay_resident/features/verification/presentation/verification_controller.dart';

/// A repository each test dictates.
class FakeVerificationRepository implements VerificationRepository {
  FakeVerificationRepository({this.detail, this.correctionOutcome});

  Result<VerificationStatusDetail>? detail;
  Result<void>? correctionOutcome;

  final List<String> correctionKeys = <String>[];
  final List<Map<VerificationItemCategory, String>> sentCorrections =
      <Map<VerificationItemCategory, String>>[];

  @override
  Future<Result<VerificationStatusDetail>> loadOwnStatusDetail() async =>
      detail ??
      const Ok<VerificationStatusDetail>(VerificationStatusDetail.unknown);

  @override
  Future<Result<VerificationStatus>> loadOwnStatus() async =>
      const Err<VerificationStatus>(ServerFailure(isTemporary: true));

  @override
  Future<Result<void>> submitCorrections({
    required Map<VerificationItemCategory, String> corrections,
    required String idempotencyKey,
  }) async {
    correctionKeys.add(idempotencyKey);
    sentCorrections.add(
      Map<VerificationItemCategory, String>.from(corrections),
    );
    return correctionOutcome ?? const Ok<void>(null);
  }

  @override
  Future<Result<VerificationStatus>> openCase({
    required KycClaim claim,
    required String idempotencyKey,
  }) async => const Err<VerificationStatus>(ServerFailure());

  @override
  Future<Result<void>> submitForReview({
    required List<String> documentUploadIds,
    required String idempotencyKey,
  }) async => const Ok<void>(null);
}

Future<SessionController> signedInSession(AccessLevel level) async {
  final store = InMemorySessionStore();
  final controller = SessionController(store: store);
  await controller.signIn(
    resident: ResidentSession(accountId: 'acct-1', accessLevel: level),
    accessToken: 'token',
  );
  return controller;
}

void main() {
  group('stage mapping', () {
    test('every server state maps to a resident stage', () {
      const expected = <VerificationAttemptState, ResidentVerificationStage>{
        VerificationAttemptState.notStarted:
            ResidentVerificationStage.notStarted,
        VerificationAttemptState.draft: ResidentVerificationStage.inProgress,
        VerificationAttemptState.submitted:
            ResidentVerificationStage.pendingReview,
        VerificationAttemptState.underReview:
            ResidentVerificationStage.pendingReview,
        VerificationAttemptState.approved: ResidentVerificationStage.verified,
        VerificationAttemptState.rejected:
            ResidentVerificationStage.unsuccessful,
      };

      expected.forEach((state, stage) {
        expect(
          ResidentVerificationStage.fromAttemptState(state),
          stage,
          reason: state.name,
        );
      });
    });

    test('an unrecognised state degrades to manual review, never verified', () {
      // Fail closed. Mapping an unknown state to verified would grant
      // capabilities the server never granted.
      expect(
        ResidentVerificationStage.fromAttemptState(null),
        ResidentVerificationStage.manualReview,
      );
      expect(
        ResidentVerificationStage.fromAttemptState(null),
        isNot(ResidentVerificationStage.verified),
      );
    });

    test('the Master Command states are all reachable', () {
      // Not Started, In Progress, Pending Review, Needs More Information,
      // Verified, Unsuccessful / Cannot Verify Automatically.
      expect(ResidentVerificationStage.values, hasLength(7));
      expect(
        ResidentVerificationStage.values.map((s) => s.name),
        containsAll(<String>[
          'notStarted',
          'inProgress',
          'pendingReview',
          'needsMoreInformation',
          'verified',
          'unsuccessful',
          'manualReview',
        ]),
      );
    });

    test('every stage has a label and a plain summary', () {
      for (final stage in ResidentVerificationStage.values) {
        expect(stage.label, isNotEmpty, reason: stage.name);
        expect(stage.summary.length, greaterThan(20), reason: stage.name);
      }
    });

    test('no stage copy promises a turnaround time', () {
      // The app has no basis for "three working days", a municipal queue does
      // not honour it, and a missed promise costs more than saying nothing.
      final numeric = RegExp(r'\b\d+\s*(day|days|hour|hours|week|weeks)\b');
      for (final stage in ResidentVerificationStage.values) {
        final copy = '${stage.label} ${stage.summary}'.toLowerCase();
        expect(numeric.hasMatch(copy), isFalse, reason: stage.name);
        for (final phrase in <String>[
          'within',
          'guarantee',
          'immediately approved',
        ]) {
          expect(
            copy,
            isNot(contains(phrase)),
            reason: '${stage.name}/$phrase',
          );
        }
      }
    });

    test('every stage that needs action offers one', () {
      for (final stage in ResidentVerificationStage.values) {
        if (!stage.needsResidentAction) continue;
        expect(stage.nextActionLabel, isNotNull, reason: stage.name);
      }
    });

    test('every stage without an in-app action offers the municipal hall', () {
      // Acceptance 3: every failed/unsuccessful state has a safe next step.
      for (final stage in <ResidentVerificationStage>[
        ResidentVerificationStage.unsuccessful,
        ResidentVerificationStage.manualReview,
      ]) {
        expect(stage.suggestsInPerson, isTrue, reason: stage.name);
      }
    });
  });

  group('decoder — privacy', () {
    /// A payload carrying everything a citizen must never receive.
    Map<String, dynamic> hostilePayload() => <String, dynamic>{
      'state': 'under_review',
      'submitted_categories': <String>['personalDetails', 'address'],
      'resident_guidance': 'We are checking your details.',
      // None of the following may survive decoding.
      'reviewed_by': 'staff-uuid-1',
      'reviewer_name': 'Maria Santos',
      'reviewer_id': 'staff-1',
      'risk_score': 0.87,
      'fraud_score': 12,
      'confidence': 0.44,
      'internal_notes': 'Applicant looks suspicious',
      'remarks': 'Escalate to supervisor',
      'caseworker_notes': 'Called barangay captain',
      'audit_trail': <Object>[
        <String, dynamic>{'actor_name': 'Maria Santos', 'action': 'reviewed'},
      ],
      'status_changes': <Object>[
        <String, dynamic>{'actor_id': 'staff-1', 'to': 'under_review'},
      ],
      'match_candidates': <Object>[
        <String, dynamic>{'name': 'Juan Dela Cruz', 'resident_id': 'r-99'},
      ],
      'matched_resident': <String, dynamic>{'name': 'Juan Dela Cruz'},
      'rejection_code': 'HEURISTIC_NAME_MISMATCH',
      'rejection_heuristic': 'levenshtein > 3',
    };

    test('staff-only and third-party fields do not survive decoding', () {
      final detail = VerificationStatusDto.fromJson(hostilePayload());
      final rendered = <String>[
        detail.rawState,
        detail.residentGuidance ?? '',
        detail.toString(),
        ...detail.submittedCategories.map((c) => '${c.label} ${c.description}'),
        ...detail.issues.map((i) => '${i.category.label} ${i.instruction}'),
      ].join(' ').toLowerCase();

      for (final forbidden in <String>[
        'maria santos',
        'juan dela cruz',
        'staff-1',
        'staff-uuid-1',
        'suspicious',
        'escalate',
        'barangay captain',
        'heuristic',
        'levenshtein',
        'r-99',
        '0.87',
        '0.44',
      ]) {
        expect(rendered, isNot(contains(forbidden)), reason: forbidden);
      }
    });

    test('the decoder reads an allow-list, and names what it refuses', () {
      // A deny-list decoder is one forgotten key away from rendering a note.
      expect(VerificationStatusDto.allowedKeys, isNotEmpty);
      expect(
        VerificationStatusDto.allowedKeys.intersection(
          VerificationStatusDto.forbiddenKeys,
        ),
        isEmpty,
      );
      for (final forbidden in <String>[
        'reviewed_by',
        'risk_score',
        'internal_notes',
        'audit_trail',
        'match_candidates',
        'rejection_heuristic',
      ]) {
        expect(VerificationStatusDto.forbiddenKeys, contains(forbidden));
      }
    });

    test('the detail type has no field for staff-only data', () {
      // Guards the shape itself: a server that sent more finds nowhere to put it.
      final detail = VerificationStatusDto.fromJson(hostilePayload());
      expect(detail.toString(), isNot(contains('review')));
      expect(detail.toString(), contains('pendingReview'));
    });
  });

  group('decoder — states and items', () {
    test('recognised states map through', () {
      const cases = <String, ResidentVerificationStage>{
        'not_started': ResidentVerificationStage.notStarted,
        'draft': ResidentVerificationStage.inProgress,
        'in_progress': ResidentVerificationStage.inProgress,
        'submitted': ResidentVerificationStage.pendingReview,
        'under_review': ResidentVerificationStage.pendingReview,
        'approved': ResidentVerificationStage.verified,
        'verified': ResidentVerificationStage.verified,
        'rejected': ResidentVerificationStage.unsuccessful,
      };
      cases.forEach((wire, stage) {
        final detail = VerificationStatusDto.fromJson(<String, dynamic>{
          'state': wire,
        });
        expect(detail.stage, stage, reason: wire);
        expect(detail.rawState, wire);
      });
    });

    test('an unknown state degrades and keeps the raw value for support', () {
      final detail = VerificationStatusDto.fromJson(<String, dynamic>{
        'state': 'awaiting_barangay_endorsement',
      });

      expect(detail.stage, ResidentVerificationStage.manualReview);
      expect(detail.rawState, 'awaiting_barangay_endorsement');
      expect(detail.isUnrecognised, isTrue);
    });

    test('submitted categories decode, unknown ones are dropped', () {
      final detail = VerificationStatusDto.fromJson(<String, dynamic>{
        'state': 'submitted',
        'submitted_categories': <String>[
          'personalDetails',
          'address',
          'someFutureCategory',
        ],
      });

      expect(detail.submittedCategories, hasLength(2));
      expect(
        detail.submittedCategories,
        containsAll(<VerificationItemCategory>[
          VerificationItemCategory.personalDetails,
          VerificationItemCategory.address,
        ]),
      );
    });

    test('issues need a known category and an instruction', () {
      final detail = VerificationStatusDto.fromJson(<String, dynamic>{
        'state': 'under_review',
        'issues': <Object>[
          <String, dynamic>{
            'category': 'address',
            'instruction': 'Add your house number.',
          },
          // No instruction: a resident cannot act on it.
          <String, dynamic>{'category': 'personalDetails'},
          // Unknown category: showing a raw code invites guessing.
          <String, dynamic>{'category': 'mystery', 'instruction': 'Fix it.'},
          'not an object',
        ],
      });

      expect(detail.issues, hasLength(1));
      expect(detail.issues.single.category, VerificationItemCategory.address);
    });

    test('a non-object payload decodes to the unknown default', () {
      expect(
        VerificationStatusDto.fromJson('nonsense').stage,
        ResidentVerificationStage.notStarted,
      );
      expect(VerificationStatusDto.fromJson(null).rawState, isEmpty);
    });
  });

  group('centralized unlock — no restart', () {
    test('a verified status raises the session level immediately', () async {
      // Acceptance 2. The router listens to SessionController, so this is what
      // makes the digital ID reachable in the same frame.
      final session = await signedInSession(AccessLevel.unverified);
      addTearDown(session.dispose);

      final controller = VerificationController(
        repository: FakeVerificationRepository(
          detail: const Ok<VerificationStatusDetail>(
            VerificationStatusDetail(
              stage: ResidentVerificationStage.verified,
              rawState: 'approved',
            ),
          ),
        ),
        session: session,
      );
      addTearDown(controller.dispose);

      expect(session.accessLevel, AccessLevel.unverified);
      await controller.refresh();
      expect(session.accessLevel, AccessLevel.verified);
    });

    test(
      'the session controller notifies, so the router re-evaluates',
      () async {
        final session = await signedInSession(AccessLevel.unverified);
        addTearDown(session.dispose);

        var notifications = 0;
        session.addListener(() => notifications++);

        final controller = VerificationController(
          repository: FakeVerificationRepository(
            detail: const Ok<VerificationStatusDetail>(
              VerificationStatusDetail(
                stage: ResidentVerificationStage.verified,
                rawState: 'approved',
              ),
            ),
          ),
          session: session,
        );
        addTearDown(controller.dispose);

        await controller.refresh();
        expect(notifications, 1);
      },
    );

    test('a non-verified status never raises the level', () async {
      for (final stage in <ResidentVerificationStage>[
        ResidentVerificationStage.notStarted,
        ResidentVerificationStage.inProgress,
        ResidentVerificationStage.pendingReview,
        ResidentVerificationStage.needsMoreInformation,
        ResidentVerificationStage.unsuccessful,
        ResidentVerificationStage.manualReview,
      ]) {
        final session = await signedInSession(AccessLevel.unverified);
        addTearDown(session.dispose);

        final controller = VerificationController(
          repository: FakeVerificationRepository(
            detail: Ok<VerificationStatusDetail>(
              VerificationStatusDetail(stage: stage, rawState: 'whatever'),
            ),
          ),
          session: session,
        );
        addTearDown(controller.dispose);

        await controller.refresh();
        expect(session.accessLevel, AccessLevel.unverified, reason: stage.name);
      }
    });

    test(
      'a status that stops saying verified lowers the level again',
      () async {
        // A revoked or suspended verification must take the capability with it.
        final session = await signedInSession(AccessLevel.verified);
        addTearDown(session.dispose);

        final controller = VerificationController(
          repository: FakeVerificationRepository(
            detail: const Ok<VerificationStatusDetail>(
              VerificationStatusDetail(
                stage: ResidentVerificationStage.manualReview,
                rawState: 'suspended',
              ),
            ),
          ),
          session: session,
        );
        addTearDown(controller.dispose);

        await controller.refresh();
        expect(session.accessLevel, AccessLevel.unverified);
      },
    );

    test(
      'a failed load never changes the level or clears the last status',
      () async {
        final session = await signedInSession(AccessLevel.unverified);
        addTearDown(session.dispose);

        final repository = FakeVerificationRepository(
          detail: const Ok<VerificationStatusDetail>(
            VerificationStatusDetail(
              stage: ResidentVerificationStage.pendingReview,
              rawState: 'under_review',
            ),
          ),
        );
        final controller = VerificationController(
          repository: repository,
          session: session,
        );
        addTearDown(controller.dispose);

        await controller.refresh();
        expect(
          controller.status?.stage,
          ResidentVerificationStage.pendingReview,
        );

        // Now the network drops.
        repository.detail = const Err<VerificationStatusDetail>(
          NetworkFailure(),
        );
        await controller.refresh();

        expect(controller.failure, isA<NetworkFailure>());
        expect(
          controller.status?.stage,
          ResidentVerificationStage.pendingReview,
          reason: 'a resident should not watch their status vanish',
        );
        expect(session.accessLevel, AccessLevel.unverified);
      },
    );

    test('verification cannot manufacture a session for a guest', () async {
      final session = SessionController(store: InMemorySessionStore());
      addTearDown(session.dispose);
      await session.restore();

      final controller = VerificationController(
        repository: FakeVerificationRepository(
          detail: const Ok<VerificationStatusDetail>(
            VerificationStatusDetail(
              stage: ResidentVerificationStage.verified,
              rawState: 'approved',
            ),
          ),
        ),
        session: session,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(session.accessLevel, AccessLevel.guest);
    });
  });

  group('needs-more-information correction flow', () {
    VerificationStatusDetail withIssues() => const VerificationStatusDetail(
      stage: ResidentVerificationStage.needsMoreInformation,
      rawState: 'under_review',
      issues: <VerificationItemIssue>[
        VerificationItemIssue(
          category: VerificationItemCategory.address,
          instruction: 'Add your house number.',
        ),
      ],
    );

    Future<(VerificationController, FakeVerificationRepository)> build() async {
      final session = await signedInSession(AccessLevel.unverified);
      addTearDown(session.dispose);
      final repository = FakeVerificationRepository(
        detail: Ok<VerificationStatusDetail>(withIssues()),
      );
      final controller = VerificationController(
        repository: repository,
        session: session,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      return (controller, repository);
    }

    test('a correction can only be entered for a flagged category', () async {
      final (controller, _) = await build();

      controller.updateCorrection(
        VerificationItemCategory.personalDetails,
        'Ana',
      );
      expect(
        controller.corrections,
        isEmpty,
        reason: 'the office did not flag personal details',
      );

      controller.updateCorrection(VerificationItemCategory.address, '12 Rizal');
      expect(
        controller.corrections[VerificationItemCategory.address],
        '12 Rizal',
      );
    });

    test('sending is blocked until every flagged item is answered', () async {
      final (controller, repository) = await build();

      expect(controller.correctionsComplete, isFalse);
      expect(await controller.submitCorrections(), isFalse);
      expect(repository.correctionKeys, isEmpty);

      controller.updateCorrection(VerificationItemCategory.address, '   ');
      expect(
        controller.correctionsComplete,
        isFalse,
        reason: 'whitespace only',
      );

      controller.updateCorrection(VerificationItemCategory.address, '12 Rizal');
      expect(controller.correctionsComplete, isTrue);
    });

    test(
      'sending carries an idempotency key and only the flagged item',
      () async {
        final (controller, repository) = await build();
        controller.updateCorrection(
          VerificationItemCategory.address,
          '12 Rizal',
        );

        expect(await controller.submitCorrections(), isTrue);

        expect(repository.correctionKeys, hasLength(1));
        expect(repository.correctionKeys.single, isNotEmpty);
        expect(
          repository.sentCorrections.single.keys,
          <VerificationItemCategory>[VerificationItemCategory.address],
        );
      },
    );

    test('a failed send keeps the typed values and reuses the key', () async {
      final (controller, repository) = await build();
      repository.correctionOutcome = const Err<void>(NetworkFailure());
      controller.updateCorrection(VerificationItemCategory.address, '12 Rizal');

      expect(await controller.submitCorrections(), isFalse);
      expect(controller.failure, isA<NetworkFailure>());
      expect(
        controller.corrections[VerificationItemCategory.address],
        '12 Rizal',
        reason: 'a resident should not retype after a dropped connection',
      );

      await controller.submitCorrections();
      expect(repository.correctionKeys, hasLength(2));
      expect(
        repository.correctionKeys.first,
        repository.correctionKeys.last,
        reason: 'a retry must not create a second review item',
      );
    });

    test('a successful send clears the typed values', () async {
      final (controller, _) = await build();
      controller.updateCorrection(VerificationItemCategory.address, '12 Rizal');
      await controller.submitCorrections();

      expect(controller.corrections, isEmpty);
    });
  });

  group('honest seams', () {
    test('categories describe kinds, never values', () {
      for (final category in VerificationItemCategory.values) {
        expect(category.label, isNotEmpty, reason: category.name);
        expect(category.description, isNotEmpty, reason: category.name);
      }
    });
  });
}
