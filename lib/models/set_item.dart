import 'package:uuid/uuid.dart';

enum SetType { WARMUP, NORMAL, DROPSET, FAILURE }

class SetItem {
  final String setId;
  final int index;
  final SetType type;
  final double weightKg;
  final int reps;
  final int targetReps;
  final double? rpe;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? supersetGroupId;

  SetItem({
    String? setId,
    required this.index,
    this.type = SetType.NORMAL,
    required this.weightKg,
    required this.reps,
    this.targetReps = 10,
    this.rpe,
    this.isCompleted = false,
    this.completedAt,
    this.supersetGroupId,
  }) : setId = setId ?? const Uuid().v4();

  SetItem copyWith({
    String? setId,
    int? index,
    SetType? type,
    double? weightKg,
    int? reps,
    int? targetReps,
    double? rpe,
    bool? isCompleted,
    DateTime? completedAt,
    String? supersetGroupId,
  }) {
    return SetItem(
      setId: setId ?? this.setId,
      index: index ?? this.index,
      type: type ?? this.type,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      targetReps: targetReps ?? this.targetReps,
      rpe: rpe ?? this.rpe,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      supersetGroupId: supersetGroupId ?? this.supersetGroupId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setId': setId,
      'index': index,
      'type': type.name,
      'weightKg': weightKg,
      'reps': reps,
      'targetReps': targetReps,
      'rpe': rpe,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'supersetGroupId': supersetGroupId,
    };
  }

  factory SetItem.fromJson(Map<String, dynamic> json) {
    return SetItem(
      setId: json['setId'] as String?,
      index: json['index'] as int? ?? 0,
      type: SetType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SetType.NORMAL,
      ),
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      reps: json['reps'] as int? ?? 0,
      targetReps: json['targetReps'] as int? ?? 10,
      rpe: (json['rpe'] as num?)?.toDouble(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      supersetGroupId: json['supersetGroupId'] as String?,
    );
  }
}
