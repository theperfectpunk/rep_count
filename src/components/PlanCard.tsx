import React from 'react';
import { View, Text, Pressable } from 'react-native';
import { WorkoutPlan } from '../data/prebuiltPlans';
import { CustomWorkoutPlan } from '../services/planService';

export interface PlanCardProps {
  plan: WorkoutPlan | CustomWorkoutPlan;
  isActive?: boolean;
  onPress: () => void;
}

export function PlanCard({ plan, isActive, onPress }: PlanCardProps) {
  const isCustom = plan.type === 'custom';

  const formatSplitName = (split: string) => {
    switch (split) {
      case 'ppl':
        return 'Push / Pull / Legs';
      case 'upper_lower':
        return 'Upper / Lower';
      case 'full_body':
        return 'Full Body';
      case 'bro_split':
        return '5-Day Bro Split';
      default:
        return split.charAt(0).toUpperCase() + split.slice(1);
    }
  };

  const totalExercises = plan.days.reduce((acc, day) => acc + (day.exercises?.length || 0), 0);

  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        {
          transform: [{ scale: pressed ? 0.98 : 1 }],
          opacity: pressed ? 0.9 : 1,
        },
      ]}
      className={`bg-[#14141F] rounded-xl p-5 mb-4 border border-[#1E1E2E] shadow-lg ${
        isActive ? 'border-l-4 border-l-[#6C5CE7]' : ''
      }`}
    >
      <View className="flex-row items-center justify-between mb-2">
        <View className="flex-1 mr-2">
          <Text className="text-xl font-bold text-[#F0F0F5]" numberOfLines={1}>
            {plan.name}
          </Text>
        </View>
        
        {/* Badge */}
        <View
          className={`px-3 py-1 rounded-full ${
            isCustom ? 'bg-[#00E676]/15 border border-[#00E676]/30' : 'bg-[#6C5CE7]/15 border border-[#6C5CE7]/30'
          }`}
        >
          <Text
            className={`text-xs font-semibold ${
              isCustom ? 'text-[#00E676]' : 'text-[#6C5CE7]'
            }`}
          >
            {isCustom ? 'Custom' : 'Pre-built'}
          </Text>
        </View>
      </View>

      {/* Meta Info (Split & Days) */}
      <View className="flex-row items-center flex-wrap gap-2 mb-2">
        <View className="bg-[#1E1E2E] px-2.5 py-1 rounded-md">
          <Text className="text-xs text-[#8888A0]">
            {formatSplitName(plan.split)}
          </Text>
        </View>
        <Text className="text-[#8888A0] text-xs">•</Text>
        <Text className="text-xs text-[#8888A0] font-medium">
          {plan.daysPerWeek} {plan.daysPerWeek === 1 ? 'day' : 'days'} / week
        </Text>
        <Text className="text-[#8888A0] text-xs">•</Text>
        <Text className="text-xs text-[#8888A0]">
          {totalExercises} exercises total
        </Text>
      </View>

      {/* Description */}
      {!!plan.description && (
        <Text className="text-[#8888A0] text-sm mt-1 leading-5" numberOfLines={2}>
          {plan.description}
        </Text>
      )}

      {/* Active Indicator Bar */}
      {isActive && (
        <View className="mt-3 pt-3 border-t border-[#1E1E2E] flex-row items-center justify-between">
          <View className="flex-row items-center">
            <View className="w-2.5 h-2.5 rounded-full bg-[#00E676] mr-2" />
            <Text className="text-xs font-semibold text-[#00E676]">ACTIVE PLAN</Text>
          </View>
          <Text className="text-xs text-[#6C5CE7] font-semibold">Tap to view details →</Text>
        </View>
      )}
    </Pressable>
  );
}

export default PlanCard;
