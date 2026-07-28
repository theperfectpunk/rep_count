import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  ScrollView,
  Pressable,
  Modal,
  ActivityIndicator,
  Alert,
  SafeAreaView,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import { exercises, Exercise } from '../../src/data/exercises';
import { PlanDay, PlanExercise } from '../../src/data/prebuiltPlans';
import { useSaveCustomPlan } from '../../src/hooks/useWorkoutPlans';
import { useAuth } from '../../src/hooks/useAuth';

const MUSCLE_GROUPS = ['all', 'chest', 'back', 'legs', 'shoulders', 'arms', 'core'];

export default function CreatePlanScreen() {
  const router = useRouter();
  const { user } = useAuth();
  const userId = user?.uid || 'demo-user';

  const { mutate: savePlan, isPending: isSaving } = useSaveCustomPlan();

  // Form State
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [split, setSplit] = useState('custom');
  const [daysPerWeek, setDaysPerWeek] = useState(3);
  const [days, setDays] = useState<PlanDay[]>([
    { dayName: 'Day 1', dayNumber: 1, exercises: [] },
    { dayName: 'Day 2', dayNumber: 2, exercises: [] },
    { dayName: 'Day 3', dayNumber: 3, exercises: [] },
  ]);

  // Exercise Picker Modal State
  const [isPickerVisible, setIsPickerVisible] = useState(false);
  const [activeDayIndex, setActiveDayIndex] = useState<number | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedMuscle, setSelectedMuscle] = useState('all');

  // Handle changing daysPerWeek count
  const handleDaysPerWeekChange = (count: number) => {
    setDaysPerWeek(count);
    setDays((prevDays) => {
      if (count > prevDays.length) {
        const newDays = [...prevDays];
        for (let i = prevDays.length; i < count; i++) {
          newDays.push({
            dayName: `Day ${i + 1}`,
            dayNumber: i + 1,
            exercises: [],
          });
        }
        return newDays;
      } else {
        return prevDays.slice(0, count);
      }
    });
  };

  // Update Day Name
  const handleUpdateDayName = (index: number, newName: string) => {
    setDays((prev) => {
      const updated = [...prev];
      updated[index] = { ...updated[index], dayName: newName };
      return updated;
    });
  };

  // Open Exercise Picker for specific day
  const handleOpenPicker = (dayIdx: number) => {
    setActiveDayIndex(dayIdx);
    setSearchQuery('');
    setSelectedMuscle('all');
    setIsPickerVisible(true);
  };

  // Add exercise to active day
  const handleSelectExercise = (exercise: Exercise) => {
    if (activeDayIndex === null) return;

    setDays((prev) => {
      const updated = [...prev];
      const targetDay = { ...updated[activeDayIndex] };
      // Check if already added to this day
      if (targetDay.exercises.some((e) => e.exerciseId === exercise.id)) {
        Alert.alert('Already Added', `${exercise.name} is already added to this day.`);
        return prev;
      }
      targetDay.exercises = [
        ...targetDay.exercises,
        {
          exerciseId: exercise.id,
          targetSets: 3,
          targetReps: '8-12',
        },
      ];
      updated[activeDayIndex] = targetDay;
      return updated;
    });

    setIsPickerVisible(false);
  };

  // Update Exercise Target Sets / Reps
  const handleUpdateExercise = (
    dayIdx: number,
    exIdx: number,
    field: 'targetSets' | 'targetReps',
    value: any
  ) => {
    setDays((prev) => {
      const updated = [...prev];
      const targetDay = { ...updated[dayIdx] };
      const targetExercises = [...targetDay.exercises];
      targetExercises[exIdx] = {
        ...targetExercises[exIdx],
        [field]: value,
      };
      targetDay.exercises = targetExercises;
      updated[dayIdx] = targetDay;
      return updated;
    });
  };

  // Remove Exercise from Day
  const handleRemoveExercise = (dayIdx: number, exIdx: number) => {
    setDays((prev) => {
      const updated = [...prev];
      const targetDay = { ...updated[dayIdx] };
      targetDay.exercises = targetDay.exercises.filter((_, i) => i !== exIdx);
      updated[dayIdx] = targetDay;
      return updated;
    });
  };

  // Save Plan Action
  const handleSave = () => {
    if (!name.trim()) {
      Alert.alert('Validation Error', 'Please enter a plan name.');
      return;
    }

    const hasEmptyDays = days.some((day) => day.exercises.length === 0);
    if (hasEmptyDays) {
      Alert.alert('Empty Days', 'Please add at least one exercise to every day in your routine.');
      return;
    }

    const newPlan = {
      userId,
      name: name.trim(),
      description: description.trim() || 'Custom workout plan',
      type: 'custom' as const,
      split: split || 'custom',
      daysPerWeek,
      days,
      createdAt: new Date(),
      isActive: false,
    };

    savePlan(newPlan, {
      onSuccess: () => {
        router.back();
      },
      onError: (err: any) => {
        Alert.alert('Error', err.message || 'Failed to save custom plan.');
      },
    });
  };

  // Filtered exercises for picker
  const filteredExercises = exercises.filter((ex) => {
    const matchesSearch = ex.name.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesMuscle =
      selectedMuscle === 'all' || ex.muscleGroup.toLowerCase() === selectedMuscle.toLowerCase();
    return matchesSearch && matchesMuscle;
  });

  return (
    <SafeAreaView className="flex-1 bg-[#0A0A0F]">
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        {/* Header */}
        <View className="px-5 pt-3 pb-3 flex-row items-center justify-between border-b border-[#1E1E2E]">
          <Pressable
            onPress={() => router.back()}
            className="w-10 h-10 rounded-full bg-[#14141F] items-center justify-center border border-[#1E1E2E] active:opacity-80"
          >
            <SymbolView
              name={{ ios: 'xmark', android: 'close', web: 'close' }}
              tintColor="#F0F0F5"
              size={20}
            />
          </Pressable>

          <Text className="text-lg font-bold text-[#F0F0F5]">Create Custom Plan</Text>

          <Pressable
            onPress={handleSave}
            disabled={isSaving}
            className="px-4 py-2 rounded-xl bg-[#6C5CE7] active:opacity-80 flex-row items-center"
          >
            {isSaving ? (
              <ActivityIndicator size="small" color="#FFF" />
            ) : (
              <Text className="text-white font-bold text-sm">Save</Text>
            )}
          </Pressable>
        </View>

        <ScrollView
          className="flex-1 px-5 pt-4"
          contentContainerStyle={{ paddingBottom: 100 }}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          {/* Plan Meta Information */}
          <View className="bg-[#14141F] rounded-2xl p-5 mb-6 border border-[#1E1E2E]">
            <Text className="text-xs font-semibold text-[#8888A0] uppercase tracking-wider mb-4">
              Plan Details
            </Text>

            {/* Plan Name */}
            <View className="mb-4">
              <Text className="text-xs font-medium text-[#8888A0] mb-1.5">Plan Name *</Text>
              <TextInput
                value={name}
                onChangeText={setName}
                placeholder="e.g., Hypertrophy Push/Pull/Legs"
                placeholderTextColor="#666680"
                className="bg-[#1E1E2E] text-[#F0F0F5] px-4 py-3 rounded-xl border border-[#2E2E42] text-base"
              />
            </View>

            {/* Description */}
            <View className="mb-4">
              <Text className="text-xs font-medium text-[#8888A0] mb-1.5">Description</Text>
              <TextInput
                value={description}
                onChangeText={setDescription}
                placeholder="Target goals, rest guidelines, or notes..."
                placeholderTextColor="#666680"
                multiline
                numberOfLines={3}
                textAlignVertical="top"
                className="bg-[#1E1E2E] text-[#F0F0F5] px-4 py-3 rounded-xl border border-[#2E2E42] text-sm min-h-[80px]"
              />
            </View>

            {/* Days per week selector */}
            <View>
              <Text className="text-xs font-medium text-[#8888A0] mb-2">Days Per Week</Text>
              <View className="flex-row gap-2 flex-wrap">
                {[1, 2, 3, 4, 5, 6, 7].map((num) => (
                  <Pressable
                    key={num}
                    onPress={() => handleDaysPerWeekChange(num)}
                    className={`w-10 h-10 rounded-xl items-center justify-center border ${
                      daysPerWeek === num
                        ? 'bg-[#6C5CE7] border-[#6C5CE7]'
                        : 'bg-[#1E1E2E] border-[#2E2E42]'
                    }`}
                  >
                    <Text
                      className={`font-bold text-sm ${
                        daysPerWeek === num ? 'text-white' : 'text-[#8888A0]'
                      }`}
                    >
                      {num}
                    </Text>
                  </Pressable>
                ))}
              </View>
            </View>
          </View>

          {/* Days & Exercises Section */}
          <Text className="text-xs font-semibold text-[#8888A0] uppercase tracking-wider mb-4">
            Daily Workout Routines
          </Text>

          {days.map((day, dIdx) => (
            <View
              key={dIdx}
              className="bg-[#14141F] rounded-2xl p-5 mb-5 border border-[#1E1E2E]"
            >
              {/* Day Header Input */}
              <View className="mb-4">
                <Text className="text-xs font-medium text-[#8888A0] mb-1.5">
                  Day {dIdx + 1} Name
                </Text>
                <TextInput
                  value={day.dayName}
                  onChangeText={(val) => handleUpdateDayName(dIdx, val)}
                  placeholder={`e.g., Push Day`}
                  placeholderTextColor="#666680"
                  className="bg-[#1E1E2E] text-[#F0F0F5] px-4 py-2.5 rounded-xl border border-[#2E2E42] font-semibold text-base"
                />
              </View>

              {/* Added Exercises */}
              <View className="mb-4">
                {day.exercises.length === 0 ? (
                  <Text className="text-xs text-[#8888A0] italic text-center py-4 bg-[#1E1E2E]/40 rounded-xl border border-dashed border-[#2E2E42]">
                    No exercises added yet. Tap below to add exercises to this day.
                  </Text>
                ) : (
                  day.exercises.map((planEx, exIdx) => {
                    const exDetails = exercises.find((e) => e.id === planEx.exerciseId);
                    return (
                      <View
                        key={planEx.exerciseId + exIdx}
                        className="bg-[#1E1E2E] p-3.5 rounded-xl mb-3 border border-[#2E2E42]"
                      >
                        <View className="flex-row items-center justify-between mb-2">
                          <Text className="text-sm font-bold text-[#F0F0F5] flex-1 mr-2">
                            {exDetails?.name || planEx.exerciseId}
                          </Text>
                          <Pressable
                            onPress={() => handleRemoveExercise(dIdx, exIdx)}
                            className="p-1"
                          >
                            <SymbolView
                              name={{ ios: 'trash', android: 'delete', web: 'delete' }}
                              tintColor="#FF5252"
                              size={16}
                            />
                          </Pressable>
                        </View>

                        <View className="flex-row items-center gap-3">
                          {/* Target Sets */}
                          <View className="flex-row items-center bg-[#14141F] rounded-lg px-2.5 py-1 border border-[#2E2E42]">
                            <Text className="text-xs text-[#8888A0] mr-2">Sets:</Text>
                            <Pressable
                              onPress={() =>
                                handleUpdateExercise(
                                  dIdx,
                                  exIdx,
                                  'targetSets',
                                  Math.max(1, planEx.targetSets - 1)
                                )
                              }
                              className="w-6 h-6 rounded bg-[#2E2E42] items-center justify-center"
                            >
                              <Text className="text-white font-bold text-xs">-</Text>
                            </Pressable>
                            <Text className="text-sm font-bold text-[#F0F0F5] mx-3">
                              {planEx.targetSets}
                            </Text>
                            <Pressable
                              onPress={() =>
                                handleUpdateExercise(
                                  dIdx,
                                  exIdx,
                                  'targetSets',
                                  planEx.targetSets + 1
                                )
                              }
                              className="w-6 h-6 rounded bg-[#2E2E42] items-center justify-center"
                            >
                              <Text className="text-white font-bold text-xs">+</Text>
                            </Pressable>
                          </View>

                          {/* Target Reps */}
                          <View className="flex-1 flex-row items-center bg-[#14141F] rounded-lg px-3 py-1 border border-[#2E2E42]">
                            <Text className="text-xs text-[#8888A0] mr-2">Reps:</Text>
                            <TextInput
                              value={planEx.targetReps}
                              onChangeText={(val) =>
                                handleUpdateExercise(dIdx, exIdx, 'targetReps', val)
                              }
                              placeholder="8-12"
                              placeholderTextColor="#666680"
                              className="flex-1 text-sm font-bold text-[#F0F0F5] p-0"
                            />
                          </View>
                        </View>
                      </View>
                    );
                  })
                )}
              </View>

              {/* Add Exercise Button */}
              <Pressable
                onPress={() => handleOpenPicker(dIdx)}
                className="bg-[#6C5CE7]/15 py-3 rounded-xl border border-[#6C5CE7]/40 flex-row items-center justify-center active:opacity-80"
              >
                <SymbolView
                  name={{ ios: 'plus', android: 'add', web: 'add' }}
                  tintColor="#6C5CE7"
                  size={16}
                />
                <Text className="text-[#6C5CE7] font-bold text-sm ml-2">Add Exercise</Text>
              </Pressable>
            </View>
          ))}

          {/* Bottom Save Button */}
          <Pressable
            onPress={handleSave}
            disabled={isSaving}
            className="bg-[#6C5CE7] py-4 rounded-xl items-center justify-center mt-2 shadow-lg active:opacity-90 border border-[#A29BFE]/30"
          >
            {isSaving ? (
              <ActivityIndicator color="#FFF" />
            ) : (
              <Text className="text-white font-bold text-base">Save Workout Plan</Text>
            )}
          </Pressable>
        </ScrollView>
      </KeyboardAvoidingView>

      {/* Exercise Picker Modal */}
      <Modal
        visible={isPickerVisible}
        animationType="slide"
        transparent={false}
        onRequestClose={() => setIsPickerVisible(false)}
      >
        <SafeAreaView className="flex-1 bg-[#0A0A0F]">
          {/* Picker Header */}
          <View className="px-5 pt-3 pb-3 flex-row items-center justify-between border-b border-[#1E1E2E]">
            <Text className="text-lg font-bold text-[#F0F0F5]">Select Exercise</Text>
            <Pressable
              onPress={() => setIsPickerVisible(false)}
              className="w-10 h-10 rounded-full bg-[#14141F] items-center justify-center border border-[#1E1E2E]"
            >
              <SymbolView
                name={{ ios: 'xmark', android: 'close', web: 'close' }}
                tintColor="#F0F0F5"
                size={20}
              />
            </Pressable>
          </View>

          {/* Search Bar */}
          <View className="px-5 pt-4 pb-2">
            <View className="bg-[#14141F] px-4 py-2.5 rounded-xl border border-[#1E1E2E] flex-row items-center">
              <SymbolView
                name={{ ios: 'magnifyingglass', android: 'search', web: 'search' }}
                tintColor="#8888A0"
                size={18}
              />
              <TextInput
                value={searchQuery}
                onChangeText={setSearchQuery}
                placeholder="Search exercise name..."
                placeholderTextColor="#666680"
                className="flex-1 text-[#F0F0F5] ml-2.5 text-sm"
              />
              {searchQuery !== '' && (
                <Pressable onPress={() => setSearchQuery('')}>
                  <SymbolView
                    name={{ ios: 'xmark.circle.fill', android: 'cancel', web: 'cancel' }}
                    tintColor="#8888A0"
                    size={16}
                  />
                </Pressable>
              )}
            </View>
          </View>

          {/* Muscle Group Filter Tabs */}
          <View className="pb-3">
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              className="px-5"
              contentContainerStyle={{ gap: 8 }}
            >
              {MUSCLE_GROUPS.map((group) => (
                <Pressable
                  key={group}
                  onPress={() => setSelectedMuscle(group)}
                  className={`px-4 py-2 rounded-full border ${
                    selectedMuscle === group
                      ? 'bg-[#6C5CE7] border-[#6C5CE7]'
                      : 'bg-[#14141F] border-[#1E1E2E]'
                  }`}
                >
                  <Text
                    className={`text-xs font-semibold uppercase ${
                      selectedMuscle === group ? 'text-white' : 'text-[#8888A0]'
                    }`}
                  >
                    {group}
                  </Text>
                </Pressable>
              ))}
            </ScrollView>
          </View>

          {/* Exercise List */}
          <ScrollView className="flex-1 px-5" showsVerticalScrollIndicator={false}>
            {filteredExercises.length === 0 ? (
              <View className="py-12 items-center">
                <Text className="text-[#8888A0] text-sm">No exercises found</Text>
              </View>
            ) : (
              filteredExercises.map((ex) => (
                <Pressable
                  key={ex.id}
                  onPress={() => handleSelectExercise(ex)}
                  className="bg-[#14141F] p-4 rounded-xl mb-3 border border-[#1E1E2E] active:bg-[#1E1E2E]"
                >
                  <View className="flex-row items-center justify-between mb-1">
                    <Text className="text-base font-bold text-[#F0F0F5] flex-1 mr-2">
                      {ex.name}
                    </Text>
                    <View className="bg-[#6C5CE7]/15 px-2.5 py-0.5 rounded-md">
                      <Text className="text-[11px] font-semibold text-[#A29BFE] uppercase">
                        {ex.muscleGroup}
                      </Text>
                    </View>
                  </View>

                  <Text className="text-xs text-[#8888A0] capitalize">
                    Equipment: {ex.equipment}
                  </Text>

                  {ex.description && (
                    <Text className="text-xs text-[#8888A0]/80 mt-1" numberOfLines={1}>
                      {ex.description}
                    </Text>
                  )}
                </Pressable>
              ))
            )}
          </ScrollView>
        </SafeAreaView>
      </Modal>
    </SafeAreaView>
  );
}
