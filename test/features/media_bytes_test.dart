import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/http_api_transport.dart';
import 'package:taytay_resident/core/api/media_bytes_api.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/storage/media_byte_cache.dart';
import 'package:taytay_resident/features/citizen_api/data/node_citizen_api.dart';
import 'package:taytay_resident/features/citizen_api/domain/citizen_contract.dart';
import 'package:taytay_resident/features/credential/domain/credential_repository.dart';
import 'package:taytay_resident/features/credential/presentation/digital_id_canvas.dart';
import 'package:taytay_resident/features/home/data/home_catalogue.dart';
import 'package:taytay_resident/features/home/domain/home_content.dart';
import 'package:taytay_resident/features/home/presentation/home_canvas.dart';
import 'package:taytay_resident/features/news/domain/announcement_repository.dart';
import 'package:taytay_resident/features/news/presentation/balita_canvas.dart';
import 'package:taytay_resident/features/tulong/domain/social_service.dart';
import 'package:taytay_resident/features/tulong/presentation/tulong_canvas.dart';

const String _newsId = '11111111-1111-4111-8111-111111111111';
const String _slug = 'pwd-assistance';
const String _bannerId = '22222222-2222-4222-8222-222222222222';
const String _mediaId = '33333333-3333-4333-8333-333333333333';

final Uint8List _png = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x02,
  0x00,
  0x00,
  0x00,
  0x90,
  0x77,
  0x53,
  0xDE,
  0x00,
  0x00,
  0x00,
  0x0C,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0x00,
  0x00,
  0x03,
  0x01,
  0x01,
  0x00,
  0xC9,
  0xFE,
  0x92,
  0xEF,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

class _Scripted implements ApiTransport {
  _Scripted(this.responses);

  final List<ApiHttpResponse> responses;
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return Ok<ApiHttpResponse>(responses.removeAt(0));
  }
}

AppConfig _config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

ApiClient _client(_Scripted transport, {String? token = 'tok'}) => ApiClient(
  config: _config(),
  transport: transport,
  accessTokenProvider: () async => token,
);

ApiHttpResponse _image(Uint8List bytes, {String type = 'image/png'}) =>
    ApiHttpResponse(
      statusCode: 200,
      body: '',
      bodyBytes: bytes,
      headers: <String, String>{'content-type': type},
    );

ApiHttpResponse _missing(String message) => ApiHttpResponse(
  statusCode: 404,
  body: jsonEncode(<String, Object?>{
    'error': <String, Object?>{
      'code': 'NOT_FOUND',
      'message': message,
      'details': <String, Object?>{},
      'request_id': 'req-missing',
    },
  }),
  headers: const <String, String>{
    'content-type': 'application/json',
    'x-request-id': 'req-missing',
  },
);

