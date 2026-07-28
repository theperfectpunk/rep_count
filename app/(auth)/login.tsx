import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  ActivityIndicator,
  SafeAreaView,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { logIn } from '../../src/services/authService';

export default function LoginScreen() {
  const router = useRouter();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleLogin = async () => {
    if (!email.trim() || !password.trim()) {
      setError('Please enter both email and password.');
      return;
    }

    setError(null);
    setLoading(true);

    try {
      await logIn(email.trim(), password);
      // Auth listener in root layout will automatically handle routing upon user login
    } catch (err: any) {
      console.error('Login error:', err);
      let message = 'Failed to log in. Please check your credentials.';
      if (err.code === 'auth/invalid-credential' || err.code === 'auth/user-not-found' || err.code === 'auth/wrong-password') {
        message = 'Invalid email or password.';
      } else if (err.code === 'auth/invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (err.code === 'auth/too-many-requests') {
        message = 'Too many failed attempts. Please try again later.';
      } else if (err.message) {
        message = err.message;
      }
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView className="flex-1 bg-[#0A0A0F]">
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        className="flex-1"
      >
        <ScrollView
          contentContainerStyle={{ flexGrow: 1, justifyContent: 'center' }}
          className="px-6 py-8"
          keyboardShouldPersistTaps="handled"
        >
          {/* Header & Logo */}
          <View className="items-center mb-10">
            <View className="w-20 h-20 rounded-3xl bg-[#1E1E2E] items-center justify-center mb-4 border border-[#6C5CE7]/30 shadow-lg shadow-[#6C5CE7]/20">
              <Text className="text-4xl">🏋️</Text>
            </View>
            <Text className="text-3xl font-bold text-[#F0F0F5] tracking-tight">
              RepCount
            </Text>
            <Text className="text-[#8888A0] text-sm mt-1">
              Track your strength, conquer your goals
            </Text>
          </View>

          {/* Form Container */}
          <View className="bg-[#14141F] p-6 rounded-3xl border border-[#1E1E2E] shadow-xl">
            <Text className="text-xl font-semibold text-[#F0F0F5] mb-6">
              Welcome Back
            </Text>

            {/* Error Display */}
            {error && (
              <View className="bg-[#FF5252]/10 border border-[#FF5252]/30 p-3.5 rounded-xl mb-4 flex-row items-center">
                <Ionicons name="alert-circle-outline" size={20} color="#FF5252" />
                <Text className="text-[#FF5252] text-sm ml-2 flex-1 font-medium">
                  {error}
                </Text>
              </View>
            )}

            {/* Email Input */}
            <View className="mb-4">
              <Text className="text-[#8888A0] text-xs font-semibold uppercase tracking-wider mb-2 ml-1">
                Email Address
              </Text>
              <View className="flex-row items-center bg-[#1E1E2E] border border-[#2A2A3D] focus:border-[#6C5CE7] rounded-xl px-3.5 py-3">
                <Ionicons name="mail-outline" size={20} color="#8888A0" />
                <TextInput
                  value={email}
                  onChangeText={setEmail}
                  placeholder="user@example.com"
                  placeholderTextColor="#555568"
                  keyboardType="email-address"
                  autoCapitalize="none"
                  autoCorrect={false}
                  className="flex-1 ml-3 text-[#F0F0F5] text-base"
                />
              </View>
            </View>

            {/* Password Input */}
            <View className="mb-6">
              <Text className="text-[#8888A0] text-xs font-semibold uppercase tracking-wider mb-2 ml-1">
                Password
              </Text>
              <View className="flex-row items-center bg-[#1E1E2E] border border-[#2A2A3D] focus:border-[#6C5CE7] rounded-xl px-3.5 py-3">
                <Ionicons name="lock-closed-outline" size={20} color="#8888A0" />
                <TextInput
                  value={password}
                  onChangeText={setPassword}
                  placeholder="••••••••"
                  placeholderTextColor="#555568"
                  secureTextEntry={!showPassword}
                  className="flex-1 ml-3 text-[#F0F0F5] text-base"
                />
                <TouchableOpacity
                  onPress={() => setShowPassword(!showPassword)}
                  hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
                >
                  <Ionicons
                    name={showPassword ? 'eye-off-outline' : 'eye-outline'}
                    size={20}
                    color="#8888A0"
                  />
                </TouchableOpacity>
              </View>
            </View>

            {/* Log In Button */}
            <TouchableOpacity
              onPress={handleLogin}
              disabled={loading}
              activeOpacity={0.8}
              className="bg-[#6C5CE7] py-4 rounded-xl items-center justify-center shadow-lg shadow-[#6C5CE7]/30"
            >
              {loading ? (
                <ActivityIndicator color="#FFFFFF" />
              ) : (
                <Text className="text-white font-bold text-base tracking-wide">
                  Log In
                </Text>
              )}
            </TouchableOpacity>
          </View>

          {/* Footer Link */}
          <View className="flex-row justify-center items-center mt-8">
            <Text className="text-[#8888A0] text-sm">
              Don't have an account?{' '}
            </Text>
            <TouchableOpacity onPress={() => router.replace('/(auth)/signup')}>
              <Text className="text-[#A29BFE] font-bold text-sm">
                Sign Up
              </Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
