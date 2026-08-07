import 'set_item.dart';

class ExerciseLog {
  final String exerciseId;
  final String exerciseName;
  final String targetMuscle;
  final String equipment;
  final String? notes;
  final List<SetItem> sets;

  ExerciseLog({
    required this.exerciseId,
    required this.exerciseName,
    required this.targetMuscle,
    required this.equipment,
    this.notes,
    required this.sets,
  });

  ExerciseLog copyWith({
    String? exerciseId,
    String? exerciseName,
    String? targetMuscle,
    String? equipment,
    String? notes,
    List<SetItem>? sets,
  }) {
    return ExerciseLog(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      equipment: equipment ?? this.equipment,
      notes: notes ?? this.notes,
      sets: sets ?? this.sets,
    );
  }

  double get totalVolumeKg {
    return sets
        .where((s) => s.isCompleted)
        .fold(0.0, (sum, s) => sum + (s.weightKg * s.reps));
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'targetMuscle': targetMuscle,
      'equipment': equipment,
      'notes': notes,
      'sets': sets.map((s) => s.toJson()).toList(),
    };
  }

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      targetMuscle: json['targetMuscle'] as String,
      equipment: json['equipment'] as String,
      notes: json['notes'] as String?,
      sets: (json['sets'] as List<dynamic>?)
              ?.map((s) => SetItem.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
