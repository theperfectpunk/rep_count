import '../models/exercise.dart';

class ExerciseRepository {
  static final List<Exercise> _masterExercises = [
    Exercise(
      id: 'ex_bench_press',
      name: 'Barbell Bench Press',
      category: 'Compound',
      equipment: 'Barbell',
      primaryMuscle: 'Chest',
      secondaryMuscles: ['Triceps', 'Front Delts'],
      historicalOneRepMax: 125.0,
    ),
    Exercise(
      id: 'ex_squat',
      name: 'Barbell Back Squat',
      category: 'Compound',
      equipment: 'Barbell',
      primaryMuscle: 'Quads',
      secondaryMuscles: ['Glutes', 'Hamstrings'],
      historicalOneRepMax: 160.0,
    ),
    Exercise(
      id: 'ex_deadlift',
      name: 'Conventional Deadlift',
      category: 'Compound',
      equipment: 'Barbell',
      primaryMuscle: 'Hamstrings',
      secondaryMuscles: ['Lower Back', 'Glutes', 'Traps'],
      historicalOneRepMax: 190.0,
    ),
    Exercise(
      id: 'ex_overhead_press',
      name: 'Overhead Barbell Press',
      category: 'Compound',
      equipment: 'Barbell',
      primaryMuscle: 'Shoulders',
      secondaryMuscles: ['Triceps', 'Upper Chest'],
      historicalOneRepMax: 75.0,
    ),
    Exercise(
      id: 'ex_pull_ups',
      name: 'Bodyweight Pull-Ups',
      category: 'Bodyweight',
      equipment: 'Pull-Up Bar',
      primaryMuscle: 'Lats',
      secondaryMuscles: ['Biceps', 'Rear Delts'],
      historicalOneRepMax: 105.0,
    ),
    Exercise(
      id: 'ex_incline_db_press',
      name: 'Incline Dumbbell Press',
      category: 'Hypertrophy',
      equipment: 'Dumbbell',
      primaryMuscle: 'Upper Chest',
      secondaryMuscles: ['Front Delts', 'Triceps'],
      historicalOneRepMax: 40.0,
    ),
    Exercise(
      id: 'ex_cable_flyes',
      name: 'High-to-Low Cable Flyes',
      category: 'Isolation',
      equipment: 'Cable',
      primaryMuscle: 'Chest',
      secondaryMuscles: ['Front Delts'],
      historicalOneRepMax: 32.5,
    ),
    Exercise(
      id: 'ex_barbell_curl',
      name: 'EZ-Bar Bicep Curl',
      category: 'Isolation',
      equipment: 'EZ-Bar',
      primaryMuscle: 'Biceps',
      secondaryMuscles: ['Forearms'],
      historicalOneRepMax: 45.0,
    ),
    Exercise(
      id: 'ex_tricep_pushdown',
      name: 'Rope Tricep Pushdown',
      category: 'Isolation',
      equipment: 'Cable',
      primaryMuscle: 'Triceps',
      secondaryMuscles: [],
      historicalOneRepMax: 35.0,
    ),
    Exercise(
      id: 'ex_leg_extension',
      name: 'Seated Leg Extension',
      category: 'Isolation',
      equipment: 'Machine',
      primaryMuscle: 'Quads',
      secondaryMuscles: [],
      historicalOneRepMax: 90.0,
    ),
  ];

  List<Exercise> getMasterExercises() => List.unmodifiable(_masterExercises);

  List<Exercise> searchExercises(String query, {String? muscle, String? equipment}) {
    return _masterExercises.where((ex) {
      final matchesQuery = query.isEmpty ||
          ex.name.toLowerCase().contains(query.toLowerCase()) ||
          ex.primaryMuscle.toLowerCase().contains(query.toLowerCase());
      final matchesMuscle = muscle == null || muscle == 'All' || ex.primaryMuscle == muscle;
      final matchesEquipment = equipment == null || equipment == 'All' || ex.equipment == equipment;
      return matchesQuery && matchesMuscle && matchesEquipment;
    }).toList();
  }
}
