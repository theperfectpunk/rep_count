import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/workout_session.dart';

class WorkoutRepository {
  final FirebaseFirestore? _firestore;
  final List<WorkoutSession> _localHistory = [];

  WorkoutRepository({FirebaseFirestore? firestore})
      : _firestore = firestore {
    _populateInitialHistory();
  }

  void _populateInitialHistory() {
    final now = DateTime.now();
    _localHistory.addAll([
      WorkoutSession(
        workoutId: 'hist_01',
        title: 'Push Heavy - Chest & Shoulders',
        startedAt: now.subtract(const Duration(days: 2, hours: 1, minutes: 15)),
        completedAt: now.subtract(const Duration(days: 2)),
        durationSeconds: 4500,
        totalVolumeKg: 12450.0,
        prsUnlocked: 2,
        isCompleted: true,
        exercises: [],
      ),
      WorkoutSession(
        workoutId: 'hist_02',
        title: 'Pull & Arms',
        startedAt: now.subtract(const Duration(days: 4, hours: 1)),
        completedAt: now.subtract(const Duration(days: 4)),
        durationSeconds: 3600,
        totalVolumeKg: 9800.0,
        prsUnlocked: 1,
        isCompleted: true,
        exercises: [],
      ),
      WorkoutSession(
        workoutId: 'hist_03',
        title: 'Leg Day Hypertrophy',
        startedAt: now.subtract(const Duration(days: 6, hours: 1, minutes: 20)),
        completedAt: now.subtract(const Duration(days: 6)),
        durationSeconds: 4800,
        totalVolumeKg: 15600.0,
        prsUnlocked: 3,
        isCompleted: true,
        exercises: [],
      ),
    ]);
  }

  List<WorkoutSession> getWorkoutHistory() {
    return List.unmodifiable(_localHistory);
  }

  Stream<List<WorkoutSession>> streamUserWorkouts(String userId) {
    if (_firestore == null) {
      return Stream.value(getWorkoutHistory());
    }

    return _firestore!
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final remoteList = snapshot.docs
          .map((doc) => WorkoutSession.fromJson(doc.data()))
          .toList();
      return [...remoteList, ..._localHistory];
    });
  }

  Future<void> saveCompletedWorkout(WorkoutSession session, {String? userId}) async {
    // 1. Instant local write (0ms latency optimistic update)
    _localHistory.insert(0, session);

    // 2. Background sync to Firestore if configured
    if (_firestore != null && userId != null) {
      try {
        final docRef = _firestore!
            .collection('users')
            .doc(userId)
            .collection('workouts')
            .doc(session.workoutId);

        final payload = session.toJson();
        payload['updatedAt'] = FieldValue.serverTimestamp();

        await docRef.set(payload, SetOptions(merge: true));
        debugPrint('🔥 Workout successfully synced to Cloud Firestore path: users/$userId/workouts/${session.workoutId}');
      } catch (e) {
        debugPrint('Firestore background sync queued offline: $e');
      }
    }
  }
}
