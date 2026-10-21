import 'dart:typed_data';

import '../../../../core/api/dev_mock_access.dart';
import '../../../../core/documents/document_capture.dart';
import '../../../../core/documents/upload_policy.dart';
import '../../../../core/mock/mock_behavior.dart';
import '../../../../core/mock/mock_fixtures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/access_level.dart';
import '../../../../core/session/push_registration.dart';
import '../../../../core/session/session_state.dart';
import '../../../../core/storage/public_cache.dart';
import '../../../auth/domain/account_application.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/domain/code_exchange.dart';
import '../../../auth/domain/device_session_repository.dart';
import '../../../credential/domain/credential_repository.dart';
import '../../../credential/domain/digital_id.dart';
import '../../../events/domain/event_registration.dart'
    as event_outcome
    show RegistrationOutcome;
import '../../../events/domain/event_repository.dart' hide RegistrationOutcome;
import '../../../household/domain/household_record.dart';
import '../../../household/domain/household_repository.dart';
import '../../../household/domain/household_summary.dart';
import '../../../messaging/domain/office_messaging_repository.dart';
import '../../../news/domain/announcement_repository.dart';
import '../../../notifications/domain/notification_repository.dart';
import '../../../platform/domain/app_bootstrap.dart';
import '../../../platform/domain/platform_repository.dart';
import '../../../profile/domain/profile_fields.dart';
import '../../../profile/domain/resident_profile_detail.dart';
import '../../../profile/domain/resident_profile_repository.dart';
import '../../../programs/domain/assistance_program.dart'
    hide RequirementObligation;
import '../../../programs/domain/program_repository.dart';
import '../../../registration/domain/registration_domain.dart';
import '../../../requirements/domain/resident_requirement.dart';
import '../../../services/domain/assistance_case.dart';
import '../../../services/domain/assistance_history.dart';
import '../../../services/domain/assistance_intake.dart';
import '../../../services/domain/lgu_service.dart';
import '../../../services/domain/service_catalog_repository.dart';
import '../../../services/domain/service_request_repository.dart';
import '../../../settings/domain/account_controls.dart';
import '../../../verification/domain/correctable_field.dart';
import '../../../verification/domain/kyc_claim.dart';
import '../../../verification/domain/verification_repository.dart';
import '../../../verification/domain/verification_status_detail.dart';
import 'code_challenge_book.dart';

/// Frozen instant for fixtures and goldens: 20 Oct 2026, 09:05 in Manila.
final DateTime mockNow = DateTime.utc(2026, 10, 20, 1, 5);

Map<String, Object?>? _asMap(Object? entry) {
  if (entry is! Map) return null;
  final raw = Map<Object?, Object?>.from(entry);
  return <String, Object?>{
    for (final MapEntry<Object?, Object?> item in raw.entries)
      if (item.key != null) item.key.toString(): item.value,
  };
}

Paginated<T> _page<T>(List<T> items) => Paginated<T>(
  items: items,
  page: 1,
  perPage: items.length,
  total: items.length,
  totalPages: 1,
  hasMore: false,
);

/// Shared synthetic resident. Loaded from JSON so the app and the tests read
/// the same fixture.
class MockResident {
  const MockResident({
    required this.displayName,
    required this.email,
    required this.mobile,
    required this.accountId,
    required this.barangay,
  });

  final String displayName;
  final String email;
  final String mobile;
  final String accountId;
  final String barangay;

