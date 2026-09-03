import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rep_count/providers/active_workout_provider.dart';
import 'package:rep_count/providers/rest_timer_provider.dart';
import 'package:rep_count/models/exercise_log.dart';
import 'package:rep_count/models/set_item.dart';

void main() {
  group('ActiveWorkoutNotifier Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial active workout state is null', () {
      final activeWorkout = container.read(activeWorkoutProvider);
      expect(activeWorkout, isNull);
    });

    test('startEmptyWorkout initializes session state with 0 duration', () {
      container
          .read(activeWorkoutProvider.notifier)
          .startEmptyWorkout(title: 'Test Session');

      final activeWorkout = container.read(activeWorkoutProvider);
      expect(activeWorkout, isNotNull);
      expect(activeWorkout!.title, equals('Test Session'));
      expect(activeWorkout.durationSeconds, equals(0));
      expect(activeWorkout.exercises, isEmpty);
    });

    test('addExercise appends exercise log and updates state', () {
      final notifier = container.read(activeWorkoutProvider.notifier);
      notifier.startEmptyWorkout();

      final exercise = ExerciseLog(
        exerciseId: 'ex_bench',
        exerciseName: 'Bench Press',
        targetMuscle: 'Chest',
        equipment: 'Barbell',
        sets: [
          SetItem(index: 0, weightKg: 100.0, reps: 10),
        ],
      );

      notifier.addExercise(exercise);

      final state = container.read(activeWorkoutProvider);
      expect(state!.exercises.length, equals(1));
      expect(state.exercises.first.exerciseName, equals('Bench Press'));
    });

    test('toggleSetCompletion updates volume and triggers rest timer', () {
      final notifier = container.read(activeWorkoutProvider.notifier);
      notifier.startEmptyWorkout();

      final exercise = ExerciseLog(
        exerciseId: 'ex_bench',
        exerciseName: 'Bench Press',
        targetMuscle: 'Chest',
        equipment: 'Barbell',
        sets: [
          SetItem(index: 0, weightKg: 100.0, reps: 10, isCompleted: false),
        ],
      );

      notifier.addExercise(exercise);
      notifier.toggleSetCompletion('ex_bench', 0);

      final state = container.read(activeWorkoutProvider);
      expect(state!.exercises.first.sets.first.isCompleted, isTrue);
      expect(state.totalVolumeKg, equals(1000.0));

      final timerState = container.read(restTimerProvider);
      expect(timerState.isActive, isTrue);
      expect(timerState.secondsRemaining, equals(90));
    });

    test('removeSet deletes target set row and re-indexes remaining sets', () {
      final notifier = container.read(activeWorkoutProvider.notifier);
      notifier.startEmptyWorkout();

      final exercise = ExerciseLog(
        exerciseId: 'ex_squat',
        exerciseName: 'Back Squat',
        targetMuscle: 'Quads',
        equipment: 'Barbell',
        sets: [
          SetItem(index: 0, weightKg: 120.0, reps: 5),
          SetItem(index: 1, weightKg: 140.0, reps: 5),
        ],
      );

      notifier.addExercise(exercise);
      notifier.removeSet('ex_squat', 0);

      final state = container.read(activeWorkoutProvider);
      expect(state!.exercises.first.sets.length, equals(1));
      expect(state.exercises.first.sets.first.weightKg, equals(140.0));
      expect(state.exercises.first.sets.first.index, equals(0));
    });

    test('removeExercise removes entire exercise from active session', () {
      final notifier = container.read(activeWorkoutProvider.notifier);
      notifier.startEmptyWorkout();

      notifier.addExercise(ExerciseLog(
        exerciseId: 'ex_bench',
        exerciseName: 'Bench Press',
        targetMuscle: 'Chest',
        equipment: 'Barbell',
        sets: [SetItem(index: 0, weightKg: 100, reps: 10)],
      ));

      expect(container.read(activeWorkoutProvider)!.exercises.length, equals(1));
      notifier.removeExercise('ex_bench');
      expect(container.read(activeWorkoutProvider)!.exercises, isEmpty);
    });

    test('updateSetType updates set classification correctly', () {
      final notifier = container.read(activeWorkoutProvider.notifier);
      notifier.startEmptyWorkout();

      notifier.addExercise(ExerciseLog(
        exerciseId: 'ex_bench',
        exerciseName: 'Bench Press',
        targetMuscle: 'Chest',
        equipment: 'Barbell',
        sets: [SetItem(index: 0, weightKg: 60, reps: 15, type: SetType.NORMAL)],
      ));

      notifier.updateSetType('ex_bench', 0, SetType.WARMUP);
      final set = container.read(activeWorkoutProvider)!.exercises.first.sets.first;
      expect(set.type, equals(SetType.WARMUP));
    });

    test('updateSetRpe logs perceived exertion rating', () {
      final notifier = container.read(activeWorkoutProvider.notifier);
      notifier.startEmptyWorkout();

      notifier.addExercise(ExerciseLog(
        exerciseId: 'ex_deadlift',
        exerciseName: 'Deadlift',
        targetMuscle: 'Hamstrings',
        equipment: 'Barbell',
        sets: [SetItem(index: 0, weightKg: 180, reps: 3)],
      ));

      notifier.updateSetRpe('ex_deadlift', 0, 8.5);
      final set = container.read(activeWorkoutProvider)!.exercises.first.sets.first;
      expect(set.rpe, equals(8.5));
    });
  });
}
