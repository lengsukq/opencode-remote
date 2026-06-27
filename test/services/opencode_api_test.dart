import 'package:flutter_test/flutter_test.dart';
import 'package:opencode_remote/services/opencode_api.dart';

void main() {
  group('OpenCodeApi.buildUri', () {
    test('builds simple path', () {
      final api = OpenCodeApi(baseUrl: 'http://localhost:4096');
      final uri = api.buildUri('/global/health');
      expect(uri.toString(), 'http://localhost:4096/global/health');
    });

    test('appends directory query param', () {
      final api = OpenCodeApi(
        baseUrl: 'http://localhost:4096',
        directory: '/home/user/project',
      );
      final uri = api.buildUri('/session');
      expect(uri.queryParameters['directory'], '/home/user/project');
    });

    test('preserves existing query params', () {
      final api = OpenCodeApi(
        baseUrl: 'http://localhost:4096',
        directory: '/tmp',
      );
      final uri = api.buildUri('/session/s1/message?limit=10');
      expect(uri.queryParameters['directory'], '/tmp');
    });
  });

  group('OpenCodeApi.modelRef', () {
    test('parses valid model ref', () {
      final ref = OpenCodeApi.modelRef('openai/gpt-4');
      expect(ref, {'providerID': 'openai', 'modelID': 'gpt-4'});
    });

    test('returns null for invalid format', () {
      expect(OpenCodeApi.modelRef('invalid'), isNull);
      expect(OpenCodeApi.modelRef('a/b/c'), isNull);
      expect(OpenCodeApi.modelRef(''), isNull);
    });
  });

  group('OpenCodeApi.safeList', () {
    test('parses valid list', () {
      final json = [
        {'id': '1', 'name': 'a'},
        {'id': '2', 'name': 'b'},
      ];
      final result = OpenCodeApi.safeList(
        json,
        (m) => MapEntry(m['id'] as String, m['name'] as String),
      );
      expect(result.length, 2);
      expect(result[0].key, '1');
    });

    test('returns empty list for non-list input', () {
      final result = OpenCodeApi.safeList('not a list', (m) => m);
      expect(result, isEmpty);
    });

    test('skips invalid items', () {
      final json = [
        {'id': '1'},
        'not a map',
        {'id': '3'},
      ];
      final result = OpenCodeApi.safeList(json, (m) => m['id'] as String);
      expect(result.length, 2);
    });
  });

  group('OpenCodeApi.safeMap', () {
    test('returns map for valid input', () {
      final json = {'key': 'value'};
      expect(OpenCodeApi.safeMap(json), json);
    });

    test('returns empty map for non-map input', () {
      expect(OpenCodeApi.safeMap('string'), isEmpty);
      expect(OpenCodeApi.safeMap(42), isEmpty);
      expect(OpenCodeApi.safeMap(null), isEmpty);
    });
  });

  group('OpenCodeApiException.friendlyMessage', () {
    test('returns auth failed for 401', () {
      final e = OpenCodeApiException(401, 'Unauthorized');
      expect(e.friendlyMessage, contains('认证'));
    });

    test('returns permission denied for 403', () {
      final e = OpenCodeApiException(403, 'Forbidden');
      expect(e.friendlyMessage, contains('权限'));
    });

    test('returns not found for 404', () {
      final e = OpenCodeApiException(404, 'Not Found');
      expect(e.friendlyMessage, contains('不存在'));
    });

    test('returns server error for 500+', () {
      final e = OpenCodeApiException(500, 'Internal Error');
      expect(e.friendlyMessage, contains('服务器'));
    });

    test('toString includes status code', () {
      final e = OpenCodeApiException(404, 'Not Found');
      expect(e.toString(), contains('404'));
    });
  });

  group('OpenCodeApi auth header', () {
    test('encodes credentials correctly', () {
      final api = OpenCodeApi(
        baseUrl: 'http://localhost',
        username: 'admin',
        password: 'secret',
      );
      expect(api.headers['Authorization'], startsWith('Basic '));
    });

    test('uses default credentials', () {
      final api = OpenCodeApi(baseUrl: 'http://localhost');
      expect(api.headers['Authorization'], isNotNull);
    });
  });
}
