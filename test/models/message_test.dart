import 'package:flutter_test/flutter_test.dart';
import 'package:opencode_remote/models/message.dart';

void main() {
  group('Message.fromInfo', () {
    test('parses basic user message', () {
      final info = {
        'id': 'msg_1',
        'sessionID': 'sess_1',
        'role': 'user',
        'time': {'created': 1700000000000},
      };
      final parts = [
        {'type': 'text', 'text': 'Hello world'},
      ];
      final msg = Message.fromInfo(info, parts);
      expect(msg.id, 'msg_1');
      expect(msg.sessionID, 'sess_1');
      expect(msg.role, 'user');
      expect(msg.content, 'Hello world');
      expect(msg.createdAt, 1700000000000);
    });

    test('handles empty info gracefully', () {
      final msg = Message.fromInfo({}, []);
      expect(msg.id, '');
      expect(msg.role, 'user');
      expect(msg.content, '');
      expect(msg.createdAt, 0);
    });

    test('extracts reasoning from parts', () {
      final info = {'role': 'assistant'};
      final parts = [
        {'type': 'text', 'text': 'Answer'},
        {'type': 'reasoning', 'text': 'Thinking...'},
      ];
      final msg = Message.fromInfo(info, parts);
      expect(msg.content, 'Answer');
      expect(msg.reasoning, 'Thinking...');
      expect(msg.hasReasoning, true);
    });

    test('extracts model info for assistant', () {
      final info = {
        'role': 'assistant',
        'providerID': 'openai',
        'modelID': 'gpt-4',
      };
      final msg = Message.fromInfo(info, []);
      expect(msg.model, 'openai/gpt-4');
    });

    test('extracts model info for user', () {
      final info = {
        'role': 'user',
        'model': {'providerID': 'anthropic', 'modelID': 'claude-3'},
      };
      final msg = Message.fromInfo(info, []);
      expect(msg.model, 'anthropic/claude-3');
    });

    test('handles null/missing fields safely', () {
      final info = <String, dynamic>{
        'role': null,
        'time': null,
        'tokens': null,
        'cost': null,
      };
      final msg = Message.fromInfo(info, []);
      expect(msg.role, 'user');
      expect(msg.cost, 0);
      expect(msg.hasTokens, false);
    });

    test('parses tokens correctly', () {
      final info = {
        'tokens': {'input': 100, 'output': 200, 'reasoning': 50},
      };
      final msg = Message.fromInfo(info, []);
      expect(msg.hasTokens, true);
      expect(msg.tokenInput, 100);
      expect(msg.tokenOutput, 200);
      expect(msg.tokenReasoning, 50);
    });
  });
}
