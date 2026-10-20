import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/dev_mock_access.dart';
import 'package:taytay_resident/core/api/request_context.dart';

void main() {
  test('the vendored Role enum is the one this app mints from', () {
    final Object? decoded = jsonDecode(
      File('docs/integration/taytay-node-openapi.json').readAsStringSync(),
    );
    final roles =
        (decoded as Map<String, dynamic>)['components'] as Map<String, dynamic>;
    final schema =
        (roles['schemas'] as Map<String, dynamic>)['Role']
            as Map<String, dynamic>;
    expect(schema['enum'], <String>[
      'guest',
      'registered',
      'verified',
      'staff',
      'admin',
    ]);
    expect(DevMockAccess.mintedRoles, <String>{'registered', 'verified'});
  });

  test('a dev session is Bearer mock:<role>:<id>', () {
    final token = DevMockAccess.tryToken(id: 'resident-juana');
    expect(token, 'mock:verified:resident-juana');
    expect(
      DevMockAccess.tryToken(id: 'resident-juana', role: 'registered'),
      'mock:registered:resident-juana',
    );
    expect(DevMockAccess.tryToken(id: 'resident-juana', role: 'staff'), isNull);
    expect(DevMockAccess.tryToken(id: 'resident-juana', role: 'admin'), isNull);
    expect(DevMockAccess.tryToken(id: 'resident-juana', role: 'guest'), isNull);

    final headers = RequestContext(
      requestId: 'req-1',
      bearerToken: token,
    ).headers();
    expect(headers['Authorization'], 'Bearer mock:verified:resident-juana');
    expect(headers.containsKey('X-Role'), isFalse);
    expect(
      RequestContext(requestId: 'req-1', bearerToken: token).toString(),
      isNot(contains('mock:')),
    );
  });

  test('a colon in the id cannot become a second role segment', () {
    expect(DevMockAccess.tryToken(id: ''), isNull);
    expect(DevMockAccess.tryToken(id: 'a:b'), isNull);
  });
}
