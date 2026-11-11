import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/storage/public_cache.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/core/time/manila_time.dart';
import 'package:taytay_resident/features/tulong/data/social_service_api_repository.dart';
import 'package:taytay_resident/features/tulong/domain/service_search.dart';
import 'package:taytay_resident/features/tulong/domain/social_service.dart';
import 'package:taytay_resident/features/tulong/domain/social_service_repository.dart';
import 'package:taytay_resident/features/tulong/presentation/tulong_canvas.dart';
import 'package:taytay_resident/features/tulong/presentation/tulong_screen.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/soft_note.dart';

/// Tulong searches on the phone and sends no search term (D-59, D-205).
///
/// Replaces what `s7_tulong_test` pinned before D-205: that the typed search
/// went to `GET /services` as `q`.

/// Answers each request from [answer] and keeps every request it was sent.
class _Routed implements ApiTransport {
  _Routed(this.answer);

  final ApiHttpResponse Function(ApiRequest request) answer;
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return Ok<ApiHttpResponse>(answer(request));
  }
}

ApiHttpResponse _page(
  List<Object?> data, {
  String? cursor,
  bool more = false,
}) => ApiHttpResponse(
  statusCode: 200,
  body: jsonEncode(<String, Object?>{
    'data': data,
    'meta': <String, Object?>{
      'pagination': <String, Object?>{'has_more': more, 'next_cursor': cursor},
    },
  }),
);

final ApiHttpResponse _serverError = ApiHttpResponse(
  statusCode: 500,
  body: jsonEncode(<String, Object?>{
    'error': <String, Object?>{
      'code': 'internal_error',
      'message': 'operator text',
      'details': null,
      'request_id': 'req-synthetic',
    },
  }),
);

int _ids = 0;

Map<String, Object?> _service(
  String name,
  String slug, {
  String summary = 'A synthetic summary',
  String? category,
  bool hidden = false,
}) => <String, Object?>{
  'id': '11111111-1111-4111-8111-${(100000000000 + _ids++).toString()}',
  'name': name,
  'slug': slug,
  'summary': summary,
  'details': 'Synthetic details for a test service.',
  'category': category,
  'requirements': const <String>['Bring an ID'],
  'contacts': const <Object?>[],
  'locations': const <Object?>[],
  'featured': false,
  'hidden_from_list': hidden,
  'created_at': '2026-07-01T00:00:00Z',
  'updated_at': '2026-07-01T00:00:00Z',
};

final List<Object?> _firstPage = <Object?>[
  _service('Senior Citizen Pension', 'senior-pension'),
  _service(
    'Tulong para sa Santo Niño',
    'nino-aid',
    summary: 'Cash aid for families in Santo Niño',
  ),
];

final List<Object?> _secondPage = <Object?>[
  _service('Burial Assistance', 'burial', category: 'Crisis help'),
  // Repeated across pages: shown once.
  _service('Senior Citizen Pension', 'senior-pension'),
  _service('Hidden Programme', 'hidden', hidden: true),
];

AppConfig _dev() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
  rawMockLatencyMs: '0',
);

SocialServiceApiRepository _repository(_Routed transport) =>
    SocialServiceApiRepository(
      apiClient: ApiClient(
        config: _dev(),
        transport: transport,
        cache: PublicCache(),
      ),
    );

SocialService _plain(
  String name,
  String slug, {
  String summary = 'Summary',
  String? category,
  String? office,
}) => SocialService(
  id: slug,
  name: name,
  slug: slug,
  summary: summary,
  details: 'Details',
  category: category,
  officeShortName: office,
);

/// Every request [transport] was sent, checked for [term] anywhere.
void _expectNoTerm(_Routed transport, String term) {
  final String needle = term.toLowerCase();
  for (final ApiRequest request in transport.requests) {
    expect(request.query.keys, isNot(contains('q')), reason: request.path);
    expect(
      request.query.values.any(
        (String value) => value.toLowerCase().contains(needle),
      ),
      isFalse,
      reason: request.path,
    );
    expect(request.path.toLowerCase().contains(needle), isFalse);
    expect(request.body, isNull);
  }
}

