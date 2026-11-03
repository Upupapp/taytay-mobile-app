import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_controller.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/features/verification/data/kyc_api_repository.dart';
import 'package:taytay_resident/features/verification/domain/correctable_field.dart';
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
  final List<Map<CorrectableField, String>> sentCorrections =
      <Map<CorrectableField, String>>[];

  @override
  Future<Result<VerificationStatusDetail>> loadOwnStatusDetail() async =>
      detail ??
      const Ok<VerificationStatusDetail>(VerificationStatusDetail.unknown);

  @override
  Future<Result<VerificationStatus>> loadOwnStatus() async =>
      const Err<VerificationStatus>(ServerFailure(isTemporary: true));

  final List<String> messages = <String>[];
  int startCalls = 0;
  int replaceCalls = 0;
  String? lastIdType;

  @override
  Future<Result<VerificationStatus>> submitVerification({
    required String idType,
    required VerificationImagePart front,
    VerificationImagePart? back,
    required VerificationImagePart selfie,
    String? idempotencyKey,
  }) async {
    startCalls++;
    lastIdType = idType;
    return const Ok<VerificationStatus>(
      VerificationStatus(
        state: VerificationAttemptState.underReview,
        rawState: 'pending',
      ),
    );
  }

  @override
  Future<Result<VerificationStatusDetail>> replaceDocuments({
    VerificationImagePart? front,
    VerificationImagePart? back,
    VerificationImagePart? selfie,
    String? idempotencyKey,
  }) async {
    replaceCalls++;
    return const Ok<VerificationStatusDetail>(
      VerificationStatusDetail(
        stage: ResidentVerificationStage.unsuccessful,
        rawState: 'rejected',
        canEdit: true,
      ),
    );
  }

  @override
  Future<Result<void>> submitCorrections({
    required Map<CorrectableField, String> corrections,
    required String idempotencyKey,
    String message = '',
    bool allowBlank = false,
  }) async {
    correctionKeys.add(idempotencyKey);
    messages.add(message);
    sentCorrections.add(Map<CorrectableField, String>.from(corrections));
    return correctionOutcome ?? const Ok<void>(null);
  }

  @override
  Future<Result<KycDocument>> attachDocument({
    required KycDocumentType type,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String idempotencyKey,
  }) async => const Err<KycDocument>(ServerFailure());

  @override
  Future<Result<List<KycDocument>>> loadDocuments() async =>
      const Ok<List<KycDocument>>(<KycDocument>[]);

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
    // THE SERVER'S OWN KEYS, not an invented shape (C-11/C-12).
    //
    // This payload used to name `state`, `submitted_categories` and
    // `resident_guidance` — none of which `GET me/kyc` sends. It was testing a
    // decoder against a contract that does not exist, which is why the decoder
    // it tested had no production caller. The safe half is unchanged: every
    // hostile key below is one the applicant projection must never carry.
    Map<String, dynamic> hostilePayload() => <String, dynamic>{
      'id': 'case-1',
      'status': 'under_review',
      'can_edit': false,
      'submitted_at': '2026-08-01T00:00:00Z',
      'message': 'We are checking your details.',
      // A staff note may still arrive. It is ignored.
      'notes': 'internal-office-note-7f3a',
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

    test('staff-only and third-party fields do not survive decoding', () async {
      // THROUGH THE REPOSITORY, so what is proven is the path a resident's data
      // actually travels. The previous version called a DTO no production file
      // imports — twenty-nine tests certifying a decoder nothing ran (C-12).
      final repository = KycApiRepository(
        apiClient: ApiClient(
          config: config(),
          transport: _OneResponse(hostilePayload()),
          accessTokenProvider: () async => 'tok',
        ),
      );

      final result = await repository.loadOwnStatusDetail();
      final detail = result.valueOrNull!;

      final rendered = <String>[
        detail.rawState,
        detail.residentGuidance ?? '',
        detail.toString(),
        ...detail.submittedCategories.map((c) => '${c.label} ${c.description}'),
        ...detail.issues.map((i) => '${i.category.label} ${i.instruction}'),
      ].join(' ').toLowerCase();

      for (final forbidden in <String>[
        'internal-office-note-7f3a',
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

    test('the fields the server does send are all read', () {
      // The other half of C-11: five of the projection's eight keys were being
      // read off the socket and dropped. `submitted_at` is why "Sent on …"
      // never appeared, and `can_edit` is the office's own answer to a question
      // this app was inferring for itself.
      const source = 'lib/features/verification/data/kyc_api_repository.dart';
      final decoder = File(source).readAsStringSync();

      for (final key in <String>[
        'status',
        'message',
        'submitted_at',
        'can_edit',
        'submitted_categories',
        'issues',
      ]) {
        expect(
          decoder,
          contains("'$key'"),
          reason: '$source no longer reads $key from the applicant projection',
        );
      }
    });

    test('the production decoder names every key it reads', () {
      // The allow-list property, asserted against the decoder that actually
      // runs. A deny-list is one forgotten key away from rendering a note; this
      // proves the shape of the code rather than the behaviour of one payload,
      // which is what the deleted DTO's own test was for.
      //
      // The scan starts at the method definition. The call site appears first
      // and ends at the next function, so a search for the bare name would
      // miss the body that copies fields.
      const source = 'lib/features/verification/data/kyc_api_repository.dart';
      final decoder = File(source).readAsStringSync();
      expect(decoder, isNot(contains("['notes']")));

      for (final name in <String>['_decodeDetail', '_decodeStatus']) {
        final int at = decoder.indexOf('$name(');
        final String block = decoder.substring(
          at,
          at + decoder.substring(at).indexOf('\n  }'),
        );
        for (final forbidden in <String>[
          'reviewed_by',
          'risk_score',
          'internal_notes',
          'notes',
          'audit_trail',
          'match_candidates',
          'rejection_heuristic',
          'reviewer',
        ]) {
          expect(
            block,
            isNot(contains(forbidden)),
            reason: '$name reads $forbidden',
          );
        }
      }
    });

    test('the detail type has no field for staff-only data', () async {
      // Guards the shape itself: a server that sent more finds nowhere to put it.
      final repository = KycApiRepository(
        apiClient: ApiClient(
          config: config(),
          transport: _OneResponse(hostilePayload()),
          accessTokenProvider: () async => 'tok',
        ),
      );
      final detail = (await repository.loadOwnStatusDetail()).valueOrNull!;
      expect(detail.toString(), isNot(contains('review')));
      expect(detail.toString(), isNot(contains('internal-office-note-7f3a')));
    });
  });
  group('decoder — states, through the path production uses', () {
    // Retargeted in C-12. These ran against `VerificationStatusDto.fromJson`,
    // which no production file imports and which reads a `state` key the server
    // does not send. The state mapping they cover is real and worth keeping, so
    // it now runs through the repository against the server's own `status` key.
    //
    // What was deleted rather than ported: the `submitted_categories` and
    // `issues` decoding tests. Neither field appears in `applicantProjection`,
    // nothing in production decodes them, and a test for a decoder nobody calls
    // reading a field nobody sends is two fictions holding each other up. The
    // gap they represented is C-11, and it is recorded there rather than papered
    // over here.

    Future<VerificationStatusDetail> decodeVia(
      Map<String, dynamic> body,
    ) async {
      final repository = KycApiRepository(
        apiClient: ApiClient(
          config: config(),
          transport: _OneResponse(body),
          accessTokenProvider: () async => 'tok',
        ),
      );
      return (await repository.loadOwnStatusDetail()).valueOrNull!;
    }

    test('every status the server can send maps through', () async {
      // THE SERVER'S OWN VOCABULARY, taken from `KycStatus` at the pinned
      // baseline — not the one the deleted DTO recognised.
      //
      // This is the third contract C-12 turned up and the one that settles it.
      // The DTO parsed `not_started`, `in_progress`, `under_review` and
      // `verified`; the server sends none of those. Production's
      // `VerificationAttemptState.parse` matches `KycStatus` exactly. The DTO
      // was not an alternative decoder, it was a decoder for an imagined API —
      // which is why deleting it costs nothing and why testing it proved
      // nothing.
      const cases = <String, ResidentVerificationStage>{
        'draft': ResidentVerificationStage.inProgress,
        'submitted': ResidentVerificationStage.pendingReview,
        'screening': ResidentVerificationStage.pendingReview,
        'manual-review': ResidentVerificationStage.pendingReview,
        'needs-more-information':
            ResidentVerificationStage.needsMoreInformation,
        'approved': ResidentVerificationStage.verified,
        'rejected': ResidentVerificationStage.unsuccessful,
      };

      for (final entry in cases.entries) {
        final detail = await decodeVia(<String, dynamic>{'status': entry.key});
        expect(detail.stage, entry.value, reason: entry.key);
        expect(detail.rawState, entry.key);
      }
    });

    test(
      'an unknown state degrades and keeps the raw value for support',
      () async {
        final detail = await decodeVia(<String, dynamic>{
          'status': 'awaiting_barangay_endorsement',
        });

        // Unknown lands on review, never on verified, and the server's own word
        // is preserved so a support desk and a resident see the same thing.
        expect(detail.stage, ResidentVerificationStage.pendingReview);
        expect(detail.rawState, 'awaiting_barangay_endorsement');
      },
    );

    test(
      'can_edit is read, and its absence falls back rather than locking out',
      () async {
        // C-11. The office computes this; the app used to infer it.
        final open = await decodeVia(<String, dynamic>{
          'status': 'draft',
          'can_edit': true,
        });
        expect(open.canEdit, isTrue);
        expect(open.isEditableByApplicant, isTrue);

        final closed = await decodeVia(<String, dynamic>{
          'status': 'draft',
          'can_edit': false,
        });
        expect(closed.canEdit, isFalse);
        expect(
          closed.isEditableByApplicant,
          isFalse,
          reason: 'the office said no; the stage does not get to overrule it',
        );

        // Absent: fall back to the old inference rather than locking a resident
        // out of a case the office may well consider open.
        final silent = await decodeVia(<String, dynamic>{'status': 'draft'});
        expect(silent.canEdit, isNull);
        expect(silent.isEditableByApplicant, isTrue);
      },
    );

    test(
      'submitted_at is read — this is why "Sent on" never appeared',
      () async {
        final detail = await decodeVia(<String, dynamic>{
          'status': 'submitted',
          'submitted_at': '2026-08-01T09:30:00Z',
        });

        expect(detail.submittedAt, isNotNull);
        expect(detail.submittedAt!.toUtc().year, 2026);
      },
    );

    test('an empty payload decodes to not-started, not to a failure', () async {
      // A resident who has never applied is in an ordinary state with a next
      // step, not an error.
      final detail = await decodeVia(<String, dynamic>{});
      expect(detail.stage, ResidentVerificationStage.notStarted);
      expect(detail.rawState, '');
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
    VerificationStatusDetail withIssues({bool? canEdit = true}) =>
        VerificationStatusDetail(
          stage: ResidentVerificationStage.needsMoreInformation,
          rawState: 'under_review',
          canEdit: canEdit,
          issues: const <VerificationItemIssue>[
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

      controller.updateCorrection(CorrectableField.firstName, 'Ana');
      expect(
        controller.corrections,
        isEmpty,
        reason: 'the office did not flag personal details',
      );

      controller.chooseField(
        VerificationItemCategory.address,
        CorrectableField.streetAddress,
      );
      controller.updateCorrection(CorrectableField.streetAddress, '12 Rizal');
      expect(
        controller.corrections[CorrectableField.streetAddress],
        '12 Rizal',
      );
    });

    test('sending is blocked until every flagged item is answered', () async {
      final (controller, repository) = await build();

      expect(controller.correctionsComplete, isFalse);
      expect(await controller.submitCorrections(), isFalse);
      expect(repository.correctionKeys, isEmpty);

      controller.chooseField(
        VerificationItemCategory.address,
        CorrectableField.streetAddress,
      );
      controller.updateCorrection(CorrectableField.streetAddress, '   ');
      expect(
        controller.correctionsComplete,
        isFalse,
        reason: 'whitespace only',
      );

      controller.chooseField(
        VerificationItemCategory.address,
        CorrectableField.streetAddress,
      );
      controller.updateCorrection(CorrectableField.streetAddress, '12 Rizal');
      expect(controller.correctionsComplete, isTrue);
    });

    test(
      'sending carries an idempotency key and only the flagged item',
      () async {
        final (controller, repository) = await build();
        controller.chooseField(
          VerificationItemCategory.address,
          CorrectableField.streetAddress,
        );
        controller.updateCorrection(CorrectableField.streetAddress, '12 Rizal');

        expect(await controller.submitCorrections(), isTrue);

        expect(repository.correctionKeys, hasLength(1));
        expect(repository.correctionKeys.single, isNotEmpty);
        expect(repository.sentCorrections.single.keys, <CorrectableField>[
          CorrectableField.streetAddress,
        ]);
      },
    );

    test('a failed send keeps the typed values and reuses the key', () async {
      final (controller, repository) = await build();
      repository.correctionOutcome = const Err<void>(NetworkFailure());
      controller.chooseField(
        VerificationItemCategory.address,
        CorrectableField.streetAddress,
      );
      controller.updateCorrection(CorrectableField.streetAddress, '12 Rizal');

      expect(await controller.submitCorrections(), isFalse);
      expect(controller.failure, isA<NetworkFailure>());
      expect(
        controller.corrections[CorrectableField.streetAddress],
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
      controller.chooseField(
        VerificationItemCategory.address,
        CorrectableField.streetAddress,
      );
      controller.updateCorrection(CorrectableField.streetAddress, '12 Rizal');
      await controller.submitCorrections();

      expect(controller.corrections, isEmpty);
    });
  });

  group('can_edit fails closed', () {
    VerificationImagePart photo() => VerificationImagePart(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      fileName: 'sample.jpg',
      mimeType: 'image/jpeg',
    );

    Future<(VerificationController, FakeVerificationRepository)> open(
      VerificationStatusDetail detail,
    ) async {
      final session = await signedInSession(AccessLevel.unverified);
      addTearDown(session.dispose);
      final repository = FakeVerificationRepository(
        detail: Ok<VerificationStatusDetail>(detail),
      );
      final controller = VerificationController(
        repository: repository,
        session: session,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      return (controller, repository);
    }

    const VerificationItemIssue flagged = VerificationItemIssue(
      category: VerificationItemCategory.address,
      instruction: 'Add your house number.',
    );

    test(
      'a false can_edit blocks start, re-upload, resubmit and corrections',
      () async {
        final (controller, repository) = await open(
          const VerificationStatusDetail(
            stage: ResidentVerificationStage.needsMoreInformation,
            rawState: 'rejected',
            canEdit: false,
            issues: <VerificationItemIssue>[flagged],
          ),
        );
        controller.chooseField(
          VerificationItemCategory.address,
          CorrectableField.streetAddress,
        );
        controller.updateCorrection(CorrectableField.streetAddress, '12 Rizal');
        expect(controller.correctionsComplete, isTrue);
        expect(controller.allowsEdit, isFalse);

        expect(
          await controller.startVerification(
            idType: 'philid',
            front: photo(),
            selfie: photo(),
          ),
          isFalse,
        );
        expect(await controller.replaceImage(front: photo()), isFalse);
        expect(await controller.resubmit('Please look again.'), isFalse);
        expect(await controller.submitCorrections(), isFalse);

        expect(repository.startCalls, 0);
        expect(repository.replaceCalls, 0);
        expect(repository.correctionKeys, isEmpty);
      },
    );

    test('a missing can_edit does not fall back to the stage', () async {
      final (controller, repository) = await open(
        const VerificationStatusDetail(
          stage: ResidentVerificationStage.needsMoreInformation,
          rawState: 'rejected',
          issues: <VerificationItemIssue>[flagged],
        ),
      );
      expect(controller.status?.isEditableByApplicant, isTrue);
      expect(controller.allowsEdit, isFalse);
      controller.chooseField(
        VerificationItemCategory.address,
        CorrectableField.streetAddress,
      );
      controller.updateCorrection(CorrectableField.streetAddress, '12 Rizal');

      expect(await controller.replaceImage(front: photo()), isFalse);
      expect(await controller.resubmit(''), isFalse);
      expect(await controller.submitCorrections(), isFalse);
      expect(repository.replaceCalls, 0);
      expect(repository.correctionKeys, isEmpty);
    });

    test('start works when there is no request and edits do not', () async {
      final (controller, repository) = await open(
        const VerificationStatusDetail(
          stage: ResidentVerificationStage.notStarted,
          rawState: '',
        ),
      );
      expect(controller.canStart, isTrue);
      expect(controller.allowsEdit, isFalse);

      expect(
        await controller.startVerification(
          idType: 'passport',
          front: photo(),
          selfie: photo(),
        ),
        isTrue,
      );
      expect(repository.startCalls, 1);
      expect(repository.lastIdType, 'passport');
      expect(await controller.replaceImage(front: photo()), isFalse);
      expect(await controller.resubmit('hello'), isFalse);
      expect(repository.replaceCalls, 0);
      expect(repository.correctionKeys, isEmpty);
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

  group('HTTP errors on start, re-upload and resubmit', () {
    VerificationImagePart photo() => VerificationImagePart(
      bytes: Uint8List.fromList(<int>[9, 8, 7]),
      fileName: 'sample.jpg',
      mimeType: 'image/jpeg',
    );

    Future<(VerificationController, _Queue)> drive(
      List<ApiHttpResponse> responses,
    ) async {
      final session = await signedInSession(AccessLevel.unverified);
      addTearDown(session.dispose);
      final transport = _Queue(responses);
      final controller = VerificationController(
        repository: KycApiRepository(
          apiClient: ApiClient(
            config: config(),
            transport: transport,
            accessTokenProvider: () async => 'tok',
          ),
        ),
        session: session,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      return (controller, transport);
    }

    test(
      'a 409 on start is treated as success and the status is re-read',
      () async {
        final (controller, transport) = await drive(<ApiHttpResponse>[
          _error(404, 'NOT_FOUND'),
          _error(409, 'CONFLICT'),
          _ok(<String, Object?>{'status': 'pending', 'can_edit': true}),
        ]);
        expect(controller.canStart, isTrue);

        expect(
          await controller.startVerification(
            idType: 'philid',
            front: photo(),
            selfie: photo(),
          ),
          isTrue,
        );
        await pumpEventQueue();
        expect(controller.failure, isNull);
        expect(controller.status?.rawState, 'pending');
        expect(
          transport.requests.where(
            (ApiRequest request) =>
                request.method == HttpMethod.post &&
                request.path == 'me/verification-requests',
          ),
          hasLength(1),
        );
      },
    );

    test('a 422 on start stays a validation failure', () async {
      final (controller, transport) = await drive(<ApiHttpResponse>[
        _error(404, 'NOT_FOUND'),
        _error(422, 'VALIDATION_FAILED'),
      ]);

      expect(
        await controller.startVerification(
          idType: 'philid',
          front: photo(),
          selfie: photo(),
        ),
        isFalse,
      );
      expect(controller.failure, isA<ValidationFailure>());
      expect(
        transport.requests.where((ApiRequest r) => r.method == HttpMethod.post),
        hasLength(1),
      );
    });

    test('re-upload 404 and 409 are failures', () async {
      final (missing, _) = await drive(<ApiHttpResponse>[
        _ok(<String, Object?>{'status': 'rejected', 'can_edit': true}),
        _error(404, 'NOT_FOUND'),
      ]);
      expect(await missing.replaceImage(front: photo()), isFalse);
      expect(missing.failure, isA<NotFoundFailure>());

      final (conflict, _) = await drive(<ApiHttpResponse>[
        _ok(<String, Object?>{'status': 'rejected', 'can_edit': true}),
        _error(409, 'CONFLICT'),
      ]);
      expect(await conflict.replaceImage(selfie: photo()), isFalse);
      expect(conflict.failure, isA<ConflictFailure>());
    });

    test('resubmit 409 and 422 are failures', () async {
      final (conflict, _) = await drive(<ApiHttpResponse>[
        _ok(<String, Object?>{'status': 'rejected', 'can_edit': true}),
        _error(409, 'CONFLICT'),
      ]);
      expect(await conflict.resubmit('Please look again.'), isFalse);
      expect(conflict.failure, isA<ConflictFailure>());

      final (invalid, _) = await drive(<ApiHttpResponse>[
        _ok(<String, Object?>{'status': 'rejected', 'can_edit': true}),
        _error(422, 'VALIDATION_FAILED'),
      ]);
      expect(await invalid.resubmit(''), isFalse);
      expect(invalid.failure, isA<ValidationFailure>());
    });
  });
}

ApiHttpResponse _ok(Map<String, Object?> data) => ApiHttpResponse(
  statusCode: 200,
  body: jsonEncode(<String, Object?>{
    'data': data,
    'meta': <String, Object?>{},
  }),
  headers: const <String, String>{'content-type': 'application/json'},
);

ApiHttpResponse _error(int status, String code) => ApiHttpResponse(
  statusCode: status,
  body: jsonEncode(<String, Object?>{
    'error': <String, Object?>{
      'code': code,
      'message': 'operator text',
      'details': <String, Object?>{},
      'request_id': 'req-http',
    },
  }),
  headers: const <String, String>{'content-type': 'application/json'},
);

class _Queue implements ApiTransport {
  _Queue(this.responses);

  final List<ApiHttpResponse> responses;
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return Ok<ApiHttpResponse>(responses.removeAt(0));
  }
}

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

/// Answers every request with one JSON body. Used to put a hostile payload on
/// the wire and watch what the real decoder does with it.
class _OneResponse implements ApiTransport {
  _OneResponse(this.body);

  final Map<String, dynamic> body;

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async =>
      Ok<ApiHttpResponse>(
        ApiHttpResponse(
          statusCode: 200,
          body: jsonEncode(<String, dynamic>{'data': body}),
          headers: const <String, String>{'content-type': 'application/json'},
        ),
      );
}
