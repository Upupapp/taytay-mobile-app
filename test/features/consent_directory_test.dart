import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/taytay_icons.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/storage/public_cache.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/account/presentation/account_canvas.dart';
import 'package:taytay_resident/features/directory/data/office_api_repository.dart';
import 'package:taytay_resident/features/directory/domain/office.dart';
import 'package:taytay_resident/features/directory/presentation/directory_canvas.dart';
import 'package:taytay_resident/features/directory/presentation/directory_screen.dart';
import 'package:taytay_resident/features/settings/data/privacy_api_repository.dart';
import 'package:taytay_resident/features/settings/domain/account_controls.dart';
import 'package:taytay_resident/features/tulong/data/social_service_api_repository.dart';
import 'package:taytay_resident/features/tulong/domain/social_service.dart';
import 'package:taytay_resident/shared/widgets/taytay_icon.dart';

class _Recording implements ApiTransport {
  _Recording(this.responses);

  final List<ApiHttpResponse> responses;
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return Ok<ApiHttpResponse>(responses.removeAt(0));
  }
}

ApiHttpResponse _json(int status, Object? data, {String? message}) {
  final Object body = status >= 200 && status < 300
      ? <String, Object?>{'data': data, 'meta': <String, Object?>{}}
      : <String, Object?>{
          'error': <String, Object?>{
            'code': status == 404 ? 'NOT_FOUND' : 'VALIDATION_FAILED',
            'message': message ?? 'operator text the resident must not see',
            'request_id': 'req-sample',
          },
        };
  return ApiHttpResponse(
    statusCode: status,
    body: jsonEncode(body),
    headers: const <String, String>{'x-request-id': 'req-sample'},
  );
}

AppConfig _config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

ApiClient _client(_Recording transport, {void Function()? onUnauthenticated}) {
  return ApiClient(
    config: _config(),
    transport: transport,
    accessTokenProvider: () async => 'sample-token',
    onUnauthenticated: onUnauthenticated == null
        ? null
        : () async => onUnauthenticated(),
  );
}

