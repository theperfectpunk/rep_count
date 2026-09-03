import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/active_workout_provider.dart';
import '../providers/repository_providers.dart';
import '../models/workout_session.dart';
import '../screens/settings_screen.dart';

final userWorkoutsProvider = FutureProvider<List<WorkoutSession>>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  String? userId;
  try {
    userId = FirebaseAuth.instance.currentUser?.uid;
  } catch (_) {}
  return await repo.fetchUserWorkouts(userId ?? '');
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(userWorkoutsProvider);
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    final userName = user?.displayName ??
        (user?.email != null && user!.email!.contains('@')
            ? user.email!.split('@').first
            : (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty
                ? user.phoneNumber!
                : 'Mohit Tokas'));

    final trimmedName = userName.trim();
    final parts = trimmedName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.length > 1
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (trimmedName.isNotEmpty
            ? trimmedName.substring(0, trimmedName.length >= 2 ? 2 : 1).toUpperCase()
            : 'MT');

    return Scaffold(
      backgroundColor: const Color(0xFF11111B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11111B),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF6C5CE7),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                workoutsAsync.when(
                  data: (workouts) => Text(
                    _calculateStreak(workouts),
                    style: TextStyle(
                      color: Colors.orangeAccent.shade200,
                      fontSize: 12,
                    ),
                  ),
                  loading: () => Text(
                    '🔥 ...',
                    style: TextStyle(
                      color: Colors.orangeAccent.shade200,
                      fontSize: 12,
                    ),
                  ),
                  error: (_, __) => Text(
                    '🔥 Start Your Streak!',
                    style: TextStyle(
                      color: Colors.orangeAccent.shade200,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF6C5CE7),
        backgroundColor: const Color(0xFF1E1E2E),
        onRefresh: () async {
          ref.refresh(userWorkoutsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start Empty Workout Primary CTA
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(activeWorkoutProvider.notifier)
                      .startEmptyWorkout(title: 'Quick Workout');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF6C5CE7).withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'START EMPTY WORKOUT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Async Workout Content
              workoutsAsync.when(
                data: (workouts) => _buildDashboardContent(context, workouts),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                ),
                error: (error, stackTrace) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'Failed to load workout history',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.refresh(userWorkoutsProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                        ),
                        child: const Text('Retry',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
      BuildContext context, List<WorkoutSession> workouts) {
    // 1. Calculate Weekly Volume & Stats
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfThisWeek =
        today.subtract(Duration(days: today.weekday - 1));
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));

    double thisWeekVolume = 0.0;
    double lastWeekVolume = 0.0;
    List<double> dailyVolumes = List.filled(7, 0.0);

    for (final s in workouts) {
      final sessionDate = s.completedAt ?? s.startedAt;
      final vol = _calculateSessionVolume(s);

      // Check current week
      if (sessionDate.isAfter(
          startOfThisWeek.subtract(const Duration(milliseconds: 1)))) {
        thisWeekVolume += vol;
        int dayIndex = sessionDate.weekday - 1;
        if (dayIndex >= 0 && dayIndex < 7) {
          dailyVolumes[dayIndex] += vol;
        }
      }
      // Check last week
      else if (sessionDate.isAfter(
              startOfLastWeek.subtract(const Duration(milliseconds: 1))) &&
          sessionDate.isBefore(startOfThisWeek)) {
        lastWeekVolume += vol;
      }
    }

    String volumeText = workouts.isEmpty ? '0 kg' : _formatVolume(thisWeekVolume);
    String percentageText;
    Color percentageColor;
    Color percentageBg;

    if (workouts.isEmpty || (thisWeekVolume == 0 && lastWeekVolume == 0)) {
      percentageText = 'No data yet';
      percentageColor = Colors.grey.shade400;
      percentageBg = Colors.white.withOpacity(0.08);
    } else if (lastWeekVolume == 0) {
      percentageText = '+100% vs last week';
      percentageColor = const Color(0xFF00B894);
      percentageBg = const Color(0xFF00B894).withOpacity(0.15);
    } else {
      double diff =
          ((thisWeekVolume - lastWeekVolume) / lastWeekVolume) * 100;
      if (diff >= 0) {
        percentageText = '+${diff.toStringAsFixed(1)}% vs last week';
        percentageColor = const Color(0xFF00B894);
        percentageBg = const Color(0xFF00B894).withOpacity(0.15);
      } else {
        percentageText = '${diff.toStringAsFixed(1)}% vs last week';
        percentageColor = Colors.redAccent;
        percentageBg = Colors.redAccent.withOpacity(0.15);
      }
    }

    double maxDailyVol = dailyVolumes.reduce((a, b) => a > b ? a : b);
    double maxY = maxDailyVol > 0 ? maxDailyVol * 1.2 : 1000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weekly Volume Chart Widget
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WEEKLY VOLUME',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        volumeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: percentageBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      percentageText,
                      style: TextStyle(
                        color: percentageColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 120,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                            final int index = value.toInt();
                            if (index < 0 || index >= days.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                days[index],
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: List.generate(
                      7,
                      (index) => _buildBar(index, dailyVolumes[index]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Recent Activity Log Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (workouts.isNotEmpty)
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(color: Color(0xFF6C5CE7)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Activity History Cards or Empty State
        if (workouts.isEmpty)
          _buildEmptyState()
        else
          ...workouts.map((session) => _buildActivityCard(context, session)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center,
              size: 48,
              color: Color(0xFF6C5CE7),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No workouts logged yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your first session to see stats here!',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: y > 0 ? const Color(0xFF6C5CE7) : Colors.white10,
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context, WorkoutSession session) {
    final volume = _calculateSessionVolume(session);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                session.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (session.prsUnlocked > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amberAccent, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events,
                          color: Colors.amberAccent, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${session.prsUnlocked} PRs',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timer_outlined,
                  color: Colors.grey.shade400, size: 14),
              const SizedBox(width: 4),
              Text(
                '${session.durationSeconds ~/ 60} mins',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.fitness_center,
                  color: Colors.grey.shade400, size: 14),
              const SizedBox(width: 4),
              Text(
                '${volume.toInt()} kg total volume',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateSessionVolume(WorkoutSession session) {
    double setVolume = 0.0;
    for (final ex in session.exercises) {
      for (final set in ex.sets) {
        if (set.isCompleted) {
          setVolume += (set.weightKg * set.reps);
        }
      }
    }
    if (setVolume > 0) {
      return setVolume;
    }
    return session.totalVolumeKg;
  }

  String _calculateStreak(List<WorkoutSession> workouts) {
    if (workouts.isEmpty) return '🔥 Start Your Streak!';

    final dates = workouts.map((s) => s.completedAt ?? s.startedAt).toList();
    if (dates.isEmpty) return '🔥 Start Your Streak!';

    DateTime startOfWeek(DateTime dt) {
      final d = DateTime(dt.year, dt.month, dt.day);
      return d.subtract(Duration(days: d.weekday - 1));
    }

    final now = DateTime.now();
    final currentWeekStart = startOfWeek(now);
    final workoutWeeks = dates.map((d) => startOfWeek(d)).toSet();

    int streak = 0;
    DateTime checkWeek = currentWeekStart;

    if (!workoutWeeks.contains(checkWeek)) {
      checkWeek = checkWeek.subtract(const Duration(days: 7));
    }

    while (workoutWeeks.contains(checkWeek)) {
      streak++;
      checkWeek = checkWeek.subtract(const Duration(days: 7));
    }

    if (streak == 0) {
      return '🔥 Start Your Streak!';
    } else if (streak == 1) {
      return '🔥 1 Week Streak';
    } else {
      return '🔥 $streak Week Streak';
    }
  }

  String _formatVolume(double volume) {
    if (volume == 0) return '0 kg';
    final int val = volume.round();
    final String str = val.toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$formatted kg';
  }
}
