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

    testWidgets('displays version number in bottom right', (tester) async {
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

      // Version text should be present (default is 'dev' in tests)
      expect(find.text('dev'), findsOneWidget);
    });

    testWidgets('version text is right-aligned', (tester) async {
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

      // Find the Align widget containing the version text
      final align = tester.widget<Align>(
        find.ancestor(
          of: find.text('dev'),
          matching: find.byType(Align),
        ).first,
      );

      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('uses three-column layout with Expanded widgets', (tester) async {
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

      // Should have two Expanded widgets (left spacer and right with version)
      expect(find.byType(Expanded), findsNWidgets(2));
    });

    testWidgets('version text has correct styling', (tester) async {
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

      final textWidget = tester.widget<Text>(find.text('dev'));
      expect(textWidget.style?.fontSize, 11);
      expect(textWidget.style?.color, const Color(0xFF666666));
      expect(textWidget.style?.fontFamily, 'monospace');
    });
  });
}
