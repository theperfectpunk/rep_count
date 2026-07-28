import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

import { useAuth } from '../../src/hooks/useAuth';
import {
  useRecentWorkouts,
  useTotalStats,
  useWorkoutsThisWeek,
} from '../../src/hooks/useWorkoutSessions';
import { useSettingsStore } from '../../src/stores/settingsStore';
import { useWorkoutStore } from '../../src/stores/workoutStore';
import { StatsCard } from '../../src/components/StatsCard';
import { WorkoutSummaryCard } from '../../src/components/WorkoutSummaryCard';
import { WorkoutSession } from '../../src/services/workoutService';
import { formatWeight } from '../../src/utils/formatters';

export default function HomeScreen() {
  const router = useRouter();
  const { user, profile, loading: authLoading } = useAuth();
  const { unit } = useSettingsStore();
  const { isActive, startWorkout } = useWorkoutStore();

  const [refreshing, setRefreshing] = useState(false);

  const userId = user?.uid;

  const {
    data: recentWorkouts,
    isLoading: recentLoading,
    refetch: refetchRecent,
  } = useRecentWorkouts(userId);

  const {
    data: totalStats,
    isLoading: statsLoading,
    refetch: refetchStats,
  } = useTotalStats(userId);

  const {
    data: thisWeekWorkouts,
    isLoading: weekLoading,
    refetch: refetchWeek,
  } = useWorkoutsThisWeek(userId);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await Promise.all([refetchRecent(), refetchStats(), refetchWeek()]);
    setRefreshing(false);
  }, [refetchRecent, refetchStats, refetchWeek]);

  const handleStartWorkout = () => {
    if (!isActive) {
      startWorkout('Quick Workout');
    }
    router.push('/workout/active');
  };

  const displayName =
    profile?.displayName || user?.displayName || user?.email?.split('@')[0] || 'Athlete';
  const streak = profile?.streak ?? 0;

  const todayDateString = new Date().toLocaleDateString('en-US', {
    weekday: 'long',
    month: 'short',
    day: 'numeric',
  });

  const workoutsThisWeekCount = thisWeekWorkouts?.length ?? 0;
  const totalVolume = totalStats?.totalVolume ?? 0;
  const formattedTotalVolume = formatWeight(totalVolume, unit);

  const isLoading = authLoading || (userId ? recentLoading || statsLoading || weekLoading : false);

  return (
    <SafeAreaView className="flex-1 bg-[#0A0A0F]" edges={['top', 'left', 'right']}>
      <ScrollView
        className="flex-1 px-4"
        contentContainerStyle={{ paddingBottom: 32 }}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor="#6C5CE7"
            colors={['#6C5CE7']}
          />
        }
      >
        {/* Header Section */}
        <View className="flex-row justify-between items-center mt-2 mb-6">
          <View>
            <Text className="text-[#F0F0F5] text-2xl font-extrabold tracking-tight">
              Hey, {displayName}! 👋
            </Text>
            <Text className="text-[#8888A0] text-sm font-medium mt-0.5">{todayDateString}</Text>
          </View>

          {/* Streak Badge */}
          <View className="flex-row items-center bg-[#14141F] border border-[#1E1E2E] px-3 py-1.5 rounded-full">
            <Text className="text-base mr-1.5">🔥</Text>
            <Text className="text-[#F0F0F5] text-sm font-bold">{streak}</Text>
            <Text className="text-[#8888A0] text-xs font-medium ml-1">days</Text>
          </View>
        </View>

        {/* Quick Stats Row */}
        <View className="flex-row space-x-3 mb-6">
          <StatsCard
            icon="calendar"
            label="This Week"
            value={workoutsThisWeekCount}
            className="mr-1.5"
          />
          <StatsCard
            icon="barbell"
            label="Total Volume"
            value={formattedTotalVolume}
            className="mx-1.5"
          />
          <StatsCard
            icon="flame"
            label="Streak"
            value={`${streak}d`}
            className="ml-1.5"
          />
        </View>

        {/* Start Workout Call to Action */}
        <TouchableOpacity
          activeOpacity={0.85}
          onPress={handleStartWorkout}
          className={`rounded-2xl p-5 mb-8 flex-row items-center justify-between shadow-lg ${
            isActive ? 'bg-[#6C5CE7] border border-[#A29BFE]' : 'bg-[#6C5CE7]'
          }`}
          style={{
            shadowColor: '#6C5CE7',
            shadowOffset: { width: 0, height: 6 },
            shadowOpacity: 0.35,
            shadowRadius: 10,
            elevation: 8,
          }}
        >
          <View className="flex-1 mr-3">
            <View className="flex-row items-center mb-1">
              {isActive && (
                <View className="w-2.5 h-2.5 rounded-full bg-[#00E676] mr-2" />
              )}
              <Text className="text-white text-xl font-extrabold tracking-wide">
                {isActive ? 'Resume Workout' : 'Start Workout'}
              </Text>
            </View>
            <Text className="text-[#A29BFE] text-xs font-medium">
              {isActive
                ? 'Your active session is waiting for you'
                : 'Log sets, reps & track your progress'}
            </Text>
          </View>

          <View className="w-12 h-12 rounded-full bg-white/20 items-center justify-center">
            <Ionicons
              name={isActive ? 'play-forward' : 'play'}
              size={24}
              color="#FFFFFF"
              style={{ marginLeft: isActive ? 0 : 3 }}
            />
          </View>
        </TouchableOpacity>

        {/* Recent Workouts Section */}
        <View className="mb-4">
          <View className="flex-row justify-between items-center mb-4">
            <Text className="text-[#F0F0F5] text-lg font-bold">Recent Workouts</Text>
            {recentWorkouts && recentWorkouts.length > 0 && (
              <TouchableOpacity onPress={() => router.push('/progress')}>
                <Text className="text-[#6C5CE7] text-xs font-semibold">See All</Text>
              </TouchableOpacity>
            )}
          </View>

          {isLoading && !refreshing ? (
            <View className="py-8 items-center justify-center">
              <ActivityIndicator size="small" color="#6C5CE7" />
              <Text className="text-[#8888A0] text-xs mt-2">Loading sessions...</Text>
            </View>
          ) : recentWorkouts && recentWorkouts.length > 0 ? (
            recentWorkouts.map((workout: WorkoutSession) => (
              <WorkoutSummaryCard
                key={workout.id || Math.random().toString()}
                workout={workout}
                unit={unit}
                onPress={() => {
                  if (workout.id) {
                    router.push(`/workout/${workout.id}`);
                  }
                }}
              />
            ))
          ) : (
            /* Empty State */
            <View className="bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-6 items-center justify-center my-2">
              <View className="w-14 h-14 rounded-2xl bg-[#1E1E2E] items-center justify-center mb-3">
                <Ionicons name="barbell-outline" size={28} color="#6C5CE7" />
              </View>
              <Text className="text-[#F0F0F5] text-base font-bold mb-1">
                No Workouts Logged Yet
              </Text>
              <Text className="text-[#8888A0] text-xs text-center mb-4 px-4 leading-5">
                Ready to crush your fitness goals? Hit the button above to start your first workout session!
              </Text>
              <TouchableOpacity
                activeOpacity={0.8}
                onPress={handleStartWorkout}
                className="bg-[#1E1E2E] border border-[#6C5CE7]/40 px-4 py-2.5 rounded-xl flex-row items-center"
              >
                <Ionicons name="add-circle-outline" size={16} color="#A29BFE" style={{ marginRight: 6 }} />
                <Text className="text-[#A29BFE] text-xs font-semibold">Start First Session</Text>
              </TouchableOpacity>
            </View>
          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}
