import 'package:flutter_test/flutter_test.dart';
import 'package:opencode_remote/models/part.dart';

void main() {
  group('Part.fromJson', () {
    test('parses text part', () {
      final json = {
        'id': 'p1',
        'type': 'text',
        'text': 'Hello',
      };
      final part = Part.fromJson(json);
      expect(part.id, 'p1');
      expect(part.type, 'text');
      expect(part.text, 'Hello');
      expect(part.tool, isNull);
    });

    test('parses reasoning part', () {
      final json = {
        'id': 'p2',
        'type': 'reasoning',
        'text': 'Thinking...',
      };
      final part = Part.fromJson(json);
      expect(part.type, 'reasoning');
      expect(part.reasoningText, 'Thinking...');
    });

    test('parses tool part', () {
      final json = {
        'id': 'p3',
        'type': 'tool',
        'callID': 'call_1',
        'tool': 'read_file',
        'state': {
          'status': 'completed',
          'output': 'file content',
        },
      };
      final part = Part.fromJson(json);
      expect(part.type, 'tool');
      expect(part.tool, isNotNull);
      expect(part.tool!.callID, 'call_1');
      expect(part.tool!.tool, 'read_file');
      expect(part.tool!.isCompleted, true);
      expect(part.tool!.output, 'file content');
    });

    test('parses file part', () {
      final json = {
        'id': 'p4',
        'type': 'file',
        'mime': 'image/png',
        'filename': 'screenshot.png',
        'url': 'https://example.com/img.png',
      };
      final part = Part.fromJson(json);
      expect(part.type, 'file');
      expect(part.file, isNotNull);
      expect(part.file!.mime, 'image/png');
      expect(part.file!.filename, 'screenshot.png');
    });

    test('parses snapshot part', () {
      final json = {
        'id': 'p5',
        'type': 'snapshot',
        'snapshot': 'base64data',
      };
      final part = Part.fromJson(json);
      expect(part.type, 'snapshot');
      expect(part.snapshot, 'base64data');
    });

    test('parses patch part', () {
      final json = {
        'id': 'p6',
        'type': 'patch',
        'hash': 'abc123',
        'files': ['lib/main.dart', 'lib/utils.dart'],
      };
      final part = Part.fromJson(json);
      expect(part.type, 'patch');
      expect(part.patch, isNotNull);
      expect(part.patch!.hash, 'abc123');
      expect(part.patch!.files, ['lib/main.dart', 'lib/utils.dart']);
    });

    test('handles empty/unknown type', () {
      final part = Part.fromJson({'id': 'p7'});
      expect(part.type, '');
      expect(part.text, isNull);
      expect(part.tool, isNull);
    });

    test('handles null fields safely', () {
      final json = {
        'id': null,
        'sessionID': null,
        'messageID': null,
        'type': 'text',
        'text': null,
      };
      final part = Part.fromJson(json);
      expect(part.id, '');
      expect(part.sessionID, '');
      expect(part.messageID, '');
      expect(part.text, isNull);
    });
  });
}
