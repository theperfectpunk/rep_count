import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  Pressable,
  ActivityIndicator,
  RefreshControl,
  SafeAreaView,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SymbolView } from 'expo-symbols';
import { prebuiltPlans } from '../../src/data/prebuiltPlans';
import { PlanCard } from '../../src/components/PlanCard';
import { useUserPlans } from '../../src/hooks/useWorkoutPlans';
import { useAuth } from '../../src/hooks/useAuth';
import { useSettingsStore } from '../../src/stores/settingsStore';

export default function PlansScreen() {
  const router = useRouter();
  const { user } = useAuth();
  const activePlanId = useSettingsStore((state) => state.activePlanId);
  const [selectedTab, setSelectedTab] = useState<'prebuilt' | 'custom'>('prebuilt');

  const userId = user?.uid || 'demo-user';
  const { data: customPlans = [], isLoading, refetch, isRefetching } = useUserPlans(userId);

  return (
    <SafeAreaView className="flex-1 bg-[#0A0A0F]">
      {/* Header */}
      <View className="px-5 pt-4 pb-3 flex-row items-center justify-between border-b border-[#1E1E2E]">
        <View>
          <Text className="text-2xl font-bold text-[#F0F0F5]">Workout Plans</Text>
          <Text className="text-xs text-[#8888A0] mt-0.5">
            Choose a routine or build your own custom split
          </Text>
        </View>
        <Pressable
          onPress={() => router.push('/plans/create')}
          className="w-10 h-10 rounded-full bg-[#6C5CE7] items-center justify-center shadow-lg active:opacity-80"
        >
          <SymbolView
            name={{ ios: 'plus', android: 'add', web: 'add' }}
            tintColor="#FFFFFF"
            size={22}
          />
        </Pressable>
      </View>

      {/* Segmented Control / Tab Switcher */}
      <View className="px-5 my-4">
        <View className="flex-row bg-[#14141F] p-1.5 rounded-xl border border-[#1E1E2E]">
          <Pressable
            onPress={() => setSelectedTab('prebuilt')}
            className={`flex-1 py-2.5 rounded-lg items-center justify-center ${
              selectedTab === 'prebuilt' ? 'bg-[#6C5CE7]' : 'bg-transparent'
            }`}
          >
            <Text
              className={`text-sm font-semibold ${
                selectedTab === 'prebuilt' ? 'text-white' : 'text-[#8888A0]'
              }`}
            >
              Pre-built ({prebuiltPlans.length})
            </Text>
          </Pressable>

          <Pressable
            onPress={() => setSelectedTab('custom')}
            className={`flex-1 py-2.5 rounded-lg items-center justify-center ${
              selectedTab === 'custom' ? 'bg-[#6C5CE7]' : 'bg-transparent'
            }`}
          >
            <Text
              className={`text-sm font-semibold ${
                selectedTab === 'custom' ? 'text-white' : 'text-[#8888A0]'
              }`}
            >
              My Plans ({customPlans.length})
            </Text>
          </Pressable>
        </View>
      </View>

      {/* Content List */}
      <ScrollView
        className="flex-1 px-5"
        contentContainerStyle={{ paddingBottom: 100 }}
        showsVerticalScrollIndicator={false}
        refreshControl={
          selectedTab === 'custom' ? (
            <RefreshControl
              refreshing={isRefetching}
              onRefresh={refetch}
              tintColor="#6C5CE7"
              colors={['#6C5CE7']}
            />
          ) : undefined
        }
      >
        {selectedTab === 'prebuilt' ? (
          <View>
            <Text className="text-xs font-semibold text-[#8888A0] uppercase tracking-wider mb-3">
              Proven Training Programs
            </Text>
            {prebuiltPlans.map((plan) => {
              const isActive = activePlanId === plan.id;
              return (
                <PlanCard
                  key={plan.id}
                  plan={plan}
                  isActive={isActive}
                  onPress={() => router.push(`/plans/${plan.id}`)}
                />
              );
            })}
          </View>
        ) : (
          <View>
            <Text className="text-xs font-semibold text-[#8888A0] uppercase tracking-wider mb-3">
              Your Custom Routines
            </Text>

            {isLoading ? (
              <View className="py-12 items-center justify-center">
                <ActivityIndicator size="large" color="#6C5CE7" />
                <Text className="text-[#8888A0] text-sm mt-3">Loading custom plans...</Text>
              </View>
            ) : customPlans.length === 0 ? (
              <View className="bg-[#14141F] rounded-2xl p-8 items-center border border-[#1E1E2E] my-4">
                <View className="w-16 h-16 rounded-full bg-[#6C5CE7]/15 items-center justify-center mb-4 border border-[#6C5CE7]/30">
                  <SymbolView
                    name={{ ios: 'square.and.pencil', android: 'edit', web: 'edit' }}
                    tintColor="#6C5CE7"
                    size={30}
                  />
                </View>
                <Text className="text-lg font-bold text-[#F0F0F5] text-center mb-2">
                  No Custom Plans Yet
                </Text>
                <Text className="text-sm text-[#8888A0] text-center mb-6 leading-5">
                  Design your personalized workout routine tailored to your specific goals, exercises, and sets.
                </Text>
                <Pressable
                  onPress={() => router.push('/plans/create')}
                  className="bg-[#6C5CE7] px-6 py-3 rounded-xl flex-row items-center active:opacity-90 shadow-md"
                >
                  <SymbolView
                    name={{ ios: 'plus', android: 'add', web: 'add' }}
                    tintColor="#FFFFFF"
                    size={18}
                  />
                  <Text className="text-white font-bold text-sm ml-2">Create Custom Plan</Text>
                </Pressable>
              </View>
            ) : (
              customPlans.map((plan) => {
                const isActive = activePlanId === plan.id || plan.isActive;
                return (
                  <PlanCard
                    key={plan.id}
                    plan={plan}
                    isActive={isActive}
                    onPress={() => router.push(`/plans/${plan.id}`)}
                  />
                );
              })
            )}
          </View>
        )}
      </ScrollView>

      {/* Floating Action Button */}
      <View className="absolute bottom-6 right-5">
        <Pressable
          onPress={() => router.push('/plans/create')}
          className="bg-[#6C5CE7] flex-row items-center px-5 py-3.5 rounded-full shadow-2xl active:scale-95 border border-[#A29BFE]/30"
          style={{ elevation: 8 }}
        >
          <SymbolView
            name={{ ios: 'plus', android: 'add', web: 'add' }}
            tintColor="#FFFFFF"
            size={20}
          />
          <Text className="text-white font-bold text-sm ml-2">Create Plan</Text>
        </Pressable>
      </View>
    </SafeAreaView>
  );
}
