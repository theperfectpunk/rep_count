import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

import { useAuth } from '../../src/hooks/useAuth';
import { useTotalStats } from '../../src/hooks/useWorkoutSessions';
import { useSettingsStore } from '../../src/stores/settingsStore';
import { logOut } from '../../src/services/authService';
import { formatWeight, formatNumber } from '../../src/utils/formatters';

export default function ProfileScreen() {
  const router = useRouter();
  const { user, profile, loading: authLoading } = useAuth();
  const { unit, defaultRestTimer, toggleUnit, setDefaultRestTimer } = useSettingsStore();

  const [refreshing, setRefreshing] = useState(false);

  const userId = user?.uid;

  const {
    data: totalStats,
    isLoading: statsLoading,
    refetch,
  } = useTotalStats(userId);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await refetch();
    setRefreshing(false);
  }, [refetch]);

  const handleSignOut = async () => {
    try {
      await logOut();
    } catch (error) {
      Alert.alert('Sign Out Error', 'Failed to sign out. Please try again.');
    }
  };

  const displayName =
    profile?.displayName || user?.displayName || user?.email?.split('@')[0] || 'Athlete';
  const email = profile?.email || user?.email || 'No email registered';
  const streak = profile?.currentStreak ?? profile?.streak ?? 0;
  const initial = displayName.charAt(0).toUpperCase();

  const restTimerOptions = [30, 60, 90, 120, 180];

  const isLoading = authLoading || (userId ? statsLoading : false);

  return (
    <SafeAreaView className="flex-1 bg-[#0A0A0F]" edges={['top', 'left', 'right']}>
      <ScrollView
        className="flex-1 px-4"
        contentContainerStyle={{ paddingBottom: 40 }}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor="#6C5CE7"
            colors={['#6C5CE7']}
          />
        }
      >
        {/* Header Section */}
        <View className="mt-4 mb-6">
          <Text className="text-[#F0F0F5] text-2xl font-extrabold tracking-tight">Profile</Text>
          <Text className="text-[#8888A0] text-sm font-medium mt-0.5">
            Manage your account, settings & app preferences
          </Text>
        </View>

        {/* User Profile Card */}
        <View className="bg-[#14141F] border border-[#1E1E2E] rounded-3xl p-6 mb-6 items-center">
          {/* Avatar Icon / Initial in Glowing Circle */}
          <View className="relative mb-3">
            <View
              className="w-20 h-20 rounded-full bg-[#6C5CE7] items-center justify-center border-2 border-[#A29BFE]"
              style={{
                shadowColor: '#6C5CE7',
                shadowOffset: { width: 0, height: 6 },
                shadowOpacity: 0.5,
                shadowRadius: 12,
                elevation: 10,
              }}
            >
              <Text className="text-white text-3xl font-extrabold">{initial}</Text>
            </View>
            <View className="absolute -bottom-1 -right-1 bg-[#14141F] border border-[#6C5CE7] p-1.5 rounded-full">
              <Ionicons name="fitness" size={14} color="#00E676" />
            </View>
          </View>

          {/* User Info */}
          <Text className="text-[#F0F0F5] text-2xl font-extrabold text-center mb-0.5">
            {displayName}
          </Text>
          <Text className="text-[#8888A0] text-sm font-medium text-center mb-4">
            {email}
          </Text>

          {/* Streak Badge */}
          <View className="flex-row items-center bg-[#0A0A0F] border border-[#1E1E2E] px-4 py-2 rounded-full">
            <Text className="text-lg mr-2">🔥</Text>
            <Text className="text-[#F0F0F5] text-sm font-extrabold mr-1">{streak}</Text>
            <Text className="text-[#8888A0] text-xs font-semibold">Day Streak</Text>
          </View>
        </View>

        {/* Lifetime Stats Grid */}
        <View className="mb-6">
          <Text className="text-[#F0F0F5] text-lg font-extrabold mb-3 tracking-tight">
            Lifetime Statistics
          </Text>

          {isLoading && !refreshing ? (
            <View className="bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-6 items-center justify-center">
              <ActivityIndicator size="small" color="#6C5CE7" />
              <Text className="text-[#8888A0] text-xs mt-2 font-medium">Loading statistics...</Text>
            </View>
          ) : (
            <View className="flex-row justify-between space-x-3">
              {/* Workouts Completed */}
              <View className="flex-1 bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-4 mr-1">
                <View className="w-10 h-10 rounded-xl bg-[#6C5CE7]/15 border border-[#6C5CE7]/30 items-center justify-center mb-2">
                  <Ionicons name="checkmark-circle" size={20} color="#6C5CE7" />
                </View>
                <Text className="text-[#8888A0] text-xs font-medium mb-1" numberOfLines={1}>
                  Workouts
                </Text>
                <Text className="text-[#F0F0F5] text-xl font-extrabold" numberOfLines={1} adjustsFontSizeToFit>
                  {formatNumber(totalStats?.totalWorkouts ?? 0)}
                </Text>
              </View>

              {/* Total Volume */}
              <View className="flex-1 bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-4 mx-1">
                <View className="w-10 h-10 rounded-xl bg-[#6C5CE7]/15 border border-[#6C5CE7]/30 items-center justify-center mb-2">
                  <Ionicons name="barbell" size={20} color="#6C5CE7" />
                </View>
                <Text className="text-[#8888A0] text-xs font-medium mb-1" numberOfLines={1}>
                  Total Volume
                </Text>
                <Text className="text-[#F0F0F5] text-xl font-extrabold" numberOfLines={1} adjustsFontSizeToFit>
                  {formatWeight(totalStats?.totalVolume ?? 0, unit)}
                </Text>
              </View>

              {/* Total Sets */}
              <View className="flex-1 bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-4 ml-1">
                <View className="w-10 h-10 rounded-xl bg-[#6C5CE7]/15 border border-[#6C5CE7]/30 items-center justify-center mb-2">
                  <Ionicons name="layers" size={20} color="#6C5CE7" />
                </View>
                <Text className="text-[#8888A0] text-xs font-medium mb-1" numberOfLines={1}>
                  Total Sets
                </Text>
                <Text className="text-[#F0F0F5] text-xl font-extrabold" numberOfLines={1} adjustsFontSizeToFit>
                  {formatNumber(totalStats?.totalSets ?? 0)}
                </Text>
              </View>
            </View>
          )}
        </View>

        {/* Preferences & Settings */}
        <View className="mb-6">
          <Text className="text-[#F0F0F5] text-lg font-extrabold mb-3 tracking-tight">
            Preferences & Settings
          </Text>

          {/* Weight Unit Selector */}
          <View className="bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-4 mb-4">
            <View className="flex-row items-center mb-3">
              <View className="w-9 h-9 rounded-xl bg-[#1E1E2E] items-center justify-center mr-3">
                <Ionicons name="scale-outline" size={18} color="#A29BFE" />
              </View>
              <View className="flex-1">
                <Text className="text-[#F0F0F5] text-base font-bold">Weight Unit</Text>
                <Text className="text-[#8888A0] text-xs font-medium">
                  Choose default unit for logging & stats
                </Text>
              </View>
            </View>

            {/* Segmented Control */}
            <View className="flex-row bg-[#0A0A0F] p-1 rounded-xl border border-[#1E1E2E]">
              <TouchableOpacity
                activeOpacity={0.8}
                onPress={() => {
                  if (unit !== 'kg') toggleUnit();
                }}
                className={`flex-1 py-2.5 rounded-lg items-center justify-center ${
                  unit === 'kg' ? 'bg-[#6C5CE7]' : 'bg-transparent'
                }`}
              >
                <Text
                  className={`text-sm font-extrabold ${
                    unit === 'kg' ? 'text-white' : 'text-[#8888A0]'
                  }`}
                >
                  Kilograms (kg)
                </Text>
              </TouchableOpacity>

              <TouchableOpacity
                activeOpacity={0.8}
                onPress={() => {
                  if (unit !== 'lbs') toggleUnit();
                }}
                className={`flex-1 py-2.5 rounded-lg items-center justify-center ${
                  unit === 'lbs' ? 'bg-[#6C5CE7]' : 'bg-transparent'
                }`}
              >
                <Text
                  className={`text-sm font-extrabold ${
                    unit === 'lbs' ? 'text-white' : 'text-[#8888A0]'
                  }`}
                >
                  Pounds (lbs)
                </Text>
              </TouchableOpacity>
            </View>
          </View>

          {/* Default Rest Timer Selector */}
          <View className="bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-4">
            <View className="flex-row items-center mb-3">
              <View className="w-9 h-9 rounded-xl bg-[#1E1E2E] items-center justify-center mr-3">
                <Ionicons name="timer-outline" size={18} color="#A29BFE" />
              </View>
              <View className="flex-1">
                <Text className="text-[#F0F0F5] text-base font-bold">Default Rest Timer</Text>
                <Text className="text-[#8888A0] text-xs font-medium">
                  Auto-countdown duration after completing a set
                </Text>
              </View>
            </View>

            {/* Selector Options */}
            <View className="flex-row flex-wrap justify-between gap-2 mt-1">
              {restTimerOptions.map((seconds) => {
                const isSelected = defaultRestTimer === seconds;
                return (
                  <TouchableOpacity
                    key={seconds}
                    activeOpacity={0.8}
                    onPress={() => setDefaultRestTimer(seconds)}
                    className={`flex-1 py-2.5 px-3 rounded-xl border items-center justify-center min-w-[56px] ${
                      isSelected
                        ? 'bg-[#6C5CE7] border-[#A29BFE]'
                        : 'bg-[#0A0A0F] border-[#1E1E2E]'
                    }`}
                  >
                    <Text
                      className={`text-sm font-extrabold ${
                        isSelected ? 'text-white' : 'text-[#8888A0]'
                      }`}
                    >
                      {seconds}s
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>
        </View>

        {/* Account & Actions Section */}
        <View className="mb-6">
          <Text className="text-[#F0F0F5] text-lg font-extrabold mb-3 tracking-tight">
            Account & Library
          </Text>

          {/* Browse Exercise Library */}
          <TouchableOpacity
            activeOpacity={0.8}
            onPress={() => router.push('/exercises')}
            className="bg-[#14141F] border border-[#1E1E2E] rounded-2xl p-4 mb-3 flex-row items-center justify-between"
          >
            <View className="flex-row items-center flex-1 mr-2">
              <View className="w-10 h-10 rounded-xl bg-[#6C5CE7]/15 border border-[#6C5CE7]/30 items-center justify-center mr-3">
                <Ionicons name="book-outline" size={20} color="#6C5CE7" />
              </View>
              <View className="flex-1">
                <Text className="text-[#F0F0F5] text-base font-bold">
                  Browse Exercise Library
                </Text>
                <Text className="text-[#8888A0] text-xs font-medium">
                  Explore 50+ exercises & muscle targets
                </Text>
              </View>
            </View>
            <Ionicons name="chevron-forward" size={20} color="#8888A0" />
          </TouchableOpacity>

          {/* Sign Out Button */}
          <TouchableOpacity
            activeOpacity={0.85}
            onPress={handleSignOut}
            className="bg-[#FF5252]/10 border border-[#FF5252]/30 rounded-2xl p-4 flex-row items-center justify-center"
          >
            <Ionicons name="log-out-outline" size={20} color="#FF5252" style={{ marginRight: 8 }} />
            <Text className="text-[#FF5252] text-base font-extrabold">Sign Out</Text>
          </TouchableOpacity>
        </View>

        {/* App Version Info Footer */}
        <View className="items-center py-4">
          <Text className="text-[#8888A0] text-xs font-semibold tracking-wide">
            RepCount v1.0.0 • Expo SDK 57
          </Text>
          <Text className="text-[#8888A0]/60 text-[10px] font-medium mt-0.5">
            Midnight Iron Edition
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}
