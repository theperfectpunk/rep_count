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
import { signUp } from '../../src/services/authService';

export default function SignupScreen() {
  const router = useRouter();

  const [displayName, setDisplayName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSignup = async () => {
    if (!displayName.trim()) {
      setError('Please enter your display name.');
      return;
    }
    if (!email.trim()) {
      setError('Please enter your email address.');
      return;
    }
    if (!password) {
      setError('Please enter a password.');
      return;
    }
    if (password.length < 6) {
      setError('Password should be at least 6 characters.');
      return;
    }
    if (password !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    setError(null);
    setLoading(true);

    try {
      await signUp(email.trim(), password, displayName.trim());
      // Auth state listener in root layout will redirect upon login
    } catch (err: any) {
      console.error('Signup error:', err);
      let message = 'Failed to create account. Please try again.';
      if (err.code === 'auth/email-already-in-use') {
        message = 'An account with this email already exists.';
      } else if (err.code === 'auth/invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (err.code === 'auth/weak-password') {
        message = 'Password is too weak. Choose a stronger password.';
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
          <View className="items-center mb-8">
            <View className="w-16 h-16 rounded-2xl bg-[#1E1E2E] items-center justify-center mb-3 border border-[#6C5CE7]/30 shadow-lg shadow-[#6C5CE7]/20">
              <Text className="text-3xl">🏋️</Text>
            </View>
            <Text className="text-3xl font-bold text-[#F0F0F5] tracking-tight">
              Create Account
            </Text>
            <Text className="text-[#8888A0] text-sm mt-1">
              Start your fitness journey with RepCount
            </Text>
          </View>

          {/* Form Container */}
          <View className="bg-[#14141F] p-6 rounded-3xl border border-[#1E1E2E] shadow-xl">
            {/* Error Display */}
            {error && (
              <View className="bg-[#FF5252]/10 border border-[#FF5252]/30 p-3.5 rounded-xl mb-4 flex-row items-center">
                <Ionicons name="alert-circle-outline" size={20} color="#FF5252" />
                <Text className="text-[#FF5252] text-sm ml-2 flex-1 font-medium">
                  {error}
                </Text>
              </View>
            )}

            {/* Display Name Input */}
            <View className="mb-4">
              <Text className="text-[#8888A0] text-xs font-semibold uppercase tracking-wider mb-2 ml-1">
                Display Name
              </Text>
              <View className="flex-row items-center bg-[#1E1E2E] border border-[#2A2A3D] focus:border-[#6C5CE7] rounded-xl px-3.5 py-3">
                <Ionicons name="person-outline" size={20} color="#8888A0" />
                <TextInput
                  value={displayName}
                  onChangeText={setDisplayName}
                  placeholder="John Doe"
                  placeholderTextColor="#555568"
                  autoCapitalize="words"
                  className="flex-1 ml-3 text-[#F0F0F5] text-base"
                />
              </View>
            </View>

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
            <View className="mb-4">
              <Text className="text-[#8888A0] text-xs font-semibold uppercase tracking-wider mb-2 ml-1">
                Password
              </Text>
              <View className="flex-row items-center bg-[#1E1E2E] border border-[#2A2A3D] focus:border-[#6C5CE7] rounded-xl px-3.5 py-3">
                <Ionicons name="lock-closed-outline" size={20} color="#8888A0" />
                <TextInput
                  value={password}
                  onChangeText={setPassword}
                  placeholder="At least 6 characters"
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

            {/* Confirm Password Input */}
            <View className="mb-6">
              <Text className="text-[#8888A0] text-xs font-semibold uppercase tracking-wider mb-2 ml-1">
                Confirm Password
              </Text>
              <View className="flex-row items-center bg-[#1E1E2E] border border-[#2A2A3D] focus:border-[#6C5CE7] rounded-xl px-3.5 py-3">
                <Ionicons name="shield-checkmark-outline" size={20} color="#8888A0" />
                <TextInput
                  value={confirmPassword}
                  onChangeText={setConfirmPassword}
                  placeholder="Re-enter password"
                  placeholderTextColor="#555568"
                  secureTextEntry={!showConfirmPassword}
                  className="flex-1 ml-3 text-[#F0F0F5] text-base"
                />
                <TouchableOpacity
                  onPress={() => setShowConfirmPassword(!showConfirmPassword)}
                  hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
                >
                  <Ionicons
                    name={showConfirmPassword ? 'eye-off-outline' : 'eye-outline'}
                    size={20}
                    color="#8888A0"
                  />
                </TouchableOpacity>
              </View>
            </View>

            {/* Sign Up Button */}
            <TouchableOpacity
              onPress={handleSignup}
              disabled={loading}
              activeOpacity={0.8}
              className="bg-[#6C5CE7] py-4 rounded-xl items-center justify-center shadow-lg shadow-[#6C5CE7]/30"
            >
              {loading ? (
                <ActivityIndicator color="#FFFFFF" />
              ) : (
                <Text className="text-white font-bold text-base tracking-wide">
                  Create Account
                </Text>
              )}
            </TouchableOpacity>
          </View>

          {/* Footer Link */}
          <View className="flex-row justify-center items-center mt-8">
            <Text className="text-[#8888A0] text-sm">
              Already have an account?{' '}
            </Text>
            <TouchableOpacity onPress={() => router.replace('/(auth)/login')}>
              <Text className="text-[#A29BFE] font-bold text-sm">
                Log In
              </Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