  static Future<MockResident> load() async {
    final json = await MockFixtures.object('resident');
    return MockResident(
      displayName: json['displayName']! as String,
      email: json['email']! as String,
      mobile: json['mobile']! as String,
      accountId: json['accountId']! as String,
      barangay: json['barangay']! as String,
    );
  }
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._gate);

  final MockBehaviorController _gate;
  final CodeChallengeBook _codes = CodeChallengeBook();

  @override
  Future<Result<void>> requestOneTimeCode({required String mobileNumber}) {
    return _gate.respond<void>(null);
  }

  @override
  Future<Result<AuthOutcome>> verifyOneTimeCode({
    required String mobileNumber,
    required String code,
  }) async {
    final resident = await MockResident.load();
    final token = DevMockAccess.tryToken(id: resident.accountId);
    if (token == null) {
      return const Err<AuthOutcome>(
        ContractFailure(
          debugMessage: 'Dev mock account id cannot form a bearer segment.',
        ),
      );
    }
    return _gate.respond(
      AuthOutcome(
        resident: ResidentSession(
          accountId: resident.accountId,
          accessLevel: AccessLevel.verified,
          displayName: 'Juana',
        ),
        accessToken: token,
      ),
    );
  }

  @override
  Future<Result<AuthOutcome>> signInWithPassword({
    required String identifier,
    required String password,
  }) async {
    if (password == 'wrong-password') {
      return const Err<AuthOutcome>(UnauthenticatedFailure());
    }
    final resident = await MockResident.load();
    final token = DevMockAccess.tryToken(id: resident.accountId);
    if (token == null) {
      return const Err<AuthOutcome>(
        ContractFailure(
          debugMessage: 'Dev mock account id cannot form a bearer segment.',
        ),
      );
    }
    return _gate.respond(
      AuthOutcome(
        resident: ResidentSession(
          accountId: resident.accountId,
          accessLevel: AccessLevel.unverified,
          displayName: 'Juana',
        ),
        accessToken: token,
      ),
    );
  }

  @override
  Future<Result<CodeAcceptance>> sendEmailCode() {
    return _gate.respond(_codes.sendEmailCode().valueOrNull!);
  }

  @override
  Future<Result<EmailVerified>> verifyEmailCode({required String code}) {
    final Result<EmailVerified> verdict = _codes.verifyEmailCode(code);
    return switch (verdict) {
      Ok<EmailVerified>(:final value) => _gate.respond(value),
      Err<EmailVerified>(:final failure) => Future<Result<EmailVerified>>.value(
        Err<EmailVerified>(failure),
      ),
    };
  }

  @override
  Future<Result<CodeAcceptance>> requestPasswordReset({required String email}) {
    final Result<CodeAcceptance> verdict = _codes.requestReset(email);
    return switch (verdict) {
      Ok<CodeAcceptance>(:final value) => _gate.respond(value),
      Err<CodeAcceptance>(:final failure) =>
        Future<Result<CodeAcceptance>>.value(Err<CodeAcceptance>(failure)),
    };
  }

  @override
  Future<Result<PasswordResetGrant>> verifyPasswordReset({
    required String email,
    required String code,
  }) {
    final Result<PasswordResetGrant> verdict = _codes.verifyReset(
      email: email,
      code: code,
    );
    return switch (verdict) {
      Ok<PasswordResetGrant>(:final value) => _gate.respond(value),
      Err<PasswordResetGrant>(:final failure) =>
        Future<Result<PasswordResetGrant>>.value(
          Err<PasswordResetGrant>(failure),
        ),
    };
  }

  @override
  Future<Result<PasswordUpdated>> completePasswordReset({
    required String resetToken,
    required String newPassword,
  }) {
    final Result<PasswordUpdated> verdict = _codes.complete(
      resetToken: resetToken,
      newPassword: newPassword,
    );
    return switch (verdict) {
      Ok<PasswordUpdated>(:final value) => _gate.respond(value),
      Err<PasswordUpdated>(:final failure) =>
        Future<Result<PasswordUpdated>>.value(Err<PasswordUpdated>(failure)),
    };
  }

  @override
  Future<Result<AuthOutcome>> createAccount({
    required String email,
    required String password,
  }) {
    if (email.trim().isEmpty || password.isEmpty) {
      return Future<Result<AuthOutcome>>.value(
        const Err<AuthOutcome>(
          ValidationFailure(
            debugMessage: 'An email address and a password are required.',
          ),
        ),
      );
    }
    return registerAccount(email: email);
  }

  @override
  Future<Result<CodeAcceptance>> sendEmailVerification({String? email}) {
    if (email != null && email.trim().isEmpty) {
      return Future<Result<CodeAcceptance>>.value(
        const Err<CodeAcceptance>(
          ValidationFailure(debugMessage: 'An email address is required.'),
        ),
      );
    }
    return sendEmailCode();
  }

  @override
  Future<Result<EmailVerified>> confirmEmailVerification({
    String? code,
    String? link,
  }) {
    if (link != null && link.isNotEmpty) {
      return Future<Result<EmailVerified>>.value(
        const Err<EmailVerified>(
          ValidationFailure(
            debugMessage:
                'An email link cannot be confirmed on the published route.',
          ),
        ),
      );
    }
    if (code == null || code.isEmpty) {
      return Future<Result<EmailVerified>>.value(
        const Err<EmailVerified>(
          ValidationFailure(debugMessage: 'A code is required.'),
        ),
      );
    }
    return verifyEmailCode(code: code);
  }

  @override
  Future<Result<CodeAcceptance>> sendPasswordReset({required String email}) {
    return requestPasswordReset(email: email);
  }

  @override
  Future<Result<void>> submitProfile(AccountApplication application) {
    if (application.email.trim().isEmpty || application.password.isEmpty) {
      return Future<Result<void>>.value(
        const Err<void>(
          ValidationFailure(
            debugMessage: 'An email address and a password are required.',
          ),
        ),
      );
    }
    return _gate.respond<void>(null);
  }

  @override
  Future<Result<AuthOutcome>> registerAccount({required String email}) async {
    final resident = await MockResident.load();
    final token = DevMockAccess.tryToken(id: resident.accountId);
    if (token == null) {
      return const Err<AuthOutcome>(
        ContractFailure(
          debugMessage: 'Dev mock account id cannot form a bearer segment.',
        ),
      );
    }
    return _gate.respond(
      AuthOutcome(
        resident: ResidentSession(
          accountId: resident.accountId,
          accessLevel: AccessLevel.unverified,
          displayName: 'Juana',
        ),
        accessToken: token,
      ),
    );
  }

  @override
  Future<Result<void>> signOut() => _gate.respond<void>(null);
}

class MockDeviceSessionRepository implements DeviceSessionRepository {
  MockDeviceSessionRepository(this._gate);

  final MockBehaviorController _gate;

  @override
  Future<Result<List<DeviceSessionSummary>>> listActiveSessions() {
    return _gate.respond(<DeviceSessionSummary>[
      DeviceSessionSummary(
        id: 'session-sample-1',
        label: 'This phone',
        isCurrentDevice: true,
        lastSeenAt: mockNow,
      ),
    ]);
  }

  @override
  Future<Result<void>> revokeSession({required String sessionId}) =>
      _gate.respond<void>(null);

  @override
  Future<Result<void>> revokeAllOtherSessions() => _gate.respond<void>(null);
}

class MockAnnouncementRepository implements AnnouncementRepository {
  MockAnnouncementRepository(this._gate);

  final MockBehaviorController _gate;

  Future<List<Announcement>> _items() async {
    final raw = await MockFixtures.list('announcements');
    return <Announcement>[
      for (final entry in raw)
        if (_asMap(entry) case final Map<String, Object?> map)
          Announcement(
            id: map['id']! as String,
            title: map['title']! as String,
            body: map['body']! as String,
            summary: map['summary'] as String?,
            publishedAt: mockNow,
            advisoryLevel: const ServerValue<AdvisoryLevel>(
              raw: 'advisory',
              known: AdvisoryLevel.advisory,
            ),
            publicationState: const ServerValue<PublicationState>(
              raw: 'published',
              known: PublicationState.published,
            ),
          ),
    ];
  }

  @override
  Future<Result<Paginated<Announcement>>> listAnnouncements({
    int page = 1,
    int perPage = 15,
  }) async {
    return _gate.respond(_page(await _items()));
  }

  @override
  Future<Result<Announcement>> loadAnnouncement(String id) async {
    final items = await _items();
    final match = items.where((item) => item.id == id);
    if (match.isEmpty) {
      return const Err<Announcement>(
        NotFoundFailure(debugMessage: 'No sample post with that id.'),
      );
    }
    return _gate.respond(match.first);
  }

  @override
  Future<Result<Paginated<PostComment>>> listComments(
    String postId, {
    int page = 1,
    int perPage = 15,
  }) {
    return _gate.respond(
      _page(<PostComment>[
        PostComment(
          id: 'comment-sample-1',
          body: 'SAMPLE comment from Juana Dela Cruz.',
          authorName: 'Juana Dela Cruz',
          authorKind: const ServerValue<CommentAuthorKind>(
            raw: 'resident',
            known: CommentAuthorKind.resident,
          ),
          createdAt: mockNow,
          isMine: true,
        ),
      ]),
    );
  }

