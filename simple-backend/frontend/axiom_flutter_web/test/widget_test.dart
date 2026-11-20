import 'package:axiom_flutter_web/axiom_generated/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generated models decode the backend JSON', () {
    final token = Token.fromJson({
      'access_token': 'abc',
      'token_type': 'bearer',
    });
    expect(token.accessToken, 'abc');
    final item = Item.fromJson({
      'id': '1',
      'title': 'My item',
      'description': 'hello',
      'owner_id': 'u1',
      'created_at': '2026-11-20T10:00:00',
    });
    expect(item.title, 'My item');
  });
}
