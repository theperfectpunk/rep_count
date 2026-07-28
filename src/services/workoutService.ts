import { collection, addDoc, query, where, orderBy, limit, getDocs, Timestamp, serverTimestamp } from 'firebase/firestore';
import { db, auth } from '../config/firebase';
import { ActiveExercise } from '../stores/workoutStore';

export interface SavedSet {
  setNumber: number;
  reps: number;
  weight: number;
  isWarmup: boolean;
  isPR: boolean;
}

export interface SavedExercise {
  exerciseId: string;
  name: string;
  muscleGroup: string;
  sets: SavedSet[];
}

export interface WorkoutSession {
  id?: string;
  userId: string;
  planId: string | null;
  planDayName: string | null;
  workoutName: string;
  startedAt: Timestamp | any;
  finishedAt: Timestamp | any;
  totalVolume: number;
  totalSets: number;
  exercises: SavedExercise[] | ActiveExercise[] | any[];
}

export async function saveWorkoutSession(session: Omit<WorkoutSession, 'id'> | any): Promise<string> {
  const docRef = await addDoc(collection(db, 'workoutSessions'), session);
  return docRef.id;
}

export async function getRecentWorkouts(userId: string, count: number = 5): Promise<WorkoutSession[]> {
  const q = query(
    collection(db, 'workoutSessions'),
    where('userId', '==', userId),
    orderBy('finishedAt', 'desc'),
    limit(count)
  );
  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as WorkoutSession));
}

export async function getWorkoutsByDateRange(
  userId: string,
  startDate: Date,
  endDate: Date
): Promise<WorkoutSession[]> {
  const q = query(
    collection(db, 'workoutSessions'),
    where('userId', '==', userId),
    where('finishedAt', '>=', Timestamp.fromDate(startDate)),
    where('finishedAt', '<=', Timestamp.fromDate(endDate)),
    orderBy('finishedAt', 'desc')
  );
  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as WorkoutSession));
}

export async function getWorkoutsThisWeek(userId: string): Promise<WorkoutSession[]> {
  const now = new Date();
  const startOfWeek = new Date(now);
  const day = now.getDay();
  const diff = now.getDate() - day + (day === 0 ? -6 : 1);
  startOfWeek.setDate(diff);
  startOfWeek.setHours(0, 0, 0, 0);

  return getWorkoutsByDateRange(userId, startOfWeek, now);
}

export async function getTotalStats(userId: string): Promise<{
  totalWorkouts: number;
  totalVolume: number;
  totalSets: number;
}> {
  const q = query(
    collection(db, 'workoutSessions'),
    where('userId', '==', userId)
  );
  const snapshot = await getDocs(q);
  let totalVolume = 0;
  let totalSets = 0;
  snapshot.docs.forEach(doc => {
    const data = doc.data();
    totalVolume += data.totalVolume || 0;
    totalSets += data.totalSets || 0;
  });
  return {
    totalWorkouts: snapshot.size,
    totalVolume,
    totalSets,
  };
}

export const workoutService = {
  saveWorkoutSession: async (sessionData: {
    workoutName: string;
    planId?: string | null;
    planDayName?: string | null;
    startedAt: Date | null;
    exercises: ActiveExercise[];
    totalVolume: number;
    totalSets: number;
  }) => {
    const user = auth.currentUser;
    const userId = user ? user.uid : 'anonymous_user';
    const now = new Date();
    const durationSeconds = sessionData.startedAt
      ? Math.max(0, Math.floor((now.getTime() - new Date(sessionData.startedAt).getTime()) / 1000))
      : 0;

    const payload = {
      userId,
      workoutName: sessionData.workoutName || 'Workout',
      planId: sessionData.planId || null,
      planDayName: sessionData.planDayName || null,
      startedAt: sessionData.startedAt ? Timestamp.fromDate(sessionData.startedAt) : Timestamp.now(),
      finishedAt: Timestamp.now(),
      durationSeconds,
      totalVolume: sessionData.totalVolume,
      totalSets: sessionData.totalSets,
      exercises: sessionData.exercises,
      createdAt: serverTimestamp(),
    };

    try {
      const docRef = await addDoc(collection(db, 'workoutSessions'), payload);
      return { id: docRef.id, ...payload };
    } catch (error) {
      console.warn('Firestore saveWorkoutSession error or offline mode:', error);
      return { id: `local_${Date.now()}`, ...payload };
    }
  },

  async getPreviousBestForExercise(exerciseId: string): Promise<{ weight: number; reps: number } | null> {
    try {
      const user = auth.currentUser;
      if (!user) return null;

      const q = query(
        collection(db, 'workoutSessions'),
        where('userId', '==', user.uid),
        orderBy('finishedAt', 'desc'),
        limit(10)
      );

      const snapshot = await getDocs(q);
      let best: { weight: number; reps: number } | null = null;

      snapshot.forEach((doc) => {
        const data = doc.data();
        if (data.exercises && Array.isArray(data.exercises)) {
          const matchingEx = data.exercises.find((e: any) => e.exerciseId === exerciseId);
          if (matchingEx && matchingEx.sets) {
            matchingEx.sets.forEach((s: any) => {
              if (s.isCompleted && s.weight != null && s.reps != null) {
                if (!best || s.weight > best.weight || (s.weight === best.weight && s.reps > best.reps)) {
                  best = { weight: s.weight, reps: s.reps };
                }
              }
            });
          }
        }
      });

      return best;
    } catch (error) {
      console.warn('Error fetching previous best for exercise:', error);
      return null;
    }
  },
};