  @override
  Future<Result<ReactionOutcome>> setReaction({
    required String postId,
    required ReactionKind reaction,
    required String idempotencyKey,
  }) {
    return _gate.respond(
      ReactionOutcome(
        reactions: 1,
        myReaction: ServerValue<ReactionKind>(
          raw: reaction.wireValue,
          known: reaction,
        ),
      ),
    );
  }

  @override
  Future<Result<ReactionOutcome>> clearReaction({
    required String postId,
    required String idempotencyKey,
  }) {
    return _gate.respond(const ReactionOutcome(reactions: 0));
  }

  @override
  Future<Result<PostComment>> addComment({
    required String postId,
    required String body,
    required String idempotencyKey,
    String? parentId,
  }) {
    return _gate.respond(
      PostComment(
        id: 'comment-sample-new',
        body: body,
        authorName: 'Juana Dela Cruz',
        authorKind: const ServerValue<CommentAuthorKind>(
          raw: 'resident',
          known: CommentAuthorKind.resident,
        ),
        createdAt: mockNow,
        isMine: true,
        parentId: parentId,
      ),
    );
  }

  @override
  Future<Result<void>> deleteOwnComment({
    required String postId,
    required String commentId,
    required String idempotencyKey,
  }) => _gate.respond<void>(null);

  @override
  Future<Result<void>> reportComment({
    required String postId,
    required String commentId,
    required ReportReason reason,
    required String idempotencyKey,
  }) => _gate.respond<void>(null);
}

class MockServiceCatalogRepository implements ServiceCatalogRepository {
  MockServiceCatalogRepository(this._gate);

  final MockBehaviorController _gate;

  @override
  Future<Result<Paginated<LguService>>> listServices({
    ServiceChannel? channel,
    ServiceCategory? category,
    int page = 1,
    int perPage = 15,
  }) async {
    final raw = await MockFixtures.list('services');
    final items = <LguService>[
      for (final entry in raw)
        if (_asMap(entry) case final Map<String, Object?> map)
          LguService(
            id: map['id']! as String,
            code: map['code']! as String,
            name: map['name']! as String,
            description: map['description']! as String,
            category: ServerValue<ServiceCategory>(
              raw: map['category']! as String,
              known: ServiceCategory.values
                  .where((value) => value.wireValue == map['category'])
                  .firstOrNull,
            ),
            status: const ServerValue<ServicePublicationStatus>(
              raw: 'published',
              known: ServicePublicationStatus.published,
            ),
            availableChannels: const <ServerValue<ServiceChannel>>[
              ServerValue<ServiceChannel>(
                raw: 'citizen-mobile',
                known: ServiceChannel.citizenMobile,
              ),
            ],
          ),
    ];
    return _gate.respond(_page(items));
  }

  @override
  CachedRead<Paginated<LguService>>? lastKnownServices({
    ServiceChannel? channel,
    ServiceCategory? category,
    int page = 1,
    int perPage = 15,
  }) {
    return null;
  }
}

class MockProgramRepository implements ProgramRepository {
  MockProgramRepository(this._gate);

  final MockBehaviorController _gate;

  AssistanceProgram _program(String id) => AssistanceProgram(
    id: id,
    code: 'PWD-CASH-GIFT',
    name: 'SAMPLE PWD Cash Gift',
    description:
        'Illustrative programme for Juana Dela Cruz. Not an LGU offer.',
    acceptsApplications: false,
    ownerOffice: 'MSWDO',
  );

  @override
  Future<Result<Paginated<AssistanceProgram>>> listActivePrograms({
    int page = 1,
    int perPage = 15,
  }) {
    return _gate.respond(_page(<AssistanceProgram>[_program('prog-sample-1')]));
  }

  @override
  Future<Result<AssistanceProgram>> loadProgram(String id) {
    return _gate.respond(_program(id));
  }
}

class MockEventRepository implements EventRepository {
  MockEventRepository(this._gate);

  final MockBehaviorController _gate;

  LguEvent _event(String id) => LguEvent(
    id: id,
    title: 'SAMPLE community clean-up',
    description: 'An illustrative event. Not a published LGU schedule.',
    startsAt: mockNow,
    venue: const EventVenue(name: 'SAMPLE plaza'),
  );

  @override
  Future<Result<Paginated<LguEvent>>> listEvents({
    EventScope scope = EventScope.upcoming,
    int page = 1,
    int perPage = 15,
  }) {
    return _gate.respond(_page(<LguEvent>[_event('event-sample-1')]));
  }

  @override
  Future<Result<LguEvent>> loadEvent(String id) => _gate.respond(_event(id));

  @override
  Future<Result<EventRegistrationForm>> loadRegistrationForm(String eventId) {
    return _gate.respond(
      EventRegistrationForm(
        eventId: eventId,
        eventTitle: 'SAMPLE community clean-up',
        allowsUnverifiedResidents: true,
      ),
    );
  }

  @override
  Future<Result<RegistrationAttempt>> register({
    required String eventId,
    required Map<String, Object?> answers,
    required List<String> consentKeys,
    required String idempotencyKey,
  }) {
    return _gate.respond(
      RegistrationAttempt(
        outcome: event_outcome.RegistrationOutcome.registered,
        residentMessage: 'SAMPLE registration recorded on this device only.',
        registration: EventRegistration(
          eventId: eventId,
          id: 'reg-sample-1',
          state: const ServerValue<EventRegistrationState>(
            raw: 'registered',
            known: EventRegistrationState.registered,
          ),
        ),
      ),
    );
  }

  @override
  Future<Result<EventRegistration>> cancelRegistration({
    required String eventId,
    required String registrationId,
    required String idempotencyKey,
  }) {
    return _gate.respond(
      EventRegistration(
        eventId: eventId,
        id: registrationId,
        state: const ServerValue<EventRegistrationState>(
          raw: 'cancelled',
          known: EventRegistrationState.cancelled,
        ),
      ),
    );
  }
}

