import React from 'react';
import {
  View,
  Text,
  ScrollView,
  Pressable,
  ActivityIndicator,
  Alert,
  SafeAreaView,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import { prebuiltPlans, WorkoutPlan } from '../../src/data/prebuiltPlans';
import { getExerciseById } from '../../src/data/exercises';
import { useCustomPlan, useDeletePlan, useSetActivePlan } from '../../src/hooks/useWorkoutPlans';
import { useAuth } from '../../src/hooks/useAuth';
import { useSettingsStore } from '../../src/stores/settingsStore';
import { useWorkoutStore } from '../../src/stores/workoutStore';
import { CustomWorkoutPlan } from '../../src/services/planService';

export default function PlanDetailScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{ id: string }>();
  const id = Array.isArray(params.id) ? params.id[0] : params.id;

  const { user } = useAuth();
  const userId = user?.uid || 'demo-user';

  const activePlanId = useSettingsStore((state) => state.activePlanId);
  const setActivePlanIdStore = useSettingsStore((state) => state.setActivePlanId);

  const { mutate: deletePlanMutation, isPending: isDeleting } = useDeletePlan();
  const { mutate: setActivePlanMutation } = useSetActivePlan();

  // 1. Check if it's a pre-built plan
  const prebuiltPlan = prebuiltPlans.find((p) => p.id === id);

  // 2. Otherwise fetch custom plan from Firestore
  const { data: customPlan, isLoading: isLoadingCustom } = useCustomPlan(
    !prebuiltPlan && id ? id : undefined
  );

  const plan: WorkoutPlan | CustomWorkoutPlan | undefined = prebuiltPlan || (customPlan || undefined);
  const isCustom = plan?.type === 'custom';
  const isActive = activePlanId === id || (plan as CustomWorkoutPlan)?.isActive === true;

  const handleToggleActive = () => {
    if (!plan || !id) return;
    const newActiveState = !isActive;
    const targetPlanId = newActiveState ? id : null;
    setActivePlanIdStore(targetPlanId);

    if (userId && id) {
      setActivePlanMutation({ userId, planId: id });
    }
  };

  const handleDelete = () => {
    if (!id || !isCustom) return;
    Alert.alert(
      'Delete Custom Plan',
      'Are you sure you want to delete this workout plan? This action cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: () => {
            deletePlanMutation(id, {
              onSuccess: () => {
                if (activePlanId === id) {
                  setActivePlanIdStore(null);
                }
                router.back();
              },
            });
          },
        },
      ]
    );
  };

  const handleStartDay = (dayName: string, exercises: { exerciseId: string; targetSets: number; targetReps: string }[]) => {
    if (!plan) return;

    const store = useWorkoutStore.getState();
    // 1. Start workout
    store.startWorkout(dayName, plan.id, dayName);

    // 2. Add each exercise and its sets
    exercises.forEach((planEx) => {
      const exDetails = getExerciseById(planEx.exerciseId);
      const name = exDetails?.name || planEx.exerciseId;
      const muscleGroup = exDetails?.muscleGroup || 'other';

      // addExercise creates 1 set by default
      store.addExercise(planEx.exerciseId, name, muscleGroup);
      const currentExercises = useWorkoutStore.getState().exercises;
      const exIdx = currentExercises.length - 1;

      // Add remaining sets (targetSets - 1)
      const numSetsToAdd = Math.max(0, planEx.targetSets - 1);
      for (let i = 0; i < numSetsToAdd; i++) {
        store.addSet(exIdx);
      }
    });

    // 3. Navigate to active workout screen
    router.push('/workout/active');
  };

  if (!prebuiltPlan && isLoadingCustom) {
    return (
      <SafeAreaView className="flex-1 bg-[#0A0A0F] items-center justify-center">
        <ActivityIndicator size="large" color="#6C5CE7" />
        <Text className="text-[#8888A0] text-sm mt-3">Loading plan details...</Text>
      </SafeAreaView>
    );
  }

  if (!plan) {
    return (
      <SafeAreaView className="flex-1 bg-[#0A0A0F] p-5 items-center justify-center">
        <Text className="text-xl font-bold text-[#F0F0F5] mb-2">Plan Not Found</Text>
        <Text className="text-sm text-[#8888A0] mb-6 text-center">
          The requested workout plan does not exist or was deleted.
        </Text>
        <Pressable
          onPress={() => router.back()}
          className="bg-[#6C5CE7] px-6 py-3 rounded-xl"
        >
          <Text className="text-white font-bold text-sm">Go Back</Text>
        </Pressable>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView className="flex-1 bg-[#0A0A0F]">
      {/* Top Header */}
      <View className="px-5 pt-3 pb-3 flex-row items-center justify-between border-b border-[#1E1E2E]">
        <Pressable
          onPress={() => router.back()}
          className="w-10 h-10 rounded-full bg-[#14141F] items-center justify-center border border-[#1E1E2E] active:opacity-80"
        >
          <SymbolView
            name={{ ios: 'chevron.left', android: 'arrow_back', web: 'arrow_back' }}
            tintColor="#F0F0F5"
            size={20}
          />
        </Pressable>

        <Text className="text-base font-bold text-[#F0F0F5] flex-1 text-center mx-2" numberOfLines={1}>
          {plan.name}
        </Text>

        {isCustom ? (
          <Pressable
            onPress={handleDelete}
            disabled={isDeleting}
            className="w-10 h-10 rounded-full bg-[#FF5252]/15 items-center justify-center border border-[#FF5252]/30 active:opacity-80"
          >
            <SymbolView
              name={{ ios: 'trash', android: 'delete', web: 'delete' }}
              tintColor="#FF5252"
              size={18}
            />
          </Pressable>
        ) : (
          <View className="w-10" />
        )}
      </View>

      <ScrollView
        className="flex-1 px-5 pt-4"
        contentContainerStyle={{ paddingBottom: 120 }}
        showsVerticalScrollIndicator={false}
      >
        {/* Banner Section */}
        <View className="bg-[#14141F] rounded-2xl p-5 mb-6 border border-[#1E1E2E]">
          <View className="flex-row items-center justify-between mb-3">
            <View className="flex-row items-center gap-2">
              <View
                className={`px-3 py-1 rounded-full ${
                  isCustom ? 'bg-[#00E676]/15 border border-[#00E676]/30' : 'bg-[#6C5CE7]/15 border border-[#6C5CE7]/30'
                }`}
              >
                <Text className={`text-xs font-semibold ${isCustom ? 'text-[#00E676]' : 'text-[#6C5CE7]'}`}>
                  {isCustom ? 'Custom Plan' : 'Pre-built Plan'}
                </Text>
              </View>
              <View className="bg-[#1E1E2E] px-2.5 py-1 rounded-md">
                <Text className="text-xs text-[#8888A0] font-medium">
                  {plan.daysPerWeek} Days / Week
                </Text>
              </View>
            </View>
          </View>

          <Text className="text-2xl font-bold text-[#F0F0F5] mb-2">{plan.name}</Text>
          <Text className="text-sm text-[#8888A0] leading-6 mb-5">{plan.description}</Text>

          {/* Set Active Toggle Button */}
          <Pressable
            onPress={handleToggleActive}
            className={`py-3.5 px-4 rounded-xl flex-row items-center justify-center border ${
              isActive
                ? 'bg-[#00E676]/20 border-[#00E676]/50'
                : 'bg-[#6C5CE7] border-[#6C5CE7]'
            } active:opacity-90 shadow-md`}
          >
            <SymbolView
              name={{
                ios: isActive ? 'checkmark.circle.fill' : 'star.fill',
                android: isActive ? 'check_circle' : 'star',
                web: isActive ? 'check_circle' : 'star',
              }}
              tintColor={isActive ? '#00E676' : '#FFFFFF'}
              size={20}
            />
            <Text
              className={`font-bold text-sm ml-2.5 ${
                isActive ? 'text-[#00E676]' : 'text-white'
              }`}
            >
              {isActive ? 'Active Plan' : 'Set as Active Plan'}
            </Text>
          </Pressable>
        </View>

        {/* Day-by-Day Breakdown */}
        <Text className="text-xs font-semibold text-[#8888A0] uppercase tracking-wider mb-4">
          Routine Breakdown ({plan.days.length} Days)
        </Text>

        {plan.days.map((day, dIdx) => (
          <View
            key={day.dayName + dIdx}
            className="bg-[#14141F] rounded-2xl p-5 mb-5 border border-[#1E1E2E]"
          >
            {/* Day Header */}
            <View className="flex-row items-center justify-between mb-4 pb-3 border-b border-[#1E1E2E]">
              <View className="flex-row items-center">
                <View className="w-8 h-8 rounded-lg bg-[#6C5CE7]/20 items-center justify-center mr-3 border border-[#6C5CE7]/40">
                  <Text className="text-xs font-bold text-[#6C5CE7]">{dIdx + 1}</Text>
                </View>
                <View>
                  <Text className="text-lg font-bold text-[#F0F0F5]">{day.dayName}</Text>
                  <Text className="text-xs text-[#8888A0]">
                    {day.exercises?.length || 0} exercises
                  </Text>
                </View>
              </View>
            </View>

            {/* Exercise List */}
            <View className="mb-4">
              {day.exercises?.map((planEx, exIdx) => {
                const exDetails = getExerciseById(planEx.exerciseId);
                const muscleGroup = exDetails?.muscleGroup || 'custom';
                const exName = exDetails?.name || planEx.exerciseId;

                return (
                  <View
                    key={planEx.exerciseId + exIdx}
                    className={`py-3 ${
                      exIdx < day.exercises.length - 1 ? 'border-b border-[#1E1E2E]' : ''
                    }`}
                  >
                    <View className="flex-row items-center justify-between mb-1">
                      <Text className="text-base font-semibold text-[#F0F0F5] flex-1 mr-2">
                        {exName}
                      </Text>
                      <View className="bg-[#1E1E2E] px-2.5 py-1 rounded-md border border-[#8888A0]/20">
                        <Text className="text-xs font-semibold text-[#6C5CE7]">
                          {planEx.targetSets} × {planEx.targetReps}
                        </Text>
                      </View>
                    </View>

                    <View className="flex-row items-center flex-wrap gap-2">
                      <View className="bg-[#6C5CE7]/10 px-2 py-0.5 rounded">
                        <Text className="text-[11px] font-medium text-[#A29BFE] uppercase">
                          {muscleGroup}
                        </Text>
                      </View>

                      {planEx.notes && (
                        <Text className="text-xs text-[#8888A0] italic">
                          Note: {planEx.notes}
                        </Text>
                      )}
                    </View>
                  </View>
                );
              })}
            </View>

            {/* Start Day Button */}
            <Pressable
              onPress={() => handleStartDay(day.dayName, day.exercises)}
              className="bg-[#1E1E2E] py-3 px-4 rounded-xl flex-row items-center justify-center border border-[#6C5CE7]/40 active:bg-[#6C5CE7]"
            >
              <SymbolView
                name={{ ios: 'play.fill', android: 'play_arrow', web: 'play_arrow' }}
                tintColor="#FFFFFF"
                size={16}
              />
              <Text className="text-white font-bold text-sm ml-2">Start This Day</Text>
            </Pressable>
          </View>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}
