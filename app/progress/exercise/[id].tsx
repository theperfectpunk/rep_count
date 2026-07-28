import React, { useMemo } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useQuery } from '@tanstack/react-query';

import { useAuth } from '../../../src/hooks/useAuth';
import { useSettingsStore } from '../../../src/stores/settingsStore';
import { getWorkoutsByDateRange, WorkoutSession } from '../../../src/services/workoutService';
import { getExerciseById } from '../../../src/data/exercises';
import { calculateOneRepMax } from '../../../src/utils/calculations';
import { formatWeight, formatRelativeDate } from '../../../src/utils/formatters';
import { ProgressLineChart, ProgressDataPoint } from '../../../src/components/charts/ProgressLineChart';

const MUSCLE_BADGE_COLORS: Record<string, { bg: string; border: string; text: string }> = {
  chest: { bg: 'bg-[#FF5252]/15', border: 'border-[#FF5252]/40', text: 'text-[#FF5252]' },
  back: { bg: 'bg-[#3B82F6]/15', border: 'border-[#3B82F6]/40', text: 'text-[#3B82F6]' },
  legs: { bg: 'bg-[#10B981]/15', border: 'border-[#10B981]/40', text: 'text-[#10B981]' },
  shoulders: { bg: 'bg-[#F59E0B]/15', border: 'border-[#F59E0B]/40', text: 'text-[#F59E0B]' },
  arms: { bg: 'bg-[#8B5CF6]/15', border: 'border-[#8B5CF6]/40', text: 'text-[#8B5CF6]' },
  core: { bg: 'bg-[#EC4899]/15', border: 'border-[#EC4899]/40', text: 'text-[#EC4899]' },
};

function parseSessionDate(session: WorkoutSession): Date {
  if (session.finishedAt) {
    if (typeof session.finishedAt.toDate === 'function') return session.finishedAt.toDate();
    if (session.finishedAt.seconds) return new Date(session.finishedAt.seconds * 1000);
    return new Date(session.finishedAt);
  }
  if (session.startedAt) {
    if (typeof session.startedAt.toDate === 'function') return session.startedAt.toDate();
    if (session.startedAt.seconds) return new Date(session.startedAt.seconds * 1000);
    return new Date(session.startedAt);
  }
  return new Date();
}