class MockNotificationRepository
    implements NotificationRepository, PushRegistrationWithdrawal {
  MockNotificationRepository(this._gate);

  final MockBehaviorController _gate;

  @override
  Future<Result<Paginated<ResidentNotification>>> listOwn({
    int page = 1,
    int perPage = 15,
  }) {
    return _gate.respond(
      _page(<ResidentNotification>[
        ResidentNotification(
          id: 'note-sample-1',
          title: 'SAMPLE advisory',
          body: 'A synthetic notice for Juana Dela Cruz.',
          sentAt: mockNow,
          readAt: null,
          category: const ServerValue<NotificationCategory>(
            raw: 'public_advisory',
            known: NotificationCategory.publicAdvisory,
          ),
        ),
      ]),
    );
  }

  @override
  Future<Result<void>> markRead(String id) => _gate.respond<void>(null);

  @override
  Future<Result<void>> markAllRead() => _gate.respond<void>(null);

  @override
  Future<Result<NotificationPreferences>> loadPreferences() {
    return _gate.respond(
      const NotificationPreferences(
        push: true,
        sms: false,
        email: false,
        channels: <ChannelPreference>[
          ChannelPreference(
            type: 'verification_decided',
            inApp: true,
            push: true,
          ),
          ChannelPreference(type: 'message_received', inApp: true, push: true),
        ],
      ),
    );
  }

  @override
  Future<Result<void>> updatePreferences(NotificationPreferences preferences) =>
      _gate.respond<void>(null);

  @override
  Future<Result<String>> registerPushToken(String token) {
    return _gate.respond(token);
  }

  @override
  Future<bool> withdraw(String deviceId) async {
    final result = await _gate.respond<bool>(true);
    return switch (result) {
      Ok<bool>() => true,
      Err<bool>() => false,
    };
  }
}

class MockPlatformRepository implements PlatformRepository {
  MockPlatformRepository(this._gate);

  final MockBehaviorController _gate;

  @override
  Future<Result<ServiceHealth>> checkHealth() {
    return _gate.respond(
      const ServiceHealth(
        service: 'taytay-sample',
        status: 'ok',
        apiVersion: 'sample',
      ),
    );
  }

  @override
  Future<Result<AppBootstrap>> loadBootstrap() {
    return _gate.respond(
      const AppBootstrap(
        service: 'taytay-sample',
        apiVersion: 'sample',
        timezone: 'Asia/Manila',
        channel: 'citizen-mobile',
        defaultPageSize: 15,
        minimumVersion: '',
        features: FeatureFlags.none,
        support: SupportContact.none,
        serverTime: null,
      ),
    );
  }
}

class MockProfileRepository implements ResidentProfileRepository {
  MockProfileRepository(this._gate);

  final MockBehaviorController _gate;

  @override
  Future<Result<ResidentProfileSummary>> loadOwnSummary() {
    return _gate.respond(
      const ResidentProfileSummary(verificationTier: 'verified'),
    );
  }

  @override
  Future<Result<ResidentProfileDetail>> loadOwnDetail() async {
    final resident = await MockResident.load();
    return _gate.respond(
      ResidentProfileDetail(
        verificationTier: 'verified',
        emailVerified: false,
        values: <ResidentProfileField, String>{
          ResidentProfileField.emailAddress: resident.email,
        },
      ),
    );
  }

  @override
  Future<Result<void>> updateContactDetails({
    required ContactDetailsUpdate update,
    required String idempotencyKey,
  }) => _gate.respond<void>(null);

  @override
  Future<Result<void>> submitOwnUpdate({
    required Map<String, Object?> changes,
    required String idempotencyKey,
  }) => _gate.respond<void>(null);
}

class MockHouseholdRepository implements HouseholdRepository {
  MockHouseholdRepository(
    this._gate, {
    bool startEmpty = false,
    bool asHead = false,
    HouseholdInvitation? invitation,
  }) : _startEmpty = startEmpty,
       _asHead = asHead,
       _invitation = invitation;

  final MockBehaviorController _gate;
  final bool _startEmpty;
  final bool _asHead;

  HouseholdRecord? _household;
  HouseholdInvitation? _invitation;
  bool _ready = false;
  int _sequence = 0;

  @override
  Future<Result<HouseholdSummary>> loadOwnHousehold() async {
    final HouseholdRecord? record = await _current();
    if (record == null) {
      return const Err<HouseholdSummary>(
        NotFoundFailure(debugMessage: 'No household on file.'),
      );
    }
    final HouseholdSummary summary = record.toSummary();
    return _gate.respond(
      HouseholdSummary(
        role: summary.role,
        label: 'SAMPLE household',
        barangay: summary.barangay,
        streetAddress: summary.streetAddress,
        memberCount: summary.memberCount,
      ),
    );
  }

  @override
  Future<Result<void>> submitCorrectionRequest({
    required HouseholdCorrectionRequest request,
    required String idempotencyKey,
  }) => _gate.respond<void>(null);

  @override
  Future<Result<HouseholdRecord>> createHousehold({
    required String address,
    required String barangayId,
  }) async {
    final String line = address.trim();
    final String barangay = barangayId.trim();
    if (line.isEmpty || barangay.isEmpty) {
      return const Err<HouseholdRecord>(
        ValidationFailure(
          debugMessage: 'An address and a barangay are required.',
        ),
      );
    }
    if (await _current() != null) {
      return const Err<HouseholdRecord>(
        ConflictFailure(debugMessage: 'A household already exists.'),
      );
    }
    final MockResident resident = await MockResident.load();
    final HouseholdRecord created = HouseholdRecord(
      id: _id(),
      address: line,
      barangayId: barangay,
      barangayName: resident.barangay,
      headUserId: resident.accountId,
      viewerRole: HouseholdViewerRole.head,
      createdAt: DateTime.utc(2026, 1, 1),
      members: <HouseholdMember>[
        HouseholdMember(
          id: _id(),
          name: resident.displayName,
          relationship: HouseholdRelationship.head,
          birthdate: null,
          sex: null,
          userId: resident.accountId,
          inviteStatus: HouseholdInviteStatus.accepted,
        ),
      ],
    );
    _household = created;
    return _gate.respond(created);
  }

  @override
  Future<Result<HouseholdRecord?>> loadCurrent() async {
    return _gate.respond(await _current());
  }

