import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine.dart';

class RoutineRepository {
  final FirebaseFirestore? _firestore;
  List<Routine> _cachedRoutines = [];

  RoutineRepository({FirebaseFirestore? firestore})
      : _firestore = firestore;

  /// Default prepopulated routines covering EVERY body part
  static final List<Routine> defaultBodyPartRoutines = [
    Routine(
      routineId: 'rt_chest_01',
      title: 'Chest Hypertrophy & Strength',
      folderName: 'Body Part Workouts',
      exerciseIds: ['ex_bench_press', 'ex_incline_db_press', 'ex_cable_flyes', 'ex_chest_dips'],
      estimatedDurationMinutes: 50,
      targetMuscles: ['Chest', 'Triceps', 'Front Delts'],
    ),
    Routine(
      routineId: 'rt_back_01',
      title: 'Back Thickness & Lats Width',
      folderName: 'Body Part Workouts',
      exerciseIds: ['ex_deadlift', 'ex_pull_ups', 'ex_barbell_row', 'ex_lat_pulldown'],
      estimatedDurationMinutes: 55,
      targetMuscles: ['Lats', 'Upper Back', 'Biceps'],
    ),
    Routine(
      routineId: 'rt_shoulders_01',
      title: 'Boulder Shoulders',
      folderName: 'Body Part Workouts',
      exerciseIds: ['ex_overhead_press', 'ex_db_lateral_raise', 'ex_rear_delt_fly', 'ex_front_raise'],
      estimatedDurationMinutes: 45,
      targetMuscles: ['Shoulders', 'Upper Chest', 'Traps'],
    ),
    Routine(
      routineId: 'rt_quads_01',
      title: 'Quad Dominance & Power',
      folderName: 'Body Part Workouts',
      exerciseIds: ['ex_squat', 'ex_leg_press', 'ex_leg_extension', 'ex_bulgarian_split_squat'],
      estimatedDurationMinutes: 60,
      targetMuscles: ['Quads', 'Glutes'],
    ),
    Routine(
      routineId: 'rt_hamstrings_glutes_01',
      title: 'Posterior Chain & Glutes',
      folderName: 'Body Part Workouts',
      exerciseIds: ['ex_romanian_deadlift', 'ex_lying_leg_curl', 'ex_hip_thrust', 'ex_seated_leg_curl'],
      estimatedDurationMinutes: 50,
      targetMuscles: ['Hamstrings', 'Glutes'],
    ),
    Routine(
      routineId: 'rt_arms_01',
      title: 'Ultimate Arm Pump',
      folderName: 'Body Part Workouts',
      exerciseIds: ['ex_barbell_curl', 'ex_skull_crushers', 'ex_hammer_curl', 'ex_tricep_pushdown'],
      estimatedDurationMinutes: 45,
      targetMuscles: ['Biceps', 'Triceps', 'Forearms'],
    ),
    Routine(
      routineId: 'rt_core_calves_01',
      title: 'Abs Core & Calf Conditioning',
      folderName: 'Body Part Workouts',
      exerciseIds: ['ex_hanging_leg_raise', 'ex_ab_wheel_rollout', 'ex_cable_crunch', 'ex_standing_calf_raise'],
      estimatedDurationMinutes: 40,
      targetMuscles: ['Abs', 'Calves'],
    ),
  ];

  /// Prepopulates initial workouts for EVERY body part when a new user is created
  Future<void> prepopulateUserBodyPartWorkouts(String userId) async {
    if (_firestore == null) return;
    try {
      final batch = _firestore!.batch();
      for (final routine in defaultBodyPartRoutines) {
        final docRef = _firestore!
            .collection('users')
            .doc(userId)
            .collection('routines')
            .doc(routine.routineId);
        batch.set(docRef, routine.toJson());
      }
      await batch.commit();
      debugPrint('✅ Successfully prepopulated body part workouts for user: $userId');
    } catch (e) {
      debugPrint('⚠️ Error prepopulating workouts for user $userId: $e');
    }
  }

  /// Fetch user routines with Firestore Source of Truth.
  Future<List<Routine>> fetchUserRoutines(String userId) async {
    if (_firestore != null) {
      try {
        final snapshot = await _firestore!
            .collection('users')
            .doc(userId)
            .collection('routines')
            .get();

        if (snapshot.docs.isEmpty) {
          debugPrint('🔥 New user detected ($userId). Prepopulating body part workouts...');
          await prepopulateUserBodyPartWorkouts(userId);
          _cachedRoutines = List.from(defaultBodyPartRoutines);
          await _saveToPersistentCache(_cachedRoutines, userId);
          return _cachedRoutines;
        }

        final routines = snapshot.docs
            .map((doc) => Routine.fromJson(doc.data()..putIfAbsent('routineId', () => doc.id)))
            .toList();
        _cachedRoutines = routines;
        await _saveToPersistentCache(routines, userId);
        debugPrint('🔥 Loaded ${routines.length} user routines from Firestore & updated local persistent cache.');
        return _cachedRoutines;
      } catch (e) {
        debugPrint('⚠️ Error fetching user routines: $e. Checking persistent disk cache...');
      }
    }

    final savedCache = await _loadFromPersistentCache(userId);
    if (savedCache != null && savedCache.isNotEmpty) {
      _cachedRoutines = savedCache;
      debugPrint('📦 Loaded ${savedCache.length} user routines from local persistent disk cache.');
      return _cachedRoutines;
    }

    debugPrint('⚡ First run ever & offline. Using default body part workouts.');
    _cachedRoutines = List.from(defaultBodyPartRoutines);
    return _cachedRoutines;
  }

  Future<void> _saveToPersistentCache(List<Routine> routines, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = routines.map((r) => r.toJson()).toList();
      await prefs.setString('cached_user_routines_${userId}_json', json.encode(jsonList));
    } catch (e) {
      debugPrint('⚠️ Error writing routine persistent cache: $e');
    }
  }

  Future<List<Routine>?> _loadFromPersistentCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString('cached_user_routines_${userId}_json');
      if (rawJson == null || rawJson.isEmpty) return null;
      final List decoded = json.decode(rawJson);
      return decoded.map((item) => Routine.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      debugPrint('⚠️ Error reading routine persistent cache: $e');
      return null;
    }
  }
}
