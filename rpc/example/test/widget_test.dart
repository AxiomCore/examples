import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';
import 'package:example/axiom_generated/models.dart';

void main() {
  test('RPC model preserves the extracted person identity', () {
    final person = Person.fromJson({'id': 'person-1', 'name': 'Example'});
    expect(person.toJson(), {'id': 'person-1', 'name': 'Example'});
  });

  testWidgets('RPC screen renders without contacting the backend', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RpcDemoScreen()));
    expect(find.text('RPC Chaining Demo'), findsOneWidget);
    expect(find.text('Get Contacts (RPC)'), findsOneWidget);
  });
}
