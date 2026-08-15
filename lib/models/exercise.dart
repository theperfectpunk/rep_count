class Exercise {
  final String id;
  final String name;
  final String category;
  final String equipment;
  final String primaryMuscle;
  final String? subMuscle;
  final List<String> secondaryMuscles;
  final String? thumbnailUrl;
  final double historicalOneRepMax;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.equipment,
    required this.primaryMuscle,
    this.subMuscle,
    required this.secondaryMuscles,
    this.thumbnailUrl,
    this.historicalOneRepMax = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'equipment': equipment,
      'primaryMuscle': primaryMuscle,
      'subMuscle': subMuscle,
      'secondaryMuscles': secondaryMuscles,
      'thumbnailUrl': thumbnailUrl,
      'historicalOneRepMax': historicalOneRepMax,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      equipment: json['equipment'] as String,
      primaryMuscle: json['primaryMuscle'] as String,
      subMuscle: json['subMuscle'] as String?,
      secondaryMuscles: List<String>.from(json['secondaryMuscles'] as List? ?? []),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      historicalOneRepMax: (json['historicalOneRepMax'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
