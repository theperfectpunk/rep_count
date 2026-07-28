import { Exercise } from './exercises';

export interface PlanExercise {
  exerciseId: string;
  targetSets: number;
  targetReps: string; // e.g. '8-12' or '5' or '12-15'
  notes?: string;
}

export interface PlanDay {
  dayName: string;
  dayNumber: number;
  exercises: PlanExercise[];
}

export interface WorkoutPlan {
  id: string;
  name: string;
  description: string;
  type: 'pre-built';
  split: 'ppl' | 'upper_lower' | 'full_body' | 'bro_split';
  daysPerWeek: number;
  days: PlanDay[];
}

export const prebuiltPlans: WorkoutPlan[] = [
  // PLAN 1: Push / Pull / Legs (6-Day)
  {
    id: 'push-pull-legs-6-day',
    name: 'Push / Pull / Legs (6-Day)',
    description: 'A comprehensive 6-day split designed for hyper-focused volume and muscle recovery, targeting Push, Pull, and Leg muscle groups twice per week.',
    type: 'pre-built',
    split: 'ppl',
    daysPerWeek: 6,
    days: [
      {
        dayName: 'Push Day 1',
        dayNumber: 1,
        exercises: [
          { exerciseId: 'barbell-bench-press', targetSets: 4, targetReps: '6-8', notes: 'Focus on heavy progressive overload' },
          { exerciseId: 'incline-dumbbell-press', targetSets: 3, targetReps: '8-10' },
          { exerciseId: 'cable-flyes', targetSets: 3, targetReps: '12-15' },
          { exerciseId: 'overhead-press', targetSets: 3, targetReps: '8-10' },
          { exerciseId: 'lateral-raises', targetSets: 4, targetReps: '12-15' },
          { exerciseId: 'tricep-pushdown', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'overhead-tricep-extension', targetSets: 3, targetReps: '10-12' },
        ],
      },
      {
        dayName: 'Pull Day 1',
        dayNumber: 2,
        exercises: [
          { exerciseId: 'deadlift', targetSets: 3, targetReps: '5', notes: 'Heavy compound hinge' },
          { exerciseId: 'barbell-row', targetSets: 4, targetReps: '8-10' },
          { exerciseId: 'pull-ups', targetSets: 3, targetReps: '8-12' },
          { exerciseId: 'lat-pulldown', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'face-pulls', targetSets: 4, targetReps: '15-20' },
          { exerciseId: 'barbell-curl', targetSets: 3, targetReps: '8-10' },
          { exerciseId: 'hammer-curl', targetSets: 3, targetReps: '10-12' },
        ],
      },
      {
        dayName: 'Legs Day 1',
        dayNumber: 3,
        exercises: [
          { exerciseId: 'barbell-squat', targetSets: 4, targetReps: '6-8', notes: 'Focus on depth and stance stability' },
          { exerciseId: 'romanian-deadlift', targetSets: 3, targetReps: '8-10' },
          { exerciseId: 'leg-press', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'leg-curl', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'leg-extension', targetSets: 3, targetReps: '12-15' },
          { exerciseId: 'calf-raises-standing', targetSets: 4, targetReps: '12-15' },
          { exerciseId: 'hip-thrust', targetSets: 3, targetReps: '10-12' },
        ],
      },
      {
        dayName: 'Push Day 2',
        dayNumber: 4,
        exercises: [
          { exerciseId: 'barbell-bench-press', targetSets: 4, targetReps: '8-10' },
          { exerciseId: 'incline-dumbbell-press', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'cable-flyes', targetSets: 3, targetReps: '12-15' },
          { exerciseId: 'overhead-press', targetSets: 3, targetReps: '8-10' },
          { exerciseId: 'lateral-raises', targetSets: 4, targetReps: '12-15' },
          { exerciseId: 'tricep-pushdown', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'overhead-tricep-extension', targetSets: 3, targetReps: '10-12' },
        ],
      },
      {
        dayName: 'Pull Day 2',
        dayNumber: 5,
        exercises: [
          { exerciseId: 'deadlift', targetSets: 3, targetReps: '5' },
          { exerciseId: 'barbell-row', targetSets: 4, targetReps: '8-10' },
          { exerciseId: 'pull-ups', targetSets: 3, targetReps: '8-12' },
          { exerciseId: 'lat-pulldown', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'face-pulls', targetSets: 4, targetReps: '15-20' },
          { exerciseId: 'barbell-curl', targetSets: 3, targetReps: '8-10' },
          { exerciseId: 'hammer-curl', targetSets: 3, targetReps: '10-12' },
        ],
      },
      {
        dayName: 'Legs Day 2',
        dayNumber: 6,
        exercises: [
          { exerciseId: 'barbell-squat', targetSets: 4, targetReps: '8-10' },
          { exerciseId: 'romanian-deadlift', targetSets: 3, targetReps: '8-10' },
          { exerciseId: 'leg-press', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'leg-curl', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'leg-extension', targetSets: 3, targetReps: '12-15' },
          { exerciseId: 'calf-raises-standing', targetSets: 4, targetReps: '12-15' },
          { exerciseId: 'hip-thrust', targetSets: 3, targetReps: '10-12' },
        ],
      },
    ],
  },

  // PLAN 2: Upper / Lower (4-Day)
  {
    id: 'upper-lower-4-day',
    name: 'Upper / Lower Split (4-Day)',
    description: 'A balanced 4-day split alternating upper body push/pull with heavy lower body compound movements for optimal strength and hypertrophy.',
    type: 'pre-built',
    split: 'upper_lower',
    daysPerWeek: 4,
    days: [
      {
        dayName: 'Upper Body A',
        dayNumber: 1,
        exercises: [
          { exerciseId: 'barbell-bench-press', targetSets: 4, targetReps: '6-8' },
          { exerciseId: 'barbell-row', targetSets: 4, targetReps: '6-8' },
          { exerciseId: 'overhead-press', targetSets: 3, targetReps: '8-10' },
          { exerciseId: 'pull-ups', targetSets: 3, targetReps: '8-12' },
          { exerciseId: 'lateral-raises', targetSets: 3, targetReps: '12-15' },
          { exerciseId: 'barbell-curl', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'tricep-pushdown', targetSets: 3, targetReps: '10-12' },
        ],
      },
      {
        dayName: 'Lower Body A',
        dayNumber: 2,
        exercises: [
          { exerciseId: 'barbell-squat', targetSets: 4, targetReps: '6-8' },
          { exerciseId: 'romanian-deadlift', targetSets: 3, targetReps: '8-10' },
          { exerciseId: 'leg-press', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'leg-curl', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'calf-raises-standing', targetSets: 4, targetReps: '12-15' },
          { exerciseId: 'plank', targetSets: 3, targetReps: '60s', notes: 'Hold for 60s per set' },
        ],
      },
      {
        dayName: 'Upper Body B',
        dayNumber: 3,
        exercises: [
          { exerciseId: 'incline-dumbbell-press', targetSets: 4, targetReps: '8-10' },
          { exerciseId: 'dumbbell-row', targetSets: 4, targetReps: '8-10' },
          { exerciseId: 'dumbbell-shoulder-press', targetSets: 3, targetReps: '8-10' },
          { exerciseId: 'lat-pulldown', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'cable-flyes', targetSets: 3, targetReps: '12-15' },
          { exerciseId: 'hammer-curl', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'skull-crushers', targetSets: 3, targetReps: '10-12' },
        ],
      },
      {
        dayName: 'Lower Body B',
        dayNumber: 4,
        exercises: [
          { exerciseId: 'front-squat', targetSets: 4, targetReps: '8-10' },
          { exerciseId: 'hip-thrust', targetSets: 4, targetReps: '8-10' },
          { exerciseId: 'bulgarian-split-squat', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'leg-extension', targetSets: 3, targetReps: '12-15' },
          { exerciseId: 'leg-curl', targetSets: 3, targetReps: '12-15' },
          { exerciseId: 'calf-raises-seated', targetSets: 4, targetReps: '12-15' },
          { exerciseId: 'hanging-leg-raise', targetSets: 3, targetReps: '12-15' },
        ],
      },
    ],
  },

  // PLAN 3: Full Body (3-Day)
  {
    id: 'full-body-3-day',
    name: 'Full Body Blast (3-Day)',
    description: 'An efficient 3-day full body split ideal for building overall strength and muscular endurance with complete rest days in between.',
    type: 'pre-built',
    split: 'full_body',
    daysPerWeek: 3,
    days: [
      {
        dayName: 'Full Body Workout 1',
        dayNumber: 1,
        exercises: [
          { exerciseId: 'barbell-squat', targetSets: 4, targetReps: '6-8' },
          { exerciseId: 'barbell-bench-press', targetSets: 4, targetReps: '6-8' },
          { exerciseId: 'barbell-row', targetSets: 4, targetReps: '8-10' },
          { exerciseId: 'overhead-press', targetSets: 3, targetReps: '8-10' },
          { exerciseId: 'barbell-curl', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'plank', targetSets: 3, targetReps: '60s', notes: 'Hold for 60s per set' },
        ],
      },
      {
        dayName: 'Full Body Workout 2',
        dayNumber: 2,
        exercises: [
          { exerciseId: 'deadlift', targetSets: 3, targetReps: '5' },
          { exerciseId: 'incline-dumbbell-press', targetSets: 4, targetReps: '8-10' },
          { exerciseId: 'pull-ups', targetSets: 3, targetReps: '8-12' },
          { exerciseId: 'lateral-raises', targetSets: 4, targetReps: '12-15' },
          { exerciseId: 'tricep-pushdown', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'hanging-leg-raise', targetSets: 3, targetReps: '12-15' },
        ],
      },
      {
        dayName: 'Full Body Workout 3',
        dayNumber: 3,
        exercises: [
          { exerciseId: 'leg-press', targetSets: 4, targetReps: '10-12' },
          { exerciseId: 'dumbbell-bench-press', targetSets: 4, targetReps: '8-10' },
          { exerciseId: 'seated-cable-row', targetSets: 4, targetReps: '10-12' },
          { exerciseId: 'arnold-press', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'hammer-curl', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'cable-crunch', targetSets: 3, targetReps: '15-20' },
        ],
      },
    ],
  },

  // PLAN 4: 5-Day Bro Split
  {
    id: 'bro-split-5-day',
    name: '5-Day Bro Split',
    description: 'A classic single-muscle group focus per day to maximize volume, localized pump, and hypertrophy for advanced bodybuilders.',
    type: 'pre-built',
    split: 'bro_split',
    daysPerWeek: 5,
    days: [
      {
        dayName: 'Chest Day',
        dayNumber: 1,
        exercises: [
          { exerciseId: 'barbell-bench-press', targetSets: 4, targetReps: '6-8' },
          { exerciseId: 'incline-barbell-bench-press', targetSets: 3, targetReps: '8-10' },
          { exerciseId: 'dumbbell-flyes', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'cable-flyes', targetSets: 3, targetReps: '12-15' },
          { exerciseId: 'chest-dips', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'pec-deck', targetSets: 3, targetReps: '12-15' },
        ],
      },
      {
        dayName: 'Back Day',
        dayNumber: 2,
        exercises: [
          { exerciseId: 'deadlift', targetSets: 4, targetReps: '5' },
          { exerciseId: 'pull-ups', targetSets: 4, targetReps: '8-12' },
          { exerciseId: 'barbell-row', targetSets: 4, targetReps: '8-10' },
          { exerciseId: 'lat-pulldown', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'seated-cable-row', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'straight-arm-pulldown', targetSets: 3, targetReps: '12-15' },
        ],
      },
      {
        dayName: 'Shoulders Day',
        dayNumber: 3,
        exercises: [
          { exerciseId: 'overhead-press', targetSets: 4, targetReps: '6-8' },
          { exerciseId: 'arnold-press', targetSets: 3, targetReps: '8-10' },
          { exerciseId: 'lateral-raises', targetSets: 4, targetReps: '12-15' },
          { exerciseId: 'front-raises', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'rear-delt-flyes', targetSets: 4, targetReps: '12-15' },
          { exerciseId: 'face-pulls', targetSets: 4, targetReps: '15-20' },
        ],
      },
      {
        dayName: 'Legs Day',
        dayNumber: 4,
        exercises: [
          { exerciseId: 'barbell-squat', targetSets: 4, targetReps: '6-8' },
          { exerciseId: 'romanian-deadlift', targetSets: 4, targetReps: '8-10' },
          { exerciseId: 'leg-press', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'leg-extension', targetSets: 3, targetReps: '12-15' },
          { exerciseId: 'leg-curl', targetSets: 3, targetReps: '12-15' },
          { exerciseId: 'calf-raises-standing', targetSets: 4, targetReps: '12-15' },
          { exerciseId: 'hip-thrust', targetSets: 3, targetReps: '10-12' },
        ],
      },
      {
        dayName: 'Arms Day',
        dayNumber: 5,
        exercises: [
          { exerciseId: 'barbell-curl', targetSets: 4, targetReps: '8-10' },
          { exerciseId: 'hammer-curl', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'preacher-curl', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'tricep-pushdown', targetSets: 4, targetReps: '10-12' },
          { exerciseId: 'skull-crushers', targetSets: 3, targetReps: '10-12' },
          { exerciseId: 'overhead-tricep-extension', targetSets: 3, targetReps: '10-12' },
        ],
      },
    ],
  },
];
