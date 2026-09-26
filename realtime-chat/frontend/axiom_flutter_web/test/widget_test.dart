import 'package:flutter_test/flutter_test.dart';
import 'package:axiom_flutter_web/axiom_generated/models.dart';

void main() {
  test('chat messages retain their wire fields', () {
    final message = ChatMessage.fromJson({
      'sender': 'Example', 'content': 'Hello', 'timestamp': '2026-09-26T00:00:00Z',
    });
    expect(message.toJson()['content'], 'Hello');
    expect(message.toJson()['sender'], 'Example');
  });
}
