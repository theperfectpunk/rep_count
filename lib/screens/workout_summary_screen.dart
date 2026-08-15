import 'package:flutter/material.dart';
import '../models/workout_session.dart';
import '../models/exercise_log.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final WorkoutSession session;

  const WorkoutSummaryScreen({
    Key? key,
    required this.session,
  }) : super(key: key);

  String _formatDuration(int seconds) {
    final hrs = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hrs > 0) {
      return '${hrs}h ${mins}m';
    } else if (mins > 0) {
      return '${mins}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  double _calculateTotalVolume() {
    if (session.totalVolumeKg > 0) {
      return session.totalVolumeKg;
    }
    double volume = 0.0;
    for (final exercise in session.exercises) {
      for (final setItem in exercise.sets) {
        if (setItem.isCompleted) {
          volume += setItem.weightKg * setItem.reps;
        }
      }
    }
    // If no completed sets found volume, sum all set volumes
    if (volume == 0.0) {
      for (final exercise in session.exercises) {
        for (final setItem in exercise.sets) {
          volume += setItem.weightKg * setItem.reps;
        }
      }
    }
    return volume;
  }

  int _calculateCompletedSets() {
    int count = 0;
    for (final exercise in session.exercises) {
      for (final setItem in exercise.sets) {
        if (setItem.isCompleted) {
          count++;
        }
      }
    }
    if (count == 0) {
      for (final exercise in session.exercises) {
        count += exercise.sets.length;
      }
    }
    return count;
  }

  List<String> _extractTargetMuscles() {
    final muscles = <String>{};
    for (final exercise in session.exercises) {
      if (exercise.targetMuscle.isNotEmpty) {
        muscles.add(exercise.targetMuscle);
      }
    }
    return muscles.toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalVolume = _calculateTotalVolume();
    final completedSets = _calculateCompletedSets();
    final exercisesDone = session.exercises.length;
    final musclesTargeted = _extractTargetMuscles();

    return Scaffold(
      backgroundColor: const Color(0xFF11111B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11111B),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Celebration Banner / Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6C5CE7).withOpacity(0.15),
                      ),
                      child: const Text(
                        '🎉',
                        style: TextStyle(fontSize: 48),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFF00B894)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        'WORKOUT COMPLETED!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      session.title,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Key Metrics Cards Header
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'WORKOUT SUMMARY',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2x2 Grid of Metric Cards
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildMetricCard(
                          icon: Icons.timer_outlined,
                          iconColor: const Color(0xFF6C5CE7),
                          label: 'Duration',
                          value: _formatDuration(session.durationSeconds),
                        ),
                        _buildMetricCard(
                          icon: Icons.fitness_center,
                          iconColor: const Color(0xFF00B894),
                          label: 'Total Volume',
                          value: '${totalVolume.toStringAsFixed(1)} kg',
                        ),
                        _buildMetricCard(
                          icon: Icons.check_circle_outline,
                          iconColor: Colors.amberAccent,
                          label: 'Sets Completed',
                          value: '$completedSets',
                        ),
                        _buildMetricCard(
                          icon: Icons.format_list_bulleted,
                          iconColor: Colors.pinkAccent,
                          label: 'Exercises Done',
                          value: '$exercisesDone',
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Muscle Groups Targeted Section
                    if (musclesTargeted.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'MUSCLES TARGETED',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: musclesTargeted.map((muscle) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E2E),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF6C5CE7).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.bolt,
                                    size: 14,
                                    color: Color(0xFF00B894),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    muscle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom "Done" Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B894),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'DONE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
