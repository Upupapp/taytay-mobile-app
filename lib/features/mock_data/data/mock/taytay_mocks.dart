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
import '../../../events/domain/event_registration.dart'
    as event_outcome
    show RegistrationOutcome;
import '../../../events/domain/event_repository.dart' hide RegistrationOutcome;
import '../../../household/domain/household_repository.dart';
import '../../../household/domain/household_summary.dart';
import '../../../messaging/domain/office_messaging_repository.dart';
import '../../../news/domain/announcement_repository.dart';
import '../../../notifications/domain/notification_repository.dart';
import '../../../platform/domain/app_bootstrap.dart';
import '../../../platform/domain/platform_repository.dart';
import '../../../platform/domain/privacy_notice.dart';
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
import '../../../services/domain/lgu_service.dart';
import '../../../services/domain/service_catalog_repository.dart';
import '../../../services/domain/service_request_repository.dart';
import '../../../settings/domain/account_controls.dart';
import '../../../verification/domain/correctable_field.dart';
import '../../../verification/domain/kyc_claim.dart';
import '../../../verification/domain/verification_repository.dart';
import '../../../verification/domain/verification_status_detail.dart';
import 'code_challenge_book.dart';
import 'resident_record_mock.dart';

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
    final Result<CodeAcceptance> verdict = _codes.sendEmailCode();
    return switch (verdict) {
      Ok<CodeAcceptance>(:final value) => _gate.respond(value),
      Err<CodeAcceptance>(:final failure) =>
        Future<Result<CodeAcceptance>>.value(Err<CodeAcceptance>(failure)),
    };
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
    if (application.idFrontBytes == null ||
        application.idFrontBytes!.isEmpty ||
        application.idFrontName == null ||
        application.idFrontName!.isEmpty ||
        application.idFrontMime == null ||
        application.idFrontMime!.isEmpty ||
        application.selfieBytes == null ||
        application.selfieBytes!.isEmpty ||
        application.selfieName == null ||
        application.selfieName!.isEmpty ||
        application.selfieMime == null ||
        application.selfieMime!.isEmpty) {
      return Future<Result<void>>.value(
        const Err<void>(
          ValidationFailure(
            debugMessage: 'The ID front and a selfie are required.',
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

  BalitaPresentation? _presentation(Map<String, Object?> map) {
    final Object? facts = map['facts'];
    final List<BalitaFact> parsed = facts is List
        ? <BalitaFact>[
            for (final Object? row in facts)
              if (row is Map)
                BalitaFact(
                  label: '${row['label'] ?? ''}',
                  value: '${row['value'] ?? ''}',
                  icon: '${row['icon'] ?? 'landmark'}',
                ),
          ]
        : const <BalitaFact>[];
    if (map['cover_asset'] == null &&
        map['lead'] == null &&
        map['footer'] == null &&
        map['date_label'] == null &&
        map['list_date'] == null &&
        map['photo_credit'] == null &&
        map['pinned_title'] == null &&
        parsed.isEmpty &&
        map['sample'] != true) {
      return null;
    }
    return BalitaPresentation(
      coverAsset: map['cover_asset'] as String?,
      photoCredit: map['photo_credit'] as String?,
      lead: map['lead'] as String?,
      footer: map['footer'] as String?,
      dateLabel: map['date_label'] as String?,
      listDate: map['list_date'] as String?,
      coverHeight: map['cover_height'] is num
          ? (map['cover_height']! as num).toDouble()
          : 180,
      listCover: map['list_cover'] == true,
      facts: parsed,
      tileIcon: map['tile_icon'] as String?,
      sample: map['sample'] == true,
      pinnedTitle: map['pinned_title'] as String?,
      pinnedBody: map['pinned_body'] as String?,
    );
  }

  Future<List<Announcement>> _items() async {
    final raw = await MockFixtures.list('announcements');
    final Map<String, String> offices = await _officeLabels();
    return <Announcement>[
      for (final entry in raw)
        if (_asMap(entry) case final Map<String, Object?> map)
          Announcement(
            id: map['id']! as String,
            title: map['title']! as String,
            body: map['body']! as String,
            summary: map['summary'] as String?,
            category: map['category'] as String?,
            author: _bylineOffice(map, offices),
            officeSlug: map['office_slug'] as String?,
            publishedAt: map['published_at'] is String
                ? DateTime.tryParse(map['published_at']! as String)
                : mockNow,
            isPinned: map['pinned'] == true,
            pinnedAt: map['pinned_at'] is String
                ? DateTime.tryParse(map['pinned_at']! as String)
                : null,
            shareUrl: map['share_url'] as String?,
            coverUrl: map['cover_url'] as String?,
            publicationState: const ServerValue<PublicationState>(
              raw: 'published',
              known: PublicationState.published,
            ),
            presentation: _presentation(map),
          ),
    ];
  }

  /// Byline office: `short_name`, then `name`, then the slug. The announcement
  /// `author` is only the fallback when the office row has neither label.
  String? _bylineOffice(
    Map<String, Object?> article,
    Map<String, String> offices,
  ) {
    final Object? slug = article['office_slug'];
    if (slug is String && offices[slug] != null) return offices[slug];
    final Object? author = article['author'];
    if (author is! String) return null;
    final String trimmed = author.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// `short_name` when it is a string. Null falls through to `name`, then the id.
  Future<Map<String, String>> _officeLabels() async {
    final Map<String, Object?> json = await MockFixtures.object('offices');
    final Object? rows = json['offices'];
    if (rows is! List) return const <String, String>{};
    final Map<String, String> labels = <String, String>{};
    for (final Object? row in rows) {
      if (row is! Map) continue;
      final Object? id = row['id'];
      if (id is! String || id.isEmpty) continue;
      final String? shortName = _officeText(row['short_name']);
      final String? name = _officeText(row['name']);
      labels[id] = shortName ?? name ?? id;
    }
    return labels;
  }

  String? _officeText(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Future<Result<Paginated<Announcement>>> listAnnouncements({
    int page = 1,
    int perPage = 15,
    String? category,
  }) async {
    final List<Announcement> all = await _items();
    final String? chip = category?.trim();
    final List<Announcement> matched =
        chip == null || chip.isEmpty || chip == 'Lahat'
        ? all
        : all
              .where(
                (Announcement item) =>
                    (item.category ?? '').toLowerCase() == chip.toLowerCase(),
              )
              .toList(growable: false);
    // The server lists pinned articles first, including under a category.
    final List<Announcement> filtered = <Announcement>[
      ...matched.where((Announcement item) => item.isPinned),
      ...matched.where((Announcement item) => !item.isPinned),
    ];
    final int start = (page - 1) * perPage;
    final List<Announcement> slice = start >= filtered.length
        ? const <Announcement>[]
        : filtered.skip(start).take(perPage).toList(growable: false);
    return _gate.respond(
      Paginated<Announcement>(
        items: slice,
        page: page,
        perPage: perPage,
        total: filtered.length,
        totalPages: filtered.isEmpty
            ? 1
            : ((filtered.length + perPage - 1) ~/ perPage),
        hasMore: start + slice.length < filtered.length,
      ),
    );
  }

  @override
  Future<Result<List<NewsCategory>>> listCategories() {
    return _gate.respond(NewsCategory.catalogue);
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
    String? cursor,
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
          ChannelPreference(type: 'balita', inApp: true, push: true),
          ChannelPreference(type: 'emergency', inApp: true, push: true),
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
        privacyNotice: PrivacyNotice(
          version: 'placeholder',
          bodyMarkdown: 'This placeholder is not shown.',
        ),
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
        createdAt: MockResidentRecordRepository.sampleAccountCreatedAt,
        verificationDecidedAt: DateTime.utc(2026, 10, 21, 16),
        values: <ResidentProfileField, String>{
          ResidentProfileField.fullName: resident.displayName,
          ResidentProfileField.emailAddress: resident.email,
          ResidentProfileField.mobileNumber: resident.mobile,
          ResidentProfileField.barangay: resident.barangay,
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
  MockHouseholdRepository(this._gate);

  final MockBehaviorController _gate;

  @override
  Future<Result<HouseholdSummary>> loadOwnHousehold() async {
    final resident = await MockResident.load();
    return _gate.respond(
      HouseholdSummary(
        role: HouseholdRole.member,
        label: 'SAMPLE household',
        barangay: resident.barangay,
      ),
    );
  }

  @override
  Future<Result<void>> submitCorrectionRequest({
    required HouseholdCorrectionRequest request,
    required String idempotencyKey,
  }) => _gate.respond<void>(null);
}

class MockCredentialRepository implements CredentialRepository {
  MockCredentialRepository(this._gate);

  final MockBehaviorController _gate;

  @override
  Future<Result<ResidentCredential?>> loadOwnCredential() {
    // Fictional SAMPLE card. The number and the dates are the illustration
    // on 08-11, not an issued credential. The QR expiry is far ahead so a
    // dev session does not refetch on a loop. The token is not a secret.
    return _gate.respond(
      ResidentCredential(
        id: 'credential-sample-1',
        idNumber: 'TYT-0000-0000',
        state: CredentialLifecycleState.active,
        rawState: 'active',
        issuedAt: DateTime.utc(2026, 10, 22, 12),
        expiresAt: DateTime.utc(2029, 10, 22, 12),
        qr: PresentationArtifact(
          payload: 'sample-qr-not-a-credential',
          expiresAt: DateTime.utc(2099, 1, 1, 13, 42),
        ),
      ),
    );
  }

  @override
  Future<Result<String?>> loadResidentName() {
    // The 08-11 illustration name. Fictional. Not the account-home fixture.
    return _gate.respond('Juan Dela Cruz');
  }

  @override
  Future<Result<PresentationArtifact>> requestPresentationArtifact() {
    return _gate.respond(
      const PresentationArtifact(payload: 'SAMPLE-PRESENTATION'),
    );
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
      VerificationStatusDetail(
        stage: ResidentVerificationStage.verified,
        rawState: 'approved',
        idType: MockResidentRecordRepository.sampleIdType,
        submittedAt: MockResidentRecordRepository.sampleSubmittedAt,
        reviewedAt: MockResidentRecordRepository.sampleVerifiedAt,
        canEdit: false,
        residentGuidance: null,
        submittedCategories: const <VerificationItemCategory>[
          VerificationItemCategory.identityDocument,
          VerificationItemCategory.photo,
        ],
      ),
    );
  }

  @override
  Future<Result<VerificationStatus>> submitVerification({
    required String idType,
    required VerificationImagePart front,
    VerificationImagePart? back,
    required VerificationImagePart selfie,
    String? idempotencyKey,
  }) {
    return _gate.respond(
      const VerificationStatus(
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
  }) {
    return _gate.respond(
      VerificationStatusDetail(
        stage: ResidentVerificationStage.pendingReview,
        rawState: 'pending',
        canEdit: true,
        idType: MockResidentRecordRepository.sampleIdType,
        submittedAt: MockResidentRecordRepository.sampleSubmittedAt,
        submittedCategories: const <VerificationItemCategory>[
          VerificationItemCategory.identityDocument,
          VerificationItemCategory.photo,
        ],
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
    String message = '',
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
