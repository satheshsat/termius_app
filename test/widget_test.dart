import 'package:flutter_test/flutter_test.dart';
import 'package:termius_app/main.dart';

void main() {
  testWidgets('TermiusApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TermiusApp());
    expect(find.byType(TermiusApp), findsOneWidget);
  });
}
