import React, { useState, useEffect } from 'react';
import { View, Text, TextInput, Pressable } from 'react-native';
import { Swipeable } from 'react-native-gesture-handler';
import { Ionicons } from '@expo/vector-icons';
import { ExerciseSet } from '../stores/workoutStore';

export interface SetRowProps {
  set: ExerciseSet;
  exerciseIndex: number;
  setIndex: number;
  unit: 'kg' | 'lbs';
  previousBest?: string;
  onUpdate: (exerciseIndex: number, setIndex: number, data: Partial<ExerciseSet>) => void;
  onComplete: (exerciseIndex: number, setIndex: number) => void;
  onDelete: (exerciseIndex: number, setIndex: number) => void;
}

export const SetRow: React.FC<SetRowProps> = ({
  set,
  exerciseIndex,
  setIndex,
  unit,
  previousBest = '-',
  onUpdate,
  onComplete,
  onDelete,
}) => {
  const [weightText, setWeightText] = useState<string>(
    set.weight !== null && set.weight !== undefined ? String(set.weight) : ''
  );
  const [repsText, setRepsText] = useState<string>(
    set.reps !== null && set.reps !== undefined ? String(set.reps) : ''
  );

  useEffect(() => {
    setWeightText(set.weight !== null && set.weight !== undefined ? String(set.weight) : '');
  }, [set.weight]);

  useEffect(() => {
    setRepsText(set.reps !== null && set.reps !== undefined ? String(set.reps) : '');
  }, [set.reps]);

  const handleWeightChange = (text: string) => {
    setWeightText(text);
    const num = parseFloat(text);
    onUpdate(exerciseIndex, setIndex, {
      weight: !text || isNaN(num) ? null : num,
    });
  };

  const handleRepsChange = (text: string) => {
    setRepsText(text);
    const num = parseInt(text, 10);
    onUpdate(exerciseIndex, setIndex, {
      reps: !text || isNaN(num) ? null : num,
    });
  };

  const toggleWarmup = () => {
    onUpdate(exerciseIndex, setIndex, { isWarmup: !set.isWarmup });
  };

  const renderRightActions = () => {
    return (
      <Pressable
        onPress={() => onDelete(exerciseIndex, setIndex)}
        className="bg-[#FF5252] justify-center items-center px-4 rounded-r-xl mb-2.5 h-12"
      >
        <Ionicons name="trash-outline" size={20} color="#FFFFFF" />
      </Pressable>
    );
  };

  return (
    <Swipeable renderRightActions={renderRightActions} friction={2} rightThreshold={40}>
      <Pressable
        onLongPress={() => onDelete(exerciseIndex, setIndex)}
        className={`flex-row items-center justify-between px-3 py-2 mb-2.5 rounded-xl border ${
          set.isCompleted
            ? 'bg-[#00E676]/10 border-l-4 border-l-[#00E676] border-y-[#00E676]/20 border-r-[#00E676]/20'
            : 'bg-[#1E1E2E] border-[#2A2A3D] border-l-4 border-l-transparent'
        }`}
      >
        {/* Set Number / Warmup Badge */}
        <Pressable
          onPress={toggleWarmup}
          className="w-9 items-center justify-center py-1 rounded-md"
          hitSlop={6}
        >
          {set.isWarmup ? (
            <View className="bg-[#FFD600]/20 px-2 py-0.5 rounded border border-[#FFD600]/40">
              <Text className="text-[#FFD600] font-extrabold text-xs">W</Text>
            </View>
          ) : (
            <Text className="text-[#8888A0] font-bold text-sm">{set.setNumber}</Text>
          )}
        </Pressable>

        {/* Previous Best */}
        <View className="w-16 items-center justify-center">
          <Text className="text-[#8888A0] text-xs font-medium" numberOfLines={1}>
            {previousBest}
          </Text>
        </View>

        {/* Weight Input */}
        <View className="flex-1 max-w-[80px] mx-1">
          <TextInput
            value={weightText}
            onChangeText={handleWeightChange}
            placeholder="0"
            placeholderTextColor="#666680"
            keyboardType="decimal-pad"
            returnKeyType="done"
            selectTextOnFocus
            className="bg-[#14141F] text-[#F0F0F5] font-bold text-center py-1.5 px-2 rounded-lg border border-[#2A2A3D] text-sm"
          />
        </View>

        {/* Multiplier Label */}
        <Text className="text-[#8888A0] font-bold text-xs mx-0.5">×</Text>

        {/* Reps Input */}
        <View className="flex-1 max-w-[80px] mx-1">
          <TextInput
            value={repsText}
            onChangeText={handleRepsChange}
            placeholder="0"
            placeholderTextColor="#666680"
            keyboardType="number-pad"
            returnKeyType="done"
            selectTextOnFocus
            className="bg-[#14141F] text-[#F0F0F5] font-bold text-center py-1.5 px-2 rounded-lg border border-[#2A2A3D] text-sm"
          />
        </View>

        {/* Complete Checkmark Button */}
        <Pressable
          onPress={() => onComplete(exerciseIndex, setIndex)}
          className={`w-9 h-9 rounded-xl items-center justify-center ml-1.5 ${
            set.isCompleted ? 'bg-[#00E676]' : 'bg-[#2A2A3D] active:bg-[#35354D]'
          }`}
          hitSlop={4}
        >
          <Ionicons
            name={set.isCompleted ? 'checkmark-sharp' : 'checkmark-sharp'}
            size={20}
            color={set.isCompleted ? '#0A0A0F' : '#8888A0'}
          />
        </Pressable>
      </Pressable>
    </Swipeable>
  );
};
