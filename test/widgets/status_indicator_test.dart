import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bb_draft/widgets/status_indicator.dart';
import 'package:bb_draft/providers/status_provider.dart';

void main() {
  group('StatusIndicator', () {
    testWidgets('displays label and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusIndicator(
              label: 'Backend',
              icon: Icons.cloud,
              status: ConnectionStatus.connected,
            ),
          ),
        ),
      );

      expect(find.text('Backend: Connected'), findsOneWidget);
      expect(find.byIcon(Icons.cloud), findsOneWidget);
    });

    testWidgets('shows green color when connected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusIndicator(
              label: 'Backend',
              icon: Icons.cloud,
              status: ConnectionStatus.connected,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.cloud));
      expect(icon.color, const Color(0xFF4CAF50)); // Green
    });

    testWidgets('shows red color when disconnected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusIndicator(
              label: 'Database',
              icon: Icons.storage,
              status: ConnectionStatus.disconnected,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.storage));
      expect(icon.color, const Color(0xFFF44336)); // Red
    });

    testWidgets('shows grey color when checking', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusIndicator(
              label: 'Backend',
              icon: Icons.cloud,
              status: ConnectionStatus.checking,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.cloud));
      expect(icon.color, const Color(0xFF9E9E9E)); // Grey
    });

    testWidgets('displays correct status text for connected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusIndicator(
              label: 'Backend',
              icon: Icons.cloud,
              status: ConnectionStatus.connected,
            ),
          ),
        ),
      );

      expect(find.text('Backend: Connected'), findsOneWidget);
    });

    testWidgets('displays correct status text for disconnected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusIndicator(
              label: 'Database',
              icon: Icons.storage,
              status: ConnectionStatus.disconnected,
            ),
          ),
        ),
      );

      expect(find.text('Database: Disconnected'), findsOneWidget);
    });

    testWidgets('displays correct status text for checking', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusIndicator(
              label: 'Backend',
              icon: Icons.cloud,
              status: ConnectionStatus.checking,
            ),
          ),
        ),
      );

      expect(find.text('Backend: Checking...'), findsOneWidget);
    });
  });
}
