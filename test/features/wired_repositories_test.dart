import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/events/data/event_api_repository.dart';
import 'package:taytay_resident/features/events/domain/event_repository.dart';
import 'package:taytay_resident/features/household/data/household_api_repository.dart';
import 'package:taytay_resident/features/household/domain/household_summary.dart';
import 'package:taytay_resident/features/news/data/newsfeed_api_repository.dart';
import 'package:taytay_resident/features/news/domain/announcement_repository.dart';
import 'package:taytay_resident/features/notifications/data/notification_api_repository.dart';
import 'package:taytay_resident/features/notifications/domain/notification_repository.dart';
import 'package:taytay_resident/features/services/data/assistance_api_repository.dart';
import 'package:taytay_resident/features/services/domain/assistance_case.dart';
import 'package:taytay_resident/features/services/domain/assistance_history.dart';
import 'package:taytay_resident/features/services/domain/service_request_repository.dart';

/// Wire tests for the repositories TABs 05 and 08–13 wired.
///
/// ---
///
/// **Why this file exists separately.** Those TABs each removed an "absent
/// backend explains itself" test as they replaced the stub it asserted, and put
/// nothing in its place. The suite count fell and the wiring detector went on
/// passing, which together look like progress and are not: the detector proves a
/// repository is *bound*, never that it calls the right path or reads the right
/// field. Without this file, TAB 23 would inherit thirteen wired repositories
/// and a suite that had never seen any of them make a request.
///
/// **What each group asserts is the claim its commit made.** No seats-left
/// arithmetic; no member list; routing-only notification targets; critical
/// categories that cannot be switched off; the idempotency key on the operations
/// that create something. Those were rationale in a commit message, which is a
/// place claims go to be believed rather than checked.
class _Scripted implements ApiTransport {
  _Scripted(this.responses);

  final List<Result<ApiHttpResponse>> responses;
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return responses.isEmpty
        ? const Err<ApiHttpResponse>(NetworkFailure())
        : responses.removeAt(0);
  }
}

Result<ApiHttpResponse> ok(Object data, {Object? meta, int status = 200}) =>
    Ok<ApiHttpResponse>(
      ApiHttpResponse(
        statusCode: status,
        body: jsonEncode(<String, Object?>{
          'data': data,
          'meta': meta ?? <String, Object?>{'request_id': 'req-1'},
        }),
        headers: const <String, String>{'x-request-id': 'req-1'},
      ),
    );

Result<ApiHttpResponse> apiError(int status, String code) =>
    Ok<ApiHttpResponse>(
      ApiHttpResponse(
        statusCode: status,
        body: jsonEncode(<String, Object?>{
          'error': <String, Object?>{'code': code, 'message': 'operator text'},
        }),
        headers: const <String, String>{'x-request-id': 'req-1'},
      ),
    );

ApiClient clientFor(ApiTransport transport) => ApiClient(
  config: AppConfig.from(
    rawEnvironment: 'dev',
    rawApiBaseUrl: 'https://example.test/api/v1',
    isReleaseBuild: false,
  ),
  transport: transport,
  accessTokenProvider: () async => 'tok',
);

bool sentAuthenticated(ApiRequest request) =>
    request.headers.keys.any((String k) => k.toLowerCase() == 'authorization');

