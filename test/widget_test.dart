import 'package:flutter_test/flutter_test.dart';
import 'package:bb_draft/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('BaseBall Draft'), findsOneWidget);
  });
}
