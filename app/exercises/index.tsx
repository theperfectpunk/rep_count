import React, { useState, useMemo } from 'react';
import {
  View,
  Text,
  TextInput,
  FlatList,
  TouchableOpacity,
  ScrollView,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

import { exercises, Exercise } from '../../src/data/exercises';

const MUSCLE_GROUPS = [
  'all',
  'chest',
  'back',
  'legs',
  'shoulders',
  'arms',
  'core',
] as const;

export default function ExerciseLibraryScreen() {
  const router = useRouter();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedGroup, setSelectedGroup] = useState<string>('all');
  const [expandedId, setExpandedId] = useState<string | null>(null);

  const filteredExercises = useMemo(() => {
    return exercises.filter((ex) => {
      const matchesGroup =
        selectedGroup === 'all' ||
        ex.muscleGroup.toLowerCase() === selectedGroup.toLowerCase();
      const matchesSearch =
        ex.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        ex.equipment.toLowerCase().includes(searchQuery.toLowerCase());
      return matchesGroup && matchesSearch;
    });
  }, [searchQuery, selectedGroup]);

  const toggleExpand = (id: string) => {
    setExpandedId((prev) => (prev === id ? null : id));
  };

  const renderExerciseItem = ({ item }: { item: Exercise }) => {
    const isExpanded = expandedId === item.id;

    return (
      <TouchableOpacity
        activeOpacity={0.85}
        onPress={() => toggleExpand(item.id)}
        className="bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-4 mb-3"
      >
        <View className="flex-row items-center justify-between">
          <View className="flex-1 mr-2">
            <Text className="text-[#F0F0F5] text-base font-bold mb-1">
              {item.name}
            </Text>
            <View className="flex-row items-center flex-wrap gap-2">
              <View className="bg-[#6C5CE7]/20 border border-[#6C5CE7]/40 px-2.5 py-0.5 rounded-md">
                <Text className="text-[#A29BFE] text-xs font-semibold capitalize">
                  {item.muscleGroup}
                </Text>
              </View>
              <View className="bg-[#1E1E2E] px-2.5 py-0.5 rounded-md">
                <Text className="text-[#8888A0] text-xs font-medium capitalize">
                  {item.equipment}
                </Text>
              </View>
            </View>
          </View>
          <Ionicons
            name={isExpanded ? 'chevron-up' : 'chevron-down'}
            size={20}
            color="#8888A0"
          />
        </View>

        {isExpanded && (
          <View className="mt-3 pt-3 border-t border-[#1E1E2E]">
            <Text className="text-[#8888A0] text-xs font-semibold mb-1 uppercase tracking-wider">
              Instructions & Technique
            </Text>
            <Text className="text-[#F0F0F5] text-sm leading-5">
              {item.description}
            </Text>
          </View>
        )}
      </TouchableOpacity>
    );
  };

  return (
    <SafeAreaView className="flex-1 bg-[#0A0A0F]" edges={['top', 'left', 'right']}>
      {/* Header Bar */}
      <View className="flex-row items-center px-4 py-3 border-b border-[#1E1E2E]">
        <TouchableOpacity
          onPress={() => router.back()}
          className="w-10 h-10 rounded-xl bg-[#14141F] border border-[#1E1E2E] items-center justify-center mr-3"
        >
          <Ionicons name="arrow-back" size={20} color="#F0F0F5" />
        </TouchableOpacity>
        <View className="flex-1">
          <Text className="text-[#F0F0F5] text-xl font-extrabold">Exercise Library</Text>
          <Text className="text-[#8888A0] text-xs font-medium">
            {filteredExercises.length} movements available
          </Text>
        </View>
      </View>

      {/* Search Input */}
      <View className="px-4 pt-4 pb-2">
        <View className="flex-row items-center bg-[#14141F] border border-[#1E1E2E] rounded-xl px-3 py-2.5">
          <Ionicons name="search" size={18} color="#8888A0" style={{ marginRight: 8 }} />
          <TextInput
            value={searchQuery}
            onChangeText={setSearchQuery}
            placeholder="Search exercises or equipment..."
            placeholderTextColor="#8888A0"
            className="flex-1 text-[#F0F0F5] text-sm font-medium p-0"
          />
          {searchQuery.length > 0 && (
            <TouchableOpacity onPress={() => setSearchQuery('')}>
              <Ionicons name="close-circle" size={18} color="#8888A0" />
            </TouchableOpacity>
          )}
        </View>
      </View>

      {/* Muscle Group Filter Pills */}
      <View className="py-2">
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={{ paddingHorizontal: 16, gap: 8 }}
        >
          {MUSCLE_GROUPS.map((group) => {
            const isSelected = selectedGroup === group;
            return (
              <TouchableOpacity
                key={group}
                onPress={() => setSelectedGroup(group)}
                className={`px-4 py-2 rounded-xl border ${
                  isSelected
                    ? 'bg-[#6C5CE7] border-[#A29BFE]'
                    : 'bg-[#14141F] border-[#1E1E2E]'
                }`}
              >
                <Text
                  className={`text-xs font-extrabold capitalize ${
                    isSelected ? 'text-white' : 'text-[#8888A0]'
                  }`}
                >
                  {group}
                </Text>
              </TouchableOpacity>
            );
          })}
        </ScrollView>
      </View>

      {/* Exercises List */}
      <FlatList
        data={filteredExercises}
        keyExtractor={(item) => item.id}
        renderItem={renderExerciseItem}
        contentContainerStyle={{ padding: 16, paddingBottom: 40 }}
        showsVerticalScrollIndicator={false}
        ListEmptyComponent={
          <View className="py-12 items-center justify-center">
            <Ionicons name="alert-circle-outline" size={40} color="#8888A0" />
            <Text className="text-[#F0F0F5] text-base font-bold mt-2">
              No Exercises Found
            </Text>
            <Text className="text-[#8888A0] text-xs text-center mt-1">
              Try searching for another term or selecting a different muscle group.
            </Text>
          </View>
        }
      />
    </SafeAreaView>
  );
}