export default function ExerciseProgressDetailScreen() {
  const router = useRouter();
  const { id } = useLocalSearchParams<{ id: string }>();
  const { user } = useAuth();
  const { unit } = useSettingsStore();

  const exercise = getExerciseById(id || '');

  // Query workouts range for 1 year
  const dateRange = useMemo(() => {
    const end = new Date();
    end.setHours(23, 59, 59, 999);
    const start = new Date();
    start.setFullYear(end.getFullYear() - 1);
    start.setHours(0, 0, 0, 0);
    return { start, end };
  }, []);

  const { data: sessions = [], isLoading } = useQuery({
    queryKey: ['exerciseProgressDetail', user?.uid, id],
    queryFn: () => getWorkoutsByDateRange(user!.uid, dateRange.start, dateRange.end),
    enabled: !!user?.uid && !!id,
  });

  // Extract history entries and compute stats
  const { historyLog, chartData, stats } = useMemo(() => {
    let est1RM = 0;
    let maxWeight = 0;
    let maxReps = 0;
    let totalSets = 0;

    const log: Array<{
      sessionId: string;
      workoutName: string;
      date: Date;
      sets: Array<{ setNumber: number; weight: number; reps: number; isWarmup?: boolean; isPR?: boolean }>;
    }> = [];

    const dateMap = new Map<string, { dateStr: string; dateObj: Date; maxWeight: number; max1RM: number }>();

    // Process sessions chronologically for chart, but log newest first
    const sortedChronological = [...sessions].sort(
      (a, b) => parseSessionDate(a).getTime() - parseSessionDate(b).getTime()
    );

    sortedChronological.forEach((session) => {
      if (!session.exercises || !Array.isArray(session.exercises)) return;
      const matchingEx = session.exercises.find((ex: any) => ex.exerciseId === id);
      if (!matchingEx || !matchingEx.sets || !Array.isArray(matchingEx.sets)) return;

      const dateObj = parseSessionDate(session);
      const dateKey = dateObj.toISOString().split('T')[0];
      const dateStr = dateObj.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });

      let sessionMaxW = 0;
      let sessionMax1RM = 0;
      const validSets: Array<{ setNumber: number; weight: number; reps: number; isWarmup?: boolean; isPR?: boolean }> = [];

      matchingEx.sets.forEach((set: any, idx: number) => {
        if (set.isCompleted === false) return;
        const w = Number(set.weight) || 0;
        const r = Number(set.reps) || 0;
        if (w > 0 && r > 0) {
          totalSets++;
          const set1RM = calculateOneRepMax(w, r);
          if (w > maxWeight) maxWeight = w;
          if (r > maxReps) maxReps = r;
          if (set1RM > est1RM) est1RM = set1RM;

          if (w > sessionMaxW) sessionMaxW = w;
          if (set1RM > sessionMax1RM) sessionMax1RM = set1RM;

          validSets.push({
            setNumber: set.setNumber || idx + 1,
            weight: w,
            reps: r,
            isWarmup: !!set.isWarmup,
            isPR: !!set.isPR,
          });
        }
      });

      if (validSets.length > 0) {
        log.push({
          sessionId: session.id || `s_${Date.now()}_${Math.random()}`,
          workoutName: session.workoutName || 'Workout',
          date: dateObj,
          sets: validSets,
        });

        dateMap.set(dateKey, {
          dateStr,
          dateObj,
          maxWeight: sessionMaxW,
          max1RM: sessionMax1RM,
        });
      }
    });

    // Build chart data array
    const chart: ProgressDataPoint[] = Array.from(dateMap.values()).map((d) => ({
      date: d.dateStr,
      weight: d.maxWeight,
      oneRM: d.max1RM,
    }));

    // Sort log newest first
    log.sort((a, b) => b.date.getTime() - a.date.getTime());

    return {
      historyLog: log,
      chartData: chart,
      stats: {
        est1RM,
        maxWeight,
        maxReps,
        totalSets,
      },
    };
  }, [sessions, id]);

  if (!exercise) {
    return (
      <SafeAreaView className="flex-1 bg-[#0A0A0F] items-center justify-center p-4">
        <Ionicons name="alert-circle" size={48} color="#FF5252" />
        <Text className="text-[#F0F0F5] text-lg font-bold mt-2">Exercise Not Found</Text>
        <TouchableOpacity
          onPress={() => router.back()}
          className="mt-4 bg-[#1E1E2E] px-4 py-2 rounded-xl border border-[#6C5CE7]"
        >
          <Text className="text-[#6C5CE7] font-bold">Go Back</Text>
        </TouchableOpacity>
      </SafeAreaView>
    );
  }

  const badgeTheme =
    MUSCLE_BADGE_COLORS[exercise.muscleGroup.toLowerCase()] || {
      bg: 'bg-[#6C5CE7]/15',
      border: 'border-[#6C5CE7]/40',
      text: 'text-[#6C5CE7]',
    };

  return (
    <SafeAreaView className="flex-1 bg-[#0A0A0F]">
      {/* Top Header Bar */}
      <View className="flex-row items-center justify-between px-4 py-3 border-b border-[#1E1E2E]">
        <TouchableOpacity
          activeOpacity={0.7}
          onPress={() => router.back()}
          className="w-9 h-9 rounded-full bg-[#14141F] border border-[#1E1E2E] items-center justify-center"
        >
          <Ionicons name="arrow-back" size={20} color="#F0F0F5" />
        </TouchableOpacity>

        <Text className="text-[#F0F0F5] text-base font-bold flex-1 text-center mx-2" numberOfLines={1}>
          {exercise.name}
        </Text>

        <View className="w-9 h-9" />
      </View>

      <ScrollView className="flex-1 px-4 pt-4" contentContainerStyle={{ paddingBottom: 40 }}>
        {/* Header Badge Card */}
        <View className="bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-5 mb-5">
          <Text className="text-[#F0F0F5] text-2xl font-black mb-2">{exercise.name}</Text>
          
          <View className="flex-row items-center gap-2 mb-3">
            <View className={`px-2.5 py-1 rounded-lg border ${badgeTheme.bg} ${badgeTheme.border}`}>
              <Text className={`text-xs font-bold uppercase ${badgeTheme.text}`}>
                {exercise.muscleGroup}
              </Text>
            </View>
            <View className="px-2.5 py-1 rounded-lg border bg-[#1E1E2E] border-[#8888A0]/30">
              <Text className="text-[#8888A0] text-xs font-medium capitalize">
                {exercise.equipment}
              </Text>
            </View>
          </View>

          <Text className="text-[#8888A0] text-xs leading-5">
            {exercise.description}
          </Text>
        </View>

        {/* All-Time Stats Card */}
        <View className="mb-6">
          <Text className="text-[#F0F0F5] text-lg font-bold mb-3">All-Time Statistics</Text>
          
          <View className="flex-row flex-wrap gap-3">
            <View className="flex-1 min-w-[45%] bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-4">
              <View className="w-8 h-8 rounded-full bg-[#00E676]/15 items-center justify-center mb-2">
                <Ionicons name="trophy" size={16} color="#00E676" />
              </View>
              <Text className="text-[#8888A0] text-xs font-medium">Est. 1RM</Text>
              <Text className="text-[#00E676] text-xl font-black mt-1">
                {stats.est1RM > 0 ? formatWeight(stats.est1RM, unit) : '--'}
              </Text>
            </View>

            <View className="flex-1 min-w-[45%] bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-4">
              <View className="w-8 h-8 rounded-full bg-[#6C5CE7]/15 items-center justify-center mb-2">
                <Ionicons name="barbell" size={16} color="#6C5CE7" />
              </View>
              <Text className="text-[#8888A0] text-xs font-medium">Max Weight</Text>
              <Text className="text-[#F0F0F5] text-xl font-black mt-1">
                {stats.maxWeight > 0 ? formatWeight(stats.maxWeight, unit) : '--'}
              </Text>
            </View>

            <View className="flex-1 min-w-[45%] bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-4">
              <View className="w-8 h-8 rounded-full bg-[#A29BFE]/15 items-center justify-center mb-2">
                <Ionicons name="repeat" size={16} color="#A29BFE" />
              </View>
              <Text className="text-[#8888A0] text-xs font-medium">Max Reps</Text>
              <Text className="text-[#F0F0F5] text-xl font-black mt-1">
                {stats.maxReps > 0 ? `${stats.maxReps} reps` : '--'}
              </Text>
            </View>

            <View className="flex-1 min-w-[45%] bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-4">
              <View className="w-8 h-8 rounded-full bg-[#FFD600]/15 items-center justify-center mb-2">
                <Ionicons name="layers" size={16} color="#FFD600" />
              </View>
              <Text className="text-[#8888A0] text-xs font-medium">Total Sets</Text>
              <Text className="text-[#F0F0F5] text-xl font-black mt-1">
                {stats.totalSets > 0 ? stats.totalSets : '--'}
              </Text>
            </View>
          </View>
        </View>

        {/* 1RM Progression Chart */}
        <View className="mb-6">
          <Text className="text-[#F0F0F5] text-lg font-bold mb-3">1RM Growth History</Text>
          <ProgressLineChart
            data={chartData}
            metric="oneRM"
            unit={unit}
            title={`${exercise.name} 1RM`}
          />
        </View>

        {/* History Log */}
        <View className="mb-4">
          <Text className="text-[#F0F0F5] text-lg font-bold mb-3">Workout Set History</Text>

          {isLoading && (
            <View className="py-8 items-center">
              <ActivityIndicator size="small" color="#6C5CE7" />
              <Text className="text-[#8888A0] text-xs mt-2">Loading set history...</Text>
            </View>
          )}

          {!isLoading && historyLog.length === 0 && (
            <View className="bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-6 items-center">
              <Ionicons name="journal-outline" size={28} color="#8888A0" />
              <Text className="text-[#F0F0F5] text-sm font-semibold mt-2">No Past Workout Logs</Text>
              <Text className="text-[#8888A0] text-xs text-center mt-1">
                Logs will appear here once you perform and finish sets of {exercise.name}.
              </Text>
            </View>
          )}

          {!isLoading &&
            historyLog.map((logItem) => (
              <View
                key={logItem.sessionId}
                className="bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-4 mb-3"
              >
                <View className="flex-row justify-between items-center pb-2.5 border-b border-[#1E1E2E]">
                  <View>
                    <Text className="text-[#F0F0F5] text-sm font-bold">{logItem.workoutName}</Text>
                    <Text className="text-[#8888A0] text-xs mt-0.5">
                      {formatRelativeDate(logItem.date)} ({logItem.date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })})
                    </Text>
                  </View>
                  <View className="bg-[#1E1E2E] px-2.5 py-1 rounded-full">
                    <Text className="text-[#A29BFE] text-xs font-semibold">
                      {logItem.sets.length} {logItem.sets.length === 1 ? 'set' : 'sets'}
                    </Text>
                  </View>
                </View>

                {/* Table Header */}
                <View className="flex-row justify-between pt-2.5 pb-1 px-1">
                  <Text className="text-[#8888A0] text-[11px] font-semibold w-12 text-center">Set</Text>
                  <Text className="text-[#8888A0] text-[11px] font-semibold flex-1 text-center">Weight</Text>
                  <Text className="text-[#8888A0] text-[11px] font-semibold flex-1 text-center">Reps</Text>
                  <Text className="text-[#8888A0] text-[11px] font-semibold flex-1 text-center">Est. 1RM</Text>
                </View>

                {/* Set Rows */}
                {logItem.sets.map((set) => {
                  const set1RM = calculateOneRepMax(set.weight, set.reps);
                  return (
                    <View
                      key={set.setNumber}
                      className="flex-row justify-between items-center py-2 px-1 border-t border-[#1E1E2E]/40"
                    >
                      <View className="w-12 items-center flex-row justify-center">
                        <Text className="text-[#8888A0] text-xs font-medium">{set.setNumber}</Text>
                        {set.isWarmup && (
                          <Text className="text-[#FFD600] text-[9px] font-bold ml-1">W</Text>
                        )}
                      </View>

                      <Text className="text-[#F0F0F5] text-xs font-bold flex-1 text-center">
                        {set.weight} {unit}
                      </Text>

                      <Text className="text-[#F0F0F5] text-xs font-bold flex-1 text-center">
                        {set.reps}
                      </Text>

                      <View className="flex-1 items-center flex-row justify-center">
                        <Text className="text-[#00E676] text-xs font-bold">
                          {set1RM} {unit}
                        </Text>
                        {set.isPR && (
                          <View className="bg-[#FFD600]/20 px-1 py-0.2 rounded ml-1">
                            <Text className="text-[#FFD600] text-[8px] font-black">PR</Text>
                          </View>
                        )}
                      </View>
                    </View>
                  );
                })}
              </View>
            ))}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}
