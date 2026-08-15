import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_count/main.dart';

void main() {
  testWidgets('App smoke test - renders Dashboard and Start Workout button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GymWorkoutApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify main screen renders
    expect(find.text('START EMPTY WORKOUT'), findsOneWidget);
    expect(find.text('WEEKLY VOLUME'), findsOneWidget);
  });
}
