import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('stream controls render before any network connection', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StreamTester()));
    expect(find.text('HTTP Stream'), findsOneWidget);
    expect(find.text('SSE Stream'), findsOneWidget);
    expect(find.text('Connect WS'), findsOneWidget);
  });
}
