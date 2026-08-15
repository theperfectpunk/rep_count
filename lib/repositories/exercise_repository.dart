import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';

class ExerciseRepository {
  final FirebaseFirestore? _firestore;
  List<Exercise> _cachedExercises = [];

  ExerciseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore;

  static final List<Exercise> _masterExercises = [
    // --- CHEST ---
    Exercise(
      id: 'ex_bench_press',
      name: 'Barbell Bench Press',
      category: 'Compound',
      equipment: 'Barbell',
      primaryMuscle: 'Chest',
      subMuscle: 'Mid Chest',
      secondaryMuscles: ['Triceps', 'Front Delts'],
      historicalOneRepMax: 125.0,
    ),
    Exercise(
      id: 'ex_incline_db_press',
      name: 'Incline Dumbbell Press',
      category: 'Hypertrophy',
      equipment: 'Dumbbell',
      primaryMuscle: 'Chest',
      subMuscle: 'Upper Chest',
      secondaryMuscles: ['Front Delts', 'Triceps'],
      historicalOneRepMax: 40.0,
    ),
    Exercise(
      id: 'ex_cable_flyes',
      name: 'High-to-Low Cable Flyes',
      category: 'Isolation',
      equipment: 'Cable',
      primaryMuscle: 'Chest',
      subMuscle: 'Lower Chest',
      secondaryMuscles: ['Front Delts'],
      historicalOneRepMax: 32.5,
    ),
    Exercise(
      id: 'ex_chest_dips',
      name: 'Weighted Chest Dips',
      category: 'Bodyweight',
      equipment: 'Dip Station',
      primaryMuscle: 'Chest',
      subMuscle: 'Lower Chest',
      secondaryMuscles: ['Triceps', 'Front Delts'],
      historicalOneRepMax: 45.0,
    ),

    // --- BACK / LATS ---
    Exercise(
      id: 'ex_pull_ups',
      name: 'Bodyweight Pull-Ups',
      category: 'Bodyweight',
      equipment: 'Pull-Up Bar',
      primaryMuscle: 'Back',
      subMuscle: 'Lats',
      secondaryMuscles: ['Biceps', 'Rear Delts'],
      historicalOneRepMax: 105.0,
    ),
    Exercise(
      id: 'ex_barbell_row',
      name: 'Bent-Over Barbell Row',
      category: 'Compound',
      equipment: 'Barbell',
      primaryMuscle: 'Back',
      subMuscle: 'Mid Back',
      secondaryMuscles: ['Lats', 'Biceps', 'Rear Delts'],
      historicalOneRepMax: 100.0,
    ),
    Exercise(
      id: 'ex_lat_pulldown',
      name: 'Wide-Grip Lat Pulldown',
      category: 'Hypertrophy',
      equipment: 'Cable',
      primaryMuscle: 'Back',
      subMuscle: 'Lats',
      secondaryMuscles: ['Biceps'],
      historicalOneRepMax: 85.0,
    ),
    Exercise(
      id: 'ex_seated_cable_row',
      name: 'Seated Cable Row',
      category: 'Hypertrophy',
      equipment: 'Cable',
      primaryMuscle: 'Back',
      subMuscle: 'Mid Back',
      secondaryMuscles: ['Biceps', 'Rhomboids'],
      historicalOneRepMax: 90.0,
    ),

    // --- SHOULDERS ---
    Exercise(
      id: 'ex_overhead_press',
      name: 'Overhead Barbell Press',
      category: 'Compound',
      equipment: 'Barbell',
      primaryMuscle: 'Shoulders',
      subMuscle: 'Front Delt',
      secondaryMuscles: ['Triceps', 'Upper Chest'],
      historicalOneRepMax: 75.0,
    ),
    Exercise(
      id: 'ex_db_lateral_raise',
      name: 'Dumbbell Lateral Raise',
      category: 'Isolation',
      equipment: 'Dumbbell',
      primaryMuscle: 'Shoulders',
      subMuscle: 'Side Delt',
      secondaryMuscles: ['Traps'],
      historicalOneRepMax: 17.5,
    ),
    Exercise(
      id: 'ex_face_pulls',
      name: 'Rope Face Pulls',
      category: 'Isolation',
      equipment: 'Cable',
      primaryMuscle: 'Shoulders',
      subMuscle: 'Rear Delt',
      secondaryMuscles: ['Rear Delts', 'Traps'],
      historicalOneRepMax: 35.0,
    ),
    Exercise(
      id: 'ex_arnold_press',
      name: 'Dumbbell Arnold Press',
      category: 'Hypertrophy',
      equipment: 'Dumbbell',
      primaryMuscle: 'Shoulders',
      subMuscle: 'Front Delt',
      secondaryMuscles: ['Triceps'],
      historicalOneRepMax: 30.0,
    ),

    // --- QUADS ---
    Exercise(
      id: 'ex_squat',
      name: 'Barbell Back Squat',
      category: 'Compound',
      equipment: 'Barbell',
      primaryMuscle: 'Quads',
      subMuscle: 'Quads',
      secondaryMuscles: ['Glutes', 'Hamstrings'],
      historicalOneRepMax: 160.0,
    ),
    Exercise(
      id: 'ex_leg_press',
      name: '45-Degree Leg Press',
      category: 'Compound',
      equipment: 'Machine',
      primaryMuscle: 'Quads',
      subMuscle: 'Quads',
      secondaryMuscles: ['Glutes'],
      historicalOneRepMax: 280.0,
    ),
    Exercise(
      id: 'ex_leg_extension',
      name: 'Seated Leg Extension',
      category: 'Isolation',
      equipment: 'Machine',
      primaryMuscle: 'Quads',
      subMuscle: 'Quads',
      secondaryMuscles: [],
      historicalOneRepMax: 90.0,
    ),
    Exercise(
      id: 'ex_bulgarian_split_squat',
      name: 'Dumbbell Bulgarian Split Squat',
      category: 'Hypertrophy',
      equipment: 'Dumbbell',
      primaryMuscle: 'Quads',
      subMuscle: 'Quads',
      secondaryMuscles: ['Glutes'],
      historicalOneRepMax: 32.0,
    ),

    // --- HAMSTRINGS & GLUTES ---
    Exercise(
      id: 'ex_deadlift',
      name: 'Conventional Deadlift',
      category: 'Compound',
      equipment: 'Barbell',
      primaryMuscle: 'Hamstrings',
      subMuscle: 'Hamstrings',
      secondaryMuscles: ['Lower Back', 'Glutes', 'Traps'],
      historicalOneRepMax: 190.0,
    ),
    Exercise(
      id: 'ex_romanian_deadlift',
      name: 'Barbell Romanian Deadlift (RDL)',
      category: 'Hypertrophy',
      equipment: 'Barbell',
      primaryMuscle: 'Hamstrings',
      subMuscle: 'Hamstrings',
      secondaryMuscles: ['Glutes', 'Lower Back'],
      historicalOneRepMax: 140.0,
    ),
    Exercise(
      id: 'ex_lying_leg_curl',
      name: 'Lying Leg Curl',
      category: 'Isolation',
      equipment: 'Machine',
      primaryMuscle: 'Hamstrings',
      subMuscle: 'Hamstrings',
      secondaryMuscles: ['Calves'],
      historicalOneRepMax: 65.0,
    ),
    Exercise(
      id: 'ex_hip_thrust',
      name: 'Barbell Hip Thrust',
      category: 'Hypertrophy',
      equipment: 'Barbell',
      primaryMuscle: 'Glutes',
      subMuscle: 'Glutes',
      secondaryMuscles: ['Glutes', 'Quads'],
      historicalOneRepMax: 180.0,
    ),

    // --- BICEPS & FOREARMS ---
    Exercise(
      id: 'ex_barbell_curl',
      name: 'EZ-Bar Bicep Curl',
      category: 'Isolation',
      equipment: 'EZ-Bar',
      primaryMuscle: 'Biceps',
      subMuscle: 'Biceps',
      secondaryMuscles: ['Forearms'],
      historicalOneRepMax: 45.0,
    ),
    Exercise(
      id: 'ex_hammer_curl',
      name: 'Dumbbell Hammer Curl',
      category: 'Isolation',
      equipment: 'Dumbbell',
      primaryMuscle: 'Biceps',
      subMuscle: 'Biceps',
      secondaryMuscles: ['Brachialis', 'Forearms'],
      historicalOneRepMax: 22.5,
    ),
    Exercise(
      id: 'ex_incline_bicep_curl',
      name: 'Incline Dumbbell Curl',
      category: 'Isolation',
      equipment: 'Dumbbell',
      primaryMuscle: 'Biceps',
      subMuscle: 'Biceps',
      secondaryMuscles: [],
      historicalOneRepMax: 18.0,
    ),

    // --- TRICEPS ---
    Exercise(
      id: 'ex_tricep_pushdown',
      name: 'Rope Tricep Pushdown',
      category: 'Isolation',
      equipment: 'Cable',
      primaryMuscle: 'Triceps',
      subMuscle: 'Triceps',
      secondaryMuscles: [],
      historicalOneRepMax: 35.0,
    ),
    Exercise(
      id: 'ex_skull_crushers',
      name: 'Lying EZ-Bar Skull Crushers',
      category: 'Isolation',
      equipment: 'EZ-Bar',
      primaryMuscle: 'Triceps',
      subMuscle: 'Triceps',
      secondaryMuscles: ['Forearms'],
      historicalOneRepMax: 40.0,
    ),
    Exercise(
      id: 'ex_overhead_tricep_ext',
      name: 'Overhead Dumbbell Tricep Extension',
      category: 'Isolation',
      equipment: 'Dumbbell',
      primaryMuscle: 'Triceps',
      subMuscle: 'Triceps',
      secondaryMuscles: [],
      historicalOneRepMax: 30.0,
    ),

    // --- CALVES ---
    Exercise(
      id: 'ex_standing_calf_raise',
      name: 'Standing Machine Calf Raise',
      category: 'Isolation',
      equipment: 'Machine',
      primaryMuscle: 'Calves',
      subMuscle: 'Calves',
      secondaryMuscles: [],
      historicalOneRepMax: 110.0,
    ),
    Exercise(
      id: 'ex_seated_calf_raise',
      name: 'Seated Calf Raise',
      category: 'Isolation',
      equipment: 'Machine',
      primaryMuscle: 'Calves',
      subMuscle: 'Calves',
      secondaryMuscles: [],
      historicalOneRepMax: 70.0,
    ),

    // --- ABS / CORE ---
    Exercise(
      id: 'ex_hanging_leg_raise',
      name: 'Hanging Leg Raise',
      category: 'Bodyweight',
      equipment: 'Pull-Up Bar',
      primaryMuscle: 'Abs',
      subMuscle: 'Lower Abs',
      secondaryMuscles: ['Hip Flexors'],
      historicalOneRepMax: 0.0,
    ),
    Exercise(
      id: 'ex_ab_wheel_rollout',
      name: 'Ab Wheel Rollout',
      category: 'Bodyweight',
      equipment: 'Ab Wheel',
      primaryMuscle: 'Abs',
      subMuscle: 'Upper Abs',
      secondaryMuscles: ['Lower Back', 'Lats'],
      historicalOneRepMax: 0.0,
    ),
    Exercise(
      id: 'ex_cable_crunch',
      name: 'Kneeling Cable Crunch',
      category: 'Isolation',
      equipment: 'Cable',
      primaryMuscle: 'Abs',
      subMuscle: 'Upper Abs',
      secondaryMuscles: [],
      historicalOneRepMax: 50.0,
    ),

    // --- GLUTES (NEW) ---
    Exercise(
      id: 'ex_glute_bridge',
      name: 'Barbell Glute Bridge',
      category: 'Hypertrophy',
      equipment: 'Barbell',
      primaryMuscle: 'Glutes',
      subMuscle: 'Glutes',
      secondaryMuscles: ['Hamstrings'],
      historicalOneRepMax: 120.0,
    ),
    Exercise(
      id: 'ex_cable_kickback',
      name: 'Cable Glute Kickback',
      category: 'Isolation',
      equipment: 'Cable',
      primaryMuscle: 'Glutes',
      subMuscle: 'Glutes',
      secondaryMuscles: ['Hamstrings'],
      historicalOneRepMax: 25.0,
    ),
    Exercise(
      id: 'ex_step_up',
      name: 'Dumbbell Step-Up',
      category: 'Compound',
      equipment: 'Dumbbell',
      primaryMuscle: 'Glutes',
      subMuscle: 'Glutes',
      secondaryMuscles: ['Quads'],
      historicalOneRepMax: 30.0,
    ),

    // --- CHEST (extra) ---
    Exercise(
      id: 'ex_decline_bench',
      name: 'Decline Barbell Bench Press',
      category: 'Compound',
      equipment: 'Barbell',
      primaryMuscle: 'Chest',
      subMuscle: 'Lower Chest',
      secondaryMuscles: ['Triceps', 'Front Delts'],
      historicalOneRepMax: 90.0,
    ),
    Exercise(
      id: 'ex_low_cable_fly',
      name: 'Low-to-High Cable Fly',
      category: 'Isolation',
      equipment: 'Cable',
      primaryMuscle: 'Chest',
      subMuscle: 'Upper Chest',
      secondaryMuscles: ['Front Delts'],
      historicalOneRepMax: 20.0,
    ),

    // --- BACK (extra) ---
    Exercise(
      id: 'ex_tbar_row',
      name: 'T-Bar Row',
      category: 'Compound',
      equipment: 'Barbell',
      primaryMuscle: 'Back',
      subMuscle: 'Mid Back',
      secondaryMuscles: ['Biceps', 'Lats'],
      historicalOneRepMax: 80.0,
    ),
    Exercise(
      id: 'ex_back_extension',
      name: 'Back Extension (Hyperextension)',
      category: 'Bodyweight',
      equipment: 'Bodyweight',
      primaryMuscle: 'Back',
      subMuscle: 'Lower Back',
      secondaryMuscles: ['Glutes', 'Hamstrings'],
      historicalOneRepMax: 0.0,
    ),
    Exercise(
      id: 'ex_straight_arm_pulldown',
      name: 'Straight-Arm Cable Pulldown',
      category: 'Isolation',
      equipment: 'Cable',
      primaryMuscle: 'Back',
      subMuscle: 'Lats',
      secondaryMuscles: ['Triceps'],
      historicalOneRepMax: 30.0,
    ),

    // --- SHOULDERS (extra) ---
    Exercise(
      id: 'ex_reverse_fly',
      name: 'Dumbbell Reverse Fly',
      category: 'Isolation',
      equipment: 'Dumbbell',
      primaryMuscle: 'Shoulders',
      subMuscle: 'Rear Delt',
      secondaryMuscles: ['Upper Back'],
      historicalOneRepMax: 12.0,
    ),
    Exercise(
      id: 'ex_cable_lateral_raise',
      name: 'Cable Lateral Raise',
      category: 'Isolation',
      equipment: 'Cable',
      primaryMuscle: 'Shoulders',
      subMuscle: 'Side Delt',
      secondaryMuscles: [],
      historicalOneRepMax: 10.0,
    ),

    // --- TRAPS ---
    Exercise(
      id: 'ex_barbell_shrug',
      name: 'Barbell Shrug',
      category: 'Isolation',
      equipment: 'Barbell',
      primaryMuscle: 'Traps',
      subMuscle: 'Traps',
      secondaryMuscles: ['Upper Back'],
      historicalOneRepMax: 100.0,
    ),
    Exercise(
      id: 'ex_db_shrug',
      name: 'Dumbbell Shrug',
      category: 'Isolation',
      equipment: 'Dumbbell',
      primaryMuscle: 'Traps',
      subMuscle: 'Traps',
      secondaryMuscles: ['Upper Back'],
      historicalOneRepMax: 40.0,
    ),

    // --- FOREARMS ---
    Exercise(
      id: 'ex_wrist_curl',
      name: 'Barbell Wrist Curl',
      category: 'Isolation',
      equipment: 'Barbell',
      primaryMuscle: 'Forearms',
      subMuscle: 'Forearms',
      secondaryMuscles: [],
      historicalOneRepMax: 30.0,
    ),
    Exercise(
      id: 'ex_reverse_wrist_curl',
      name: 'Reverse Barbell Wrist Curl',
      category: 'Isolation',
      equipment: 'Barbell',
      primaryMuscle: 'Forearms',
      subMuscle: 'Forearms',
      secondaryMuscles: [],
      historicalOneRepMax: 20.0,
    ),

    // --- ADDUCTORS & ABDUCTORS ---
    Exercise(
      id: 'ex_hip_adduction',
      name: 'Machine Hip Adduction',
      category: 'Isolation',
      equipment: 'Machine',
      primaryMuscle: 'Adductors',
      subMuscle: 'Adductors',
      secondaryMuscles: [],
      historicalOneRepMax: 70.0,
    ),
    Exercise(
      id: 'ex_hip_abduction',
      name: 'Machine Hip Abduction',
      category: 'Isolation',
      equipment: 'Machine',
      primaryMuscle: 'Abductors',
      subMuscle: 'Abductors',
      secondaryMuscles: ['Glutes'],
      historicalOneRepMax: 60.0,
    ),
    Exercise(
      id: 'ex_sumo_squat',
      name: 'Dumbbell Sumo Squat',
      category: 'Compound',
      equipment: 'Dumbbell',
      primaryMuscle: 'Adductors',
      subMuscle: 'Adductors',
      secondaryMuscles: ['Quads', 'Glutes'],
      historicalOneRepMax: 40.0,
    ),

    // --- OBLIQUES / CORE ---
    Exercise(
      id: 'ex_russian_twist',
      name: 'Russian Twist',
      category: 'Bodyweight',
      equipment: 'Bodyweight',
      primaryMuscle: 'Abs',
      subMuscle: 'Obliques',
      secondaryMuscles: ['Hip Flexors'],
      historicalOneRepMax: 0.0,
    ),
    Exercise(
      id: 'ex_side_plank',
      name: 'Side Plank',
      category: 'Bodyweight',
      equipment: 'Bodyweight',
      primaryMuscle: 'Abs',
      subMuscle: 'Obliques',
      secondaryMuscles: [],
      historicalOneRepMax: 0.0,
    ),

    // --- LEGS (extra) ---
    Exercise(
      id: 'ex_sissy_squat',
      name: 'Sissy Squat',
      category: 'Bodyweight',
      equipment: 'Bodyweight',
      primaryMuscle: 'Quads',
      subMuscle: 'Quads',
      secondaryMuscles: [],
      historicalOneRepMax: 0.0,
    ),
    Exercise(
      id: 'ex_nordic_curl',
      name: 'Nordic Hamstring Curl',
      category: 'Bodyweight',
      equipment: 'Bodyweight',
      primaryMuscle: 'Hamstrings',
      subMuscle: 'Hamstrings',
      secondaryMuscles: [],
      historicalOneRepMax: 0.0,
    ),
  ];

