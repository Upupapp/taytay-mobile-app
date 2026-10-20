import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/dev_mock_access.dart';
import 'package:taytay_resident/core/api/request_context.dart';

void main() {
  test('a dev session is Bearer mock:<role>:<id>', () {
    final token = DevMockAccess.tryToken(id: 'acct-sample-juana');
    expect(token, 'mock:resident:acct-sample-juana');

    final headers = RequestContext(
      requestId: 'req-1',
      bearerToken: token,
    ).headers();
    expect(headers['Authorization'], 'Bearer mock:resident:acct-sample-juana');
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
