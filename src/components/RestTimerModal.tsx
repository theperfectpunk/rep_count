import React, { useEffect, useState, useRef } from 'react';
import {
  Modal,
  View,
  Text,
  TouchableOpacity,
  Pressable,
  Platform,
} from 'react-native';
import * as Haptics from 'expo-haptics';
import * as Notifications from 'expo-notifications';
import Svg, { Circle } from 'react-native-svg';
import { Ionicons } from '@expo/vector-icons';
import { useWorkoutStore } from '../stores/workoutStore';
import { formatDuration } from '../utils/formatters';

// Notification handler configuration
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

const PRESETS = [30, 60, 90, 120, 180];
const RADIUS = 90;
const STROKE_WIDTH = 10;
const CIRCUMFERENCE = 2 * Math.PI * RADIUS;

export const RestTimerModal: React.FC = () => {
  const { restTimerEndTime, restTimerDuration, startRestTimer, clearRestTimer } =
    useWorkoutStore();

  const [remaining, setRemaining] = useState<number>(0);
  const notificationIdRef = useRef<string | null>(null);

  const isVisible = restTimerEndTime !== null;

  // Calculate remaining seconds from timestamp math
  useEffect(() => {
    if (!restTimerEndTime) {
      setRemaining(0);
      return;
    }

    const updateTimer = () => {
      const diff = Math.max(0, Math.ceil((restTimerEndTime - Date.now()) / 1000));
      setRemaining(diff);

      if (diff === 0) {
        // Trigger Success Haptic
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success).catch(() => {});
        clearRestTimer();
      }
    };

    // Immediate calculation
    updateTimer();

    // 1-second interval ONLY for UI re-renders
    const interval = setInterval(updateTimer, 1000);

    return () => clearInterval(interval);
  }, [restTimerEndTime, clearRestTimer]);

  // Schedule local notification whenever restTimerEndTime changes
  useEffect(() => {
    const manageNotification = async () => {
      // Cancel previous notification if any
      if (Platform.OS !== 'web') {
        try {
          if (notificationIdRef.current) {
            await Notifications.cancelScheduledNotificationAsync(notificationIdRef.current);
            notificationIdRef.current = null;
          }
        } catch (e) {
          // ignore
        }
      }

      if (restTimerEndTime && Platform.OS !== 'web') {
        const secondsLeft = Math.max(1, Math.ceil((restTimerEndTime - Date.now()) / 1000));
        if (secondsLeft > 0) {
          try {
            const id = await Notifications.scheduleNotificationAsync({
              content: {
                title: 'Rest Completed! ⏱️',
                body: 'Time for your next set! Keep pushing!',
                sound: true,
              },
              trigger: {
                type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL,
                seconds: secondsLeft,
              },
            });
            notificationIdRef.current = id;
          } catch (e) {
            // ignore notification permission or scheduling errors gracefully
          }
        }
      }
    };

    manageNotification();
  }, [restTimerEndTime]);

  if (!isVisible) {
    return null;
  }

  const handleAdjust = (secondsChange: number) => {
    if (!restTimerEndTime) return;
    const currentRem = Math.max(0, Math.ceil((restTimerEndTime - Date.now()) / 1000));
    const newRem = currentRem + secondsChange;

    if (newRem <= 0) {
      handleSkip();
    } else {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {});
      startRestTimer(newRem);
    }
  };

  const handlePreset = (presetSec: number) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium).catch(() => {});
    startRestTimer(presetSec);
  };

  const handleSkip = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {});
    if (Platform.OS !== 'web' && notificationIdRef.current) {
      Notifications.cancelScheduledNotificationAsync(notificationIdRef.current).catch(() => {});
      notificationIdRef.current = null;
    }
    clearRestTimer();
  };

  const totalDuration = restTimerDuration || 90;
  const progress = Math.min(1, Math.max(0, remaining / totalDuration));
  const strokeDashoffset = CIRCUMFERENCE - progress * CIRCUMFERENCE;

  return (
    <Modal visible={isVisible} animationType="fade" transparent={true}>
      <View className="flex-1 bg-black/85 justify-center items-center px-6">
        <View className="w-full max-w-sm bg-[#14141F] rounded-3xl p-6 border border-[#1E1E2E] items-center shadow-2xl">
          {/* Header */}
          <Text className="text-[#8888A0] font-extrabold text-xs tracking-widest uppercase mb-1">
            Rest Timer
          </Text>
          <Text className="text-[#F0F0F5] font-black text-xl mb-6">Take a Breather</Text>

          {/* Circular Countdown Display */}
          <View className="items-center justify-center relative mb-6">
            <Svg width={220} height={220} viewBox="0 0 220 220">
              {/* Background Ring */}
              <Circle
                cx={110}
                cy={110}
                r={RADIUS}
                stroke="#1E1E2E"
                strokeWidth={STROKE_WIDTH}
                fill="none"
              />
              {/* Animated Progress Ring */}
              <Circle
                cx={110}
                cy={110}
                r={RADIUS}
                stroke="#6C5CE7"
                strokeWidth={STROKE_WIDTH}
                fill="none"
                strokeDasharray={CIRCUMFERENCE}
                strokeDashoffset={strokeDashoffset}
                strokeLinecap="round"
                transform="rotate(-90 110 110)"
              />
            </Svg>

            {/* Countdown Text */}
            <View className="absolute items-center justify-center">
              <Text className="text-5xl font-black text-[#F0F0F5] tracking-tighter">
                {formatDuration(remaining)}
              </Text>
              <Text className="text-[#8888A0] text-xs font-bold mt-1 uppercase tracking-wider">
                Remaining
              </Text>
            </View>
          </View>

          {/* Quick Adjustment Controls (+30s / -30s) */}
          <View className="flex-row items-center gap-4 mb-6">
            <TouchableOpacity
              onPress={() => handleAdjust(-30)}
              className="bg-[#1E1E2E] border border-[#2A2A3D] px-5 py-2.5 rounded-2xl active:bg-[#252538]"
            >
              <Text className="text-[#F0F0F5] font-extrabold text-sm">-30s</Text>
            </TouchableOpacity>

            <TouchableOpacity
              onPress={() => handleAdjust(30)}
              className="bg-[#1E1E2E] border border-[#2A2A3D] px-5 py-2.5 rounded-2xl active:bg-[#252538]"
            >
              <Text className="text-[#F0F0F5] font-extrabold text-sm">+30s</Text>
            </TouchableOpacity>
          </View>

          {/* Presets Row */}
          <View className="w-full mb-6">
            <Text className="text-[#8888A0] text-xs font-bold mb-2 text-center">Presets</Text>
            <View className="flex-row justify-between">
              {PRESETS.map((sec) => {
                const isActive = totalDuration === sec;
                return (
                  <TouchableOpacity
                    key={sec}
                    onPress={() => handlePreset(sec)}
                    className={`px-3 py-1.5 rounded-xl border ${
                      isActive
                        ? 'bg-[#6C5CE7] border-[#6C5CE7]'
                        : 'bg-[#1E1E2E] border-[#2A2A3D]'
                    }`}
                  >
                    <Text
                      className={`text-xs font-extrabold ${
                        isActive ? 'text-white' : 'text-[#8888A0]'
                      }`}
                    >
                      {sec}s
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>

          {/* Skip / Dismiss Button */}
          <TouchableOpacity
            onPress={handleSkip}
            className="w-full bg-[#6C5CE7] py-3.5 rounded-2xl items-center shadow-lg active:bg-[#5A4AD1]"
          >
            <Text className="text-white font-extrabold text-base">Skip Rest</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
};