  List<Exercise> getMasterExercises() =>
      _cachedExercises.isNotEmpty ? List.unmodifiable(_cachedExercises) : List.unmodifiable(_masterExercises);

  static const String _cacheKey = 'cached_exercises_json';

  /// Fetch exercises with Firestore as source of truth.
  /// 1. Online: Reads Firestore /exercises & updates local persistent cache.
  /// 2. Offline (Subsequent runs): Uses local persistent cache from disk.
  /// 3. Offline (First run ever): Uses hardcoded fallback.
  Future<List<Exercise>> fetchExercisesFromFirebase() async {
    if (_firestore != null) {
      try {
        final snapshot = await _firestore!
            .collection('exercises')
            .get();

        if (snapshot.docs.isNotEmpty) {
          final remoteExercises = snapshot.docs
              .map((doc) => Exercise.fromJson(doc.data()..putIfAbsent('id', () => doc.id)))
              .toList();

          _cachedExercises = remoteExercises;
          await _saveToPersistentCache(remoteExercises);
          debugPrint('🔥 Loaded ${remoteExercises.length} exercises from Firebase & updated persistent cache.');
          return _cachedExercises;
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching exercises from Firebase: $e. Checking local persistent cache...');
      }
    }

    // Try loading persistent disk cache (App run at least once)
    final savedCache = await _loadFromPersistentCache();
    if (savedCache != null && savedCache.isNotEmpty) {
      _cachedExercises = savedCache;
      debugPrint('📦 Loaded ${savedCache.length} exercises from local persistent disk cache.');
      return _cachedExercises;
    }

    // First run ever & offline: use hardcoded fallback
    debugPrint('⚡ First run ever & offline. Using hardcoded fallback exercises.');
    _cachedExercises = List.from(_masterExercises);
    return _cachedExercises;
  }

  Future<void> _saveToPersistentCache(List<Exercise> exercises) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = exercises.map((e) => e.toJson()).toList();
      await prefs.setString(_cacheKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('⚠️ Error writing persistent cache: $e');
    }
  }

