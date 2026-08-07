import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/routine.dart';
import '../providers/active_workout_provider.dart';

class RoutinePlannerScreen extends ConsumerStatefulWidget {
  const RoutinePlannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RoutinePlannerScreen> createState() =>
      _RoutinePlannerScreenState();
}

class _RoutinePlannerScreenState extends ConsumerState<RoutinePlannerScreen> {
  final List<Routine> _routines = [
    Routine(
      title: 'Push Day A (Chest/Shoulders/Triceps)',
      folderName: 'Push-Pull-Legs Split',
      exerciseIds: ['ex_bench_press', 'ex_overhead_press', 'ex_incline_db_press'],
      estimatedDurationMinutes: 55,
      targetMuscles: ['Chest', 'Shoulders', 'Triceps'],
    ),
    Routine(
      title: 'Pull Day A (Back/Biceps)',
      folderName: 'Push-Pull-Legs Split',
      exerciseIds: ['ex_deadlift', 'ex_pull_ups', 'ex_barbell_curl'],
      estimatedDurationMinutes: 50,
      targetMuscles: ['Lats', 'Biceps', 'Traps'],
    ),
    Routine(
      title: 'Leg Day A (Quads/Hamstrings)',
      folderName: 'Push-Pull-Legs Split',
      exerciseIds: ['ex_squat', 'ex_leg_extension'],
      estimatedDurationMinutes: 60,
      targetMuscles: ['Quads', 'Hamstrings', 'Glutes'],
    ),
  ];

  void _showPreviewVolumeSheet(Routine routine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ROUTINE VOLUME PREVIEW',
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                routine.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPreviewStat('Est. Duration', '${routine.estimatedDurationMinutes}m'),
                  _buildPreviewStat('Total Exercises', '${routine.exerciseIds.length}'),
                  _buildPreviewStat('Est. Volume', '14,200 kg'),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref
                      .read(activeWorkoutProvider.notifier)
                      .startEmptyWorkout(title: routine.title);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('START THIS ROUTINE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Color(0xFF6C5CE7),
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF11111B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11111B),
        elevation: 0,
        title: const Text('Routines & Folders',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF6C5CE7)),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Folder Header
          Row(
            children: [
              const Icon(Icons.folder_open, color: Color(0xFF6C5CE7), size: 20),
              const SizedBox(width: 8),
              Text(
                'Push-Pull-Legs Split (3 Routines)',
                style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._routines.map((routine) => _buildRoutineCard(routine)),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(Routine routine) {
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
          Text(routine.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: routine.targetMuscles
                .map((m) => Chip(
                      label: Text(m,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10)),
                      backgroundColor: const Color(0xFF2E2E3E),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showPreviewVolumeSheet(routine),
                icon: const Icon(Icons.bar_chart, size: 16, color: Colors.white),
                label: const Text('Preview Volume',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(activeWorkoutProvider.notifier)
                      .startEmptyWorkout(title: routine.title);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                ),
                child: const Text('Start',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