  @override
  Future<Result<HouseholdRecord>> updateCurrent({
    String? address,
    String? barangayId,
  }) async {
    final HouseholdRecord? record = await _current();
    if (record == null) {
      return const Err<HouseholdRecord>(
        NotFoundFailure(debugMessage: 'No household on file.'),
      );
    }
    if (record.viewerRole != HouseholdViewerRole.head) {
      return const Err<HouseholdRecord>(
        ForbiddenFailure(debugMessage: 'Only the head can edit the household.'),
      );
    }
    final String? line = address?.trim();
    final String? barangay = barangayId?.trim();
    if ((line == null || line.isEmpty) &&
        (barangay == null || barangay.isEmpty)) {
      return const Err<HouseholdRecord>(
        ValidationFailure(debugMessage: 'Nothing to update.'),
      );
    }
    final HouseholdRecord next = HouseholdRecord(
      id: record.id,
      address: line == null || line.isEmpty ? record.address : line,
      barangayId: barangay == null || barangay.isEmpty
          ? record.barangayId
          : barangay,
      barangayName: record.barangayName,
      headUserId: record.headUserId,
      viewerRole: record.viewerRole,
      createdAt: record.createdAt,
      members: record.members,
    );
    _household = next;
    return _gate.respond(next);
  }

  @override
  Future<Result<void>> deleteCurrent() async {
    final HouseholdRecord? record = await _current();
    if (record == null) {
      return const Err<void>(
        NotFoundFailure(debugMessage: 'No household on file.'),
      );
    }
    if (record.viewerRole != HouseholdViewerRole.head) {
      return const Err<void>(
        ForbiddenFailure(
          debugMessage: 'Only the head can delete the household.',
        ),
      );
    }
    _household = null;
    return _gate.respond<void>(null);
  }

  @override
  Future<Result<HouseholdMember>> addMember(HouseholdMemberDraft draft) async {
    final HouseholdRecord? record = await _current();
    if (record == null) {
      return const Err<HouseholdMember>(
        NotFoundFailure(debugMessage: 'No household on file.'),
      );
    }
    if (record.viewerRole != HouseholdViewerRole.head) {
      return const Err<HouseholdMember>(
        ForbiddenFailure(debugMessage: 'Only the head can add a member.'),
      );
    }
    final String name = draft.name.trim();
    if (name.isEmpty) {
      return const Err<HouseholdMember>(
        ValidationFailure(debugMessage: 'A name is required.'),
      );
    }
    final HouseholdMember member = HouseholdMember(
      id: _id(),
      name: name,
      relationship: HouseholdRelationship.fromWire(
        draft.relationship.wireValue,
      ),
      birthdate: draft.birthdate,
      sex: draft.sex,
      userId: draft.userId,
      inviteStatus: draft.userId == null
          ? HouseholdInviteStatus.none
          : HouseholdInviteStatus.pending,
    );
    _household = _copy(
      record,
      members: <HouseholdMember>[...record.members, member],
    );
    return _gate.respond(member);
  }

  @override
  Future<Result<HouseholdMember>> updateMember({
    required String memberId,
    required HouseholdMemberChange change,
  }) async {
    final HouseholdRecord? record = await _current();
    if (record == null) {
      return const Err<HouseholdMember>(
        NotFoundFailure(debugMessage: 'No household on file.'),
      );
    }
    if (record.viewerRole != HouseholdViewerRole.head) {
      return const Err<HouseholdMember>(
        ForbiddenFailure(debugMessage: 'Only the head can edit a member.'),
      );
    }
    if (change.isEmpty) {
      return const Err<HouseholdMember>(
        ValidationFailure(debugMessage: 'Nothing to update.'),
      );
    }
    final int index = record.members.indexWhere(
      (HouseholdMember member) => member.id == memberId,
    );
    if (index < 0) {
      return const Err<HouseholdMember>(
        NotFoundFailure(debugMessage: 'No such member.'),
      );
    }
    final HouseholdMember current = record.members[index];
    if (current.relationship == HouseholdRelationship.head &&
        change.relationship != null) {
      return const Err<HouseholdMember>(
        ConflictFailure(debugMessage: 'Transfer headship to change the head.'),
      );
    }
    final HouseholdMember next = HouseholdMember(
      id: current.id,
      name: change.name?.trim().isNotEmpty == true
          ? change.name!.trim()
          : current.name,
      relationship: change.relationship == null
          ? current.relationship
          : HouseholdRelationship.fromWire(change.relationship!.wireValue),
      birthdate: change.birthdate ?? current.birthdate,
      sex: change.sex ?? current.sex,
      userId: current.userId,
      inviteStatus: current.inviteStatus,
    );
    final List<HouseholdMember> members = List<HouseholdMember>.of(
      record.members,
    );
    members[index] = next;
    _household = _copy(record, members: members);
    return _gate.respond(next);
  }

  @override
  Future<Result<void>> removeMember(String memberId) async {
    final HouseholdRecord? record = await _current();
    if (record == null) {
      return const Err<void>(
        NotFoundFailure(debugMessage: 'No household on file.'),
      );
    }
    if (record.viewerRole != HouseholdViewerRole.head) {
      return const Err<void>(
        ForbiddenFailure(debugMessage: 'Only the head can remove a member.'),
      );
    }
    final HouseholdMember? member = _find(record, memberId);
    if (member == null) {
      return const Err<void>(NotFoundFailure(debugMessage: 'No such member.'));
    }
    if (member.relationship == HouseholdRelationship.head) {
      return const Err<void>(
        ConflictFailure(debugMessage: 'The head cannot be removed.'),
      );
    }
    _household = _copy(
      record,
      members: record.members
          .where((HouseholdMember item) => item.id != memberId)
          .toList(growable: false),
    );
    return _gate.respond<void>(null);
  }

  @override
  Future<Result<void>> leaveHousehold() async {
    final HouseholdRecord? record = await _current();
    if (record == null) {
      return const Err<void>(
        NotFoundFailure(debugMessage: 'No household on file.'),
      );
    }
    if (record.viewerRole == HouseholdViewerRole.head &&
        record.members.length > 1) {
      return const Err<void>(
        ConflictFailure(debugMessage: 'Transfer headship before leaving.'),
      );
    }
    _household = null;
    return _gate.respond<void>(null);
  }

