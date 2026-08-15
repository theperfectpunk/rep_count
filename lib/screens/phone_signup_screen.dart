import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PhoneSignupScreen extends StatefulWidget {
  const PhoneSignupScreen({Key? key}) : super(key: key);

  @override
  State<PhoneSignupScreen> createState() => _PhoneSignupScreenState();
}

class _PhoneSignupScreenState extends State<PhoneSignupScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController(text: '+1 555-555-5555');
  final List<TextEditingController> _pinControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  String _selectedCountryCode = '+1';
  int _secondsRemaining = 60;
  Timer? _countdownTimer;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _pinFocusNodes) {
      node.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _secondsRemaining = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _signInAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _authService.signInAnonymously();
      if (user == null && mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Guest sign-in failed. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Guest sign-in error: $e';
        });
      }
    }
  }

  Future<void> _sendOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid phone number';
      });
      return;
    }

    final phone = rawPhone.startsWith('+') ? rawPhone : '$_selectedCountryCode$rawPhone';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _authService.verifyPhoneNumber(
      phoneNumber: phone,
      onCodeSent: (verificationId, resendToken) {
        if (mounted) {
          setState(() {
            _isOtpSent = true;
            _isLoading = false;
            _verificationId = verificationId;
          });
          _startResendTimer();
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = error;
          });
        }
      },
    );
  }

  Future<void> _verifyOtp() async {
    final smsCode = _pinControllers.map((c) => c.text).join();
    if (smsCode.length < 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit OTP code';
      });
      return;
    }

    if (_verificationId == null) {
      setState(() {
        _errorMessage = 'Verification session expired. Please resend OTP.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithOtp(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      // Success: AuthStateListener in main.dart will automatically route to MainNavigationShell
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid OTP code. Please check and try again.';
        });
      }
    }
  }

  void _useTestCredentials() {
    setState(() {
      _phoneController.text = '+1 555-555-5555';
    });
    for (int i = 0; i < 6; i++) {
      _pinControllers[i].text = '${i + 1}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF11111B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Header Logo & Branding
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.fitness_center, color: Color(0xFF6C5CE7), size: 32),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'RepCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Gym Workout Planner',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Title Section
              Text(
                _isOtpSent ? 'Verify Phone OTP' : 'Create Account',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isOtpSent
                    ? 'Enter the 6-digit OTP code sent to ${_phoneController.text}'
                    : 'Enter your phone number to receive a 6-digit OTP verification code',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14, height: 1.4),
              ),

              const SizedBox(height: 32),

              // Error Banner
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade400.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // STEP 1: Phone Input Box
              if (!_isOtpSent) ...[
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: _selectedCountryCode,
                        dropdownColor: const Color(0xFF1E1E2E),
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        items: ['+1', '+91', '+44', '+61', '+81']
                            .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCountryCode = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Container(height: 24, width: 1, color: Colors.white12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: '555-555-5555',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Test & Guest Sign-In Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _useTestCredentials,
                        icon: const Icon(Icons.bug_report, size: 16, color: Color(0xFF00B894)),
                        label: const Text(
                          'Use Demo Number',
                          style: TextStyle(color: Color(0xFF00B894), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _isLoading ? null : _signInAsGuest,
                        icon: const Icon(Icons.person_outline, size: 16, color: Color(0xFF6C5CE7)),
                        label: const Text(
                          'Continue as Guest',
                          style: TextStyle(color: Color(0xFF6C5CE7), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Submit Send OTP Button
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7).withOpacity(0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: EdgeInsets.zero,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFF8B78FF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withOpacity(0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Text(
                                'Send Verification Code',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                ),
              ],

              // STEP 2: 6-Digit PIN Boxes
              if (_isOtpSent) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return Flexible(
                      child: Semantics(
                        label: 'Digit ${index + 1} of 6',
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 48, minWidth: 36),
                          child: SizedBox(
                            height: 56,
                            child: TextField(
                              controller: _pinControllers[index],
                              focusNode: _pinFocusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: const Color(0xFF1E1E2E),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
                                ),
                              ),
                              onChanged: (val) {
                                if (val.isNotEmpty && index < 5) {
                                  _pinFocusNodes[index + 1].requestFocus();
                                } else if (val.isEmpty && index > 0) {
                                  _pinFocusNodes[index - 1].requestFocus();
                                }
                                if (index == 5 && val.isNotEmpty) {
                                  _verifyOtp();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // Resend Timer Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isOtpSent = false;
                        });
                      },
                      child: const Text(
                        'Change Phone Number',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _secondsRemaining == 0 ? _sendOtp : null,
                      child: Text(
                        _secondsRemaining > 0
                            ? 'Resend in ${_secondsRemaining}s'
                            : 'Resend OTP Code',
                        style: TextStyle(
                          color: _secondsRemaining == 0 ? const Color(0xFF6C5CE7) : Colors.white38,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B894),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text(
                            'Verify & Start Training',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
