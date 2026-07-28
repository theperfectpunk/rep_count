import React, { useState, useMemo, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  TextInput,
  Modal,
  RefreshControl,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useQuery } from '@tanstack/react-query';

import { useAuth } from '../../src/hooks/useAuth';
import { useSettingsStore } from '../../src/stores/settingsStore';
import { getWorkoutsByDateRange, WorkoutSession } from '../../src/services/workoutService';
import { exercises, getExerciseById, Exercise } from '../../src/data/exercises';
import { calculateOneRepMax } from '../../src/utils/calculations';
import { formatWeight, formatNumber } from '../../src/utils/formatters';
import { VolumeChart } from '../../src/components/charts/VolumeChart';
import { ProgressLineChart, ProgressDataPoint } from '../../src/components/charts/ProgressLineChart';

const TOP_EXERCISE_IDS = [
  'barbell-bench-press',
  'barbell-squat',
  'deadlift',
  'overhead-press',
];

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

function calculateStreak(sessions: WorkoutSession[]): number {
  if (!sessions || sessions.length === 0) return 0;

  const dateSet = new Set<string>();
  sessions.forEach((s) => {
    const dateObj = parseSessionDate(s);
    if (!isNaN(dateObj.getTime())) {
      dateSet.add(dateObj.toISOString().split('T')[0]);
    }
  });

  const sortedDates = Array.from(dateSet).sort();
  if (sortedDates.length === 0) return 0;

  let maxStreak = 1;
  let currentStreak = 1;

  for (let i = 1; i < sortedDates.length; i++) {
    const prev = new Date(sortedDates[i - 1]);
    const curr = new Date(sortedDates[i]);
    const diffTime = curr.getTime() - prev.getTime();
    const diffDays = Math.round(diffTime / (1000 * 3600 * 24));

    if (diffDays === 1) {
      currentStreak++;
      if (currentStreak > maxStreak) {
        maxStreak = currentStreak;
      }
    } else {
      currentStreak = 1;
    }
  }

  return maxStreak;
}

