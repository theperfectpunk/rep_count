import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  TextInput,
  ScrollView,
  TouchableOpacity,
  Pressable,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { useQueryClient } from '@tanstack/react-query';
import * as Haptics from 'expo-haptics';
import { Ionicons } from '@expo/vector-icons';

import { useWorkoutStore, ActiveExercise } from '../../src/stores/workoutStore';
import { useSettingsStore } from '../../src/stores/settingsStore';
import { workoutService } from '../../src/services/workoutService';
import { formatDuration } from '../../src/utils/formatters';
import { SetRow } from '../../src/components/SetRow';
import { ExercisePickerSheet } from '../../src/components/ExercisePickerSheet';
import { RestTimerModal } from '../../src/components/RestTimerModal';
import { Exercise } from '../../src/data/exercises';

const MUSCLE_COLORS: Record<string, { bg: string; text: string }> = {
  chest: { bg: 'bg-[#FF5252]/15 border-[#FF5252]/40', text: 'text-[#FF5252]' },
  back: { bg: 'bg-[#3B82F6]/15 border-[#3B82F6]/40', text: 'text-[#3B82F6]' },
  legs: { bg: 'bg-[#10B981]/15 border-[#10B981]/40', text: 'text-[#10B981]' },
  shoulders: { bg: 'bg-[#F59E0B]/15 border-[#F59E0B]/40', text: 'text-[#F59E0B]' },
  arms: { bg: 'bg-[#8B5CF6]/15 border-[#8B5CF6]/40', text: 'text-[#8B5CF6]' },
  core: { bg: 'bg-[#EC4899]/15 border-[#EC4899]/40', text: 'text-[#EC4899]' },
};