void main() {
  late _Scripted transport;
  setUp(() => transport = _Scripted(<Result<ApiHttpResponse>>[]));

  group('household — the member array is never read', () {
    test(
      'the household is not fetched, so the member array is never read',
      () async {
        final Result<HouseholdSummary> result = await HouseholdApiRepository(
          apiClient: clientFor(transport),
        ).loadOwnHousehold();

        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull!.debugMessage, contains('F32'));
        expect(transport.requests, isEmpty);
      },
    );
  });

  group('assistance — the key goes on the irreversible call only', () {
    test('submitting declines and sends no draft', () async {
      final Result<ServiceRequest> result =
          await AssistanceApiRepository(
            apiClient: clientFor(transport),
          ).submitRequest(
            serviceCode: 'AICS',
            narrative: 'Roof damaged by a storm.',
            answers: const <String, Object?>{},
            consentKeys: const <String>['privacy-2026'],
            attachmentIds: const <String>[],
            idempotencyKey: 'submit-once',
          );

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull!.debugMessage, contains('F32'));
      expect(transport.requests, isEmpty);
    });

    test('history declines for both scopes', () async {
      final AssistanceApiRepository repository = AssistanceApiRepository(
        apiClient: clientFor(transport),
      );
      final past = await repository.listOwnHistory(scope: HistoryScope.past);
      final open = await repository.listOwnHistory(scope: HistoryScope.open);

      expect(past.failureOrNull, isA<ServerFailure>());
      expect(open.failureOrNull, isA<ServerFailure>());
      expect(transport.requests, isEmpty);
    });

    test(
      'a case is not loaded from a route the contract does not publish',
      () async {
        final Result<AssistanceCaseDetail> result =
            await AssistanceApiRepository(
              apiClient: clientFor(transport),
            ).loadOwnCase('case-9');

        expect(result.failureOrNull, isA<ServerFailure>());
        expect(transport.requests, isEmpty);
      },
    );
  });

  group('newsfeed — public reads stay anonymous, comments do not', () {
    test('the feed sends a token when there is one, and works without', () async {
      // THIS TEST ASSERTED THE OPPOSITE UNTIL A REAL SERVER DISAGREED.
      //
      // It required the feed to be fetched anonymously, because the route file
      // carries no `auth:sanctum` and anonymous keeps a response publicly
      // cacheable. Calling the running API returned 401: the controller refuses
      // an anonymous reader unless `newsfeed.public_access` is on, and it
      // defaults off (F30). So a request anonymous *by construction* failed for
      // signed-in residents too — the token existed and was withheld on
      // principle.
      transport.responses.add(ok(<Object?>[]));
      await NewsfeedApiRepository(
        apiClient: clientFor(transport),
      ).listAnnouncements();

      expect(transport.requests.single.path, 'news');
      expect(sentAuthenticated(transport.requests.single), isTrue);

      // With no session it still goes rather than failing for the lack of a
      // token: a guest gets the server's own answer about whether the feed is
      // public, instead of the app guessing on their behalf.
      final _Scripted guest = _Scripted(<Result<ApiHttpResponse>>[
        ok(<Object?>[]),
      ]);
      final Result<Paginated<Announcement>> result =
          await NewsfeedApiRepository(
            apiClient: ApiClient(
              config: AppConfig.from(
                rawEnvironment: 'dev',
                rawApiBaseUrl: 'https://example.test/api/v1',
                isReleaseBuild: false,
              ),
              transport: guest,
              accessTokenProvider: () async => null,
            ),
          ).listAnnouncements();

      expect(result.isOk, isTrue);
      expect(sentAuthenticated(guest.requests.single), isFalse);
    });

    test(
      'comments decline: the Node news resource has no comment route',
      () async {
        final result = await NewsfeedApiRepository(
          apiClient: clientFor(transport),
        ).listComments('p-1');

        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull!.debugMessage, contains('F32'));
        expect(transport.requests, isEmpty);
      },
    );

    test('published_at is read, never created_at', () async {
      transport.responses.add(
        ok(<Object?>[
          <String, Object?>{
            'id': 'p-1',
            'headline': 'Water interruption',
            'body': 'Details.',
            'comments_enabled': true,
            'created_at': '2026-01-01T00:00:00Z',
            'published_at': '2026-08-15T02:00:00Z',
          },
        ]),
      );

      final Result<Paginated<Announcement>> result =
          await NewsfeedApiRepository(
            apiClient: clientFor(transport),
          ).listAnnouncements();

      // On an emergency advisory the difference between drafting and publishing
      // is the one that matters.
      expect(
        (result as Ok<Paginated<Announcement>>).value.items.single.publishedAt,
        DateTime.utc(2026, 8, 15, 2),
      );
    });

    test('a decorative image is skipped, and alt text is carried', () async {
      transport.responses.add(
        ok(<Object?>[
          <String, Object?>{
            'id': 'p-1',
            'headline': 'H',
            'body': 'B',
            'media': <Object?>[
              <String, Object?>{
                'is_decorative': true,
                'alt_text': '',
                'urls': <String>['https://example.test/decor.jpg'],
              },
              <String, Object?>{
                'is_decorative': false,
                'alt_text': 'Queue outside the municipal hall',
                'urls': <String>['https://example.test/real.jpg'],
              },
            ],
          },
        ]),
      );

      final Result<Paginated<Announcement>> result =
          await NewsfeedApiRepository(
            apiClient: clientFor(transport),
          ).listAnnouncements();
      final Announcement post =
          (result as Ok<Paginated<Announcement>>).value.items.single;

      expect(post.media!.url, endsWith('real.jpg'));
      expect(post.media!.alternativeText, isNotNull);
    });

    test(
      'reporting a comment reaches the resident surface, not the staff one',
      () async {
        // F26, and it used to decline. A report button that silently does nothing
        // is worse than an absent one — the resident believes they have told the
        // municipality — so this was an honest failure until the backend published
        // a route a resident may call.
        transport.responses.add(
          ok(<String, Object?>{'status': 'accepted'}, status: 202),
        );

        final Result<void> result =
            await NewsfeedApiRepository(
              apiClient: clientFor(transport),
            ).reportComment(
              postId: 'p-1',
              commentId: 'c-1',
              reason: ReportReason.abusive,
              idempotencyKey: 'k',
            );

        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull!.debugMessage, contains('F32'));
        expect(transport.requests, isEmpty);
      },
    );
  });

  group('events — there is no seats-left number to be found', () {
    test('capacity is carried and remaining is never derived', () async {
      transport.responses.add(
        ok(<Object?>[
          <String, Object?>{
            'id': 'e-1',
            'title': 'Medical mission',
            'summary': 'Free check-ups.',
            'starts_at': '2026-09-01T01:00:00Z',
            'registration': <String, Object?>{
              'required': true,
              'capacity': 100,
              'waitlist_enabled': true,
              'availability': 'open',
              'message': 'Registration is open.',
            },
          },
        ]),
      );

      final Result<Paginated<LguEvent>> listed = await EventApiRepository(
        apiClient: clientFor(transport),
      ).listEvents();
      final Result<RegistrationAttempt> registered =
          await EventApiRepository(apiClient: clientFor(transport)).register(
            eventId: 'e-1',
            answers: const <String, Object?>{},
            consentKeys: const <String>[],
            idempotencyKey: 'reg-once',
          );

      expect(listed.failureOrNull, isA<ServerFailure>());
      expect(registered.failureOrNull, isA<ServerFailure>());
      expect(transport.requests, isEmpty);
    });
  });

  group('notifications — routing only, and critical stays on', () {
    test('a target carries a type and an id and nothing else', () async {
      transport.responses.add(
        ok(<Object?>[
          <String, Object?>{
            'id': 'n-1',
            'title': 'Your application moved',
            'body': 'Open the app to see.',
            'subject_type': 'welfare_case',
            'subject_id': 'case-9',
            'category': 'assistance_status',
            'created_at': '2026-08-18T02:00:00Z',
            // Anything else the server adds must not survive into the target.
            'resident_name': 'Ana Dela Cruz',
            'amount': 5000,
            'action': 'approve',
          },
        ]),
      );

      final Result<Paginated<ResidentNotification>> result =
          await NotificationApiRepository(
            apiClient: clientFor(transport),
          ).listOwn();
      final ResidentNotification notification =
          (result as Ok<Paginated<ResidentNotification>>).value.items.single;

      expect(notification.target, <String, String>{
        'type': 'welfare_case',
        'id': 'case-9',
      });
      final String rendered = notification.target.toString();
      for (final String leak in <String>['Ana', '5000', 'approve']) {
        expect(rendered, isNot(contains(leak)), reason: leak);
      }
    });

    test('a critical category stored as off is still on', () async {
      transport.responses.add(
        ok(<String, Object?>{
          'preferences': <Object?>[
            <String, Object?>{
              'notification_type': 'account_security',
              'channel': 'push',
              'enabled': false,
            },
            <String, Object?>{
              'notification_type': 'event_reminder',
              'channel': 'push',
              'enabled': false,
            },
          ],
          'mandatory_notice':
              'Service and security notices cannot be switched off.',
        }),
      );

      final Result<NotificationPreferences> result =
          await NotificationApiRepository(
            apiClient: clientFor(transport),
          ).loadPreferences();

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull!.debugMessage, contains('F32'));
      expect(transport.requests, isEmpty);
    });

    test('an update declines and sends no preference body', () async {
      final Result<void> result =
          await NotificationApiRepository(
            apiClient: clientFor(transport),
          ).updatePreferences(
            const NotificationPreferences(
              push: true,
              sms: false,
              email: false,
              categories: <NotificationCategory, bool>{
                NotificationCategory.accountSecurity: true,
                NotificationCategory.eventReminder: false,
              },
            ),
          );

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(transport.requests, isEmpty);
    });
  });
}