void main() {
  test('withdraw sets withdrawn_at and accept clears it', () async {
    final _Recording transport = _Recording(<ApiHttpResponse>[
      _json(200, <String, Object?>{
        'id': 'consent-1',
        'version': 'notice-2026-01',
        'accepted_at': '2026-01-02T00:00:00.000Z',
        'withdrawn_at': '2026-06-01T00:00:00.000Z',
      }),
      _json(200, <String, Object?>{
        'id': 'consent-1',
        'version': 'notice-2026-01',
        'accepted_at': '2026-01-02T00:00:00.000Z',
        'withdrawn_at': null,
      }),
    ]);
    final PrivacyApiRepository repository = PrivacyApiRepository(
      apiClient: _client(transport),
    );

    final Result<ConsentRecord> withdrawn = await repository.withdrawConsent(
      key: 'notice-2026-01',
      idempotencyKey: 'idem-1',
    );
    final ConsentRecord row = withdrawn.valueOrNull!;
    expect(row.key, 'notice-2026-01');
    expect(row.isActive, isFalse);
    expect(row.withdrawnAt, DateTime.utc(2026, 6, 1));
    expect(row.isWithdrawable, isTrue);
    expect(row.toString(), 'ConsentRecord(notice-2026-01, active: false)');
    expect(row.toString(), isNot(contains('Agreed')));

    final ApiRequest withdraw = transport.requests.single;
    expect(withdraw.method, HttpMethod.post);
    expect(withdraw.path, 'me/consents/withdraw');
    expect(withdraw.body, <String, Object?>{'version': 'notice-2026-01'});
    expect(withdraw.headers['Authorization'], 'Bearer sample-token');
    expect(withdraw.headers['Idempotency-Key'], 'idem-1');
    expect(withdraw.headers.containsKey('X-Role'), isFalse);

    final Result<ConsentRecord> accepted = await repository.acceptConsent(
      version: 'notice-2026-01',
    );
    expect(accepted.valueOrNull!.isActive, isTrue);
    expect(accepted.valueOrNull!.withdrawnAt, isNull);
    expect(transport.requests.last.path, 'me/consents');
    expect(transport.requests.last.body, <String, Object?>{
      'version': 'notice-2026-01',
    });
  });

  test(
    'a withdraw error keeps the server sentence off the resident copy',
    () async {
      final _Recording transport = _Recording(<ApiHttpResponse>[
        _json(
          404,
          null,
          message: 'operator-only sentence about a missing version',
        ),
      ]);
      final PrivacyApiRepository repository = PrivacyApiRepository(
        apiClient: _client(transport),
      );

      final Result<ConsentRecord> result = await repository.withdrawConsent(
        key: 'missing-version',
        idempotencyKey: 'idem-2',
      );
      final AppFailure failure = result.failureOrNull!;
      expect(failure, isA<NotFoundFailure>());
      expect(failure.residentMessage, isNot(contains('operator-only')));
      expect(
        failure.residentMessage.toLowerCase(),
        isNot(contains('missing version')),
      );
      expect(failure.requestId, 'req-sample');
    },
  );

  test('a consent without a version is not withdrawn by its id', () async {
    const String id = '11111111-1111-4111-8111-111111111111';
    final _Recording transport = _Recording(<ApiHttpResponse>[
      _json(200, <Object?>[
        <String, Object?>{
          'id': id,
          'accepted_at': '2026-01-02T00:00:00.000Z',
          'withdrawn_at': null,
        },
      ]),
    ]);
    final PrivacyApiRepository repository = PrivacyApiRepository(
      apiClient: _client(transport),
    );

    final Result<List<ConsentRecord>> listed = await repository.listConsents();
    final ConsentRecord row = listed.valueOrNull!.single;
    expect(row.isWithdrawable, isFalse);
    expect(row.key, isEmpty);
    expect(row.key, isNot(id));
  });

  test('image bytes are not stored in the public cache', () async {
    final PublicCache cache = PublicCache(
      allowedPaths: <String>{'offices/sample-office/hero'},
    );
    final _Recording transport = _Recording(<ApiHttpResponse>[
      ApiHttpResponse(
        statusCode: 200,
        body: '',
        bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
      ),
    ]);
    final ApiClient client = ApiClient(
      config: _config(),
      transport: transport,
      cache: cache,
    );

    await client.send<Uint8List>(
      method: HttpMethod.get,
      path: 'offices/sample-office/hero',
      authenticated: false,
      binary: true,
      endSessionOnUnauthorized: false,
      decode: (Object? data) => data is Uint8List ? data : Uint8List(0),
    );

    expect(cache.size, 0);
    expect(cache.read<Object?>('offices/sample-office/hero'), isNull);
  });

  test('service lines default to empty and the hero is anonymous', () async {
    var signedOut = 0;
    final Uint8List png = Uint8List.fromList(<int>[1, 2, 3, 4]);
    final _Recording transport = _Recording(<ApiHttpResponse>[
      _json(200, <Object?>[
        <String, Object?>{
          'id': 'office-1',
          'name': 'Sample Office',
          'slug': 'sample-office',
          'short_name': 'SAMPLE',
          'hero_url': 'https://example.test/api/v1/offices/sample-office/hero',
          'service_lines': <String>['Certificates', '  ', 'IDs'],
        },
        <String, Object?>{
          'id': 'office-2',
          'name': 'Plain Office',
          'slug': 'plain-office',
        },
      ]),
      ApiHttpResponse(
        statusCode: 401,
        body: jsonEncode(<String, Object?>{
          'error': <String, Object?>{
            'code': 'UNAUTHENTICATED',
            'message': 'session ended',
            'request_id': 'req-hero',
          },
        }),
        headers: const <String, String>{'x-request-id': 'req-hero'},
      ),
      ApiHttpResponse(
        statusCode: 200,
        body: '',
        bytes: png,
        headers: const <String, String>{'content-type': 'image/png'},
      ),
    ]);
    final OfficeApiRepository repository = OfficeApiRepository(
      apiClient: _client(transport, onUnauthenticated: () => signedOut++),
    );

    final result = await repository.list();
    final List<Office> offices = result.valueOrNull!.offices;
    expect(
      offices.first.services.map((OfficeServiceLine line) => line.label),
      <String>['Certificates', 'IDs'],
    );
    expect(offices.first.heroUrl, contains('/offices/sample-office/hero'));
    expect(offices.first.heroAsset, 'assets/photos/municipal_hall.jpg');
    expect(offices.last.services, isEmpty);
    expect(offices.last.heroUrl, isNull);
    expect(offices.last.heroAsset, 'assets/photos/municipal_hall.jpg');

    final Result<Uint8List> denied = await repository.loadHero('sample-office');
    expect(denied.failureOrNull, isA<UnauthenticatedFailure>());
    expect(signedOut, 0);
    final ApiRequest hero = transport.requests[1];
    expect(hero.path, 'offices/sample-office/hero');
    expect(hero.headers.containsKey('Authorization'), isFalse);
    expect(hero.headers['Accept'], contains('image/'));

    final Result<Uint8List> painted = await repository.loadHero(
      'sample-office',
    );
    expect(painted.valueOrNull, png);
    expect(signedOut, 0);
  });

  test('an office catalogue read sends the office slug', () async {
    final _Recording transport = _Recording(<ApiHttpResponse>[
      _json(200, <Object?>[
        <String, Object?>{
          'id': 'svc-1',
          'name': 'Sample assistance',
          'slug': 'sample-assistance',
          'summary': 'Synthetic.',
          'details': '',
          'requirements': <String>[],
          'contacts': <Object?>[],
          'locations': <Object?>[],
          'created_at': '2026-01-01T00:00:00.000Z',
          'updated_at': '2026-01-01T00:00:00.000Z',
        },
      ]),
    ]);
    final SocialServiceApiRepository repository = SocialServiceApiRepository(
      apiClient: _client(transport),
    );
    final Result<Paginated<SocialService>> listed = await repository
        .listServices(office: 'sample-office');
    expect(listed.valueOrNull!.items.single.slug, 'sample-assistance');
    expect(transport.requests.single.query['office'], 'sample-office');
    expect(transport.requests.single.path, 'services');
  });

  test('catalogue names join directory lines without replacing them', () {
    const Office office = Office(
      id: 'sample-office',
      shortName: 'SAMPLE',
      name: 'Sample Office',
      listName: 'Sample Office',
      category: 'Social services',
      listLine: 'Ground floor',
      icon: OfficeIcon.building2,
      keywords: <String>[],
      eyebrow: 'SOCIAL SERVICES',
      summary: 'Synthetic.',
      heroAsset: 'assets/photos/municipal_hall.jpg',
      heroFocus: 0.5,
      insetAsset: 'assets/photos/municipal_hall.jpg',
      representative: false,
      credit: '',
      messageable: true,
      callLabel: 'Call',
      callIsEmergency: false,
      phone: '',
      directionsQuery: 'Taytay',
      facts: <OfficeFact>[],
      services: <OfficeServiceLine>[OfficeServiceLine(label: 'Certificates')],
    );
    final List<OfficeServiceLine> lines = office
        .linesWithCatalogue(<({String label, String slug})>[
          (label: 'Certificates', slug: 'certificates'),
          (label: 'Sample assistance', slug: 'sample-assistance'),
        ]);
    expect(lines.map((OfficeServiceLine line) => line.label), <String>[
      'Certificates',
      'Sample assistance',
    ]);
    expect(lines.first.serviceSlug, isNull);
    expect(lines.last.serviceSlug, 'sample-assistance');
  });

  testWidgets('settings keeps its frame until My Account offers consents', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const AccountCanvas(frame: AccountFrame.settings),
      ),
    );
    expect(find.text('Your consents'), findsNothing);
    expect(find.text('Privacy Notice'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AccountCanvas(
          frame: AccountFrame.settings,
          showDataExport: false,
          onConsents: () {},
        ),
      ),
    );
    expect(find.text('Your consents'), findsOneWidget);
    expect(find.text('Review or withdraw what you agreed to'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is TaytayIcon && widget.icon == TaytayIcons.shieldCheck,
      ),
      findsOneWidget,
    );
    final List<String?> labels = tester
        .widgetList<Text>(find.byType(Text))
        .map((Text text) => text.data)
        .toList();
    expect(
      labels.indexOf('Your consents'),
      greaterThan(labels.indexOf('Privacy Notice')),
    );
    expect(find.text('Request a copy of my data'), findsNothing);
  });

  testWidgets('an office page shows service lines and falls back to the hall', (
    WidgetTester tester,
  ) async {
    const Office office = Office(
      id: 'sample-office',
      shortName: 'SAMPLE',
      name: 'Sample Office',
      listName: 'Sample Office',
      category: 'Social services',
      listLine: 'Ground floor',
      icon: OfficeIcon.building2,
      keywords: <String>[],
      eyebrow: 'SOCIAL SERVICES',
      summary: 'Synthetic office.',
      heroAsset: 'assets/photos/municipal_hall.jpg',
      heroFocus: 0.5,
      insetAsset: 'assets/photos/municipal_hall.jpg',
      representative: false,
      credit: '',
      messageable: true,
      callLabel: 'Call',
      callIsEmergency: false,
      phone: '',
      directionsQuery: 'Taytay',
      facts: <OfficeFact>[],
      services: <OfficeServiceLine>[
        OfficeServiceLine(label: 'Certificates'),
        OfficeServiceLine(
          label: 'Sample assistance',
          serviceSlug: 'sample-assistance',
        ),
      ],
    );
    String? opened;
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: DirectoryCanvas(
          frame: DirectoryFrame.detail,
          offices: const <Office>[],
          office: office,
          onServiceLine: (String slug) => opened = slug,
        ),
      ),
    );
    expect(find.text('Certificates'), findsOneWidget);
    expect(find.text('Sample assistance'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    await tester.tap(find.text('Sample assistance'));
    expect(opened, 'sample-assistance');
    await tester.tap(find.text('Certificates'));
    expect(opened, 'sample-assistance');
  });

  testWidgets('the office shows the hall, then its hero and its services', (
    WidgetTester tester,
  ) async {
    final _HeldOffice gate = await _pumpOffice(tester);

    expect(find.text('Sample Office'), findsWidgets);
    expect(_paintsHall(tester), isTrue);
    expect(_paintsMemory(tester), isFalse);
    expect(
      gate.requests.map((ApiRequest request) => request.path),
      containsAll(<String>['services', 'offices/sample-office/hero']),
    );
    expect(
      gate.requests
          .singleWhere((ApiRequest request) => request.path == 'services')
          .query['office'],
      'sample-office',
    );

    gate.release(
      'services',
      _json(200, <Object?>[
        <String, Object?>{
          'id': 'svc-1',
          'name': 'Sample assistance',
          'slug': 'sample-assistance',
          'summary': 'Synthetic.',
          'details': '',
          'requirements': <String>[],
          'contacts': <Object?>[],
          'locations': <Object?>[],
        },
      ]),
    );
    gate.release(
      'offices/sample-office/hero',
      ApiHttpResponse(statusCode: 200, body: '', bytes: base64Decode(_png)),
    );
    await tester.pumpAndSettle();

    expect(_paintsMemory(tester), isTrue);
    expect(find.text('Sample assistance'), findsOneWidget);
  });

  testWidgets('a hero 404 keeps the hall', (WidgetTester tester) async {
    final _HeldOffice gate = await _pumpOffice(tester);
    expect(_paintsHall(tester), isTrue);
    gate.release('services', _json(200, <Object?>[]));
    gate.release('offices/sample-office/hero', _json(404, null));
    await tester.pumpAndSettle();
    expect(find.text('Sample Office'), findsWidgets);
    expect(_paintsHall(tester), isTrue);
    expect(_paintsMemory(tester), isFalse);
  });

  testWidgets('a hero 5xx keeps the hall', (WidgetTester tester) async {
    final _HeldOffice gate = await _pumpOffice(tester);
    gate.release('services', _json(200, <Object?>[]));
    gate.release(
      'offices/sample-office/hero',
      ApiHttpResponse(
        statusCode: 500,
        body: jsonEncode(<String, Object?>{
          'error': <String, Object?>{
            'code': 'INTERNAL_ERROR',
            'message': 'operator outage text',
            'request_id': 'req-hero',
          },
        }),
        headers: const <String, String>{'x-request-id': 'req-hero'},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sample Office'), findsWidgets);
    expect(_paintsHall(tester), isTrue);
    expect(_paintsMemory(tester), isFalse);
    expect(find.textContaining('operator outage'), findsNothing);
  });
}

class _HeldOffice implements ApiTransport {
  final List<ApiRequest> requests = <ApiRequest>[];
  final Map<String, Completer<ApiHttpResponse>> _held =
      <String, Completer<ApiHttpResponse>>{};

  void release(String path, ApiHttpResponse response) {
    _held.remove(path)!.complete(response);
  }

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    if (request.path == 'offices/sample-office') {
      return Ok<ApiHttpResponse>(
        _json(200, <String, Object?>{
          'id': 'office-1',
          'name': 'Sample Office',
          'slug': 'sample-office',
          'hero_url': 'https://example.test/api/v1/offices/sample-office/hero',
          'service_lines': <String>['Certificates'],
        }),
      );
    }
    final Completer<ApiHttpResponse> completer = Completer<ApiHttpResponse>();
    _held[request.path] = completer;
    return Ok<ApiHttpResponse>(await completer.future);
  }
}

const String _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

bool _paintsMemory(WidgetTester tester) {
  return tester
      .widgetList<Image>(find.byType(Image))
      .any((Image image) => image.image is MemoryImage);
}

bool _paintsHall(WidgetTester tester) {
  return tester.widgetList<Image>(find.byType(Image)).any((Image image) {
    final ImageProvider<Object> provider = image.image;
    return provider is AssetImage &&
        provider.assetName == 'assets/photos/municipal_hall.jpg';
  });
}

Future<_HeldOffice> _pumpOffice(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final _HeldOffice gate = _HeldOffice();
  final AppDependencies dependencies = AppDependencies.build(
    config: _config(),
    transport: gate,
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
        home: const OfficeDetailScreen(officeId: 'sample-office'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return gate;
}
