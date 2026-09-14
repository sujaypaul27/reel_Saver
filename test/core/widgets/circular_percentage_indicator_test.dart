import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/core/widgets/circular_percentage_indicator.dart';

void main() {
  group('CircularPercentageIndicator Widget Tests', () {
    testWidgets('renders CustomPaint and percentage text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularPercentageIndicator(
                progress: 0.65,
                size: 80,
                strokeWidth: 6,
                progressColor: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularPercentageIndicator), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('65%'), findsOneWidget);
    });

    testWidgets('clamps percentages above 100% or below 0% gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularPercentageIndicator(
                progress: 1.2,
                size: 70,
              ),
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularPercentageIndicator(
                progress: -0.1,
                size: 70,
              ),
            ),
          ),
        ),
      );

      expect(find.text('0%'), findsOneWidget);
    });
  });
}
