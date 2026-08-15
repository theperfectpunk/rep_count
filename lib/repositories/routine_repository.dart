import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine.dart';

class RoutineRepository {
  final FirebaseFirestore _firestore;
  List<Routine> _cachedRoutines = [];

  RoutineRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
      title: 'Back Width & Thickness',
      folderName: 'Body Part Workouts',
      exerciseIds: ['ex_pull_ups', 'ex_barbell_row', 'ex_lat_pulldown', 'ex_seated_cable_row'],
      estimatedDurationMinutes: 55,
      targetMuscles: ['Back', 'Lats', 'Biceps'],
    ),
    Routine(
      routineId: 'rt_shoulders_01',
      title: 'Shoulder 3D Deltoid Focus',
      folderName: 'Body Part Workouts',
      exerciseIds: ['ex_overhead_press', 'ex_db_lateral_raise', 'ex_face_pulls', 'ex_arnold_press'],
      estimatedDurationMinutes: 45,
      targetMuscles: ['Shoulders', 'Traps', 'Triceps'],
    ),
    Routine(
      routineId: 'rt_quads_01',
      title: 'Quad Quad-Dominant Legs',
      folderName: 'Body Part Workouts',
      exerciseIds: ['ex_squat', 'ex_leg_press', 'ex_bulgarian_split_squat', 'ex_leg_extension'],
      estimatedDurationMinutes: 60,
      targetMuscles: ['Quads', 'Glutes'],
    ),
    Routine(
      routineId: 'rt_hamstrings_01',
      title: 'Hamstring & Glute Power',
      folderName: 'Body Part Workouts',
      exerciseIds: ['ex_deadlift', 'ex_romanian_deadlift', 'ex_lying_leg_curl', 'ex_hip_thrust'],
      estimatedDurationMinutes: 60,
      targetMuscles: ['Hamstrings', 'Glutes', 'Lower Back'],
    ),
    Routine(
      routineId: 'rt_glutes_01',
      title: 'Glute Activation & Growth',
      folderName: 'Body Part Workouts',
      exerciseIds: ['ex_hip_thrust', 'ex_glute_bridge', 'ex_cable_kickback', 'ex_step_up'],
      estimatedDurationMinutes: 45,
      targetMuscles: ['Glutes', 'Hamstrings'],
    ),
    Routine(
      routineId: 'rt_arms_01',
      title: 'Bicep & Tricep Arm Overload',
      folderName: 'Body Part Workouts',
      exerciseIds: ['ex_barbell_curl', 'ex_hammer_curl', 'ex_tricep_pushdown', 'ex_skull_crushers'],
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
    try {
      final batch = _firestore.batch();
      for (final routine in defaultBodyPartRoutines) {
        final docRef = _firestore
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
  /// Prepopulates body part workouts on Firestore if collection empty for user.
  Future<List<Routine>> fetchUserRoutines(String userId) async {
    try {
      final snapshot = await _firestore
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
