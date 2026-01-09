import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bb_draft/widgets/status_bar.dart';
import 'package:bb_draft/widgets/status_indicator.dart';
import 'package:bb_draft/providers/status_provider.dart';

void main() {
  group('StatusBar', () {
    testWidgets('displays two status indicators', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => StatusProvider(),
          child: const MaterialApp(
            home: Scaffold(
              body: StatusBar(),
            ),
          ),
        ),
      );

      // Should find two StatusIndicator widgets
      expect(find.byType(StatusIndicator), findsNWidgets(2));
    });

    testWidgets('displays Backend indicator', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => StatusProvider(),
          child: const MaterialApp(
            home: Scaffold(
              body: StatusBar(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud), findsOneWidget);
    });

    testWidgets('displays Database indicator', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => StatusProvider(),
          child: const MaterialApp(
            home: Scaffold(
              body: StatusBar(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.storage), findsOneWidget);
    });

    testWidgets('has dark background styling', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => StatusProvider(),
          child: const MaterialApp(
            home: Scaffold(
              body: StatusBar(),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(StatusBar),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF1E1E1E));
    });

    testWidgets('indicators are centered in row', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => StatusProvider(),
          child: const MaterialApp(
            home: Scaffold(
              body: StatusBar(),
            ),
          ),
        ),
      );

      // Find the Row that is a direct child of the StatusBar's Container
      final rows = tester.widgetList<Row>(find.byType(Row));
      final centeredRow = rows.firstWhere(
        (row) => row.mainAxisAlignment == MainAxisAlignment.center,
        orElse: () => throw StateError('No centered row found'),
      );
      expect(centeredRow.mainAxisAlignment, MainAxisAlignment.center);
    });
  });
}