void main() {
  group('readCatalogue', () {
    test('reads every page, 50 at a time, and sends no term', () async {
      final _Routed transport = _Routed(
        (ApiRequest request) => request.query['cursor'] == null
            ? _page(_firstPage, cursor: 'c-2', more: true)
            : _page(_secondPage),
      );
      final ServiceCatalogue catalogue = (await _repository(
        transport,
      ).readCatalogue()).valueOrNull!;

      expect(catalogue.complete, isTrue);
      expect(catalogue.services.map((SocialService s) => s.slug), <String>[
        'senior-pension',
        'nino-aid',
        'burial',
      ]);
      expect(transport.requests, hasLength(2));
      expect(transport.requests.first.query, <String, String>{'limit': '50'});
      expect(transport.requests.last.query, <String, String>{
        'limit': '50',
        'cursor': 'c-2',
      });
      for (final ApiRequest request in transport.requests) {
        expect(request.path, 'services');
        expect(request.method, HttpMethod.get);
      }
    });

    test('a page that fails fails the read; no part passes as all', () async {
      final _Routed transport = _Routed(
        (ApiRequest request) => request.query['cursor'] == null
            ? _page(_firstPage, cursor: 'c-2', more: true)
            : _serverError,
      );
      final Result<ServiceCatalogue> read = await _repository(
        transport,
      ).readCatalogue();
      expect(read.isErr, isTrue);
    });

    test('more pages with no cursor is read as far as it goes, and says '
        'it is not all', () async {
      final _Routed transport = _Routed(
        (ApiRequest request) => _page(_firstPage, more: true),
      );
      final ServiceCatalogue catalogue = (await _repository(
        transport,
      ).readCatalogue()).valueOrNull!;
      expect(catalogue.complete, isFalse);
      expect(catalogue.services, hasLength(2));
      expect(transport.requests, hasLength(1));
    });

    test('the page ceiling stops the read and marks it incomplete', () async {
      var page = 0;
      final _Routed transport = _Routed(
        (ApiRequest request) => _page(
          <Object?>[_service('Programme $page', 'programme-${page++}')],
          cursor: 'c-$page',
          more: true,
        ),
      );
      final ServiceCatalogue catalogue = (await _repository(
        transport,
      ).readCatalogue()).valueOrNull!;
      expect(catalogue.complete, isFalse);
      expect(
        transport.requests,
        hasLength(SocialServiceApiRepository.catalogueMaxPages),
      );
      expect(
        catalogue.services,
        hasLength(SocialServiceApiRepository.catalogueMaxPages),
      );
      _expectNoTerm(transport, 'programme');
    });
  });

  group('searchServices', () {
    final List<SocialService> services = <SocialService>[
      _plain('Senior Citizen Pension', 'senior-pension'),
      _plain(
        'Tulong para sa Santo Niño',
        'nino-aid',
        summary: 'Cash aid for families',
      ),
      _plain('Burial Assistance', 'burial', category: 'Crisis help'),
      _plain('Feeding Programme', 'feeding', office: 'MSWDO'),
      _plain('Nino Scholarship', 'scholarship'),
    ];
    List<String> slugs(String query) => <String>[
      for (final SocialService s in searchServices(services, query)) s.slug,
    ];

    test('ignores case', () {
      expect(slugs('SENIOR'), <String>['senior-pension']);
      expect(slugs('senior citizen'), <String>['senior-pension']);
    });

    test('ignores accents in what was typed and in the catalogue', () {
      expect(slugs('nino'), <String>['nino-aid', 'scholarship']);
      expect(slugs('Niño'), <String>['nino-aid', 'scholarship']);
      expect(slugs('NIÑO'), <String>['nino-aid', 'scholarship']);
      // A combining tilde typed after the letter.
      expect(slugs('niño'), <String>['nino-aid', 'scholarship']);
    });

    test('every word must appear, in any order', () {
      expect(slugs('cash nino'), <String>['nino-aid']);
      expect(slugs('  aid   cash '), <String>['nino-aid']);
      expect(slugs('cash burial'), isEmpty);
    });

    test('matches the category and the office, never the slug', () {
      expect(slugs('crisis'), <String>['burial']);
      expect(slugs('mswdo'), <String>['feeding']);
      expect(slugs('senior-pension'), isEmpty);
    });

    test('nothing typed shows everything', () {
      expect(searchServices(services, '   '), same(services));
      expect(foldForSearch('  Santo   NIÑO '), 'santo nino');
    });
  });

  group('the Tulong screen', () {
    Future<_Routed> pumpScreen(
      WidgetTester tester, {
      required bool Function() failServices,
    }) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 1800);
      addTearDown(tester.view.reset);
      final _Routed transport = _Routed((ApiRequest request) {
        if (request.path != 'services') return _page(const <Object?>[]);
        if (failServices()) return _serverError;
        return request.query['cursor'] == null
            ? _page(_firstPage, cursor: 'c-2', more: true)
            : _page(_secondPage);
      });
      final AppDependencies dependencies = AppDependencies.build(
        config: _dev(),
        transport: transport,
        secrets: InMemorySecretStore(),
        sessionStore: InMemorySessionStore(),
        localAuthenticator: const UnavailableLocalAuthenticator(),
      );
      addTearDown(dependencies.dispose);
      await tester.pumpWidget(
        AppDependenciesScope(
          dependencies: dependencies,
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppStrings.localizationsDelegates,
            supportedLocales: AppLocales.supported,
            home: const TulongScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return transport;
    }

    testWidgets('typing a search sends nothing, and filters the whole '
        'catalogue on the phone', (WidgetTester tester) async {
      final _Routed transport = await pumpScreen(
        tester,
        failServices: () => false,
      );
      // The first read is the whole catalogue, both pages.
      final int read = transport.requests.length;
      expect(
        transport.requests.where((ApiRequest r) => r.path == 'services'),
        hasLength(2),
      );
      expect(find.byKey(const Key('tulong-open-burial')), findsOneWidget);

      for (final String term in <String>['burial', 'NIÑO cash', 'solo']) {
        await tester.enterText(find.byKey(const Key('tulong-search')), term);
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
      }
      await tester.enterText(find.byKey(const Key('tulong-search')), 'burial');
      await tester.pumpAndSettle();
      // On page two of the catalogue, so only a full read finds it.
      expect(find.byKey(const Key('tulong-open-burial')), findsOneWidget);
      expect(find.byKey(const Key('tulong-open-nino-aid')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('tulong-search')),
        'nino CASH',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tulong-open-nino-aid')), findsOneWidget);
      expect(find.byKey(const Key('tulong-open-burial')), findsNothing);

      await tester.enterText(find.byKey(const Key('tulong-search')), 'solo');
      await tester.pumpAndSettle();
      expect(find.text('No programmes match that search.'), findsOneWidget);

      expect(transport.requests, hasLength(read), reason: 'typing is local');
      for (final String term in <String>['burial', 'nino', 'cash', 'solo']) {
        _expectNoTerm(transport, term);
      }
    });

    testWidgets('a failed refresh keeps the list, says when it was read, and '
        'offers Try again', (WidgetTester tester) async {
      var fail = false;
      final _Routed transport = await pumpScreen(
        tester,
        failServices: () => fail,
      );
      expect(find.byKey(TulongCanvas.staleNoteKey), findsNothing);

      fail = true;
      // show() completes only after the refresh, which needs frames: pump.
      unawaited(
        tester
            .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
            .show(),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(TulongCanvas.staleNoteKey), findsOneWidget);
      expect(find.text(TulongCanvas.staleHeading), findsOneWidget);
      expect(find.textContaining('Showing the list from '), findsOneWidget);
      expect(find.textContaining(ManilaTime.label), findsOneWidget);
      // The old list is still there, and still searchable.
      expect(find.byKey(const Key('tulong-open-burial')), findsOneWidget);
      expect(find.text('operator text'), findsNothing);
      final SoftNote note = tester.widget<SoftNote>(
        find.byKey(TulongCanvas.staleNoteKey),
      );
      expect(note.tone, NoteTone.warning);

      fail = false;
      await tester.tap(find.byKey(TulongCanvas.staleRetryKey));
      await tester.pumpAndSettle();
      expect(find.byKey(TulongCanvas.staleNoteKey), findsNothing);
      expect(find.byKey(const Key('tulong-open-burial')), findsOneWidget);
      _expectNoTerm(transport, 'burial');
    });
  });

  group('the Tulong canvas', () {
    final List<SocialService> listed = <SocialService>[
      _plain('Senior Citizen Pension', 'senior-pension'),
    ];

    Future<void> pump(WidgetTester tester, Widget canvas) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(390, 1600);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: canvas),
      );
      await tester.pump();
    }

    testWidgets('the stale note names the time in Manila and retries', (
      WidgetTester tester,
    ) async {
      var retried = 0;
      final DateTime readAt = DateTime.utc(2026, 11, 12, 1, 30);
      await pump(
        tester,
        TulongCanvas(
          frame: TulongFrame.list,
          services: listed,
          staleSince: readAt,
          onRetry: () => retried++,
        ),
      );
      expect(find.text(TulongCanvas.staleMessage(readAt)), findsOneWidget);
      expect(
        TulongCanvas.staleMessage(readAt),
        contains(ManilaTime.formatDateTime(readAt)),
      );
      expect(find.byKey(const Key('tulong-open-senior-pension')), findsOne);
      await tester.tap(find.byKey(TulongCanvas.staleRetryKey));
      expect(retried, 1);
    });

    testWidgets('a current list has no stale or partial note', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        TulongCanvas(frame: TulongFrame.list, services: listed),
      );
      expect(find.byKey(TulongCanvas.staleNoteKey), findsNothing);
      expect(find.byKey(TulongCanvas.incompleteNoteKey), findsNothing);
    });

    testWidgets('a partial catalogue says the search covers what was read', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        TulongCanvas(
          frame: TulongFrame.list,
          services: listed,
          partialCatalogueCount: 500,
        ),
      );
      expect(find.byKey(TulongCanvas.incompleteNoteKey), findsOneWidget);
      expect(find.text(TulongCanvas.incompleteMessage(500)), findsOneWidget);
      expect(TulongCanvas.incompleteMessage(500), contains('first 500'));
    });
  });
}
