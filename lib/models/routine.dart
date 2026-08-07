import 'package:uuid/uuid.dart';

class Routine {
  final String routineId;
  final String title;
  final String folderName;
  final List<String> exerciseIds;
  final int estimatedDurationMinutes;
  final List<String> targetMuscles;
  final DateTime createdAt;

  Routine({
    String? routineId,
    required this.title,
    this.folderName = 'General Routines',
    required this.exerciseIds,
    this.estimatedDurationMinutes = 45,
    required this.targetMuscles,
    DateTime? createdAt,
  })  : routineId = routineId ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'routineId': routineId,
      'title': title,
      'folderName': folderName,
      'exerciseIds': exerciseIds,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'targetMuscles': targetMuscles,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      routineId: json['routineId'] as String?,
      title: json['title'] as String,
      folderName: json['folderName'] as String? ?? 'General Routines',
      exerciseIds: List<String>.from(json['exerciseIds'] as List? ?? []),
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int? ?? 45,
      targetMuscles: List<String>.from(json['targetMuscles'] as List? ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}
