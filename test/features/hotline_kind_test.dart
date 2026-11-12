import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/brand_gradients.dart';
import 'package:taytay_resident/core/design/taytay_glyphs.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/citizen_api/data/node_citizen_api.dart';
import 'package:taytay_resident/features/citizen_api/domain/citizen_contract.dart';
import 'package:taytay_resident/features/home/domain/home_content.dart';
import 'package:taytay_resident/features/home/presentation/hotlines_screen.dart';
import 'package:taytay_resident/shared/widgets/icon_tile.dart';

import '../support/layout_matrix.dart';

/// A hotline says what it is for (`kind`, backend `ebd7aeb`), and the app
/// picks lines by it, never by a name (D-214).
void main() {
  MunicipalHotline row(
    String id, {
    String name = 'Synthetic line',
    HotlineKind kind = HotlineKind.other,
    bool active = true,
    String number = '0900-000-0000',
  }) => MunicipalHotline(
    id: id,
    name: name,
    number: number,
    category: 'municipal',
    sortOrder: 0,
    active: active,
    kind: kind,
  );

  group('the kind is read from the wire', () {
    test('every published kind, and anything else is other', () {
      expect(HotlineKind.values.map((HotlineKind k) => k.wireValue), <String>[
        'command-center',
        'emergency',
        'police',
        'fire',
        'medical',
        'disaster',
        'other',
      ]);
      for (final HotlineKind kind in HotlineKind.values) {
        expect(HotlineKind.parse(kind.wireValue), kind);
      }
      expect(HotlineKind.parse('Command Center'), HotlineKind.other);
      expect(HotlineKind.parse(null), HotlineKind.other);
      expect(HotlineKind.parse(7), HotlineKind.other);
    });

    test('only other is not an emergency line', () {
      for (final HotlineKind kind in HotlineKind.values) {
        expect(kind.isEmergency, kind != HotlineKind.other, reason: kind.name);
      }
    });

    test(
      'GET /hotlines decodes kind, and a row without one is other',
      () async {
        final ApiClient client = ApiClient(
          config: AppConfig.from(
            rawEnvironment: 'dev',
            rawApiBaseUrl: 'https://example.test/api/v1',
            isReleaseBuild: false,
          ),
          transport: _OneAnswer(
            ApiHttpResponse(
              statusCode: 200,
              body: jsonEncode(<String, Object?>{
                'data': <Object?>[
                  <String, Object?>{
                    'id': 'h1',
                    'name': 'Synthetic center',
                    'number': '0900-000-0000',
                    'category': 'municipal',
                    'kind': 'command-center',
                    'sort_order': 1,
                    'active': true,
                  },
                  <String, Object?>{
                    'id': 'h2',
                    'name': 'Synthetic older row',
                    'number': '0900-000-0001',
                    'category': 'municipal',
                    'sort_order': 2,
                    'active': true,
                  },
                ],
                'meta': <String, Object?>{'request_id': 'req-1'},
              }),
            ),
          ),
        );
        final List<MunicipalHotline> lines =
            (await NodeCitizenApi(
              apiClient: client,
            ).listHotlines()).valueOrNull ??
            const <MunicipalHotline>[];
        expect(lines.map((MunicipalHotline l) => l.kind), <HotlineKind>[
          HotlineKind.commandCenter,
          HotlineKind.other,
        ]);
      },
    );
  });

  group('the command center is picked by kind alone', () {
    test('a line named like one, but of another kind, is not it', () {
      expect(
        activeCommandCenter(<MunicipalHotline>[
          row('a', name: 'Sagip Taytay Command Center'),
          row('b', name: 'Emergency', kind: HotlineKind.emergency),
        ]),
        isNull,
      );
    });

    test('the active command-center line, whatever its name or order', () {
      final MunicipalHotline? found = activeCommandCenter(<MunicipalHotline>[
        row('a', kind: HotlineKind.emergency),
        row('b', kind: HotlineKind.commandCenter, active: false),
        row('c', name: 'Synthetic ops', kind: HotlineKind.commandCenter),
      ]);
      expect(found?.id, 'c');
    });

    test('a command-center line with no number is not offered', () {
      expect(
        activeCommandCenter(<MunicipalHotline>[
          row('a', kind: HotlineKind.commandCenter, number: '  '),
        ]),
        isNull,
      );
    });

    test('none at all', () {
      expect(activeCommandCenter(const <MunicipalHotline>[]), isNull);
    });
  });

  group('the Hotlines page draws the red siren from kind', () {
    HomeHotline line(String id, String name, HotlineKind kind) => HomeHotline(
      id: id,
      name: name,
      number: '0900-000-0000',
      category: 'municipal',
      kind: kind,
    );

    final List<HomeHotline> lines = <HomeHotline>[
      for (final HotlineKind kind in HotlineKind.values)
        line('l-${kind.wireValue}', 'Synthetic ${kind.wireValue}', kind),
      // The name the page used to match on, now an ordinary line.
      line('l-pnp', 'Taytay PNP', HotlineKind.other),
    ];

    testWidgets('emergency kinds are red sirens, other is a blue phone', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390, 2000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        layoutHost(HotlinesCanvas(lines: lines), scrollable: false),
      );
      await tester.pump();

      IconTile tileFor(String name) => tester.widget<IconTile>(
        find.descendant(
          of: find
              .ancestor(of: find.text(name), matching: find.byType(Row))
              .first,
          matching: find.byType(IconTile),
        ),
      );

      for (final HotlineKind kind in HotlineKind.values) {
        final IconTile tile = tileFor('Synthetic ${kind.wireValue}');
        expect(
          tile.glyph,
          kind.isEmergency ? TaytayGlyph.siren : TaytayGlyph.phone,
          reason: kind.wireValue,
        );
        expect(
          tile.tone,
          kind.isEmergency ? TileTone.red : TileTone.blue,
          reason: kind.wireValue,
        );
      }
      expect(tileFor('Taytay PNP').glyph, TaytayGlyph.phone);
    });

    testWidgets('the page fits every phone at 200% text', (tester) async {
      await expectCleanLayouts(
        tester,
        () => HotlinesCanvas(lines: lines),
        scrollable: false,
        height: 1600,
      );
    });
  });

  group('the contract (vendored Node export, backend ebd7aeb)', () {
    final Map<String, dynamic> node =
        jsonDecode(
              File(
                'docs/integration/taytay-node-openapi.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final Map<String, dynamic> schemas =
        (node['components'] as Map<String, dynamic>)['schemas']
            as Map<String, dynamic>;

    test('HotlineKind is the closed set the app parses', () {
      final Map<String, dynamic> kind =
          schemas['HotlineKind'] as Map<String, dynamic>;
      expect(
        (kind['enum'] as List<dynamic>).cast<String>(),
        HotlineKind.values.map((HotlineKind k) => k.wireValue).toList(),
      );
    });

    test('every hotline carries its kind', () {
      final Map<String, dynamic> hotline =
          schemas['Hotline'] as Map<String, dynamic>;
      expect(
        (hotline['required'] as List<dynamic>).cast<String>(),
        contains('kind'),
      );
      final Map<String, dynamic> property =
          (hotline['properties'] as Map<String, dynamic>)['kind']
              as Map<String, dynamic>;
      expect(property[r'$ref'], '#/components/schemas/HotlineKind');
    });
  });
}

/// Answers the one request a decode test makes.
class _OneAnswer implements ApiTransport {
  _OneAnswer(this._response);

  final ApiHttpResponse _response;

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async =>
      Ok<ApiHttpResponse>(_response);
}
