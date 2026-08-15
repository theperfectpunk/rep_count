import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rep_count/repositories/workout_repository.dart';
import 'package:rep_count/models/workout_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkoutRepository Unit Tests', () {
    late WorkoutRepository repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = WorkoutRepository();
    });

    test('Initial workout history loads default mock workouts', () {
      final history = repo.getWorkoutHistory();
      expect(history, isNotEmpty);
      expect(history.length, equals(3));
    });

    test('saveCompletedWorkout inserts new session at index 0', () async {
      final session = WorkoutSession(
        workoutId: 'test_wk_99',
        title: 'New PR Session',
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        durationSeconds: 3600,
        totalVolumeKg: 8500.0,
        prsUnlocked: 1,
        exercises: [],
        isCompleted: true,
      );

      await repo.saveCompletedWorkout(session);

      final history = repo.getWorkoutHistory();
      expect(history.first.workoutId, equals('test_wk_99'));
      expect(history.first.title, equals('New PR Session'));
    });
  });
}
