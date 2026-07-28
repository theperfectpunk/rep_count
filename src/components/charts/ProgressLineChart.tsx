import React, { useMemo } from 'react';
import { View, Text, Dimensions } from 'react-native';
import { LineChart } from 'react-native-gifted-charts';
import { Ionicons } from '@expo/vector-icons';
import { useSettingsStore } from '../../stores/settingsStore';

export interface ProgressDataPoint {
  date: string;
  weight: number;
  oneRM: number;
}

export interface ProgressLineChartProps {
  data: ProgressDataPoint[];
  metric?: 'oneRM' | 'weight';
  height?: number;
  unit?: 'kg' | 'lbs';
  title?: string;
}

export const ProgressLineChart: React.FC<ProgressLineChartProps> = ({
  data,
  metric = 'oneRM',
  height = 180,
  unit: propUnit,
  title,
}) => {
  const storeUnit = useSettingsStore((state) => state.unit);
  const activeUnit = propUnit || storeUnit;

  const chartData = useMemo(() => {
    if (!data || data.length === 0) return [];
    return data.map((item) => {
      const val = metric === 'weight' ? item.weight : item.oneRM;
      return {
        value: val,
        label: item.date,
        dataPointText: `${val}`,
      };
    });
  }, [data, metric]);

  const { minVal, maxVal } = useMemo(() => {
    if (chartData.length === 0) return { minVal: 0, maxVal: 100 };
    const values = chartData.map((d) => d.value);
    const min = Math.min(...values);
    const max = Math.max(...values);
    const padding = Math.max(Math.round((max - min) * 0.2), 10);
    return {
      minVal: Math.max(0, min - padding),
      maxVal: max + padding,
    };
  }, [chartData]);

  if (!data || data.length === 0) {
    return (
      <View className="bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-6 items-center justify-center min-h-[220px]">
        <View className="w-12 h-12 rounded-full bg-[#1E1E2E] items-center justify-center mb-3">
          <Ionicons name="trending-up-outline" size={24} color="#8888A0" />
        </View>
        <Text className="text-[#F0F0F5] text-base font-semibold mb-1 text-center">
          No Progression Data
        </Text>
        <Text className="text-[#8888A0] text-xs text-center px-4 leading-5">
          Log completed sets for this exercise over time to visualize your strength & 1RM growth.
        </Text>
      </View>
    );
  }

  const screenWidth = Dimensions.get('window').width;
  const chartWidth = Math.max(screenWidth - 80, 260);
  const spacing = Math.max(Math.floor(chartWidth / (chartData.length || 1)), 36);

  const metricLabel = metric === 'oneRM' ? 'Est. 1RM' : 'Max Weight';
  const latestVal = chartData[chartData.length - 1]?.value || 0;

  return (
    <View className="bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-4">
      <View className="flex-row justify-between items-center mb-4">
        <View className="flex-row items-center">
          <View className="w-2.5 h-2.5 rounded-full bg-[#00E676] mr-2" />
          <Text className="text-[#F0F0F5] text-sm font-bold">
            {title || `${metricLabel} Progression`}
          </Text>
        </View>
        <View className="bg-[#00E676]/15 border border-[#00E676]/30 px-2.5 py-0.5 rounded-full">
          <Text className="text-[#00E676] text-xs font-bold">
            Latest: {latestVal} {activeUnit}
          </Text>
        </View>
      </View>

      <View className="items-center justify-center overflow-hidden">
        <LineChart
          data={chartData}
          height={height}
          spacing={spacing}
          initialSpacing={16}
          endSpacing={16}
          color="#00E676"
          thickness={3}
          curved
          curvature={0.2}
          dataPointsColor="#00E676"
          dataPointsRadius={5}
          dataPointsHeight={10}
          dataPointsWidth={10}
          textColor="#F0F0F5"
          textFontSize={10}
          areaChart
          startFillColor="rgba(0, 230, 118, 0.3)"
          endFillColor="rgba(0, 230, 118, 0.0)"
          startOpacity={0.4}
          endOpacity={0.0}
          yAxisThickness={0}
          xAxisThickness={1}
          xAxisColor="#1E1E2E"
          yAxisTextStyle={{ color: '#8888A0', fontSize: 9 }}
          xAxisLabelTextStyle={{ color: '#8888A0', fontSize: 9 }}
          noOfSections={4}
          mostNegativeValue={0}
          maxValue={maxVal}
          rulesColor="#1E1E2E"
          rulesType="solid"
          isAnimated
          animationDuration={400}
          pointerConfig={{
            pointerStripColor: '#00E676',
            pointerStripWidth: 2,
            pointerColor: '#00E676',
            radius: 6,
            pointerLabelWidth: 80,
            pointerLabelHeight: 32,
            pointerLabelComponent: (items: any) => {
              const item = items[0];
              if (!item) return null;
              return (
                <View className="bg-[#1E1E2E] border border-[#00E676]/40 rounded-lg px-2 py-1 items-center justify-center">
                  <Text className="text-[#F0F0F5] text-xs font-bold">
                    {item.value} {activeUnit}
                  </Text>
                </View>
              );
            },
          }}
        />
      </View>
    </View>
  );
};

export default ProgressLineChart;
