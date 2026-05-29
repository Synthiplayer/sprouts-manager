import 'package:flutter_test/flutter_test.dart';
import 'package:sprouts_manager/app/app.dart';

void main() {
  testWidgets('app smoke test builds root widget', (WidgetTester tester) async {
    await tester.pumpWidget(const SproutsManagerApp());
    expect(find.byType(SproutsManagerApp), findsOneWidget);
  });
}
