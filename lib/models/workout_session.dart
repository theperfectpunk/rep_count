import 'package:uuid/uuid.dart';
import 'exercise_log.dart';

class WorkoutSession {
  final String workoutId;
  final String title;
  final String? routineId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int durationSeconds;
  final double totalVolumeKg;
  final int prsUnlocked;
  final List<ExerciseLog> exercises;
  final bool isCompleted;

  WorkoutSession({
    String? workoutId,
    required this.title,
    this.routineId,
    required this.startedAt,
    this.completedAt,
    this.durationSeconds = 0,
    this.totalVolumeKg = 0.0,
    this.prsUnlocked = 0,
    required this.exercises,
    this.isCompleted = false,
  }) : workoutId = workoutId ?? const Uuid().v4();

  WorkoutSession copyWith({
    String? workoutId,
    String? title,
    String? routineId,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationSeconds,
    double? totalVolumeKg,
    int? prsUnlocked,
    List<ExerciseLog>? exercises,
    bool? isCompleted,
  }) {
    return WorkoutSession(
      workoutId: workoutId ?? this.workoutId,
      title: title ?? this.title,
      routineId: routineId ?? this.routineId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
      prsUnlocked: prsUnlocked ?? this.prsUnlocked,
      exercises: exercises ?? this.exercises,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workoutId': workoutId,
      'title': title,
      'routineId': routineId,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'totalVolumeKg': totalVolumeKg,
      'prsUnlocked': prsUnlocked,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'isCompleted': isCompleted,
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      workoutId: json['workoutId'] as String?,
      title: json['title'] as String? ?? 'Empty Workout',
      routineId: json['routineId'] as String?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      totalVolumeKg: (json['totalVolumeKg'] as num?)?.toDouble() ?? 0.0,
      prsUnlocked: json['prsUnlocked'] as int? ?? 0,
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
