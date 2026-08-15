import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_count/main.dart';
import 'package:rep_count/screens/dashboard_screen.dart';
import 'package:rep_count/models/workout_session.dart';

void main() {
  testWidgets('App smoke test - renders Dashboard and Start Workout button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userWorkoutsProvider.overrideWith(
            (ref) async => <WorkoutSession>[],
          ),
        ],
        child: const GymWorkoutApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('START EMPTY WORKOUT'), findsOneWidget);
    expect(find.text('WEEKLY VOLUME'), findsOneWidget);
  });
}
