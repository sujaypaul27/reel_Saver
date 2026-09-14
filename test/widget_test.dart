import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App boots into HomeScreen successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: ReelSaverApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reel Saver'), findsOneWidget);
    expect(find.text('Automatic Detection'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });
}
