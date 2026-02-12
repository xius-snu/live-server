import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PaintRollerApp());
    expect(find.text('Paint Roller'), findsOneWidget);
  });
}
