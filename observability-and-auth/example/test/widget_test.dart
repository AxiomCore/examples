import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('auth controls render before a backend call', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Streaming and auth tester'), findsOneWidget);
    expect(find.text('1. Stream Login & Set JWT'), findsOneWidget);
  });
}