  @override
  Future<Result<HouseholdRecord>> transferHeadship({
    required String memberId,
  }) async {
    final HouseholdRecord? record = await _current();
    if (record == null) {
      return const Err<HouseholdRecord>(
        NotFoundFailure(debugMessage: 'No household on file.'),
      );
    }
    if (record.viewerRole != HouseholdViewerRole.head) {
      return const Err<HouseholdRecord>(
        ForbiddenFailure(debugMessage: 'Only the head can transfer.'),
      );
    }
    final HouseholdMember? member = _find(record, memberId);
    if (member == null || member.userId == null) {
      return const Err<HouseholdRecord>(
        NotFoundFailure(debugMessage: 'No such member.'),
      );
    }
    if (member.inviteStatus != HouseholdInviteStatus.accepted) {
      return const Err<HouseholdRecord>(
        ConflictFailure(debugMessage: 'That member has not accepted.'),
      );
    }
    final List<HouseholdMember> members = <HouseholdMember>[
      for (final HouseholdMember item in record.members)
        if (item.id == member.id)
          HouseholdMember(
            id: item.id,
            name: item.name,
            relationship: HouseholdRelationship.head,
            birthdate: item.birthdate,
            sex: item.sex,
            userId: item.userId,
            inviteStatus: item.inviteStatus,
          )
        else if (item.relationship == HouseholdRelationship.head)
          HouseholdMember(
            id: item.id,
            name: item.name,
            relationship: HouseholdRelationship.other,
            birthdate: item.birthdate,
            sex: item.sex,
            userId: item.userId,
            inviteStatus: item.inviteStatus,
          )
        else
          item,
    ];
    final HouseholdRecord next = HouseholdRecord(
      id: record.id,
      address: record.address,
      barangayId: record.barangayId,
      barangayName: record.barangayName,
      headUserId: member.userId!,
      viewerRole: HouseholdViewerRole.member,
      createdAt: record.createdAt,
      members: members,
    );
    _household = next;
    return _gate.respond(next);
  }

  @override
  Future<Result<HouseholdInvitation?>> loadCurrentInvitation() {
    return _gate.respond(_invitation);
  }

  @override
  Future<Result<HouseholdRecord>> acceptInvitation(String invitationId) async {
    final HouseholdInvitation? invitation = _invitation;
    if (invitation == null || invitation.id != invitationId) {
      return const Err<HouseholdRecord>(
        NotFoundFailure(debugMessage: 'No such invitation.'),
      );
    }
    if (await _current() != null) {
      return const Err<HouseholdRecord>(
        ConflictFailure(debugMessage: 'Already in a household.'),
      );
    }
    final MockResident resident = await MockResident.load();
    final HouseholdRecord joined = HouseholdRecord(
      id: invitation.householdId,
      address: invitation.address,
      barangayId: invitation.barangayId,
      barangayName: invitation.barangayName,
      headUserId: _id(),
      viewerRole: HouseholdViewerRole.member,
      createdAt: DateTime.utc(2026, 1, 1),
      members: <HouseholdMember>[
        HouseholdMember(
          id: _id(),
          name: resident.displayName,
          relationship: HouseholdRelationship.other,
          birthdate: null,
          sex: null,
          userId: resident.accountId,
          inviteStatus: HouseholdInviteStatus.accepted,
        ),
      ],
    );
    _household = joined;
    _invitation = null;
    return _gate.respond(joined);
  }

  @override
  Future<Result<void>> declineInvitation(String invitationId) async {
    final HouseholdInvitation? invitation = _invitation;
    if (invitation == null || invitation.id != invitationId) {
      return const Err<void>(
        NotFoundFailure(debugMessage: 'No such invitation.'),
      );
    }
    _invitation = null;
    return _gate.respond<void>(null);
  }

  Future<HouseholdRecord?> _current() async {
    if (_ready) return _household;
    _ready = true;
    if (_startEmpty) return null;
    final MockResident resident = await MockResident.load();
    final String headId = _id();
    final bool asHead = _asHead;
    _household = HouseholdRecord(
      id: _id(),
      address: 'Sample Street',
      barangayId: _id(),
      barangayName: resident.barangay,
      headUserId: asHead ? resident.accountId : headId,
      viewerRole: asHead
          ? HouseholdViewerRole.head
          : HouseholdViewerRole.member,
      createdAt: DateTime.utc(2026, 1, 1),
      members: <HouseholdMember>[
        HouseholdMember(
          id: _id(),
          name: asHead ? resident.displayName : 'Sample Head',
          relationship: HouseholdRelationship.head,
          birthdate: null,
          sex: null,
          userId: asHead ? resident.accountId : headId,
          inviteStatus: HouseholdInviteStatus.accepted,
        ),
        HouseholdMember(
          id: _id(),
          name: asHead ? 'Sample Relative' : resident.displayName,
          relationship: HouseholdRelationship.other,
          birthdate: null,
          sex: null,
          userId: asHead ? _id() : resident.accountId,
          inviteStatus: HouseholdInviteStatus.accepted,
        ),
      ],
    );
    return _household;
  }

  HouseholdRecord _copy(
    HouseholdRecord record, {
    required List<HouseholdMember> members,
  }) {
    return HouseholdRecord(
      id: record.id,
      address: record.address,
      barangayId: record.barangayId,
      barangayName: record.barangayName,
      headUserId: record.headUserId,
      viewerRole: record.viewerRole,
      createdAt: record.createdAt,
      members: members,
    );
  }

  HouseholdMember? _find(HouseholdRecord record, String memberId) {
    for (final HouseholdMember member in record.members) {
      if (member.id == memberId) return member;
    }
    return null;
  }

  String _id() {
    _sequence += 1;
    final String suffix = _sequence.toRadixString(16).padLeft(12, '0');
    return '00000000-0000-4000-8000-$suffix';
  }
}

class MockCredentialRepository implements CredentialRepository {
  MockCredentialRepository(this._gate, {this.verified = true});

  final MockBehaviorController _gate;

  /// `GET me/digital-id` answers only for a verified resident.
  final bool verified;

  DigitalIdCard? _held;

  static const String _cardId = '00000000-0000-4000-8000-0000000000e1';
  static const String _photoId = '00000000-0000-4000-8000-0000000000e2';

  @override
  Future<Result<ResidentCredential?>> loadOwnCredential() async {
    final Result<DigitalIdCard> card = await loadDigitalId();
    return switch (card) {
      Ok(:final value) => Ok<ResidentCredential?>(
        credentialFromDigitalId(value),
      ),
      Err(:final failure) when failure is NotFoundFailure =>
        const Ok<ResidentCredential?>(null),
      Err(:final failure) => Err<ResidentCredential?>(failure),
    };
  }

