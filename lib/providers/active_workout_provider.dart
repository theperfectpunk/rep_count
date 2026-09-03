import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_session.dart';
import '../models/exercise_log.dart';
import '../models/set_item.dart';
import 'rest_timer_provider.dart';

class ActiveWorkoutNotifier extends StateNotifier<WorkoutSession?> {
  final Ref ref;
  Timer? _sessionDurationTimer;

  ActiveWorkoutNotifier(this.ref) : super(null);

  void startEmptyWorkout({String title = 'Empty Workout'}) {
    _sessionDurationTimer?.cancel();
    final newSession = WorkoutSession(
      title: title,
      startedAt: DateTime.now(),
      exercises: [],
    );
    state = newSession;

    _sessionDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state != null && !state!.isCompleted) {
        state = state!.copyWith(
          durationSeconds: state!.durationSeconds + 1,
        );
      }
    });
  }

  void addExercise(ExerciseLog exercise) {
    if (state == null) return;
    final updatedExercises = List<ExerciseLog>.from(state!.exercises)..add(exercise);
    state = state!.copyWith(exercises: updatedExercises);
  }

  void addSet(String exerciseId) {
    if (state == null) return;
    final updatedExercises = state!.exercises.map((ex) {
      if (ex.exerciseId == exerciseId) {
        final lastSet = ex.sets.isNotEmpty ? ex.sets.last : null;
        final newSet = SetItem(
          index: ex.sets.length,
          weightKg: lastSet?.weightKg ?? 20.0,
          reps: lastSet?.reps ?? 10,
          targetReps: lastSet?.targetReps ?? 10,
        );
        return ex.copyWith(sets: [...ex.sets, newSet]);
      }
      return ex;
    }).toList();

    state = state!.copyWith(exercises: updatedExercises);
  }

  void toggleSetCompletion(String exerciseId, int setIndex) {
    if (state == null) return;
    bool shouldStartTimer = false;

    final updatedExercises = state!.exercises.map((ex) {
      if (ex.exerciseId == exerciseId) {
        final updatedSets = ex.sets.asMap().entries.map((entry) {
          if (entry.key == setIndex) {
            final isNowCompleted = !entry.value.isCompleted;
            if (isNowCompleted) shouldStartTimer = true;
            return entry.value.copyWith(
              isCompleted: isNowCompleted,
              completedAt: isNowCompleted ? DateTime.now() : null,
            );
          }
          return entry.value;
        }).toList();
        return ex.copyWith(sets: updatedSets);
      }
      return ex;
    }).toList();

    // Recalculate total volume load
    final newTotalVolume = updatedExercises.fold<double>(
      0.0,
      (sum, ex) => sum + ex.totalVolumeKg,
    );

    state = state!.copyWith(
      exercises: updatedExercises,
      totalVolumeKg: newTotalVolume,
    );

    // Auto-trigger rest timer if completed
    if (shouldStartTimer) {
      ref.read(restTimerProvider.notifier).startTimer(durationSeconds: 90);
    }
  }

  void updateSetValues(String exerciseId, int setIndex, {double? weight, int? reps}) {
    if (state == null) return;
    final updatedExercises = state!.exercises.map((ex) {
      if (ex.exerciseId == exerciseId) {
        final updatedSets = ex.sets.asMap().entries.map((entry) {
          if (entry.key == setIndex) {
            return entry.value.copyWith(
              weightKg: weight ?? entry.value.weightKg,
              reps: reps ?? entry.value.reps,
            );
          }
          return entry.value;
        }).toList();
        return ex.copyWith(sets: updatedSets);
      }
      return ex;
    }).toList();

    state = state!.copyWith(exercises: updatedExercises);
  }

  void removeSet(String exerciseId, int setIndex) {
    if (state == null) return;
    final updatedExercises = state!.exercises.map((ex) {
      if (ex.exerciseId == exerciseId) {
        final updatedSets = List<SetItem>.from(ex.sets)..removeAt(setIndex);
        // Re-index remaining sets
        final reindexedSets = updatedSets.asMap().entries.map((e) {
          return e.value.copyWith(index: e.key);
        }).toList();
        return ex.copyWith(sets: reindexedSets);
      }
      return ex;
    }).toList();

    state = state!.copyWith(exercises: updatedExercises);
  }

  void removeExercise(String exerciseId) {
    if (state == null) return;
    final updatedExercises = state!.exercises
        .where((ex) => ex.exerciseId != exerciseId)
        .toList();
    final newTotalVolume = updatedExercises.fold<double>(
      0.0,
      (sum, ex) => sum + ex.totalVolumeKg,
    );
    state = state!.copyWith(
      exercises: updatedExercises,
      totalVolumeKg: newTotalVolume,
    );
  }

  void updateSetType(String exerciseId, int setIndex, SetType type) {
    if (state == null) return;
    final updatedExercises = state!.exercises.map((ex) {
      if (ex.exerciseId == exerciseId) {
        final updatedSets = ex.sets.asMap().entries.map((entry) {
          if (entry.key == setIndex) {
            return entry.value.copyWith(type: type);
          }
          return entry.value;
        }).toList();
        return ex.copyWith(sets: updatedSets);
      }
      return ex;
    }).toList();

    state = state!.copyWith(exercises: updatedExercises);
  }

  void updateSetRpe(String exerciseId, int setIndex, double? rpe) {
    if (state == null) return;
    final updatedExercises = state!.exercises.map((ex) {
      if (ex.exerciseId == exerciseId) {
        final updatedSets = ex.sets.asMap().entries.map((entry) {
          if (entry.key == setIndex) {
            return entry.value.copyWith(rpe: rpe);
          }
          return entry.value;
        }).toList();
        return ex.copyWith(sets: updatedSets);
      }
      return ex;
    }).toList();

    state = state!.copyWith(exercises: updatedExercises);
  }

  WorkoutSession? finishWorkout() {
    if (state == null) return null;
    _sessionDurationTimer?.cancel();
    _sessionDurationTimer = null;
    final completedSession = state!.copyWith(
      completedAt: DateTime.now(),
      isCompleted: true,
    );
    state = null;
    return completedSession;
  }

  void cancelWorkout() {
    _sessionDurationTimer?.cancel();
    _sessionDurationTimer = null;
    state = null;
  }

  @override
  void dispose() {
    _sessionDurationTimer?.cancel();
    super.dispose();
  }
}

final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, WorkoutSession?>((ref) {
  return ActiveWorkoutNotifier(ref);
});
