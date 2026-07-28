import React from 'react';
import { View, Text } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

export interface StatsCardProps {
  icon: keyof typeof Ionicons.glyphMap | string;
  label: string;
  value: string | number;
  className?: string;
}

export const StatsCard: React.FC<StatsCardProps> = ({
  icon,
  label,
  value,
  className = '',
}) => {
  const isIoniconsName = (iconName: string): iconName is keyof typeof Ionicons.glyphMap => {
    return iconName in Ionicons.glyphMap;
  };

  return (
    <View className={`bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-3.5 flex-1 ${className}`}>
      <View className="w-9 h-9 rounded-xl bg-[#1E1E2E] items-center justify-center mb-2">
        {isIoniconsName(icon) ? (
          <Ionicons name={icon as any} size={20} color="#6C5CE7" />
        ) : (
          <Text className="text-base">{icon}</Text>
        )}
      </View>
      <Text className="text-[#8888A0] text-xs font-medium mb-1" numberOfLines={1}>
        {label}
      </Text>
      <Text className="text-[#F0F0F5] text-lg font-extrabold" numberOfLines={1} adjustsFontSizeToFit>
        {value}
      </Text>
    </View>
  );
};

export default StatsCard;
