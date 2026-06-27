import 'package:flutter_test/flutter_test.dart';
import 'package:opencode_remote/services/event_service.dart';

void main() {
  group('EventService', () {
    test('creates with required params', () {
      final service = EventService(
        baseUrl: 'http://localhost:4096',
        username: 'test',
        password: 'pass',
      );
      expect(service.baseUrl, 'http://localhost:4096');
    });

    test('events stream is broadcast', () {
      final service = EventService(baseUrl: 'http://localhost:4096');
      final sub1 = service.events.listen((_) {});
      final sub2 = service.events.listen((_) {});
      sub1.cancel();
      sub2.cancel();
      service.dispose();
    });

    test('disconnect cleans up resources', () async {
      final service = EventService(baseUrl: 'http://localhost:4096');
      await service.disconnect();
      // Should not throw
      await service.disconnect();
      service.dispose();
    });

    test('connect and disconnect cycle', () async {
      final service = EventService(baseUrl: 'http://localhost:4096');
      // Connect will fail (no server), but should not crash
      await service.connect();
      await Future.delayed(const Duration(milliseconds: 100));
      await service.disconnect();
      service.dispose();
    });
  });

  group('EventType', () {
    test('has all expected values', () {
      expect(EventType.values.length, 7);
      expect(EventType.values, contains(EventType.messageNew));
      expect(EventType.values, contains(EventType.sessionUpdated));
      expect(EventType.values, contains(EventType.messagePartDelta));
      expect(EventType.values, contains(EventType.permissionAsked));
      expect(EventType.values, contains(EventType.questionAsked));
      expect(EventType.values, contains(EventType.unknown));
    });
  });
}
