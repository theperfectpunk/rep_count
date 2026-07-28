/**
 * Calculate total volume for a set
 */
export function calculateSetVolume(reps: number, weight: number): number {
  return reps * weight;
}

/**
 * Calculate estimated 1RM using Epley formula
 */
export function calculateOneRepMax(weight: number, reps: number): number {
  if (reps === 1) return weight;
  return Math.round(weight * (1 + reps / 30));
}

/**
 * Convert weight between kg and lbs
 */
export function convertWeight(weight: number, from: 'kg' | 'lbs', to: 'kg' | 'lbs'): number {
  if (from === to) return weight;
  if (from === 'kg' && to === 'lbs') return Math.round(weight * 2.20462 * 10) / 10;
  return Math.round(weight / 2.20462 * 10) / 10;
}

/**
 * Check if a set is a personal record compared to previous sets
 */
export function isPR(
  weight: number,
  reps: number,
  previousBest: { weight: number; reps: number } | null
): boolean {
  if (!previousBest) return true;
  const currentOneRM = calculateOneRepMax(weight, reps);
  const previousOneRM = calculateOneRepMax(previousBest.weight, previousBest.reps);
  return currentOneRM > previousOneRM;
}
