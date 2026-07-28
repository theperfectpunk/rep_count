import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';

interface SettingsState {
  unit: 'kg' | 'lbs';
  defaultRestTimer: number; // seconds
  activePlanId: string | null;
  toggleUnit: () => void;
  setDefaultRestTimer: (seconds: number) => void;
  setActivePlanId: (planId: string | null) => void;
}

export const useSettingsStore = create<SettingsState>()(
  persist(
    (set) => ({
      unit: 'kg',
      defaultRestTimer: 90,
      activePlanId: null,
      toggleUnit: () =>
        set((state) => ({ unit: state.unit === 'kg' ? 'lbs' : 'kg' })),
      setDefaultRestTimer: (seconds: number) =>
        set({ defaultRestTimer: seconds }),
      setActivePlanId: (planId: string | null) =>
        set({ activePlanId: planId }),
    }),
    {
      name: 'repcount-settings',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
