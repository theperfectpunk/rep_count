import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/active_workout_provider.dart';
import '../repositories/workout_repository.dart';
import '../models/workout_session.dart';

final workoutRepoProvider = Provider((ref) => WorkoutRepository());

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(workoutRepoProvider);
    final history = repo.getWorkoutHistory();
    final activeWorkout = ref.watch(activeWorkoutProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF11111B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11111B),
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF6C5CE7),
              child: Text('MT',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mohit Tokas',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('🔥 4 Week Streak',
                    style: TextStyle(color: Colors.orangeAccent.shade200, fontSize: 12)),
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
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  Icon(Icons.play_arrow_round, color: Colors.white, size: 28),
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
                          Text('WEEKLY VOLUME',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1)),
                          const SizedBox(height: 4),
                          const Text('37,850 kg',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B894).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('+14.2% vs last week',
                            style: TextStyle(
                                color: Color(0xFF00B894),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 120,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 18000,
                        barTouchData: BarTouchDataOptions(enabled: false),
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
                                const days = [
                                  'M',
                                  'T',
                                  'W',
                                  'T',
                                  'F',
                                  'S',
                                  'S'
                                ];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    days[value.toInt() % 7],
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: [
                          _buildBar(0, 12450),
                          _buildBar(1, 0),
                          _buildBar(2, 9800),
                          _buildBar(3, 0),
                          _buildBar(4, 15600),
                          _buildBar(5, 0),
                          _buildBar(6, 0),
                        ],
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
                const Text('Recent Activity',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All',
                      style: TextStyle(color: Color(0xFF6C5CE7))),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Activity History Cards
            ...history.map((session) => _buildActivityCard(context, session)),
          ],
        ),
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
                    fontWeight: FontWeight.bold),
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
                      Text('${session.prsUnlocked} PRs',
                          style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
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
              Text('${session.durationSeconds ~/ 60} mins',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              const SizedBox(width: 16),
              Icon(Icons.fitness_center,
                  color: Colors.grey.shade400, size: 14),
              const SizedBox(width: 4),
              Text('${session.totalVolumeKg.toInt()} kg total volume',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
