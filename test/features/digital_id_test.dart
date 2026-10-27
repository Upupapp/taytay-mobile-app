import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
      expect(CredentialApiRepository.decodeResidentName(<String, Object?>{}), isNull);
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

  testWidgets('a long name stays 17/800 and ellipsizes on line 2', (
    tester,
  ) async {
    await _loadFonts();
    await _pump(
      tester,
      DigitalIdView(
        card: _card(CredentialLifecycleState.active, qr: _qr),
        name: 'Maria Concepcion Josefina Dela Paz-Villanueva Santiago Fernandez',
        now: _localNow,
      ),
    );
    final Text text = tester.widget<Text>(find.byKey(DigitalIdView.nameKey));
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.softWrap, isTrue);
    expect(text.style?.fontSize, 17);
    expect(text.style?.fontWeight, FontWeight.w800);
    expect(text.style?.height, 1.25);
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(DigitalIdView.nameKey),
    );
    // At 17 px this sample fits on two lines. The ellipsis is the overflow
    // rule, proven with one more word below.
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(paragraph.size.height, greaterThan(30));
    expect(paragraph.size.height, lessThanOrEqualTo(45));
    expect(paragraph.size.width, lessThanOrEqualTo(300));

    await _pump(
      tester,
      DigitalIdView(
        card: _card(CredentialLifecycleState.active, qr: _qr),
        name:
            'Maria Concepcion Josefina Dela Paz-Villanueva Santiago Fernandez Reyes',
        now: _localNow,
      ),
    );
    final RenderParagraph longer = tester.renderObject<RenderParagraph>(
      find.byKey(DigitalIdView.nameKey),
    );
    expect(longer.didExceedMaxLines, isTrue);
    expect(longer.size.width, lessThanOrEqualTo(300));
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

  testWidgets('a dead code is refetched once, and a live one arms no timer', (
    tester,
  ) async {
    final _Recording repository = _Recording(
      card: _card(
        CredentialLifecycleState.active,
        qr: PresentationArtifact(
          payload: 'sample-qr-not-a-credential',
          expiresAt: DateTime.utc(2099, 1, 1),
        ),
      ),
    );
    await _pump(
      tester,
      DigitalIdScreen(
        key: const Key('live-qr'),
        repository: repository,
        sample: false,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(repository.cardLoads, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(repository.cardLoads, 1);

    final _Recording expired = _Recording(
      card: _card(
        CredentialLifecycleState.active,
        qr: PresentationArtifact(
          payload: 'sample-qr-not-a-credential',
          expiresAt: DateTime.utc(2020, 1, 1),
        ),
      ),
    );
    await _pump(
      tester,
      DigitalIdScreen(
        key: const Key('dead-qr'),
        repository: expired,
        sample: false,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(expired.cardLoads, 2);
    await tester.pump(const Duration(seconds: 1));
    expect(expired.cardLoads, 2);
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
  _Recording({required this.card});

  final ResidentCredential card;
  int cardLoads = 0;

  @override
  Future<Result<ResidentCredential?>> loadOwnCredential() async {
    cardLoads += 1;
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
