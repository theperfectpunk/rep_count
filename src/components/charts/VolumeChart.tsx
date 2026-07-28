import React, { useMemo } from 'react';
import { View, Text, ActivityIndicator, Dimensions } from 'react-native';
import { BarChart } from 'react-native-gifted-charts';
import { Ionicons } from '@expo/vector-icons';
import { WorkoutSession, getWorkoutsByDateRange } from '../../services/workoutService';
import { useSettingsStore } from '../../stores/settingsStore';
import { useAuth } from '../../hooks/useAuth';
import { useQuery } from '@tanstack/react-query';
import { formatWeight, formatNumber } from '../../utils/formatters';

export interface VolumeChartProps {
  sessions?: WorkoutSession[];
  weeksCount?: number;
  height?: number;
  unit?: 'kg' | 'lbs';
  isLoading?: boolean;
}

interface WeekBucket {
  startDate: Date;
  endDate: Date;
  label: string;
  shortLabel: string;
  volume: number;
}

export const VolumeChart: React.FC<VolumeChartProps> = ({
  sessions: propSessions,
  weeksCount = 8,
  height = 180,
  unit: propUnit,
  isLoading: propIsLoading,
}) => {
  const { user } = useAuth();
  const storeUnit = useSettingsStore((state) => state.unit);
  const activeUnit = propUnit || storeUnit;

  // Calculate start/end date for range if fetching via query
  const dateRange = useMemo(() => {
    const end = new Date();
    end.setHours(23, 59, 59, 999);
    const start = new Date();
    start.setDate(end.getDate() - weeksCount * 7 + 1);
    start.setHours(0, 0, 0, 0);
    return { start, end };
  }, [weeksCount]);

  // Fetch sessions if not provided as prop
  const { data: fetchedSessions, isLoading: queryIsLoading } = useQuery({
    queryKey: ['workoutsDateRange', user?.uid, dateRange.start.toISOString(), dateRange.end.toISOString()],
    queryFn: () => getWorkoutsByDateRange(user!.uid, dateRange.start, dateRange.end),
    enabled: !propSessions && !!user?.uid,
  });

  const activeSessions = propSessions ?? fetchedSessions ?? [];
  const isLoading = propIsLoading || (!propSessions && queryIsLoading);

  // Build week buckets and aggregate volume
  const chartData = useMemo(() => {
    const now = new Date();

    // Create week buckets from (weeksCount - 1) weeks ago up to current week
    const buckets: WeekBucket[] = [];
    
    // Find the Monday of current week
    const currentDay = now.getDay();
    const distanceToMonday = currentDay === 0 ? -6 : 1 - currentDay;
    const currentWeekMonday = new Date(now);
    currentWeekMonday.setDate(now.getDate() + distanceToMonday);
    currentWeekMonday.setHours(0, 0, 0, 0);

    for (let i = weeksCount - 1; i >= 0; i--) {
      const weekStart = new Date(currentWeekMonday);
      weekStart.setDate(currentWeekMonday.getDate() - i * 7);
      
      const weekEnd = new Date(weekStart);
      weekEnd.setDate(weekStart.getDate() + 6);
      weekEnd.setHours(23, 59, 59, 999);

      // Label format: "M/D"
      const monthStr = weekStart.getMonth() + 1;
      const dayStr = weekStart.getDate();
      const shortLabel = `${monthStr}/${dayStr}`;
      
      const isThisWeek = i === 0;
      const label = isThisWeek ? 'This Wk' : shortLabel;

      buckets.push({
        startDate: weekStart,
        endDate: weekEnd,
        label,
        shortLabel,
        volume: 0,
      });
    }

    // Populate volume into buckets
    activeSessions.forEach((session) => {
      let sessionDate: Date | null = null;
      if (session.finishedAt) {
        if (typeof session.finishedAt.toDate === 'function') {
          sessionDate = session.finishedAt.toDate();
        } else if (session.finishedAt.seconds) {
          sessionDate = new Date(session.finishedAt.seconds * 1000);
        } else {
          sessionDate = new Date(session.finishedAt);
        }
      } else if (session.startedAt) {
        if (typeof session.startedAt.toDate === 'function') {
          sessionDate = session.startedAt.toDate();
        } else {
          sessionDate = new Date(session.startedAt);
        }
      }

      if (sessionDate && !isNaN(sessionDate.getTime())) {
        const volume = session.totalVolume || 0;
        const bucket = buckets.find(
          (b) => sessionDate! >= b.startDate && sessionDate! <= b.endDate
        );
        if (bucket) {
          bucket.volume += volume;
        }
      }
    });

    return buckets.map((bucket) => ({
      value: Math.round(bucket.volume),
      label: bucket.label,
      frontColor: bucket.volume > 0 ? '#6C5CE7' : '#1E1E2E',
      topLabelComponent: bucket.volume > 0 ? () => (
        <Text style={{ color: '#A29BFE', fontSize: 9, fontWeight: '600', marginBottom: 2 }}>
          {bucket.volume >= 1000 ? `${(bucket.volume / 1000).toFixed(1)}k` : bucket.volume}
        </Text>
      ) : undefined,
    }));
  }, [activeSessions, weeksCount]);

  const totalPeriodVolume = useMemo(() => {
    return chartData.reduce((acc, curr) => acc + curr.value, 0);
  }, [chartData]);

  const maxVolume = useMemo(() => {
    return Math.max(...chartData.map((d) => d.value), 100);
  }, [chartData]);

  if (isLoading) {
    return (
      <View className="bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-5 items-center justify-center min-h-[220px]">
        <ActivityIndicator size="small" color="#6C5CE7" />
        <Text className="text-[#8888A0] text-xs mt-3">Loading weekly volume data...</Text>
      </View>
    );
  }

  if (chartData.length === 0 || totalPeriodVolume === 0) {
    return (
      <View className="bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-6 items-center justify-center min-h-[220px]">
        <View className="w-12 h-12 rounded-full bg-[#1E1E2E] items-center justify-center mb-3">
          <Ionicons name="bar-chart-outline" size={24} color="#8888A0" />
        </View>
        <Text className="text-[#F0F0F5] text-base font-semibold mb-1 text-center">
          No Volume Recorded
        </Text>
        <Text className="text-[#8888A0] text-xs text-center px-4 leading-5">
          Complete workouts over the next few weeks to track your total lifted volume trends here.
        </Text>
      </View>
    );
  }

  const screenWidth = Dimensions.get('window').width;
  const chartWidth = Math.max(screenWidth - 80, 260);
  const barWidth = Math.max(Math.floor((chartWidth - 80) / weeksCount) - 6, 16);

  return (
    <View className="bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-4">
      <View className="flex-row justify-between items-center mb-4">
        <View className="flex-row items-center">
          <View className="w-2.5 h-2.5 rounded-full bg-[#6C5CE7] mr-2" />
          <Text className="text-[#F0F0F5] text-sm font-bold">Weekly Volume</Text>
        </View>
        <Text className="text-[#A29BFE] text-xs font-medium">
          Total: {formatNumber(totalPeriodVolume)} {activeUnit}
        </Text>
      </View>

      <View className="items-center justify-center overflow-hidden">
        <BarChart
          data={chartData}
          height={height}
          barWidth={barWidth}
          spacing={10}
          initialSpacing={12}
          barBorderRadius={4}
          yAxisThickness={0}
          xAxisThickness={1}
          xAxisColor="#1E1E2E"
          yAxisTextStyle={{ color: '#8888A0', fontSize: 9 }}
          xAxisLabelTextStyle={{ color: '#8888A0', fontSize: 9 }}
          noOfSections={4}
          maxValue={maxVolume * 1.15}
          rulesColor="#1E1E2E"
          rulesType="solid"
          isAnimated
          animationDuration={400}
          formatYLabel={(val) => {
            const num = Number(val);
            if (num >= 1000) return `${(num / 1000).toFixed(0)}k`;
            return `${num}`;
          }}
        />
      </View>
    </View>
  );
};

export default VolumeChart;
