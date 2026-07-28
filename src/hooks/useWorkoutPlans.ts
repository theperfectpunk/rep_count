import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getUserPlans, saveCustomPlan, deletePlan, setActivePlan, getCustomPlan, CustomWorkoutPlan } from '../services/planService';

export function useUserPlans(userId: string | undefined) {
  return useQuery({
    queryKey: ['userPlans', userId],
    queryFn: () => getUserPlans(userId!),
    enabled: !!userId,
  });
}

export function useCustomPlan(planId: string | undefined) {
  return useQuery({
    queryKey: ['customPlan', planId],
    queryFn: () => getCustomPlan(planId!),
    enabled: !!planId,
  });
}

export function useSaveCustomPlan() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: saveCustomPlan,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['userPlans'] });
    },
  });
}

export function useDeletePlan() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: deletePlan,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['userPlans'] });
      queryClient.invalidateQueries({ queryKey: ['customPlan'] });
    },
  });
}

export function useSetActivePlan() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ userId, planId }: { userId: string; planId: string }) => setActivePlan(userId, planId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['userPlans'] });
      queryClient.invalidateQueries({ queryKey: ['activePlan'] });
    },
  });
}
