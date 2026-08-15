import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_session.dart';

class WorkoutRepository {
  final FirebaseFirestore _firestore;
  List<WorkoutSession> _cachedWorkouts = [];

  WorkoutRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _populateInitialHistory();
  }

  static final List<WorkoutSession> _sampleInitialHistory = [
    WorkoutSession(
      workoutId: 'hist_01',
      title: 'Push Heavy - Chest & Shoulders',
      startedAt: DateTime.now().subtract(const Duration(days: 2, hours: 1, minutes: 15)),
      completedAt: DateTime.now().subtract(const Duration(days: 2)),
      durationSeconds: 4500,
      totalVolumeKg: 12450.0,
      prsUnlocked: 2,
      isCompleted: true,
      exercises: [],
    ),
    WorkoutSession(
      workoutId: 'hist_02',
      title: 'Pull & Arms',
      startedAt: DateTime.now().subtract(const Duration(days: 4, hours: 1)),
      completedAt: DateTime.now().subtract(const Duration(days: 4)),
      durationSeconds: 3600,
      totalVolumeKg: 9800.0,
      prsUnlocked: 1,
      isCompleted: true,
      exercises: [],
    ),
    WorkoutSession(
      workoutId: 'hist_03',
      title: 'Leg Day Hypertrophy',
      startedAt: DateTime.now().subtract(const Duration(days: 6, hours: 1, minutes: 20)),
      completedAt: DateTime.now().subtract(const Duration(days: 6)),
      durationSeconds: 4800,
      totalVolumeKg: 15600.0,
      prsUnlocked: 3,
      isCompleted: true,
      exercises: [],
    ),
  ];

  void _populateInitialHistory() {
    _cachedWorkouts = List.from(_sampleInitialHistory);
  }

  List<WorkoutSession> getWorkoutHistory() {
    return List.unmodifiable(_cachedWorkouts);
  }

  /// Fetch user workouts with Firestore as Source of Truth.
  /// 1. Online: Reads Firestore users/{userId}/workouts & updates persistent disk cache.
  /// 2. Offline (App run >= 1 time): Uses persistent disk cache from SharedPreferences.
  /// 3. Offline (First run ever): Uses sample initial history.
  Future<List<WorkoutSession>> fetchUserWorkouts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .orderBy('completedAt', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final remoteWorkouts = snapshot.docs
            .map((doc) => WorkoutSession.fromJson(doc.data()..putIfAbsent('workoutId', () => doc.id)))
            .toList();

        _cachedWorkouts = remoteWorkouts;
        await _saveToPersistentCache(remoteWorkouts, userId);
        debugPrint('🔥 Loaded ${remoteWorkouts.length} workouts from Firestore & updated local persistent cache.');
        return _cachedWorkouts;
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching workouts from Firestore: $e. Checking local persistent disk cache...');
    }

    // Try loading persistent disk cache
    final savedCache = await _loadFromPersistentCache(userId);
    if (savedCache != null && savedCache.isNotEmpty) {
      _cachedWorkouts = savedCache;
      debugPrint('📦 Loaded ${savedCache.length} workouts from local persistent disk cache.');
      return _cachedWorkouts;
    }

    // First run ever & offline: fallback to sample history
    debugPrint('⚡ First run ever & offline. Using sample initial workouts.');
    _cachedWorkouts = List.from(_sampleInitialHistory);
    return _cachedWorkouts;
  }

  /// Real-time stream of user workouts with Firestore Source of Truth.
  Stream<List<WorkoutSession>> streamUserWorkouts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _cachedWorkouts.isNotEmpty ? _cachedWorkouts : _sampleInitialHistory;
      }
      final remoteList = snapshot.docs
          .map((doc) => WorkoutSession.fromJson(doc.data()..putIfAbsent('workoutId', () => doc.id)))
          .toList();
      _cachedWorkouts = remoteList;
      _saveToPersistentCache(remoteList, userId);
      return _cachedWorkouts;
    });
  }

  Future<void> saveCompletedWorkout(WorkoutSession session, {String? userId}) async {
    // 1. Instant optimistic local write & update persistent disk cache
    _cachedWorkouts.insert(0, session);
    await _saveToPersistentCache(_cachedWorkouts, userId);

    // 2. Cloud Firestore write (Source of truth sync)
    if (userId != null && userId.isNotEmpty) {
      try {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('workouts')
            .doc(session.workoutId);

        final payload = session.toJson();
        payload['updatedAt'] = FieldValue.serverTimestamp();

        await docRef.set(payload, SetOptions(merge: true));
        debugPrint('🔥 Workout successfully synced to Cloud Firestore path: users/$userId/workouts/${session.workoutId}');
      } catch (e) {
        debugPrint('⚠️ Firestore sync failed offline: $e. Saved in local persistent cache.');
      }
    }
  }

  Future<void> _saveToPersistentCache(List<WorkoutSession> sessions, String? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = sessions.map((s) => s.toJson()).toList();
      final key = (userId != null && userId.isNotEmpty)
          ? 'cached_user_workouts_${userId}_json'
          : 'cached_user_workouts_json';
      await prefs.setString(key, json.encode(jsonList));
    } catch (e) {
      debugPrint('⚠️ Error writing workout persistent cache: $e');
    }
  }

  Future<List<WorkoutSession>?> _loadFromPersistentCache(String? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = (userId != null && userId.isNotEmpty)
          ? 'cached_user_workouts_${userId}_json'
          : 'cached_user_workouts_json';
      final rawJson = prefs.getString(key);
      if (rawJson == null || rawJson.isEmpty) return null;
      final List decoded = json.decode(rawJson);
      return decoded.map((item) => WorkoutSession.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      debugPrint('⚠️ Error reading workout persistent cache: $e');
      return null;
    }
  }
}
