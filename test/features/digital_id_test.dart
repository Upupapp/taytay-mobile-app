import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/credential/data/credential_api_repository.dart';
import 'package:taytay_resident/features/credential/domain/credential_repository.dart';
import 'package:taytay_resident/features/credential/domain/digital_id_face.dart';
import 'package:taytay_resident/features/credential/presentation/digital_id_canvas.dart';
import 'package:taytay_resident/features/credential/presentation/digital_id_screen.dart';

void main() {
  group('the face is the server card plus the expiry rule', () {
    test('a null card and an unrecognised status are not issued', () {
      expect(digitalIdFace(null, DateTime.utc(2026, 10, 22)), isNull);
      expect(
        digitalIdFace(_card(CredentialLifecycleState.applied), _now),
        isNull,
      );
      expect(
        digitalIdFace(
          _card(CredentialLifecycleState.active, raw: 'mystery'),
          _now,
        ),
        DigitalIdFace.active,
      );
      expect(
        digitalIdFace(
          const ResidentCredential(
            id: 'card-1',
            state: null,
            rawState: 'mystery',
          ),
          _now,
        ),
        isNull,
      );
    });

    test('suspended and revoked win over the expiry rule', () {
      final DateTime later = DateTime.utc(2030, 1, 1);
      expect(
        digitalIdFace(
          _card(CredentialLifecycleState.suspended, expires: _past),
          later,
        ),
        DigitalIdFace.suspended,
      );
      expect(
        digitalIdFace(
          _card(CredentialLifecycleState.revoked, expires: _past),
          later,
        ),
        DigitalIdFace.revoked,
      );
    });

    test('expired is now strictly after expires_at with a null QR', () {
      final ResidentCredential card = _card(
        CredentialLifecycleState.active,
        expires: DateTime.utc(2029, 10, 22, 12),
      );
      expect(
        digitalIdFace(card, DateTime.utc(2029, 10, 22, 12)),
        DigitalIdFace.active,
      );
      expect(
        digitalIdFace(card, DateTime.utc(2029, 10, 22, 12, 0, 1)),
        DigitalIdFace.expired,
      );
      expect(
        digitalIdFace(
          _card(
            CredentialLifecycleState.active,
            expires: DateTime.utc(2029, 10, 22, 12),
            qr: _qr,
          ),
          DateTime.utc(2030, 1, 1),
        ),
        DigitalIdFace.active,
      );
      expect(
        digitalIdFace(_card(CredentialLifecycleState.expired), _now),
        DigitalIdFace.expired,
      );
    });
  });

  group('the resident name is trimmed and not recased', () {
    test('blank becomes null and the rest is kept', () {
      expect(publishedResidentName(null), isNull);
      expect(publishedResidentName('   '), isNull);
      expect(publishedResidentName('  juan dela CRUZ '), 'juan dela CRUZ');
    });

    test('GET /me reads data.name and nothing else', () {
      expect(CredentialApiRepository.profilePath, 'me');
      expect(
        CredentialApiRepository.decodeResidentName(<String, Object?>{
          'name': '  Juan Dela Cruz  ',
          'email': 'resident@example.com',
        }),
        'Juan Dela Cruz',
      );
      expect(
        CredentialApiRepository.decodeResidentName(<String, Object?>{
          'name': ' ',
        }),
        isNull,
      );
      expect(
        CredentialApiRepository.decodeResidentName(<String, Object?>{}),
        isNull,
      );
    });
  });

  test('dates and the refresh clock use the device zone', () {
    expect(formatDigitalIdDate(DateTime(2026, 10, 22, 21, 42)), 'Oct 22, 2026');
    expect(formatDigitalIdClock(DateTime(2026, 10, 22, 21, 42)), '9:42 PM');
    expect(formatDigitalIdClock(DateTime(2026, 10, 22, 0, 5)), '12:05 AM');
    expect(formatDigitalIdClock(DateTime(2026, 10, 22, 12)), '12:00 PM');
  });

  test('credential presentation does not nudge with Transform', () {
    for (final String path in <String>[
      'lib/features/credential/presentation/digital_id_canvas.dart',
      'lib/features/credential/presentation/digital_id_screen.dart',
    ]) {
      expect(
        File(path).readAsStringSync().contains('Transform'),
        isFalse,
        reason: path,
      );
    }
  });

  testWidgets('an empty name hides the NAME block', (tester) async {
    await _pump(
      tester,
      DigitalIdView(
        card: _card(CredentialLifecycleState.active, qr: _qr),
        name: '   ',
        now: _localNow,
        sample: true,
      ),
    );
    expect(find.text('NAME'), findsNothing);
    expect(find.text('ID NUMBER'), findsOneWidget);
    expect(find.text('MUNICIPALITY OF TAYTAY'), findsOneWidget);
  });

  // Redesign P3b: DigitalID.dc.html prints the name at 14 / 800 (`.nm`) in
  // the card grid, not 17 / 800 across the old card. Still two lines, still
  // ellipsized, still as the server sent it.
  testWidgets('a long name stays 14/800 and ellipsizes on line 2', (
    tester,
  ) async {
    await _loadFonts();
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await _pump(
      tester,
      DigitalIdView(
        card: _card(CredentialLifecycleState.active, qr: _qr),
        name: 'Maria Concepcion Dela Paz',
        now: _localNow,
      ),
    );
    final Text text = tester.widget<Text>(find.byKey(DigitalIdView.nameKey));
    expect(text.data, 'Maria Concepcion Dela Paz');
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.softWrap, isTrue);
    expect(text.style?.fontSize, 14);
    expect(text.style?.fontWeight, FontWeight.w800);
    expect(text.style?.height, 1.25);
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(DigitalIdView.nameKey),
    );
    expect(paragraph.didExceedMaxLines, isFalse);

    await _pump(
      tester,
      DigitalIdView(
        card: _card(CredentialLifecycleState.active, qr: _qr),
        name:
            'Maria Concepcion Josefina Dela Paz-Villanueva Santiago Fernandez '
            'Reyes Bautista Concepcion',
        now: _localNow,
      ),
    );
    final RenderParagraph longer = tester.renderObject<RenderParagraph>(
      find.byKey(DigitalIdView.nameKey),
    );
    expect(longer.didExceedMaxLines, isTrue);
    expect(longer.size.height, lessThanOrEqualTo(14 * 1.25 * 2 + 1));
  });

  testWidgets('the QR token is not a label and is not in the widget dump', (
    tester,
  ) async {
    const String token = 'sample-qr-not-a-credential';
    await _pump(
      tester,
      DigitalIdView(
        card: _card(
          CredentialLifecycleState.active,
          qr: const PresentationArtifact(payload: token),
        ),
        name: 'Juan Dela Cruz',
        now: _localNow,
      ),
    );
    expect(find.bySemanticsLabel('QR code'), findsOneWidget);
    expect(find.textContaining(token), findsNothing);
    final String dump = tester.allWidgets
        .map((Widget widget) => widget.toString())
        .join('\n');
    expect(dump, isNot(contains(token)));
  });

  testWidgets('a code that is not live is not painted', (tester) async {
    await _pump(
      tester,
      DigitalIdView(
        card: _card(
          CredentialLifecycleState.active,
          qr: PresentationArtifact(
            payload: 'sample-qr-not-a-credential',
            expiresAt: DateTime.utc(2020, 1, 1),
          ),
        ),
        name: 'Juan Dela Cruz',
        now: _now,
      ),
    );
    expect(find.byKey(DigitalIdView.qrKey), findsNothing);
    expect(find.text('Refreshing code…'), findsOneWidget);
    expect(find.textContaining('sample-qr-not-a-credential'), findsNothing);
  });

  testWidgets('the fake clock refreshes a code at expires_at, hours ahead', (
    tester,
  ) async {
    final DateTime start = tester.binding.clock.now().toUtc();
    final DateTime expiry = start.add(const Duration(hours: 3));
    final DateTime renewed = start.add(const Duration(hours: 5));
    final _Recording repository = _Recording.cards(<ResidentCredential?>[
      _card(
        CredentialLifecycleState.active,
        qr: PresentationArtifact(
          payload: 'sample-qr-not-a-credential',
          expiresAt: expiry,
        ),
      ),
      _card(
        CredentialLifecycleState.active,
        qr: PresentationArtifact(
          payload: 'sample-qr-not-a-credential',
          expiresAt: renewed,
        ),
      ),
    ]);
    await _pump(
      tester,
      DigitalIdScreen(
        key: const Key('far-qr'),
        repository: repository,
        now: () => tester.binding.clock.now(),
        sample: false,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(repository.cardLoads, 1);
    expect(find.byKey(DigitalIdView.qrKey), findsOneWidget);
    expect(find.text('Refreshing code…'), findsNothing);

    await tester.pump(const Duration(hours: 2, minutes: 59));
    expect(repository.cardLoads, 1);
    expect(find.byKey(DigitalIdView.qrKey), findsOneWidget);

    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(repository.cardLoads, 2);
    expect(find.byKey(DigitalIdView.qrKey), findsOneWidget);
    expect(find.text('Refreshing code…'), findsNothing);

    await tester.pump(const Duration(hours: 1, minutes: 59));
    expect(repository.cardLoads, 2);
    expect(find.byKey(DigitalIdView.qrKey), findsOneWidget);
  });

  testWidgets(
    'a refetch that returns another dead code stays on Refreshing code',
    (tester) async {
      final DateTime start = tester.binding.clock.now().toUtc();
      final _Recording repository = _Recording.cards(<ResidentCredential?>[
        _card(
          CredentialLifecycleState.active,
          qr: PresentationArtifact(
            payload: 'sample-qr-not-a-credential',
            expiresAt: start.subtract(const Duration(minutes: 5)),
          ),
        ),
        _card(
          CredentialLifecycleState.active,
          qr: PresentationArtifact(
            payload: 'sample-qr-still-dead',
            expiresAt: start.subtract(const Duration(seconds: 1)),
          ),
        ),
      ]);
      await _pump(
        tester,
        DigitalIdScreen(
          key: const Key('dead-qr'),
          repository: repository,
          now: () => tester.binding.clock.now(),
          sample: false,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(repository.cardLoads, 2);
      expect(find.text('Refreshing code…'), findsOneWidget);
      expect(find.byKey(DigitalIdView.qrKey), findsNothing);
      final String dump = tester.allWidgets
          .map((Widget widget) => widget.toString())
          .join('\n');
      expect(dump, isNot(contains('sample-qr-not-a-credential')));
      expect(dump, isNot(contains('sample-qr-still-dead')));
      await tester.pump(const Duration(minutes: 2));
      expect(repository.cardLoads, 2);
      expect(find.text('Refreshing code…'), findsOneWidget);
      expect(find.byKey(DigitalIdView.qrKey), findsNothing);
    },
  );

  testWidgets('a 404 from /me/digital-id shows the not-issued card', (
    tester,
  ) async {
    final CredentialApiRepository repository = CredentialApiRepository(
      apiClient: ApiClient(
        config: AppConfig.from(
          rawEnvironment: 'dev',
          rawApiBaseUrl: 'https://example.test/api/v1',
          isReleaseBuild: false,
        ),
        transport: _NotFoundDigitalId(),
        accessTokenProvider: () async => 'firebase-id-token',
      ),
    );
    await _pump(
      tester,
      DigitalIdScreen(repository: repository, sample: false, now: () => _now),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Not yet issued'), findsOneWidget);
    expect(
      find.text('Your digital ID will appear here once Taytay LGU issues it.'),
      findsOneWidget,
    );
    expect(find.text('operator text that must not be shown'), findsNothing);
    expect(find.byKey(DigitalIdView.qrKey), findsNothing);
    expect(find.text('Juan Dela Cruz'), findsNothing);
  });
}

final DateTime _now = DateTime.utc(2026, 10, 22, 12);
final DateTime _past = DateTime.utc(2020, 1, 1);
final DateTime _localNow = DateTime(2026, 10, 22, 12);

const PresentationArtifact _qr = PresentationArtifact(
  payload: 'sample-qr-not-a-credential',
  expiresAt: null,
);

ResidentCredential _card(
  CredentialLifecycleState state, {
  String? raw,
  DateTime? expires,
  PresentationArtifact? qr,
}) {
  return ResidentCredential(
    id: 'card-1',
    state: state,
    rawState: raw ?? state.name,
    idNumber: 'TYT-0000-0000',
    issuedAt: DateTime.utc(2026, 10, 22),
    expiresAt: expires ?? DateTime.utc(2029, 10, 22),
    qr: qr,
  );
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: child,
    ),
  );
}

Future<void> _loadFonts() async {
  final FontLoader jakarta = FontLoader('Plus Jakarta Sans')
    ..addFont(
      rootBundle.load(
        'assets/fonts/plus_jakarta_sans/PlusJakartaSans-ExtraBold.ttf',
      ),
    );
  await jakarta.load();
}

class _Recording implements CredentialRepository {
  _Recording({required ResidentCredential card})
    : this.cards(<ResidentCredential?>[card]);

  _Recording.cards(this._cards);

  final List<ResidentCredential?> _cards;
  int cardLoads = 0;

  @override
  Future<Result<ResidentCredential?>> loadOwnCredential() async {
    final int index = cardLoads;
    cardLoads += 1;
    final ResidentCredential? card = index < _cards.length
        ? _cards[index]
        : _cards.last;
    return Ok<ResidentCredential?>(card);
  }

  @override
  Future<Result<String?>> loadResidentName() async {
    return const Ok<String?>('Juan Dela Cruz');
  }

  @override
  Future<Result<PresentationArtifact>> requestPresentationArtifact() async {
    return const Err<PresentationArtifact>(
      NotFoundFailure(debugMessage: 'unused'),
    );
  }
}

class _NotFoundDigitalId implements ApiTransport {
  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    if (request.path == CredentialApiRepository.path) {
      return Ok<ApiHttpResponse>(
        ApiHttpResponse(
          statusCode: 404,
          body: jsonEncode(<String, Object?>{
            'error': <String, Object?>{
              'code': 'NOT_FOUND',
              'message': 'operator text that must not be shown',
            },
          }),
        ),
      );
    }
    return Ok<ApiHttpResponse>(
      ApiHttpResponse(
        statusCode: 200,
        body: jsonEncode(<String, Object?>{
          'data': <String, Object?>{'name': 'Juan Dela Cruz'},
          'meta': <String, Object?>{'request_id': 'req-name'},
        }),
      ),
    );
  }
}