  @override
  Future<Result<PresentationArtifact>> requestPresentationArtifact() async {
    final Result<DigitalIdCard> card = await loadDigitalId();
    return switch (card) {
      Ok(:final value) => _artifact(value),
      Err(:final failure) => Err<PresentationArtifact>(failure),
    };
  }

  @override
  Future<Result<DigitalIdCard>> loadDigitalId({DateTime? now}) async {
    if (!verified) {
      return const Err<DigitalIdCard>(
        ForbiddenFailure(
          debugMessage: 'A digital ID is issued only to a verified resident.',
        ),
      );
    }
    final DateTime clock = (now ?? DateTime.now()).toUtc();
    final DigitalIdCard? held = _held;
    if (held != null && !held.qrRefreshDue(clock)) {
      return _gate.respond(held);
    }
    final DigitalIdCard minted = _mint(clock);
    final Result<DigitalIdCard> result = await _gate.respond(minted);
    if (result.isOk) _held = result.valueOrNull;
    return result;
  }

  @override
  Future<Result<DigitalIdHolder>> verifyScannedToken({
    required String token,
  }) async {
    if (token.trim().isEmpty) {
      return const Err<DigitalIdHolder>(
        ValidationFailure(debugMessage: 'A token is required.'),
      );
    }
    return const Err<DigitalIdHolder>(
      ForbiddenFailure(debugMessage: 'Staff scan is not a resident action.'),
    );
  }

  DigitalIdCard _mint(DateTime clock) {
    return DigitalIdCard(
      id: _cardId,
      idNumber: 'SAMPLE-ID-0001',
      photoMediaId: _photoId,
      status: DigitalIdStatus.active,
      rawStatus: 'active',
      issuedAt: DateTime.utc(2026, 1, 1),
      expiresAt: DateTime.utc(2027, 1, 1),
      qr: DigitalIdQr(
        token: 'sample-qr-${clock.microsecondsSinceEpoch}',
        expiresAt: clock.add(digitalIdQrLifetime),
      ),
    );
  }

  static Result<PresentationArtifact> _artifact(DigitalIdCard card) {
    final PresentationArtifact? artifact = presentationFromDigitalId(card);
    if (artifact == null) {
      return const Err<PresentationArtifact>(
        NotFoundFailure(debugMessage: 'The card has no QR payload.'),
      );
    }
    return Ok<PresentationArtifact>(artifact);
  }
}

class MockVerificationRepository implements VerificationRepository {
  MockVerificationRepository(this._gate);

  final MockBehaviorController _gate;

  @override
  Future<Result<VerificationStatus>> loadOwnStatus() {
    return _gate.respond(
      const VerificationStatus(
        state: VerificationAttemptState.approved,
        rawState: 'approved',
      ),
    );
  }

  @override
  Future<Result<VerificationStatusDetail>> loadOwnStatusDetail() {
    return _gate.respond(
      const VerificationStatusDetail(
        stage: ResidentVerificationStage.verified,
        rawState: 'approved',
      ),
    );
  }

  @override
  Future<Result<VerificationStatus>> openCase({
    required KycClaim claim,
    required String idempotencyKey,
  }) {
    return _gate.respond(
      const VerificationStatus(
        state: VerificationAttemptState.draft,
        rawState: 'draft',
      ),
    );
  }

  @override
  Future<Result<void>> submitCorrections({
    required Map<CorrectableField, String> corrections,
    required String idempotencyKey,
  }) => _gate.respond<void>(null);

  @override
  Future<Result<KycDocument>> attachDocument({
    required KycDocumentType type,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String idempotencyKey,
  }) {
    return _gate.respond(
      KycDocument(type: type, isAttached: true, receivedAt: mockNow),
    );
  }

  @override
  Future<Result<List<KycDocument>>> loadDocuments() {
    return _gate.respond(const <KycDocument>[]);
  }

  @override
  Future<Result<void>> submitForReview({
    required List<String> documentUploadIds,
    required String idempotencyKey,
  }) => _gate.respond<void>(null);
}

class MockRegistrationRepository implements RegistrationRepository {
  MockRegistrationRepository(this._gate, this._directory);

  final MockBehaviorController _gate;
  final BarangayDirectory _directory;

  @override
  Future<Result<void>> requestOneTimeCode({required String mobileNumber}) =>
      _gate.respond<void>(null);

  @override
  Future<Result<void>> verifyOneTimeCode({
    required String mobileNumber,
    required String code,
  }) => _gate.respond<void>(null);

  @override
  Future<RegistrationCapabilities> loadCapabilities() async =>
      const RegistrationCapabilities(acceptsSubmissions: true);

  @override
  Future<Result<List<Barangay>>> listBarangays() => _directory.listBarangays();

  @override
  Future<Result<RegistrationResult>> submitRegistration({
    required RegistrationDraft draft,
    required String idempotencyKey,
  }) {
    return _gate.respond(
      const RegistrationResult(
        outcome: RegistrationOutcome.submitted,
        residentMessage: 'SAMPLE submission. Nothing was sent to the LGU.',
        referenceId: 'reg-sample-juana',
      ),
    );
  }
}

class MockBarangayDirectory implements BarangayDirectory {
  MockBarangayDirectory(this._gate);

  final MockBehaviorController _gate;

  @override
  Future<Result<List<Barangay>>> listBarangays() {
    return _gate.respond(const <Barangay>[
      Barangay(id: 'brgy-sample-san-juan', name: 'San Juan', code: 'SAMPLE'),
      Barangay(id: 'brgy-sample-dolores', name: 'Dolores', code: 'SAMPLE'),
    ]);
  }
}

class MockRequirementRepository implements RequirementRepository {
  MockRequirementRepository(this._gate);

  final MockBehaviorController _gate;

