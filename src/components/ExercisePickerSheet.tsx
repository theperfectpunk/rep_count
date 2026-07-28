import React, { useState, useMemo } from 'react';
import {
  Modal,
  View,
  Text,
  TextInput,
  TouchableOpacity,
  FlatList,
  Pressable,
  SafeAreaView,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { exercises, Exercise } from '../data/exercises';

export interface ExercisePickerSheetProps {
  visible: boolean;
  onClose: () => void;
  onSelect: (exercise: Exercise) => void;
}

const CATEGORIES = ['All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'] as const;
type Category = (typeof CATEGORIES)[number];

const MUSCLE_COLORS: Record<string, string> = {
  chest: '#FF5252',
  back: '#3B82F6',
  legs: '#10B981',
  shoulders: '#F59E0B',
  arms: '#8B5CF6',
  core: '#EC4899',
};

export const ExercisePickerSheet: React.FC<ExercisePickerSheetProps> = ({
  visible,
  onClose,
  onSelect,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<Category>('All');

  const filteredExercises = useMemo(() => {
    return exercises.filter((ex) => {
      const matchesCategory =
        selectedCategory === 'All' || ex.muscleGroup.toLowerCase() === selectedCategory.toLowerCase();
      const matchesSearch =
        ex.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        ex.equipment.toLowerCase().includes(searchQuery.toLowerCase()) ||
        ex.muscleGroup.toLowerCase().includes(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    });
  }, [searchQuery, selectedCategory]);

  const handleSelect = (exercise: Exercise) => {
    onSelect(exercise);
    onClose();
    setSearchQuery('');
    setSelectedCategory('All');
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent={true}
      onRequestClose={onClose}
    >
      <View className="flex-1 justify-end bg-black/75">
        {/* Touch outside to dismiss */}
        <Pressable className="flex-1" onPress={onClose} />

        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
          className="bg-[#14141F] rounded-t-3xl border-t border-[#1E1E2E] max-h-[88%] min-h-[60%] flex-col"
        >
          {/* Handle indicator */}
          <View className="items-center py-2.5">
            <View className="w-12 h-1.5 bg-[#2A2A3D] rounded-full" />
          </View>

          {/* Header */}
          <View className="flex-row items-center justify-between px-5 pb-3 border-b border-[#1E1E2E]">
            <View>
              <Text className="text-[#F0F0F5] text-xl font-black">Select Exercise</Text>
              <Text className="text-[#8888A0] text-xs font-medium mt-0.5">
                Choose an exercise to add to your workout
              </Text>
            </View>
            <TouchableOpacity
              onPress={onClose}
              className="w-8 h-8 rounded-full bg-[#1E1E2E] items-center justify-center"
            >
              <Ionicons name="close" size={20} color="#F0F0F5" />
            </TouchableOpacity>
          </View>

          {/* Search Input */}
          <View className="px-5 pt-3 pb-2">
            <View className="flex-row items-center bg-[#1E1E2E] px-3.5 py-2.5 rounded-xl border border-[#2A2A3D]">
              <Ionicons name="search-outline" size={18} color="#8888A0" />
              <TextInput
                value={searchQuery}
                onChangeText={setSearchQuery}
                placeholder="Search exercise, muscle, equipment..."
                placeholderTextColor="#666680"
                className="flex-1 ml-2.5 text-[#F0F0F5] text-sm font-semibold p-0"
                autoCapitalize="none"
                autoCorrect={false}
              />
              {searchQuery.length > 0 && (
                <TouchableOpacity onPress={() => setSearchQuery('')}>
                  <Ionicons name="close-circle" size={18} color="#8888A0" />
                </TouchableOpacity>
              )}
            </View>
          </View>

          {/* Muscle Category Tabs */}
          <View className="pb-3 border-b border-[#1E1E2E]">
            <FlatList
              horizontal
              data={CATEGORIES}
              keyExtractor={(item) => item}
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={{ paddingHorizontal: 20, gap: 8 }}
              renderItem={({ item }) => {
                const isActive = selectedCategory === item;
                return (
                  <TouchableOpacity
                    onPress={() => setSelectedCategory(item)}
                    className={`px-4 py-2 rounded-full border ${
                      isActive
                        ? 'bg-[#6C5CE7] border-[#6C5CE7]'
                        : 'bg-[#1E1E2E] border-[#2A2A3D]'
                    }`}
                  >
                    <Text
                      className={`text-xs font-bold ${
                        isActive ? 'text-white' : 'text-[#8888A0]'
                      }`}
                    >
                      {item}
                    </Text>
                  </TouchableOpacity>
                );
              }}
            />
          </View>

          {/* Exercise List */}
          <FlatList
            data={filteredExercises}
            keyExtractor={(item) => item.id}
            contentContainerStyle={{ paddingHorizontal: 20, paddingVertical: 12 }}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
            ListEmptyComponent={
              <View className="items-center justify-center py-12">
                <Ionicons name="fitness-outline" size={48} color="#2A2A3D" />
                <Text className="text-[#8888A0] font-bold text-base mt-3">No exercises found</Text>
                <Text className="text-[#666680] text-xs mt-1 text-center">
                  Try searching for another exercise name or muscle group
                </Text>
              </View>
            }
            renderItem={({ item }) => {
              const muscleColor = MUSCLE_COLORS[item.muscleGroup] || '#6C5CE7';
              return (
                <TouchableOpacity
                  onPress={() => handleSelect(item)}
                  className="flex-row items-center justify-between bg-[#1E1E2E] p-4 mb-2.5 rounded-2xl border border-[#2A2A3D] active:bg-[#252538]"
                >
                  <View className="flex-1 mr-3">
                    <Text className="text-[#F0F0F5] font-bold text-base mb-1">
                      {item.name}
                    </Text>
                    <View className="flex-row items-center gap-2">
                      <View className="flex-row items-center">
                        <Ionicons name="barbell-outline" size={12} color="#8888A0" />
                        <Text className="text-[#8888A0] text-xs capitalize ml-1 font-medium">
                          {item.equipment}
                        </Text>
                      </View>
                    </View>
                  </View>

                  {/* Muscle Badge */}
                  <View
                    style={{ backgroundColor: `${muscleColor}20`, borderColor: `${muscleColor}50` }}
                    className="px-3 py-1 rounded-full border"
                  >
                    <Text style={{ color: muscleColor }} className="text-xs font-extrabold uppercase">
                      {item.muscleGroup}
                    </Text>
                  </View>
                </TouchableOpacity>
              );
            }}
          />
        </KeyboardAvoidingView>
      </View>
    </Modal>
  );
};
