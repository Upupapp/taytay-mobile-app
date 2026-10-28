import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/account/presentation/account_canvas.dart';
import 'package:taytay_resident/features/directory/data/office_api_repository.dart';
import 'package:taytay_resident/features/directory/domain/office.dart';
import 'package:taytay_resident/features/directory/presentation/directory_canvas.dart';
import 'package:taytay_resident/features/settings/data/privacy_api_repository.dart';
import 'package:taytay_resident/features/settings/domain/account_controls.dart';
import 'package:taytay_resident/features/tulong/data/social_service_api_repository.dart';
import 'package:taytay_resident/features/tulong/domain/social_service.dart';

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

    final Result<ConsentRecord?> accepted = await repository.recordConsent(
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
}