export default function ActiveWorkoutScreen() {
  const queryClient = useQueryClient();
  const { unit, defaultRestTimer } = useSettingsStore();

  const {
    isActive,
    workoutName,
    startedAt,
    exercises,
    startWorkout,
    finishWorkout,
    addExercise,
    removeExercise,
    addSet,
    removeSet,
    updateSet,
    completeSet,
    startRestTimer,
    resetWorkout,
  } = useWorkoutStore();

  const [isPickerVisible, setIsPickerVisible] = useState(false);
  const [isEditingTitle, setIsEditingTitle] = useState(false);
  const [workoutTitle, setWorkoutTitle] = useState(workoutName || 'Workout');
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const [isSaving, setIsSaving] = useState(false);
  const [previousBests, setPreviousBests] = useState<Record<string, string>>({});

  // Ensure workout is active when opening screen
  useEffect(() => {
    if (!isActive || !startedAt) {
      startWorkout(workoutName || 'Active Workout');
    }
  }, [isActive, startedAt, workoutName, startWorkout]);

  // Sync title from store
  useEffect(() => {
    if (workoutName) {
      setWorkoutTitle(workoutName);
    }
  }, [workoutName]);

  // Timer loop for elapsed duration
  useEffect(() => {
    if (!startedAt) return;

    const updateTimer = () => {
      const diff = Math.max(0, Math.floor((Date.now() - new Date(startedAt).getTime()) / 1000));
      setElapsedSeconds(diff);
    };

    updateTimer();
    const interval = setInterval(updateTimer, 1000);
    return () => clearInterval(interval);
  }, [startedAt]);

  // Fetch previous best set for exercises
  useEffect(() => {
    exercises.forEach(async (ex) => {
      if (ex.exerciseId && !(ex.exerciseId in previousBests)) {
        const best = await workoutService.getPreviousBestForExercise(ex.exerciseId);
        if (best) {
          setPreviousBests((prev) => ({
            ...prev,
            [ex.exerciseId]: `${best.weight}${unit} × ${best.reps}`,
          }));
        } else {
          setPreviousBests((prev) => ({
            ...prev,
            [ex.exerciseId]: '-',
          }));
        }
      }
    });
  }, [exercises, unit, previousBests]);

  // Handlers
  const handleSaveTitle = () => {
    setIsEditingTitle(false);
    const trimmed = workoutTitle.trim();
    if (trimmed) {
      useWorkoutStore.setState({ workoutName: trimmed });
    } else {
      setWorkoutTitle(workoutName || 'Workout');
    }
  };

  const handleSelectExercise = (exercise: Exercise) => {
    addExercise(exercise.id, exercise.name, exercise.muscleGroup);
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {});
  };

  const handleCompleteSet = (exerciseIndex: number, setIndex: number) => {
    const currentSet = exercises[exerciseIndex]?.sets[setIndex];
    if (!currentSet) return;

    if (!currentSet.isCompleted) {
      completeSet(exerciseIndex, setIndex);
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium).catch(() => {});
      startRestTimer(defaultRestTimer || 90);
    } else {
      updateSet(exerciseIndex, setIndex, { isCompleted: false, completedAt: null });
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {});
    }
  };

  const handleDeleteSet = (exerciseIndex: number, setIndex: number) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {});
    removeSet(exerciseIndex, setIndex);
  };

  const handleRemoveExercise = (exerciseIndex: number, exerciseName: string) => {
    Alert.alert('Remove Exercise', `Are you sure you want to remove "${exerciseName}"?`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Remove',
        style: 'destructive',
        onPress: () => {
          removeExercise(exerciseIndex);
          Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium).catch(() => {});
        },
      },
    ]);
  };

  const handleDiscardWorkout = () => {
    Alert.alert(
      'Discard Workout',
      'Are you sure you want to discard this workout? All progress will be lost.',
      [
        { text: 'Keep Workout', style: 'cancel' },
        {
          text: 'Discard',
          style: 'destructive',
          onPress: () => {
            resetWorkout();
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium).catch(() => {});
            if (router.canGoBack()) {
              router.back();
            } else {
              router.replace('/(tabs)');
            }
          },
        },
      ]
    );
  };

  const handleFinishWorkout = () => {
    let completedCount = 0;
    let totalVol = 0;

    exercises.forEach((ex) => {
      ex.sets.forEach((s) => {
        if (s.isCompleted) {
          completedCount++;
          totalVol += (s.weight || 0) * (s.reps || 0);
        }
      });
    });

    Alert.alert(
      'Finish Workout',
      completedCount === 0
        ? 'You have 0 completed sets. Finish anyway?'
        : `Ready to finish? Logged ${completedCount} set${
            completedCount > 1 ? 's' : ''
          } with ${Math.round(totalVol)} ${unit} total volume.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Finish & Save',
          onPress: async () => {
            setIsSaving(true);
            try {
              const finishedData = finishWorkout();
              await workoutService.saveWorkoutSession({
                workoutName: finishedData.workoutName || workoutTitle || 'Workout',
                planId: finishedData.planId,
                planDayName: finishedData.planDayName,
                startedAt: finishedData.startedAt,
                exercises: finishedData.exercises,
                totalVolume: totalVol,
                totalSets: completedCount,
              });

              // Invalidate react-query cache
              queryClient.invalidateQueries({ queryKey: ['recentWorkouts'] });
              queryClient.invalidateQueries({ queryKey: ['totalStats'] });
              queryClient.invalidateQueries({ queryKey: ['workoutHistory'] });

              Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success).catch(() => {});

              if (router.canGoBack()) {
                router.back();
              } else {
                router.replace('/(tabs)');
              }
            } catch (err) {
              console.error('Error saving workout:', err);
              Alert.alert('Error', 'Failed to save workout session. Please try again.');
            } finally {
              setIsSaving(false);
            }
          },
        },
      ]
    );
  };

  return (
    <SafeAreaView className="flex-1 bg-[#0A0A0F]">
      {/* HEADER SECTION */}
      <View className="flex-row items-center justify-between px-5 py-3 border-b border-[#14141F]">
        {/* Discard / Close Button */}
        <TouchableOpacity
          onPress={handleDiscardWorkout}
          className="w-10 h-10 rounded-2xl bg-[#14141F] items-center justify-center border border-[#1E1E2E]"
        >
          <Ionicons name="close" size={22} color="#8888A0" />
        </TouchableOpacity>

        {/* Workout Name & Timer */}
        <View className="items-center flex-1 mx-3">
          {isEditingTitle ? (
            <TextInput
              value={workoutTitle}
              onChangeText={setWorkoutTitle}
              onBlur={handleSaveTitle}
              onSubmitEditing={handleSaveTitle}
              autoFocus
              className="text-[#F0F0F5] font-black text-lg text-center bg-[#14141F] px-3 py-1 rounded-xl border border-[#6C5CE7] w-full"
            />
          ) : (
            <TouchableOpacity
              onPress={() => setIsEditingTitle(true)}
              className="flex-row items-center"
            >
              <Text className="text-[#F0F0F5] font-black text-lg mr-1.5" numberOfLines={1}>
                {workoutTitle}
              </Text>
              <Ionicons name="pencil" size={14} color="#8888A0" />
            </TouchableOpacity>
          )}

          {/* Duration Badge */}
          <View className="flex-row items-center mt-0.5 bg-[#14141F] px-2.5 py-0.5 rounded-full border border-[#1E1E2E]">
            <Ionicons name="time-outline" size={12} color="#6C5CE7" />
            <Text className="text-[#6C5CE7] text-xs font-extrabold ml-1">
              {formatDuration(elapsedSeconds)}
            </Text>
          </View>
        </View>

        {/* Finish Button */}
        <TouchableOpacity
          onPress={handleFinishWorkout}
          disabled={isSaving}
          className="bg-[#6C5CE7] px-4 py-2.5 rounded-2xl flex-row items-center justify-center shadow-lg active:bg-[#5A4AD1]"
        >
          {isSaving ? (
            <ActivityIndicator size="small" color="#FFFFFF" />
          ) : (
            <Text className="text-white font-black text-sm">Finish</Text>
          )}
        </TouchableOpacity>
      </View>

      {/* EXERCISE SECTIONS LIST */}
      <ScrollView
        className="flex-1 px-4 pt-4"
        contentContainerStyle={{ paddingBottom: 100 }}
        showsVerticalScrollIndicator={false}
        keyboardShouldPersistTaps="handled"
      >
        {exercises.length === 0 ? (
          /* Empty State Prompt */
          <View className="bg-[#14141F] border border-[#1E1E2E] rounded-3xl p-8 items-center justify-center mt-12">
            <View className="w-16 h-16 rounded-full bg-[#6C5CE7]/15 items-center justify-center mb-4">
              <Ionicons name="barbell-outline" size={32} color="#6C5CE7" />
            </View>
            <Text className="text-[#F0F0F5] font-black text-xl mb-2 text-center">
              Add Your First Exercise
            </Text>
            <Text className="text-[#8888A0] text-sm text-center mb-6 leading-relaxed">
              Start building your active workout by selecting exercises from your library.
            </Text>
            <TouchableOpacity
              onPress={() => setIsPickerVisible(true)}
              className="bg-[#6C5CE7] px-6 py-3.5 rounded-2xl flex-row items-center active:bg-[#5A4AD1]"
            >
              <Ionicons name="add" size={20} color="#FFFFFF" />
              <Text className="text-white font-extrabold text-base ml-2">Add Exercise</Text>
            </TouchableOpacity>
          </View>
        ) : (
          exercises.map((exercise, exerciseIndex) => {
            const muscleStyle =
              MUSCLE_COLORS[exercise.muscleGroup.toLowerCase()] || MUSCLE_COLORS['chest'];

            return (
              <View
                key={exercise.id}
                className="bg-[#14141F] rounded-3xl p-4 mb-4 border border-[#1E1E2E] shadow-xl"
              >
                {/* Exercise Header */}
                <View className="flex-row items-center justify-between pb-3 border-b border-[#1E1E2E] mb-3">
                  <View className="flex-1 mr-2">
                    <View className="flex-row items-center flex-wrap gap-2">
                      <Text className="text-[#F0F0F5] font-black text-lg">
                        {exercise.name}
                      </Text>
                      {/* Muscle Group Badge */}
                      <View className={`px-2.5 py-0.5 rounded-full border ${muscleStyle.bg}`}>
                        <Text className={`text-[10px] font-black uppercase ${muscleStyle.text}`}>
                          {exercise.muscleGroup}
                        </Text>
                      </View>
                    </View>
                  </View>

                  {/* Remove Exercise Button */}
                  <TouchableOpacity
                    onPress={() => handleRemoveExercise(exerciseIndex, exercise.name)}
                    className="w-8 h-8 rounded-full bg-[#1E1E2E] items-center justify-center"
                  >
                    <Ionicons name="trash-outline" size={16} color="#FF5252" />
                  </TouchableOpacity>
                </View>

                {/* Table Header Row */}
                <View className="flex-row items-center justify-between px-3 pb-2">
                  <Text className="w-9 text-[#8888A0] text-[10px] font-black uppercase text-center">
                    Set
                  </Text>
                  <Text className="w-16 text-[#8888A0] text-[10px] font-black uppercase text-center">
                    Prev
                  </Text>
                  <Text className="flex-1 max-w-[80px] text-[#8888A0] text-[10px] font-black uppercase text-center">
                    {unit.toUpperCase()}
                  </Text>
                  <Text className="text-[#8888A0] text-[10px] font-black text-center mx-0.5">
                    
                  </Text>
                  <Text className="flex-1 max-w-[80px] text-[#8888A0] text-[10px] font-black uppercase text-center">
                    Reps
                  </Text>
                  <Text className="w-9 text-[#8888A0] text-[10px] font-black uppercase text-center ml-1.5">
                    ✓
                  </Text>
                </View>

                {/* Set Rows */}
                {exercise.sets.map((set, setIndex) => (
                  <SetRow
                    key={set.id}
                    set={set}
                    exerciseIndex={exerciseIndex}
                    setIndex={setIndex}
                    unit={unit}
                    previousBest={previousBests[exercise.exerciseId] || '-'}
                    onUpdate={updateSet}
                    onComplete={handleCompleteSet}
                    onDelete={handleDeleteSet}
                  />
                ))}

                {/* Add Set Button */}
                <TouchableOpacity
                  onPress={() => {
                    addSet(exerciseIndex);
                    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {});
                  }}
                  className="bg-[#1E1E2E] py-2.5 rounded-xl border border-dashed border-[#2A2A3D] flex-row items-center justify-center mt-1 active:bg-[#252538]"
                >
                  <Ionicons name="add-circle-outline" size={16} color="#6C5CE7" />
                  <Text className="text-[#6C5CE7] font-extrabold text-xs ml-1.5">
                    Add Set
                  </Text>
                </TouchableOpacity>
              </View>
            );
          })
        )}
      </ScrollView>

      {/* BOTTOM STICKY FLOATING BUTTON */}
      {exercises.length > 0 && (
        <View className="absolute bottom-6 left-5 right-5">
          <TouchableOpacity
            onPress={() => setIsPickerVisible(true)}
            className="bg-[#6C5CE7] py-3.5 rounded-2xl flex-row items-center justify-center shadow-2xl active:bg-[#5A4AD1]"
          >
            <Ionicons name="add" size={22} color="#FFFFFF" />
            <Text className="text-white font-extrabold text-base ml-2">Add Exercise</Text>
          </TouchableOpacity>
        </View>
      )}

      {/* EXERCISE PICKER SHEET MODAL */}
      <ExercisePickerSheet
        visible={isPickerVisible}
        onClose={() => setIsPickerVisible(false)}
        onSelect={handleSelectExercise}
      />

      {/* REST TIMER MODAL OVERLAY */}
      <RestTimerModal />
    </SafeAreaView>
  );
}
