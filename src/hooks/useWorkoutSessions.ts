import { useQuery } from '@tanstack/react-query';
import { getRecentWorkouts, getTotalStats, getWorkoutsThisWeek } from '../services/workoutService';

export function useRecentWorkouts(userId: string | undefined) {
  return useQuery({
    queryKey: ['recentWorkouts', userId],
    queryFn: () => getRecentWorkouts(userId!, 5),
    enabled: !!userId,
  });
}

export function useTotalStats(userId: string | undefined) {
  return useQuery({
    queryKey: ['totalStats', userId],
    queryFn: () => getTotalStats(userId!),
    enabled: !!userId,
  });
}

export function useWorkoutsThisWeek(userId: string | undefined) {
  return useQuery({
    queryKey: ['workoutsThisWeek', userId],
    queryFn: () => getWorkoutsThisWeek(userId!),
    enabled: !!userId,
  });
}