  Future<List<Exercise>?> _loadFromPersistentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_cacheKey);
      if (rawJson == null || rawJson.isEmpty) return null;
      final List decoded = json.decode(rawJson);
      return decoded.map((item) => Exercise.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      debugPrint('⚠️ Error reading persistent cache: $e');
      return null;
    }
  }

  /// Stream of exercises from Firebase Firestore.
  Stream<List<Exercise>> getExercisesStream() {
    if (_firestore == null) {
      return Stream.value(_cachedExercises.isNotEmpty ? _cachedExercises : _masterExercises);
    }
    return _firestore!.collection('exercises').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _cachedExercises.isNotEmpty ? _cachedExercises : _masterExercises;
      }
      final exercises = snapshot.docs
          .map((doc) => Exercise.fromJson(doc.data()..putIfAbsent('id', () => doc.id)))
          .toList();
      _cachedExercises = exercises;
      _saveToPersistentCache(exercises);
      return _cachedExercises;
    });
  }

  List<Exercise> searchExercises(String query, {String? muscle, String? equipment, List<Exercise>? sourceList}) {
    final listToSearch = sourceList ?? (_cachedExercises.isNotEmpty ? _cachedExercises : _masterExercises);
    return listToSearch.where((ex) {
      final matchesQuery = query.isEmpty ||
          ex.name.toLowerCase().contains(query.toLowerCase()) ||
          ex.primaryMuscle.toLowerCase().contains(query.toLowerCase());
      final matchesMuscle = muscle == null || muscle == 'All' || ex.primaryMuscle == muscle;
      final matchesEquipment = equipment == null || equipment == 'All' || ex.equipment == equipment;
      return matchesQuery && matchesMuscle && matchesEquipment;
    }).toList();
  }
}