export default function ProgressScreen() {
  const router = useRouter();
  const { user } = useAuth();
  const { unit } = useSettingsStore();

  const [selectedExerciseId, setSelectedExerciseId] = useState<string>('barbell-bench-press');
  const [isPickerVisible, setIsPickerVisible] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');

  // Fetch all user workouts (up to 1 year back)
  const dateRange = useMemo(() => {
    const end = new Date();
    end.setHours(23, 59, 59, 999);
    const start = new Date();
    start.setFullYear(end.getFullYear() - 1);
    start.setHours(0, 0, 0, 0);
    return { start, end };
  }, []);

  const {
    data: sessions = [],
    isLoading,
    refetch,
    isRefetching,
  } = useQuery({
    queryKey: ['workoutsAllProgress', user?.uid],
    queryFn: () => getWorkoutsByDateRange(user!.uid, dateRange.start, dateRange.end),
    enabled: !!user?.uid,
  });

  // Calculate overview stats
  const totalWorkouts = sessions.length;
  const totalVolumeLifted = useMemo(() => {
    return sessions.reduce((sum, s) => sum + (s.totalVolume || 0), 0);
  }, [sessions]);

  const longestStreak = useMemo(() => {
    return calculateStreak(sessions);
  }, [sessions]);

  // Extract progression data for currently selected exercise
  const exerciseProgression = useMemo(() => {
    const sortedSessions = [...sessions].sort((a, b) => {
      return parseSessionDate(a).getTime() - parseSessionDate(b).getTime();
    });

    const dataPoints: ProgressDataPoint[] = [];
    let max1RMOverall = 0;
    let maxWeightOverall = 0;
    let maxVolumeSingleSession = 0;

    sortedSessions.forEach((session) => {
      if (!session.exercises || !Array.isArray(session.exercises)) return;

      const matchingEx = session.exercises.find((ex: any) => ex.exerciseId === selectedExerciseId);
      if (!matchingEx || !matchingEx.sets || !Array.isArray(matchingEx.sets)) return;

      let sessionMaxWeight = 0;
      let sessionMax1RM = 0;
      let sessionTotalVolume = 0;
      let validSetsCount = 0;

      matchingEx.sets.forEach((set: any) => {
        if (set.isCompleted === false) return;
        const w = Number(set.weight) || 0;
        const r = Number(set.reps) || 0;
        if (w > 0 && r > 0) {
          validSetsCount++;
          const set1RM = calculateOneRepMax(w, r);
          if (w > sessionMaxWeight) sessionMaxWeight = w;
          if (set1RM > sessionMax1RM) sessionMax1RM = set1RM;
          sessionTotalVolume += w * r;
        }
      });

      if (validSetsCount > 0) {
        const dateObj = parseSessionDate(session);
        const dateStr = dateObj.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });

        dataPoints.push({
          date: dateStr,
          weight: sessionMaxWeight,
          oneRM: sessionMax1RM,
        });

        if (sessionMax1RM > max1RMOverall) max1RMOverall = sessionMax1RM;
        if (sessionMaxWeight > maxWeightOverall) maxWeightOverall = sessionMaxWeight;
        if (sessionTotalVolume > maxVolumeSingleSession) maxVolumeSingleSession = sessionTotalVolume;
      }
    });

    return {
      dataPoints,
      max1RMOverall,
      maxWeightOverall,
      maxVolumeSingleSession,
    };
  }, [sessions, selectedExerciseId]);

  const selectedExercise = getExerciseById(selectedExerciseId) || exercises[0];

  // Filter exercises for modal picker
  const filteredExercises = useMemo(() => {
    return exercises.filter((ex) => {
      const matchesSearch = ex.name.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesCategory =
        selectedCategory === 'all' || ex.muscleGroup.toLowerCase() === selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    });
  }, [searchQuery, selectedCategory]);

  const onRefresh = useCallback(() => {
    refetch();
  }, [refetch]);

  return (
    <SafeAreaView className="flex-1 bg-[#0A0A0F]">
      <ScrollView
        className="flex-1 px-4 pt-2"
        contentContainerStyle={{ paddingBottom: 40 }}
        refreshControl={
          <RefreshControl
            refreshing={isRefetching}
            onRefresh={onRefresh}
            tintColor="#6C5CE7"
            colors={['#6C5CE7']}
          />
        }
      >
        {/* Header */}
        <View className="mb-6">
          <Text className="text-[#F0F0F5] text-2xl font-black tracking-tight mb-1">
            Progress & Analytics
          </Text>
          <Text className="text-[#8888A0] text-sm font-medium">
            Monitor volume trends, streak growth, and 1RM history.
          </Text>
        </View>

        {/* Overview Stats Cards */}
        <View className="flex-row gap-3 mb-6">
          <View className="flex-1 bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-3.5 items-center">
            <View className="w-8 h-8 rounded-full bg-[#6C5CE7]/15 items-center justify-center mb-2">
              <Ionicons name="barbell" size={16} color="#6C5CE7" />
            </View>
            <Text className="text-[#F0F0F5] text-lg font-black">{totalWorkouts}</Text>
            <Text className="text-[#8888A0] text-[11px] font-medium mt-0.5">Workouts</Text>
          </View>

          <View className="flex-1 bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-3.5 items-center">
            <View className="w-8 h-8 rounded-full bg-[#A29BFE]/15 items-center justify-center mb-2">
              <Ionicons name="trending-up" size={16} color="#A29BFE" />
            </View>
            <Text className="text-[#F0F0F5] text-lg font-black" numberOfLines={1}>
              {totalVolumeLifted >= 1000
                ? `${(totalVolumeLifted / 1000).toFixed(1)}k`
                : totalVolumeLifted}
            </Text>
            <Text className="text-[#8888A0] text-[11px] font-medium mt-0.5">
              Vol ({unit})
            </Text>
          </View>

          <View className="flex-1 bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-3.5 items-center">
            <View className="w-8 h-8 rounded-full bg-[#FFD600]/15 items-center justify-center mb-2">
              <Ionicons name="flame" size={16} color="#FFD600" />
            </View>
            <Text className="text-[#F0F0F5] text-lg font-black">{longestStreak}</Text>
            <Text className="text-[#8888A0] text-[11px] font-medium mt-0.5">
              Best Streak
            </Text>
          </View>
        </View>

        {/* Section 1: Weekly Volume Trend */}
        <View className="mb-6">
          <View className="flex-row justify-between items-center mb-3">
            <Text className="text-[#F0F0F5] text-lg font-bold">Weekly Volume Trend</Text>
            <Text className="text-[#8888A0] text-xs font-medium">Last 8 Weeks</Text>
          </View>
          <VolumeChart sessions={sessions} unit={unit} isLoading={isLoading} />
        </View>

        {/* Section 2: Personal Records & Exercise History */}
        <View className="mb-6">
          <View className="flex-row justify-between items-center mb-3">
            <Text className="text-[#F0F0F5] text-lg font-bold">Personal Records & 1RM</Text>
            <TouchableOpacity
              onPress={() => setIsPickerVisible(true)}
              className="flex-row items-center bg-[#1E1E2E] px-3 py-1.5 rounded-full border border-[#6C5CE7]/40"
            >
              <Ionicons name="search-outline" size={13} color="#A29BFE" style={{ marginRight: 4 }} />
              <Text className="text-[#A29BFE] text-xs font-semibold">Browse All</Text>
            </TouchableOpacity>
          </View>

          {/* Quick Exercise Chips */}
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            className="mb-4 flex-row"
            contentContainerStyle={{ gap: 8 }}
          >
            {TOP_EXERCISE_IDS.map((exId) => {
              const ex = getExerciseById(exId);
              if (!ex) return null;
              const isSelected = selectedExerciseId === exId;
              return (
                <TouchableOpacity
                  key={exId}
                  activeOpacity={0.7}
                  onPress={() => setSelectedExerciseId(exId)}
                  className={`px-3.5 py-2 rounded-xl border ${
                    isSelected
                      ? 'bg-[#6C5CE7] border-[#6C5CE7]'
                      : 'bg-[#14141F] border-[#1E1E2E]'
                  }`}
                >
                  <Text
                    className={`text-xs font-bold ${
                      isSelected ? 'text-white' : 'text-[#8888A0]'
                    }`}
                  >
                    {ex.name}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </ScrollView>

          {/* Selected Exercise Header Card */}
          <View className="bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-4 mb-4">
            <View className="flex-row justify-between items-center mb-3">
              <View className="flex-1 mr-2">
                <Text className="text-[#F0F0F5] text-base font-bold" numberOfLines={1}>
                  {selectedExercise.name}
                </Text>
                <View className="flex-row items-center gap-2 mt-1">
                  <View className="bg-[#1E1E2E] px-2 py-0.5 rounded-md border border-[#8888A0]/20">
                    <Text className="text-[#A29BFE] text-[10px] font-bold uppercase">
                      {selectedExercise.muscleGroup}
                    </Text>
                  </View>
                  <View className="bg-[#1E1E2E] px-2 py-0.5 rounded-md border border-[#8888A0]/20">
                    <Text className="text-[#8888A0] text-[10px] font-medium capitalize">
                      {selectedExercise.equipment}
                    </Text>
                  </View>
                </View>
              </View>

              <TouchableOpacity
                activeOpacity={0.7}
                onPress={() => router.push(`/progress/exercise/${selectedExercise.id}`)}
                className="bg-[#6C5CE7]/20 border border-[#6C5CE7]/40 px-3 py-1.5 rounded-xl flex-row items-center"
              >
                <Text className="text-[#A29BFE] text-xs font-bold mr-1">Details</Text>
                <Ionicons name="chevron-forward" size={14} color="#A29BFE" />
              </TouchableOpacity>
            </View>

            {/* Stats Row */}
            <View className="flex-row gap-2 pt-3 border-t border-[#1E1E2E]">
              <View className="flex-1 bg-[#1E1E2E]/60 p-2.5 rounded-xl items-center">
                <Text className="text-[#8888A0] text-[10px] font-medium">Est. 1RM</Text>
                <Text className="text-[#00E676] text-sm font-black mt-0.5">
                  {exerciseProgression.max1RMOverall > 0
                    ? formatWeight(exerciseProgression.max1RMOverall, unit)
                    : '--'}
                </Text>
              </View>

              <View className="flex-1 bg-[#1E1E2E]/60 p-2.5 rounded-xl items-center">
                <Text className="text-[#8888A0] text-[10px] font-medium">Max Weight</Text>
                <Text className="text-[#F0F0F5] text-sm font-black mt-0.5">
                  {exerciseProgression.maxWeightOverall > 0
                    ? formatWeight(exerciseProgression.maxWeightOverall, unit)
                    : '--'}
                </Text>
              </View>

              <View className="flex-1 bg-[#1E1E2E]/60 p-2.5 rounded-xl items-center">
                <Text className="text-[#8888A0] text-[10px] font-medium">Max Volume</Text>
                <Text className="text-[#F0F0F5] text-sm font-black mt-0.5">
                  {exerciseProgression.maxVolumeSingleSession > 0
                    ? formatNumber(exerciseProgression.maxVolumeSingleSession)
                    : '--'}
                </Text>
              </View>
            </View>
          </View>

          {/* 1RM Line Chart */}
          <ProgressLineChart
            data={exerciseProgression.dataPoints}
            metric="oneRM"
            unit={unit}
            title={`${selectedExercise.name} (1RM)`}
          />
        </View>

        {/* Link to Full Exercise Detail */}
        <TouchableOpacity
          activeOpacity={0.8}
          onPress={() => router.push(`/progress/exercise/${selectedExercise.id}`)}
          className="bg-[#14141F] border border-[#6C5CE7]/40 rounded-2xl p-4 flex-row items-center justify-between"
        >
          <View className="flex-row items-center flex-1 mr-2">
            <View className="w-10 h-10 rounded-xl bg-[#6C5CE7]/20 items-center justify-center mr-3">
              <Ionicons name="journal-outline" size={20} color="#6C5CE7" />
            </View>
            <View>
              <Text className="text-[#F0F0F5] text-sm font-bold">
                View Full Exercise History
              </Text>
              <Text className="text-[#8888A0] text-xs">
                See all-time set logs & details for {selectedExercise.name}
              </Text>
            </View>
          </View>
          <Ionicons name="chevron-forward" size={18} color="#6C5CE7" />
        </TouchableOpacity>
      </ScrollView>

      {/* Exercise Selector Modal */}
      <Modal
        visible={isPickerVisible}
        animationType="slide"
        transparent={false}
        onRequestClose={() => setIsPickerVisible(false)}
      >
        <SafeAreaView className="flex-1 bg-[#0A0A0F]">
          <View className="p-4 flex-row items-center justify-between border-b border-[#1E1E2E]">
            <Text className="text-[#F0F0F5] text-lg font-bold">Select Exercise</Text>
            <TouchableOpacity
              onPress={() => setIsPickerVisible(false)}
              className="p-1"
            >
              <Ionicons name="close" size={24} color="#8888A0" />
            </TouchableOpacity>
          </View>

          {/* Search Input */}
          <View className="p-4 border-b border-[#1E1E2E]">
            <View className="flex-row items-center bg-[#14141F] border border-[#1E1E2E] rounded-xl px-3 py-2">
              <Ionicons name="search" size={18} color="#8888A0" style={{ marginRight: 8 }} />
              <TextInput
                value={searchQuery}
                onChangeText={setSearchQuery}
                placeholder="Search exercise by name..."
                placeholderTextColor="#8888A0"
                className="flex-1 text-[#F0F0F5] text-sm"
              />
              {searchQuery ? (
                <TouchableOpacity onPress={() => setSearchQuery('')}>
                  <Ionicons name="close-circle" size={16} color="#8888A0" />
                </TouchableOpacity>
              ) : null}
            </View>

            {/* Muscle Group Category Filters */}
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              className="mt-3 flex-row"
              contentContainerStyle={{ gap: 6 }}
            >
              {['all', 'chest', 'back', 'legs', 'shoulders', 'arms', 'core'].map((cat) => (
                <TouchableOpacity
                  key={cat}
                  onPress={() => setSelectedCategory(cat)}
                  className={`px-3 py-1.5 rounded-full border ${
                    selectedCategory === cat
                      ? 'bg-[#6C5CE7] border-[#6C5CE7]'
                      : 'bg-[#14141F] border-[#1E1E2E]'
                  }`}
                >
                  <Text
                    className={`text-xs font-semibold capitalize ${
                      selectedCategory === cat ? 'text-white' : 'text-[#8888A0]'
                    }`}
                  >
                    {cat}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>

          {/* Exercise List */}
          <ScrollView className="flex-1 p-4">
            {filteredExercises.map((ex) => (
              <TouchableOpacity
                key={ex.id}
                activeOpacity={0.7}
                onPress={() => {
                  setSelectedExerciseId(ex.id);
                  setIsPickerVisible(false);
                }}
                className={`bg-[#14141F] border rounded-xl p-3.5 mb-2.5 flex-row items-center justify-between ${
                  selectedExerciseId === ex.id
                    ? 'border-[#6C5CE7]'
                    : 'border-[#1E1E2E]'
                }`}
              >
                <View className="flex-1 mr-2">
                  <Text className="text-[#F0F0F5] text-sm font-bold">{ex.name}</Text>
                  <Text className="text-[#8888A0] text-xs capitalize mt-0.5">
                    {ex.muscleGroup} • {ex.equipment}
                  </Text>
                </View>

                {selectedExerciseId === ex.id ? (
                  <Ionicons name="checkmark-circle" size={20} color="#6C5CE7" />
                ) : (
                  <Ionicons name="chevron-forward" size={16} color="#8888A0" />
                )}
              </TouchableOpacity>
            ))}

            {filteredExercises.length === 0 && (
              <View className="py-12 items-center justify-center">
                <Ionicons name="alert-circle-outline" size={32} color="#8888A0" />
                <Text className="text-[#8888A0] text-sm font-medium mt-2">
                  No exercises match "{searchQuery}"
                </Text>
              </View>
            )}
          </ScrollView>
        </SafeAreaView>
      </Modal>
    </SafeAreaView>
  );
}