void main() {
  test('public image routes use the configured base and cache a hit', () async {
    late Uri seen;
    var calls = 0;
    final HttpApiTransport transport = HttpApiTransport(
      config: _config(),
      client: MockClient((http.BaseRequest request) async {
        calls += 1;
        seen = request.url;
        return http.Response.bytes(
          _png,
          200,
          headers: const <String, String>{'content-type': 'image/png'},
        );
      }),
    );
    final MediaBytesApi api = MediaBytesApi(
      apiClient: ApiClient(
        config: _config(),
        transport: transport,
        accessTokenProvider: () async => 'session-token',
      ),
    );

    final Result<Uint8List?> first = await api.newsCover(_newsId);
    final Result<Uint8List?> second = await api.newsCover(_newsId);

    expect(first.valueOrNull, _png);
    expect(second.valueOrNull, _png);
    expect(calls, 1);
    expect(seen, Uri.parse('https://example.test/api/v1/news/$_newsId/cover'));
    expect(seen.toString(), isNot(contains('evil.example')));
    expect(api.toString(), isNot(contains('session-token')));
  });

  test(
    'a cover 404 is an empty picture and is not shown as server text',
    () async {
      final _Scripted transport = _Scripted(<ApiHttpResponse>[
        _missing('do not show this operator text'),
      ]);
      final MediaBytesApi api = MediaBytesApi(
        apiClient: _client(transport),
        cache: MediaByteCache(),
      );

      final Result<Uint8List?> result = await api.newsCover(_newsId);
      final Result<Uint8List?> again = await api.newsCover(_newsId);

      expect(result, isA<Ok<Uint8List?>>());
      expect(result.valueOrNull, isNull);
      expect(again.valueOrNull, isNull);
      expect(transport.requests, hasLength(1));
      expect('$result', isNot(contains('do not show this')));
      expect(transport.requests.single.path, 'news/$_newsId/cover');
      expect(
        transport.requests.single.headers['Accept'],
        contains('image/jpeg'),
      );
      expect(transport.requests.single.headers['Authorization'], 'Bearer tok');
    },
  );

  test('a bad image is refused and is not cached', () async {
    final _Scripted transport = _Scripted(<ApiHttpResponse>[
      ApiHttpResponse(
        statusCode: 200,
        body: '<html>secret</html>',
        bodyBytes: Uint8List.fromList('<html>secret</html>'.codeUnits),
        headers: const <String, String>{'content-type': 'image/jpeg'},
      ),
      _image(_png),
    ]);
    final MediaBytesApi api = MediaBytesApi(apiClient: _client(transport));

    final Result<Uint8List?> bad = await api.serviceHero(_slug);
    final Result<Uint8List?> good = await api.serviceHero(_slug);

    expect(bad, isA<Err<Uint8List?>>());
    expect('$bad', isNot(contains('secret')));
    expect(good.valueOrNull, _png);
    expect(
      transport.requests.map((ApiRequest request) => request.path),
      <String>['services/$_slug/hero', 'services/$_slug/hero'],
    );
  });

  test('an unsafe id is not requested', () async {
    final _Scripted transport = _Scripted(<ApiHttpResponse>[]);
    final MediaBytesApi api = MediaBytesApi(apiClient: _client(transport));

    expect((await api.newsCover('../admin')).valueOrNull, isNull);
    expect(
      (await api.homeBanner('https://evil.example/x')).valueOrNull,
      isNull,
    );
    expect(transport.requests, isEmpty);
  });

  test('a home banner image uses the banner id, not image_url', () async {
    final _Scripted transport = _Scripted(<ApiHttpResponse>[
      ApiHttpResponse(
        statusCode: 200,
        body: jsonEncode(<String, Object?>{
          'data': <String, Object?>{
            'banners': <Object?>[
              <String, Object?>{
                'id': _bannerId,
                'title': 'Hall hours',
                'sort_order': 1,
                'active': true,
                'image_url':
                    'https://evil.example/home/banners/$_bannerId/image',
              },
            ],
          },
          'meta': <String, Object?>{},
        }),
      ),
      _image(_png),
    ]);
    final ApiClient client = _client(transport, token: null);
    final Result<HomeFeed> home = await NodeCitizenApi(
      apiClient: client,
    ).loadHome();
    final HomeBanner banner = (home as Ok<HomeFeed>).value.banners.single;
    expect(banner.imageUrl, contains('evil.example'));

    final Result<Uint8List?> bytes = await MediaBytesApi(
      apiClient: client,
    ).homeBanner(banner.id);

    expect(bytes.valueOrNull, _png);
    expect(transport.requests.last.path, 'home/banners/$_bannerId/image');
    expect(
      transport.requests.last.headers.containsKey('Authorization'),
      isFalse,
    );
    expect(
      transport.requests.map((ApiRequest request) => request.path).join(' '),
      isNot(contains('evil.example')),
    );
  });

  test(
    'media content is authenticated and is not kept in the public cache',
    () async {
      final _Scripted missingToken = _Scripted(<ApiHttpResponse>[_image(_png)]);
      final MediaBytesApi anonymous = MediaBytesApi(
        apiClient: _client(missingToken, token: null),
      );
      final Result<Uint8List?> blocked = await anonymous.mediaContent(_mediaId);
      expect(blocked, isA<Err<Uint8List?>>());
      expect(blocked.failureOrNull, isA<UnauthenticatedFailure>());
      expect(missingToken.requests, isEmpty);

      final _Scripted transport = _Scripted(<ApiHttpResponse>[
        _image(_png),
        _image(_png),
      ]);
      final MediaBytesApi api = MediaBytesApi(apiClient: _client(transport));
      expect((await api.mediaContent(_mediaId)).valueOrNull, _png);
      expect((await api.mediaContent(_mediaId)).valueOrNull, _png);
      expect(transport.requests, hasLength(2));
      expect(
        transport.requests.every(
          (ApiRequest request) =>
              request.path == 'media/$_mediaId/content' &&
              request.headers['Authorization'] == 'Bearer tok',
        ),
        isTrue,
      );
    },
  );

  test('banner id is recorded only when image_url is set', () async {
    final List<HomeSlide> bundled = <HomeSlide>[
      const HomeSlide(
        eyebrow: 'Balita',
        title: 'Bundled',
        body: 'Body',
        action: 'Open',
        photoAsset: 'assets/photos/municipal_hall.jpg',
        credit: 'Fixture',
        routeName: 'news',
      ),
    ];
    final List<HomeSlide> linked =
        HomeCatalogue.withBanners(bundled, <HomeBanner>[
          const HomeBanner(
            id: _bannerId,
            title: 'Live title',
            sortOrder: 1,
            active: true,
            imageUrl: 'https://evil.example/banner.jpg',
          ),
        ]);
    expect(linked.single.bannerId, _bannerId);
    expect(linked.single.photoAsset, bundled.single.photoAsset);
    expect(linked.single.title, 'Live title');

    final List<HomeSlide> plain = HomeCatalogue.withBanners(
      bundled,
      <HomeBanner>[
        const HomeBanner(
          id: _bannerId,
          title: 'Live title',
          sortOrder: 1,
          active: true,
        ),
      ],
    );
    expect(plain.single.bannerId, isNull);
  });

  testWidgets('a Balita cover paints bytes and survives a failed read', (
    WidgetTester tester,
  ) async {
    var calls = 0;
    Future<Result<Uint8List?>> load(String id) async {
      calls += 1;
      expect(id, _newsId);
      return Ok<Uint8List?>(_png);
    }

    await _pump(
      tester,
      BalitaCanvas(
        frame: BalitaFrame.article,
        loadCover: load,
        article: const Announcement(
          id: _newsId,
          title: 'Hall notice',
          body: 'Bring a valid ID.',
          coverUrl: 'https://evil.example/covers/hall.jpg',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(_memoryImages(tester), isNotEmpty);
    expect(_networkImages(tester), isEmpty);
    expect(tester.takeException(), isNull);

    Future<Result<Uint8List?>> fail(String id) async =>
        const Err<Uint8List?>(NetworkFailure());
    await _pump(
      tester,
      BalitaCanvas(
        frame: BalitaFrame.article,
        loadCover: fail,
        article: const Announcement(
          id: _newsId,
          title: 'Hall notice',
          body: 'Bring a valid ID.',
          coverUrl: 'https://evil.example/covers/hall.jpg',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_memoryImages(tester), isEmpty);
    expect(_networkImages(tester), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a fixture cover does not request bytes', (
    WidgetTester tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      BalitaCanvas(
        frame: BalitaFrame.feed,
        loadCover: (String id) async {
          calls += 1;
          return Ok<Uint8List?>(_png);
        },
        articles: const <Announcement>[
          Announcement(
            id: _newsId,
            title: 'Hall notice',
            body: 'Bring a valid ID.',
            coverUrl: 'https://evil.example/covers/hall.jpg',
            presentation: BalitaPresentation(
              coverAsset: 'assets/photos/municipal_hall.jpg',
              listCover: true,
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.byType(Image), findsWidgets);
    expect(_networkImages(tester), isEmpty);
  });

  testWidgets('a Tulong hero stays the icon tile until bytes arrive', (
    WidgetTester tester,
  ) async {
    var calls = 0;
    const SocialService service = SocialService(
      id: _newsId,
      name: 'PWD Assistance',
      slug: _slug,
      summary: 'Summary',
      details: 'Details for the programme.',
      heroUrl: 'https://evil.example/services/pwd-assistance/hero',
    );

    await _pump(
      tester,
      TulongCanvas(
        frame: TulongFrame.detail,
        service: service,
        loadHero: (String slug) async {
          calls += 1;
          expect(slug, _slug);
          return const Err<Uint8List?>(NetworkFailure());
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(_memoryImages(tester), isEmpty);
    expect(tester.takeException(), isNull);

    await _pump(
      tester,
      const TulongCanvas(
        frame: TulongFrame.list,
        services: <SocialService>[service],
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);

    await _pump(
      tester,
      TulongCanvas(
        frame: TulongFrame.detail,
        service: service,
        loadHero: (String slug) async => Ok<Uint8List?>(_png),
      ),
    );
    await tester.pumpAndSettle();
    expect(_memoryImages(tester), isNotEmpty);
    expect(_networkImages(tester), isEmpty);
  });

  testWidgets('a digital ID portrait falls back to the placeholder', (
    WidgetTester tester,
  ) async {
    const ResidentCredential card = ResidentCredential(
      id: _newsId,
      rawState: 'active',
      state: CredentialLifecycleState.active,
      photoMediaId: _mediaId,
      idNumber: 'TAY-0001',
    );
    await _pump(
      tester,
      DigitalIdView(
        now: DateTime.utc(2026, 1, 1),
        card: card,
        name: 'Sample Resident',
        loadPhoto: (String id) async {
          expect(id, _mediaId);
          return const Err<Uint8List?>(NotFoundFailure());
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(_labeled('Photo placeholder'), findsOneWidget);
    expect(_memoryImages(tester), isEmpty);
    expect(tester.takeException(), isNull);

    await _pump(
      tester,
      DigitalIdView(
        now: DateTime.utc(2026, 1, 1),
        card: card,
        name: 'Sample Resident',
        loadPhoto: (String id) async => Ok<Uint8List?>(_png),
      ),
    );
    await tester.pumpAndSettle();
    expect(_labeled('ID photo'), findsWidgets);
    expect(_labeled('Photo placeholder'), findsNothing);
    expect(_networkImages(tester), isEmpty);
  });

  testWidgets('a home slide keeps the bundled photo when the banner fails', (
    WidgetTester tester,
  ) async {
    const HomeSlide slide = HomeSlide(
      eyebrow: 'Balita',
      title: 'Bundled title',
      body: 'Bundled body',
      action: 'Read',
      photoAsset: 'assets/photos/municipal_hall.jpg',
      credit: 'Fixture',
      routeName: 'news',
      bannerId: _bannerId,
    );
    var calls = 0;
    await _pump(
      tester,
      HomeCanvas(
        greeting: 'Magandang umaga',
        slides: const <HomeSlide>[slide],
        loadBanner: (String id) async {
          calls += 1;
          expect(id, _bannerId);
          return const Err<Uint8List?>(NetworkFailure());
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byType(Image), findsWidgets);
    expect(_memoryImages(tester), isEmpty);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: child,
    ),
  );
  await tester.pump();
}

Finder _labeled(String label) {
  return find.byWidgetPredicate(
    (Widget widget) =>
        widget is Semantics && widget.properties.label == label ||
        widget is Image && widget.semanticLabel == label,
  );
}

List<ImageProvider<Object>> _memoryImages(WidgetTester tester) {
  return tester
      .widgetList<Image>(find.byType(Image))
      .map((Image image) => image.image)
      .where(_isMemory)
      .toList();
}

bool _isMemory(ImageProvider<Object> provider) {
  if (provider is MemoryImage) return true;
  if (provider is ResizeImage && provider.imageProvider is MemoryImage) {
    return true;
  }
  return false;
}

List<NetworkImage> _networkImages(WidgetTester tester) {
  return tester
      .widgetList<Image>(find.byType(Image))
      .map((Image image) => image.image)
      .whereType<NetworkImage>()
      .toList();
}
