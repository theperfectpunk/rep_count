import { create } from 'zustand';

export interface ExerciseSet {
  id: string;
  setNumber: number;
  reps: number | null;
  weight: number | null;
  isWarmup: boolean;
  isCompleted: boolean;
  isPR: boolean;
  completedAt: Date | null;
}

export interface ActiveExercise {
  id: string;
  exerciseId: string;
  name: string;
  muscleGroup: string;
  sets: ExerciseSet[];
}

interface WorkoutState {
  isActive: boolean;
  workoutName: string;
  planId: string | null;
  planDayName: string | null;
  startedAt: Date | null;
  exercises: ActiveExercise[];
  restTimerEndTime: number | null;
  restTimerDuration: number;

  // Actions
  startWorkout: (name: string, planId?: string, planDayName?: string) => void;
  finishWorkout: () => { exercises: ActiveExercise[]; startedAt: Date | null; workoutName: string; planId: string | null; planDayName: string | null };
  addExercise: (exerciseId: string, name: string, muscleGroup: string) => void;
  removeExercise: (exerciseIndex: number) => void;
  addSet: (exerciseIndex: number) => void;
  removeSet: (exerciseIndex: number, setIndex: number) => void;
  updateSet: (exerciseIndex: number, setIndex: number, data: Partial<ExerciseSet>) => void;
  completeSet: (exerciseIndex: number, setIndex: number) => void;
  startRestTimer: (duration: number) => void;
  clearRestTimer: () => void;
  resetWorkout: () => void;
}

const generateId = () => Math.random().toString(36).substring(2, 9);

export const useWorkoutStore = create<WorkoutState>((set, get) => ({
  isActive: false,
  workoutName: '',
  planId: null,
  planDayName: null,
  startedAt: null,
  exercises: [],
  restTimerEndTime: null,
  restTimerDuration: 90,

  startWorkout: (name, planId, planDayName) =>
    set({
      isActive: true,
      workoutName: name,
      planId: planId || null,
      planDayName: planDayName || null,
      startedAt: new Date(),
      exercises: [],
    }),

  finishWorkout: () => {
    const state = get();
    const result = {
      exercises: state.exercises,
      startedAt: state.startedAt,
      workoutName: state.workoutName,
      planId: state.planId,
      planDayName: state.planDayName,
    };
    set({
      isActive: false,
      workoutName: '',
      planId: null,
      planDayName: null,
      startedAt: null,
      exercises: [],
      restTimerEndTime: null,
    });
    return result;
  },

  addExercise: (exerciseId, name, muscleGroup) =>
    set((state) => ({
      exercises: [
        ...state.exercises,
        {
          id: generateId(),
          exerciseId,
          name,
          muscleGroup,
          sets: [
            {
              id: generateId(),
              setNumber: 1,
              reps: null,
              weight: null,
              isWarmup: false,
              isCompleted: false,
              isPR: false,
              completedAt: null,
            },
          ],
        },
      ],
    })),

  removeExercise: (exerciseIndex) =>
    set((state) => ({
      exercises: state.exercises.filter((_, i) => i !== exerciseIndex),
    })),

  addSet: (exerciseIndex) =>
    set((state) => {
      const exercises = [...state.exercises];
      const exercise = { ...exercises[exerciseIndex] };
      const lastSet = exercise.sets[exercise.sets.length - 1];
      exercise.sets = [
        ...exercise.sets,
        {
          id: generateId(),
          setNumber: exercise.sets.length + 1,
          reps: lastSet?.reps || null,
          weight: lastSet?.weight || null,
          isWarmup: false,
          isCompleted: false,
          isPR: false,
          completedAt: null,
        },
      ];
      exercises[exerciseIndex] = exercise;
      return { exercises };
    }),

  removeSet: (exerciseIndex, setIndex) =>
    set((state) => {
      const exercises = [...state.exercises];
      const exercise = { ...exercises[exerciseIndex] };
      exercise.sets = exercise.sets
        .filter((_, i) => i !== setIndex)
        .map((s, i) => ({ ...s, setNumber: i + 1 }));
      exercises[exerciseIndex] = exercise;
      return { exercises };
    }),

  updateSet: (exerciseIndex, setIndex, data) =>
    set((state) => {
      const exercises = [...state.exercises];
      const exercise = { ...exercises[exerciseIndex] };
      exercise.sets = [...exercise.sets];
      exercise.sets[setIndex] = { ...exercise.sets[setIndex], ...data };
      exercises[exerciseIndex] = exercise;
      return { exercises };
    }),

  completeSet: (exerciseIndex, setIndex) =>
    set((state) => {
      const exercises = [...state.exercises];
      const exercise = { ...exercises[exerciseIndex] };
      exercise.sets = [...exercise.sets];
      exercise.sets[setIndex] = {
        ...exercise.sets[setIndex],
        isCompleted: true,
        completedAt: new Date(),
      };
      exercises[exerciseIndex] = exercise;
      return { exercises };
    }),

  startRestTimer: (duration) =>
    set({
      restTimerEndTime: Date.now() + duration * 1000,
      restTimerDuration: duration,
    }),

  clearRestTimer: () => set({ restTimerEndTime: null }),

  resetWorkout: () =>
    set({
      isActive: false,
      workoutName: '',
      planId: null,
      planDayName: null,
      startedAt: null,
      exercises: [],
      restTimerEndTime: null,
    }),
}));