  @override
  Future<Result<RequirementChecklist>> listRequirements(String requestId) {
    return _gate.respond(
      RequirementChecklist(
        requestId: requestId,
        uploadPolicy: UploadPolicy.fallback,
        items: const <ResidentRequirement>[
          ResidentRequirement(
            code: 'id-sample',
            label: 'SAMPLE government ID',
            obligation: ServerValue<RequirementObligation>(
              raw: 'required',
              known: RequirementObligation.required,
            ),
            status: ServerValue<RequirementStatus>(
              raw: 'missing',
              known: RequirementStatus.missing,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<UploadedDocumentReference>> uploadRequirementDocument({
    required String requestId,
    required String requirementCode,
    required CapturedDocument document,
    required String idempotencyKey,
    required UploadPolicy policy,
    void Function(double fraction)? onProgress,
    UploadCancellation? cancellation,
  }) {
    onProgress?.call(1);
    return _gate.respond(
      UploadedDocumentReference(
        id: 'upload-sample-1',
        requirementCode: requirementCode,
        rawStatus: 'submitted',
      ),
    );
  }
}

class MockServiceRequestRepository implements ServiceRequestRepository {
  MockServiceRequestRepository(this._gate);

  final MockBehaviorController _gate;

  ServiceRequest _request(String id) => ServiceRequest(
    id: id,
    serviceCode: 'PWD-CASH-GIFT',
    state: ServiceRequestState.submitted,
    rawState: 'submitted',
    submittedAt: mockNow,
    referenceNumber: 'SAMPLE-0001',
  );

  @override
  Future<Result<Paginated<ServiceRequest>>> listOwnRequests({
    int page = 1,
    int perPage = 15,
  }) {
    return _gate.respond(_page(<ServiceRequest>[_request('req-sample-1')]));
  }

  @override
  Future<Result<ServiceRequest>> loadOwnRequest(String id) =>
      _gate.respond(_request(id));

  @override
  Future<Result<AssistanceCaseDetail>> loadOwnCase(String id) {
    return _gate.respond(AssistanceCaseDetail(request: _request(id)));
  }

  @override
  Future<Result<Paginated<AssistanceHistoryEntry>>> listOwnHistory({
    required HistoryScope scope,
    int page = 1,
    int perPage = 15,
  }) {
    return _gate.respond(
      _page(<AssistanceHistoryEntry>[
        AssistanceHistoryEntry(
          requestId: 'req-sample-1',
          serviceCode: 'PWD-CASH-GIFT',
          serviceName: 'SAMPLE PWD Cash Gift',
          status: const ServerValue<ServiceRequestState>(
            raw: 'submitted',
            known: ServiceRequestState.submitted,
          ),
          submittedAt: mockNow,
        ),
      ]),
    );
  }

  @override
  Future<Result<AssistanceIntakeForm>> loadIntakeForm(String serviceCode) {
    return _gate.respond(
      AssistanceIntakeForm(
        serviceCode: serviceCode,
        serviceName: 'SAMPLE service',
        narrativePrompt: 'SAMPLE. This form is not sent to the LGU.',
      ),
    );
  }

  @override
  Future<Result<ServiceRequest>> submitRequest({
    required String serviceCode,
    required String narrative,
    required Map<String, Object?> answers,
    required List<String> consentKeys,
    required List<String> attachmentIds,
    required String idempotencyKey,
  }) => _gate.respond(_request('req-sample-new'));

  @override
  Future<Result<void>> cancelOwnRequest({
    required String id,
    required String idempotencyKey,
  }) => _gate.respond<void>(null);
}

class MockAccountControlsRepository implements AccountControlsRepository {
  MockAccountControlsRepository(this._gate);

  final MockBehaviorController _gate;

  @override
  Future<Result<AccountControls>> loadControls() {
    return _gate.respond(const AccountControls());
  }

  @override
  Future<Result<List<ConsentRecord>>> listConsents() {
    return _gate.respond(<ConsentRecord>[
      ConsentRecord(
        key: 'privacy-notice',
        label: 'Privacy notice',
        statement: 'SAMPLE consent for Juana Dela Cruz.',
        grantedAt: mockNow,
      ),
    ]);
  }

  @override
  Future<Result<ConsentRecord>> withdrawConsent({
    required String key,
    required String idempotencyKey,
  }) {
    return _gate.respond(
      ConsentRecord(
        key: key,
        label: 'Privacy notice',
        statement: 'SAMPLE',
        withdrawnAt: mockNow,
      ),
    );
  }

  @override
  Future<Result<void>> requestDataCorrection({
    required String detail,
    required String idempotencyKey,
  }) => _gate.respond<void>(null);

  @override
  Future<Result<void>> requestAccountClosure({
    required bool permanent,
    required String reason,
    required String idempotencyKey,
  }) => _gate.respond<void>(null);
}

class MockOfficeMessagingRepository implements OfficeMessagingRepository {
  MockOfficeMessagingRepository(this._gate);

  final MockBehaviorController _gate;

  OfficeThread _thread(String id) => OfficeThread(
    id: id,
    officeId: 'mswdo',
    officeName: 'MSWDO',
    topic: 'SAMPLE inquiry',
    preview: 'A synthetic message from Juana Dela Cruz.',
    updatedAt: mockNow,
    unreadCount: 1,
    lastMessageAt: mockNow,
    createdAt: mockNow,
  );

  @override
  Future<Result<List<OfficeThread>>> listThreads() {
    return _gate.respond(<OfficeThread>[_thread('thread-sample-1')]);
  }

  @override
  Future<Result<OfficeThread>> loadThread(String threadId) {
    return _gate.respond(_thread(threadId));
  }

  @override
  Future<Result<List<OfficeMessage>>> listMessages(String threadId) {
    return _gate.respond(<OfficeMessage>[
      OfficeMessage(
        id: 'msg-sample-1',
        threadId: threadId,
        body: 'A synthetic message from Juana Dela Cruz.',
        sentAt: mockNow,
        fromResident: true,
      ),
    ]);
  }

  @override
  Future<Result<OfficeMessage>> send({
    required String officeId,
    required String topic,
    required String body,
  }) {
    return _gate.respond(
      OfficeMessage(
        id: 'msg-sample-1',
        threadId: 'thread-sample-1',
        body: body,
        sentAt: mockNow,
        fromResident: true,
      ),
    );
  }

  @override
  Future<Result<OfficeMessage>> reply({
    required String threadId,
    required String body,
  }) {
    return _gate.respond(
      OfficeMessage(
        id: 'msg-sample-2',
        threadId: threadId,
        body: body,
        sentAt: mockNow,
        fromResident: true,
      ),
    );
  }

  @override
  Future<Result<void>> closeThread(String threadId) =>
      _gate.respond<void>(null);

  @override
  Future<Result<void>> markThreadRead(String threadId) =>
      _gate.respond<void>(null);
}
