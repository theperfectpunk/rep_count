import { collection, addDoc, query, where, getDocs, doc, getDoc, deleteDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../config/firebase';
import { WorkoutPlan, PlanDay } from '../data/prebuiltPlans';

export interface CustomWorkoutPlan {
  id?: string;
  userId: string;
  name: string;
  description: string;
  type: 'custom';
  split: string;
  daysPerWeek: number;
  days: PlanDay[];
  createdAt: any;
  isActive: boolean;
}

export async function saveCustomPlan(plan: Omit<CustomWorkoutPlan, 'id'>): Promise<string> {
  const docRef = await addDoc(collection(db, 'workoutPlans'), {
    ...plan,
    createdAt: serverTimestamp(),
  });
  return docRef.id;
}

export async function getUserPlans(userId: string): Promise<CustomWorkoutPlan[]> {
  if (!userId) return [];
  try {
    const q = query(
      collection(db, 'workoutPlans'),
      where('userId', '==', userId)
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as CustomWorkoutPlan));
  } catch (error) {
    console.error('Error fetching user plans:', error);
    return [];
  }
}

export async function getCustomPlan(planId: string): Promise<CustomWorkoutPlan | null> {
  if (!planId) return null;
  try {
    const docRef = doc(db, 'workoutPlans', planId);
    const snapshot = await getDoc(docRef);
    if (snapshot.exists()) {
      return { id: snapshot.id, ...snapshot.data() } as CustomWorkoutPlan;
    }
  } catch (error) {
    console.error('Error fetching custom plan:', error);
  }
  return null;
}

export async function deletePlan(planId: string): Promise<void> {
  await deleteDoc(doc(db, 'workoutPlans', planId));
}

export async function setActivePlan(userId: string, planId: string): Promise<void> {
  if (!userId || !planId) return;
  try {
    // First deactivate all plans
    const plans = await getUserPlans(userId);
    for (const plan of plans) {
      if (plan.id && plan.isActive) {
        await updateDoc(doc(db, 'workoutPlans', plan.id), { isActive: false });
      }
    }
    // Activate the selected plan if it's a custom plan in Firestore
    const planRef = doc(db, 'workoutPlans', planId);
    const docSnap = await getDoc(planRef);
    if (docSnap.exists()) {
      await updateDoc(planRef, { isActive: true });
    }
  } catch (error) {
    console.error('Error setting active plan:', error);
  }
}
