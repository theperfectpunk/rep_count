import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/dashboard_screen.dart';
import 'screens/routine_planner_screen.dart';
import 'screens/live_workout_screen.dart';
import 'screens/exercise_library_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/active_workout_provider.dart';
import 'providers/rest_timer_provider.dart';
import 'widgets/sticky_timer_bar.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'screens/phone_signup_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }
  runApp(const ProviderScope(child: GymWorkoutApp()));
}

class GymWorkoutApp extends StatelessWidget {
  const GymWorkoutApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RepCount Gym Workout Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF11111B),
        primaryColor: const Color(0xFF6C5CE7),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C5CE7),
          secondary: Color(0xFF00B894),
          surface: Color(0xFF1E1E2E),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final AuthService _authService;
  late final Stream<User?> _authStateStream;
  bool _onboardingDone = false;
  bool _isLoadingOnboarding = true;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _authStateStream = _authService.authStateChanges;
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _onboardingDone = prefs.getBool('onboarding_complete') ?? false;
        _isLoadingOnboarding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _isLoadingOnboarding) {
          return const Scaffold(
            backgroundColor: Color(0xFF11111B),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const PhoneSignupScreen();
        }

        if (!_onboardingDone) {
          return const OnboardingScreen();
        }

        return const MainNavigationShell();
      },
    );
  }
}

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({Key? key}) : super(key: key);

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    RoutinePlannerScreen(),
    LiveWorkoutScreen(),
    ExerciseLibraryScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final activeWorkout = ref.watch(activeWorkoutProvider);
    final restTimer = ref.watch(restTimerProvider);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Stack(
            children: [
              IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
              
              if (restTimer.secondsRemaining > 0)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 80,
                  child: StickyTimerBar(),
                ),

              // Floating Mini Workout Bar if session active & not on logging screen
              if (activeWorkout != null && _currentIndex != 2)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = 2; // Navigate to Live Logger
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withOpacity(0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(activeWorkout.title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    '${activeWorkout.durationSeconds ~/ 60} mins elapsed',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF181825),
        selectedItemColor: const Color(0xFF6C5CE7),
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined), label: 'Routines'),
          BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_fill, size: 28), label: 'Log'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined), label: 'Exercises'),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined), label: 'Analytics'),
        ],
      ),
    );
  }
}
