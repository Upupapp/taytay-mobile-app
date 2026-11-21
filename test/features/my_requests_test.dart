import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/config/app_environment.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/router/route_guard.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/resident_capability.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/assistance/data/own_assistance_api_repository.dart';
import 'package:taytay_resident/features/assistance/data/own_assistance_codec.dart';
import 'package:taytay_resident/features/assistance/domain/own_assistance_request.dart';
import 'package:taytay_resident/features/assistance/presentation/my_request_detail_screen.dart';
import 'package:taytay_resident/features/assistance/presentation/my_requests_canvas.dart';
import 'package:taytay_resident/features/assistance/presentation/my_requests_screen.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/error_state.dart';
import 'package:taytay_resident/shared/widgets/loading_skeleton.dart';

import '../support/layout_matrix.dart';

/// D-223: My requests, the resident's own assistance requests.
///
/// Synthetic throughout: the ids, control numbers, programmes and venues are
/// made up, and nobody here is a real resident.
const String _inPerson =
    'Some requests are discussed only in person at the MSWDO.';
const String _empty = 'No request filed with the office is shown here.';

Map<String, Object?> _row(
  String id, {
  String status = 'submitted',
  String? program = 'Sample medical assistance',
  int? amount,
  String? payoutOn,
  String? venue,
  String? releasedAt,
  String? channel,
  String? sourceReference,
}) => <String, Object?>{
  'id': id,
  'reference_number': 'AR-SAMPLE-$id',
  'program_name': program,
  'filed_at': '2026-11-03T01:15:00Z',
  'status': status,
  'status_changed_at': '2026-11-12T02:00:00Z',
  'approved_amount_centavos': amount,
  'payout_scheduled_for': payoutOn,
  'payout_venue': venue,
  'released_at': releasedAt,
  'channel': channel,
  'source_reference': sourceReference,
};

/// A request imported from the office's old paper records (D-227).
Map<String, Object?> _imported(String id) => _row(
  id,
  status: 'completed',
  amount: 150000,
  releasedAt: '2024-03-12T03:00:00Z',
  channel: 'imported',
  sourceReference: 'MSWDO-2024-0046',
);

ApiHttpResponse _page(
  List<Object?> rows, {
  bool hasMore = false,
  String? next,
}) => ApiHttpResponse(
  statusCode: 200,
  body: jsonEncode(<String, Object?>{
    'data': rows,
    'meta': <String, Object?>{
      'pagination': <String, Object?>{'has_more': hasMore, 'next_cursor': next},
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

/// Answers each request through [answer], and keeps what was asked.
class _Transport implements ApiTransport {
  _Transport(this.answer);

  Result<ApiHttpResponse> Function(ApiRequest request) answer;
  final List<ApiRequest> requests = <ApiRequest>[];

  List<ApiRequest> get reads => <ApiRequest>[
    for (final ApiRequest request in requests)
      if (request.path == 'me/assistance-requests') request,
  ];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return answer(request);
  }
}

AppConfig _dev() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
  rawMockLatencyMs: '0',
);

OwnAssistanceApiRepository _repository(_Transport transport) =>
    OwnAssistanceApiRepository(
      apiClient: ApiClient(
        config: _dev(),
        transport: transport,
        accessTokenProvider: () async => 'tok',
      ),
    );

/// A signed-in app over [transport]; the screen reads through the live
/// repository.
Future<AppDependencies> _signedIn(_Transport transport) async {
  final InMemorySessionStore store = InMemorySessionStore();
  await store.write(
    const StoredSession(
      resident: ResidentSession(
        accountId: 'acct-sample',
        accessLevel: AccessLevel.unverified,
        displayName: 'Ana',
      ),
      accessToken: 'token-sample',
    ),
  );
  final AppDependencies dependencies = AppDependencies.build(
    config: _dev(),
    transport: transport,
    secrets: InMemorySecretStore(),
    sessionStore: store,
    localAuthenticator: const UnavailableLocalAuthenticator(),
  );
  await dependencies.session.restore();
  addTearDown(dependencies.dispose);
  return dependencies;
}

Widget _host(AppDependencies dependencies, Widget screen) =>
    AppDependenciesScope(
      dependencies: dependencies,
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppLocales.supported,
        home: screen,
      ),
    );

Future<_Transport> _open(
  WidgetTester tester,
  Widget screen,
  Result<ApiHttpResponse> Function(ApiRequest request) answer,
) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(400, 2400);
  addTearDown(tester.view.reset);
  final _Transport transport = _Transport(answer);
  final AppDependencies dependencies = await _signedIn(transport);
  await tester.pumpWidget(_host(dependencies, screen));
  await tester.pumpAndSettle();
  return transport;
}

