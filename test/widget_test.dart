import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/main.dart';

void main() {
  testWidgets('Phase 0 home screen displays complete message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ReelSaverApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reel Saver - Phase 0 Complete'), findsOneWidget);
  });
}
