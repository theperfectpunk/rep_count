import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/dashboard_screen.dart';
import 'screens/routine_planner_screen.dart';
import 'screens/live_workout_screen.dart';
import 'screens/exercise_library_screen.dart';
import 'screens/analytics_screen.dart';
import 'providers/active_workout_provider.dart';

void main() {
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
      home: const MainNavigationShell(),
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

    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],
          
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
          BottomNavigationBarThemeData(),
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