bool _shows(String text) => find.text(text).evaluate().isNotEmpty;

/// [child] with the app's strings, for `layoutHost`, which has none.
Widget _l10n(Widget child) => Builder(
  builder: (BuildContext context) => Localizations.override(
    context: context,
    locale: const Locale('en'),
    delegates: AppStrings.localizationsDelegates,
    child: child,
  ),
);

void main() {
  group('the codec reads the minimum, and nothing it does not know', () {
    test('every field of a scheduled request', () {
      final OwnAssistanceRequest? row = OwnAssistanceCodec.row(
        _row(
          'ar-1',
          status: 'scheduled',
          amount: 500000,
          payoutOn: '2026-11-20',
          venue: 'Sample venue, Taytay',
        ),
      );
      expect(row, isNotNull);
      final OwnAssistanceRequest request = row!;
      expect(request.id, 'ar-1');
      expect(request.referenceNumber, 'AR-SAMPLE-ar-1');
      expect(request.programName, 'Sample medical assistance');
      expect(request.filedAt, DateTime.utc(2026, 11, 3, 1, 15));
      expect(request.status.known, AssistanceRequestStatus.scheduled);
      expect(request.stage, AssistanceStage.payoutScheduled);
      expect(request.statusChangedAt, DateTime.utc(2026, 11, 12, 2));
      expect(request.approvedAmountCentavos, 500000);
      // A date-only payout is that calendar day, never shifted by a zone.
      expect(request.payoutScheduledFor, DateTime.utc(2026, 11, 20));
      expect(request.payoutVenue, 'Sample venue, Taytay');
      expect(request.releasedAt, isNull);
    });

    test('null fields read as absent, never as zero or a guess', () {
      final OwnAssistanceRequest request = OwnAssistanceCodec.row(
        _row('ar-2', program: null),
      )!;
      expect(request.programName, isNull);
      expect(request.approvedAmountCentavos, isNull);
      expect(request.payoutScheduledFor, isNull);
      expect(request.payoutVenue, isNull);
      expect(request.releasedAt, isNull);
    });

    test(
      'an imported request keeps the number on her papers beside its own',
      () {
        final OwnAssistanceRequest request = OwnAssistanceCodec.row(
          _imported('ar-9'),
        )!;
        expect(request.channel, AssistanceChannel.imported);
        expect(request.sourceReference, 'MSWDO-2024-0046');
        expect(request.referenceNumber, 'AR-SAMPLE-ar-9');
        final OwnAssistanceRequest filed = OwnAssistanceCodec.row(
          _row('ar-8', channel: 'office'),
        )!;
        expect(filed.channel, AssistanceChannel.office);
        expect(filed.sourceReference, isNull);
        expect(
          OwnAssistanceCodec.row(
            _row('ar-7', channel: 'online', sourceReference: '  '),
          )!.sourceReference,
          isNull,
          reason: 'blank is absent',
        );
      },
    );

    test('an amount that is not integer centavos is not an amount', () {
      Map<String, Object?> withAmount(Object? amount) => <String, Object?>{
        ..._row('ar-3'),
        'approved_amount_centavos': amount,
      };
      expect(
        OwnAssistanceCodec.row(withAmount(1250.5))!.approvedAmountCentavos,
        isNull,
      );
      expect(
        OwnAssistanceCodec.row(withAmount(-100))!.approvedAmountCentavos,
        isNull,
      );
      expect(
        OwnAssistanceCodec.row(withAmount('500000'))!.approvedAmountCentavos,
        isNull,
      );
    });

    test('an unknown status is kept raw and said as updated', () {
      final OwnAssistanceRequest request = OwnAssistanceCodec.row(
        _row('ar-4', status: 'on-hold'),
      )!;
      expect(request.status.known, isNull);
      expect(request.status.raw, 'on-hold');
      expect(request.stage, AssistanceStage.updated);
      // `draft` is never sent to a resident; if it were, it is not guessed.
      expect(
        OwnAssistanceCodec.row(_row('ar-5', status: 'draft'))!.stage,
        AssistanceStage.updated,
      );
    });

    test('a row with no id is dropped; unknown fields are ignored', () {
      final List<OwnAssistanceRequest> rows = OwnAssistanceCodec.list(<Object?>[
        <String, Object?>{..._row('ar-6'), 'id': null},
        <String, Object?>{..._row('ar-7'), 'assessment': 'not for her'},
        'not a row',
      ]);
      expect(rows.map((OwnAssistanceRequest r) => r.id), <String>['ar-7']);
      expect(OwnAssistanceCodec.list(null), isEmpty);
    });

    test('toString names no control number or venue', () {
      final OwnAssistanceRequest request = OwnAssistanceCodec.row(
        _row('ar-8', status: 'scheduled', venue: 'Sample venue'),
      )!;
      expect(request.toString(), isNot(contains('AR-SAMPLE')));
      expect(request.toString(), isNot(contains('Sample venue')));
    });
  });

  group('every raw status has one resident wording', () {
    const Map<String, (AssistanceStage, String)> words =
        <String, (AssistanceStage, String)>{
          'submitted': (AssistanceStage.received, 'Received'),
          'intake-review': (AssistanceStage.received, 'Received'),
          'assessment': (AssistanceStage.beingAssessed, 'Being assessed'),
          'endorsed': (AssistanceStage.beingAssessed, 'Being assessed'),
          'approved': (AssistanceStage.approved, 'Approved'),
          'scheduled': (AssistanceStage.payoutScheduled, 'Payout scheduled'),
          'released': (AssistanceStage.released, 'Released'),
          'completed': (AssistanceStage.released, 'Released'),
          'returned': (
            AssistanceStage.needsMore,
            'The office needs more from you — please visit or contact the '
                'MSWDO',
          ),
          'rejected': (
            AssistanceStage.notApproved,
            'Not approved — the MSWDO can tell you why',
          ),
          'cancelled': (AssistanceStage.cancelled, 'Cancelled'),
          'expired': (AssistanceStage.expired, 'Expired'),
          'something-new': (AssistanceStage.updated, 'Status: updated'),
        };

    test('the stage each raw status is said as', () {
      for (final MapEntry<String, (AssistanceStage, String)> entry
          in words.entries) {
        expect(
          OwnAssistanceCodec.row(_row('ar-x', status: entry.key))!.stage,
          entry.value.$1,
          reason: entry.key,
        );
      }
      // Every status the API names is known to this build.
      for (final AssistanceRequestStatus status
          in AssistanceRequestStatus.values) {
        expect(words.keys, contains(status.wireValue));
      }
    });

    testWidgets('and the words a resident reads', (tester) async {
      for (final MapEntry<String, (AssistanceStage, String)> entry
          in words.entries) {
        await tester.pumpWidget(
          layoutHost(_l10n(StageLine(stage: entry.value.$1))),
        );
        expect(find.text(entry.value.$2), findsOneWidget, reason: entry.key);
      }
    });
  });

  // After she re-sent the document, the request still said "The office needs
  // more from you": the API keeps it `returned` until the office moves it,
  // and lists only what is still missing (A10).
  group('a returned request whose documents she sent waits for the office', () {
    Map<String, Object?> returned(
      String changedAt, {
      List<Object?> missing = const <Object?>[],
    }) => <String, Object?>{
      ..._row('ar-r', status: 'returned'),
      'status_changed_at': changedAt,
      'missing_documents': missing,
    };
    const Map<String, Object?> blurred = <String, Object?>{
      'code': 'medical-abstract',
      'name': 'Medical abstract',
      'state': 'send-again',
      'instruction': 'Send a new copy of the Medical abstract.',
    };
    final CapturedDocument file = CapturedDocument(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      fileName: 'abstract.jpg',
      mimeType: 'image/jpeg',
      source: DocumentSource.camera,
    );

    test('sent, it reads as waiting until the office moves it', () async {
      String changedAt = '2026-11-12T02:00:00Z';
      List<Object?> missing = <Object?>[blurred];
      final _Transport transport = _Transport((ApiRequest request) {
        if (request.method == HttpMethod.post) {
          missing = const <Object?>[];
          return Ok<ApiHttpResponse>(
            ApiHttpResponse(
              statusCode: 201,
              body: jsonEncode(<String, Object?>{'data': returned(changedAt)}),
            ),
          );
        }
        return Ok<ApiHttpResponse>(
          _page(<Object?>[returned(changedAt, missing: missing)]),
        );
      });
      final OwnAssistanceApiRepository repository = _repository(transport);

      final OwnAssistanceRequest before = (await repository.findOwn(
        'ar-r',
      )).valueOrNull!;
      expect(before.stage, AssistanceStage.needsMore);
      expect(before.takesDocuments, isTrue);

      final OwnAssistanceRequest sent = (await repository.addDocuments(
        'ar-r',
        files: <String, CapturedDocument>{'medical-abstract': file},
        idempotencyKey: 'key-1',
      )).valueOrNull!;
      expect(sent.stage, AssistanceStage.documentsSent);

      // A later read of the same, unmoved request still says so.
      final OwnAssistanceRequest read = (await repository.findOwn(
        'ar-r',
      )).valueOrNull!;
      expect(read.stage, AssistanceStage.documentsSent);
      expect(read.status.known, AssistanceRequestStatus.returned);

      // The office returns it again: it is hers to answer once more.
      changedAt = '2026-11-20T02:00:00Z';
      final OwnAssistanceRequest again = (await repository.findOwn(
        'ar-r',
      )).valueOrNull!;
      expect(again.stage, AssistanceStage.needsMore);
    });

    test('returned with nothing named, and nothing sent, still needs her', () {
      final OwnAssistanceRequest? row = OwnAssistanceCodec.row(
        returned('2026-11-12T02:00:00Z'),
      );
      expect(row?.stage, AssistanceStage.needsMore);
      expect(row?.withDocumentsSent().stage, AssistanceStage.documentsSent);
    });

    testWidgets('the request says it was sent and waits for the office', (
      tester,
    ) async {
      final OwnAssistanceRequest? row = OwnAssistanceCodec.row(
        returned('2026-11-12T02:00:00Z'),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppStrings.localizationsDelegates,
          supportedLocales: AppLocales.supported,
          home: MyRequestDetailCanvas(
            environment: AppEnvironment.dev,
            request: row?.withDocumentsSent(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('waiting for the office to review'),
        findsWidgets,
      );
      expect(find.textContaining('needs more from you'), findsNothing);
    });
  });

  group('the repository reads her own list a cursor page at a time', () {
    test('GET me/assistance-requests, signed in, within the limit', () async {
      final _Transport transport = _Transport(
        (ApiRequest request) => Ok<ApiHttpResponse>(
          _page(<Object?>[_row('ar-1')], hasMore: true, next: 'c-2'),
        ),
      );
      final Result<Paginated<OwnAssistanceRequest>> first = await _repository(
        transport,
      ).listOwn();
      final ApiRequest request = transport.reads.single;
      expect(request.method, HttpMethod.get);
      expect(request.headers['Authorization'], 'Bearer tok');
      expect(int.parse(request.query['limit'] ?? ''), lessThanOrEqualTo(50));
      expect(request.query.containsKey('cursor'), isFalse);
      expect(request.query.containsKey('page'), isFalse);
      final Paginated<OwnAssistanceRequest> page = first.valueOrNull!;
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'c-2');

      await _repository(transport).listOwn(cursor: 'c-2');
      expect(transport.reads.last.query['cursor'], 'c-2');
    });

    test('findOwn follows the cursors until it finds the id', () async {
      final _Transport transport = _Transport(
        (ApiRequest request) => Ok<ApiHttpResponse>(
          request.query['cursor'] == null
              ? _page(<Object?>[_row('ar-1')], hasMore: true, next: 'c-2')
              : _page(<Object?>[_row('ar-2', status: 'approved')]),
        ),
      );
      final Result<OwnAssistanceRequest> found = await _repository(
        transport,
      ).findOwn('ar-2');
      expect(found.valueOrNull?.id, 'ar-2');
      expect(transport.reads, hasLength(2));
      expect(transport.reads.first.query['limit'], '50');
    });

    test('a request the list does not carry is not found', () async {
      final _Transport transport = _Transport(
        (ApiRequest request) =>
            Ok<ApiHttpResponse>(_page(<Object?>[_row('ar-1')])),
      );
      final Result<OwnAssistanceRequest> missing = await _repository(
        transport,
      ).findOwn('ar-9');
      expect(missing.failureOrNull, isA<NotFoundFailure>());
    });

    test('findOwn stops at its ceiling rather than reading for ever', () async {
      var n = 0;
      final _Transport transport = _Transport(
        (ApiRequest request) => Ok<ApiHttpResponse>(
          _page(<Object?>[_row('ar-p${n++}')], hasMore: true, next: 'c-$n'),
        ),
      );
      final Result<OwnAssistanceRequest> missing = await _repository(
        transport,
      ).findOwn('ar-never');
      expect(missing.failureOrNull, isA<NotFoundFailure>());
      expect(
        transport.reads,
        hasLength(OwnAssistanceApiRepository.findPageCeiling),
      );
    });

    test('a failed read is the failure, not an empty list', () async {
      final _Transport transport = _Transport(
        (ApiRequest request) => Ok<ApiHttpResponse>(_serverError),
      );
      expect(
        (await _repository(transport).listOwn()).failureOrNull,
        isA<ServerFailure>(),
      );
      expect(
        (await _repository(transport).findOwn('ar-1')).failureOrNull,
        isA<ServerFailure>(),
      );
    });
  });

  group('My requests, on screen', () {
    testWidgets('loading shows the skeleton and the in-person sentence', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(
          _l10n(
            const MyRequestsCanvas(
              environment: AppEnvironment.dev,
              loading: true,
            ),
          ),
          scrollable: false,
        ),
      );
      expect(find.byType(LoadingSkeleton), findsOneWidget);
      expect(find.text(_inPerson), findsOneWidget);
      expect(find.text(_empty), findsNothing);
    });

    testWidgets('an empty list says so plainly, with the sentence', (
      tester,
    ) async {
      await _open(
        tester,
        const MyRequestsScreen(),
        (ApiRequest request) => Ok<ApiHttpResponse>(_page(const <Object?>[])),
      );
      expect(find.text('No requests to show'), findsOneWidget);
      expect(find.text(_empty), findsOneWidget);
      expect(find.text(_inPerson), findsOneWidget);
      expect(find.byType(ErrorState), findsNothing);
    });

    testWidgets('a list shows each request, its status in words', (
      tester,
    ) async {
      await _open(
        tester,
        const MyRequestsScreen(),
        (ApiRequest request) => Ok<ApiHttpResponse>(
          _page(<Object?>[
            _row('ar-1', status: 'returned', program: 'Sample burial aid'),
            _row('ar-2', status: 'endorsed'),
            _row('ar-3', status: 'on-hold'),
          ]),
        ),
      );
      expect(find.text('Sample burial aid'), findsOneWidget);
      expect(find.text('AR-SAMPLE-ar-1'), findsOneWidget);
      expect(find.text('Filed 03 Nov 2026'), findsNWidgets(3));
      expect(
        find.text(
          'The office needs more from you — please visit or contact the MSWDO',
        ),
        findsOneWidget,
      );
      expect(find.text('Being assessed'), findsOneWidget);
      expect(find.text('Status: updated'), findsOneWidget);
      expect(find.text(_inPerson), findsOneWidget);
      // No amount, venue or reason on a row.
      expect(find.textContaining('₱'), findsNothing);
      expect(find.text('Show older requests'), findsNothing);
    });

    testWidgets('an imported request shows the control number on her papers '
        'first, and this system’s reference beneath it', (tester) async {
      await _open(
        tester,
        const MyRequestsScreen(),
        (ApiRequest request) => Ok<ApiHttpResponse>(
          _page(<Object?>[_imported('ar-1'), _row('ar-2', channel: 'office')]),
        ),
      );
      expect(find.text('Control no. MSWDO-2024-0046'), findsOneWidget);
      expect(find.text('AR-SAMPLE-ar-1'), findsOneWidget);
      expect(find.text("From the office's records"), findsOneWidget);
      expect(find.text('Filed at the office'), findsOneWidget);
      expect(find.byKey(const Key('my-request-control-line')), findsOneWidget);
      final double control = tester
          .getTopLeft(find.text('Control no. MSWDO-2024-0046'))
          .dy;
      final double system = tester.getTopLeft(find.text('AR-SAMPLE-ar-1')).dy;
      expect(control, lessThan(system), reason: 'her number comes first');
    });

    testWidgets('a failure is said with Try again, and Try again reads', (
      tester,
    ) async {
      final _Transport transport = await _open(
        tester,
        const MyRequestsScreen(),
        (ApiRequest request) => Ok<ApiHttpResponse>(_serverError),
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(
        tester.widget<ErrorState>(find.byType(ErrorState)).offline,
        isFalse,
      );
      expect(find.text('operator text'), findsNothing);
      expect(find.text(_inPerson), findsOneWidget);
      expect(find.text(_empty), findsNothing);

      transport.answer = (ApiRequest request) =>
          Ok<ApiHttpResponse>(_page(<Object?>[_row('ar-1')]));
      final int before = transport.reads.length;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(transport.reads.length, before + 1);
      expect(find.text('AR-SAMPLE-ar-1'), findsOneWidget);
    });

    testWidgets('no connection is said as offline', (tester) async {
      await _open(
        tester,
        const MyRequestsScreen(),
        (ApiRequest request) => const Err<ApiHttpResponse>(
          NetworkFailure(debugMessage: 'synthetic'),
        ),
      );
      expect(
        tester.widget<ErrorState>(find.byType(ErrorState)).offline,
        isTrue,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text(_inPerson), findsOneWidget);
    });

    testWidgets('more pages are offered while the API says more exist', (
      tester,
    ) async {
      final _Transport transport = await _open(
        tester,
        const MyRequestsScreen(),
        (ApiRequest request) => Ok<ApiHttpResponse>(
          request.query['cursor'] == null
              ? _page(<Object?>[_row('ar-1')], hasMore: true, next: 'c-2')
              : _page(<Object?>[_row('ar-2')]),
        ),
      );
      expect(find.text('Show older requests'), findsOneWidget);
      expect(find.textContaining(RegExp(r'[Pp]age \d')), findsNothing);

      await tester.tap(find.text('Show older requests'));
      await tester.pumpAndSettle();

      expect(transport.reads.last.query['cursor'], 'c-2');
      expect(find.text('AR-SAMPLE-ar-1'), findsOneWidget);
      expect(find.text('AR-SAMPLE-ar-2'), findsOneWidget);
      // The last page said there is no more.
      expect(find.text('Show older requests'), findsNothing);
    });

    testWidgets('a failed next page keeps the list and offers it again', (
      tester,
    ) async {
      final _Transport transport = await _open(
        tester,
        const MyRequestsScreen(),
        (ApiRequest request) => Ok<ApiHttpResponse>(
          _page(<Object?>[_row('ar-1')], hasMore: true, next: 'c-2'),
        ),
      );
      transport.answer = (ApiRequest request) =>
          Ok<ApiHttpResponse>(_serverError);
      await tester.tap(find.text('Show older requests'));
      await tester.pumpAndSettle();
      expect(find.text('AR-SAMPLE-ar-1'), findsOneWidget);
      expect(find.text('Could not load more. Try again'), findsOneWidget);
    });
  });

  group('one request', () {
    testWidgets('a scheduled payout: amount, date and venue', (tester) async {
      await _open(
        tester,
        const MyRequestDetailScreen(requestId: 'ar-1'),
        (ApiRequest request) => Ok<ApiHttpResponse>(
          _page(<Object?>[
            _row(
              'ar-1',
              status: 'scheduled',
              amount: 500000,
              payoutOn: '2026-11-20',
              venue: 'Sample venue, Taytay',
            ),
          ]),
        ),
      );
      expect(find.text('Payout scheduled'), findsOneWidget);
      expect(find.text('₱5,000.00'), findsOneWidget);
      expect(find.text('20 Nov 2026'), findsOneWidget);
      expect(find.text('Sample venue, Taytay'), findsOneWidget);
      expect(find.text('AR-SAMPLE-ar-1'), findsOneWidget);
      expect(find.text('03 Nov 2026'), findsOneWidget);
      expect(find.text('Status last changed'), findsOneWidget);
      expect(find.text('12 Nov 2026'), findsOneWidget);
      expect(find.text('Released on'), findsNothing);
      expect(find.text(_inPerson), findsOneWidget);
    });

    testWidgets('a released request: amount and released date', (tester) async {
      await _open(
        tester,
        const MyRequestDetailScreen(requestId: 'ar-1'),
        (ApiRequest request) => Ok<ApiHttpResponse>(
          _page(<Object?>[
            _row(
              'ar-1',
              status: 'completed',
              amount: 125050,
              releasedAt: '2026-11-21T03:00:00Z',
            ),
          ]),
        ),
      );
      expect(find.text('Released'), findsOneWidget);
      expect(find.text('₱1,250.50'), findsOneWidget);
      expect(find.text('Released on'), findsOneWidget);
      expect(find.text('21 Nov 2026'), findsOneWidget);
      expect(find.text('Payout date'), findsNothing);
      expect(find.text('Where to collect'), findsNothing);
    });

    testWidgets('an imported request: the control number on her papers in '
        'the head, this system’s reference as a fact', (tester) async {
      await _open(
        tester,
        const MyRequestDetailScreen(requestId: 'ar-1'),
        (ApiRequest request) =>
            Ok<ApiHttpResponse>(_page(<Object?>[_imported('ar-1')])),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('my-request-head')),
          matching: find.text('Control no. MSWDO-2024-0046'),
        ),
        findsOneWidget,
      );
      expect(find.text('System reference'), findsOneWidget);
      expect(find.text('Reference number'), findsNothing);
      expect(find.text('AR-SAMPLE-ar-1'), findsOneWidget);
      expect(find.text("From the office's records"), findsOneWidget);
    });

    testWidgets('a request filed in this system has no control number line', (
      tester,
    ) async {
      await _open(
        tester,
        const MyRequestDetailScreen(requestId: 'ar-1'),
        (ApiRequest request) => Ok<ApiHttpResponse>(
          _page(<Object?>[_row('ar-1', channel: 'online')]),
        ),
      );
      expect(find.byKey(const Key('my-request-control-number')), findsNothing);
      expect(find.textContaining('Control no.'), findsNothing);
      expect(find.text('Reference number'), findsOneWidget);
      expect(find.text('Applied in the app'), findsOneWidget);
    });

    testWidgets('before approval, no amount and no payout', (tester) async {
      await _open(
        tester,
        const MyRequestDetailScreen(requestId: 'ar-1'),
        (ApiRequest request) => Ok<ApiHttpResponse>(
          _page(<Object?>[_row('ar-1', status: 'assessment')]),
        ),
      );
      expect(find.text('Being assessed'), findsOneWidget);
      expect(find.text('Approved amount'), findsNothing);
      expect(find.text('Payout date'), findsNothing);
      expect(find.textContaining('₱'), findsNothing);
    });

    testWidgets('a request not in her list is not shown, and says nothing '
        'about why', (tester) async {
      await _open(
        tester,
        const MyRequestDetailScreen(requestId: 'ar-9'),
        (ApiRequest request) => Ok<ApiHttpResponse>(_page(const <Object?>[])),
      );
      expect(find.text('This request is not shown here'), findsOneWidget);
      expect(find.text(_inPerson), findsOneWidget);
      expect(find.text('See all my requests'), findsOneWidget);
      expect(find.byType(ErrorState), findsNothing);
    });

    testWidgets('a failed read is said with Try again', (tester) async {
      await _open(
        tester,
        const MyRequestDetailScreen(requestId: 'ar-1'),
        (ApiRequest request) => Ok<ApiHttpResponse>(_serverError),
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('This request is not shown here'), findsNothing);
      expect(find.text(_inPerson), findsOneWidget);
    });
  });

  group('who may open it', () {
    const SessionState guest = GuestSession();
    const SessionState unverified = AuthenticatedSession(
      ResidentSession(
        accountId: 'acct-sample',
        accessLevel: AccessLevel.unverified,
      ),
    );
    const SessionState verified = AuthenticatedSession(
      ResidentSession(
        accountId: 'acct-sample',
        accessLevel: AccessLevel.verified,
      ),
    );

    test('any signed-in resident; a guest is sent to sign in', () {
      for (final String location in <String>[
        '/my-requests',
        '/my-requests/a-1',
      ]) {
        expect(
          resolveRedirect(session: guest, location: location),
          startsWith(AppRoute.signIn.path),
          reason: location,
        );
        expect(
          resolveRedirect(session: unverified, location: location),
          isNull,
          reason: location,
        );
        expect(
          resolveRedirect(session: verified, location: location),
          isNull,
          reason: location,
        );
      }
      expect(AppRoute.forPath('/my-requests/a-1'), AppRoute.myRequestDetail);
    });

    test('Track your assistance requests opens My requests when signed in', () {
      expect(
        ResidentCapability.trackAssistanceRequests.route,
        AppRoute.myRequests,
      );
      expect(
        CapabilityService.evaluate(
          session: guest,
          capability: ResidentCapability.trackAssistanceRequests,
        ),
        const CapabilityNeedsSignIn(),
      );
      for (final SessionState session in <SessionState>[unverified, verified]) {
        expect(
          CapabilityService.evaluate(
            session: session,
            capability: ResidentCapability.trackAssistanceRequests,
          ).isUsable,
          isTrue,
        );
      }
    });
  });

  group('every frame fits every phone', () {
    final List<OwnAssistanceRequest> rows = OwnAssistanceCodec.list(<Object?>[
      _row('ar-1', status: 'returned'),
      _row('ar-2', status: 'rejected', program: null),
      _row('ar-3', status: 'scheduled'),
    ]);
    final OwnAssistanceRequest scheduled = OwnAssistanceCodec.row(
      _row(
        'ar-4',
        status: 'scheduled',
        amount: 1234567,
        payoutOn: '2026-11-20',
        venue: 'Sample covered court, a long venue name in Barangay Sample',
      ),
    )!;

    final Map<String, Widget Function()> frames = <String, Widget Function()>{
      'loading': () => const MyRequestsCanvas(
        environment: AppEnvironment.dev,
        loading: true,
      ),
      'failed': () => const MyRequestsCanvas(
        environment: AppEnvironment.dev,
        failure: NetworkFailure(debugMessage: 'synthetic'),
      ),
      'empty': () => const MyRequestsCanvas(
        environment: AppEnvironment.dev,
        items: <OwnAssistanceRequest>[],
      ),
      'list with more': () => MyRequestsCanvas(
        environment: AppEnvironment.dev,
        items: rows,
        hasMore: true,
        moreFailed: true,
        onOpen: (_) {},
      ),
      'one request': () => MyRequestDetailCanvas(
        environment: AppEnvironment.dev,
        request: scheduled,
      ),
      'one imported request': () => MyRequestDetailCanvas(
        environment: AppEnvironment.dev,
        request: OwnAssistanceCodec.row(_imported('ar-5'))!,
      ),
      'imported in the list': () => MyRequestsCanvas(
        environment: AppEnvironment.dev,
        items: OwnAssistanceCodec.list(<Object?>[_imported('ar-6')]),
        onOpen: (_) {},
      ),
      'not shown': () => const MyRequestDetailCanvas(
        environment: AppEnvironment.dev,
        failure: NotFoundFailure(debugMessage: 'synthetic'),
      ),
    };

    for (final MapEntry<String, Widget Function()> frame in frames.entries) {
      testWidgets(frame.key, (tester) async {
        await expectCleanLayouts(
          tester,
          () => _l10n(frame.value()),
          scrollable: false,
          height: 1400,
        );
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(400, 1400);
        await tester.pumpWidget(
          layoutHost(_l10n(frame.value()), scrollable: false),
        );
        await tester.pump();
        expect(_shows(_inPerson), isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  });
}
