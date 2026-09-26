import 'package:flutter_test/flutter_test.dart';
import 'package:axiom_flutter_web/main.dart';

void main() {
  testWidgets('backend consumer controls render without a service', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Axiom Full Test'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
