import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { WorkoutSession } from '../services/workoutService';
import { formatRelativeDate, formatWeight } from '../utils/formatters';

export interface WorkoutSummaryCardProps {
  workout: WorkoutSession;
  unit?: 'kg' | 'lbs';
  onPress?: () => void;
}

export const WorkoutSummaryCard: React.FC<WorkoutSummaryCardProps> = ({
  workout,
  unit = 'kg',
  onPress,
}) => {
  const dateObj = workout.finishedAt?.toDate
    ? workout.finishedAt.toDate()
    : workout.finishedAt
    ? new Date(workout.finishedAt as any)
    : new Date();

  const formattedDate = formatRelativeDate(dateObj);
  const exerciseCount = workout.exercises?.length || 0;
  const formattedVolume = formatWeight(workout.totalVolume || 0, unit);

  return (
    <TouchableOpacity
      activeOpacity={0.7}
      onPress={onPress}
      className="bg-[#14141F] border border-[#1E1E2E] border-l-4 border-l-[#6C5CE7] rounded-xl p-4 mb-3"
    >
      <View className="flex-row justify-between items-center mb-2">
        <Text className="text-[#F0F0F5] text-base font-bold flex-1 mr-2" numberOfLines={1}>
          {workout.workoutName || 'Workout'}
        </Text>
        <View className="flex-row items-center bg-[#1E1E2E] px-2.5 py-1 rounded-full">
          <Ionicons name="calendar-outline" size={12} color="#8888A0" style={{ marginRight: 4 }} />
          <Text className="text-[#8888A0] text-xs font-medium">{formattedDate}</Text>
        </View>
      </View>

      <View className="flex-row items-center justify-between pt-2 border-t border-[#1E1E2E]/60 mt-1">
        <View className="flex-row items-center flex-wrap gap-x-4">
          <View className="flex-row items-center">
            <Ionicons name="barbell-outline" size={14} color="#A29BFE" style={{ marginRight: 4 }} />
            <Text className="text-[#F0F0F5] text-xs font-semibold">{formattedVolume}</Text>
          </View>

          <View className="flex-row items-center">
            <Ionicons name="fitness-outline" size={14} color="#A29BFE" style={{ marginRight: 4 }} />
            <Text className="text-[#8888A0] text-xs">
              {exerciseCount} {exerciseCount === 1 ? 'exercise' : 'exercises'}
            </Text>
          </View>

          {workout.totalSets ? (
            <View className="flex-row items-center">
              <Ionicons name="layers-outline" size={14} color="#A29BFE" style={{ marginRight: 4 }} />
              <Text className="text-[#8888A0] text-xs">{workout.totalSets} sets</Text>
            </View>
          ) : null}
        </View>

        <Ionicons name="chevron-forward" size={16} color="#8888A0" />
      </View>
    </TouchableOpacity>
  );
};

export default WorkoutSummaryCard;
