import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/active_workout_provider.dart';
import '../models/exercise_log.dart';
import '../models/set_item.dart';
import '../repositories/exercise_repository.dart';
import '../widgets/plate_calculator_modal.dart';
import '../widgets/sticky_timer_bar.dart';

class LiveWorkoutScreen extends ConsumerWidget {
  const LiveWorkoutScreen({Key? key}) : super(key: key);

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    final hrs = mins ~/ 60;
    if (hrs > 0) {
      return '${hrs}h ${mins % 60}m';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showAddExerciseModal(BuildContext context, WidgetRef ref) {
    final repo = ExerciseRepository();
    final exercises = repo.getMasterExercises();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Exercise to Workout',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final ex = exercises[index];
                    return ListTile(
                      title: Text(ex.name,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${ex.primaryMuscle} • ${ex.equipment}',
                          style: TextStyle(color: Colors.grey.shade400)),
                      trailing: const Icon(Icons.add_circle_outline,
                          color: Color(0xFF6C5CE7)),
                      onTap: () {
                        final newLog = ExerciseLog(
                          exerciseId: ex.id,
                          exerciseName: ex.name,
                          targetMuscle: ex.primaryMuscle,
                          equipment: ex.equipment,
                          sets: [
                            SetItem(index: 0, weightKg: 60.0, reps: 10, type: SetType.NORMAL),
                            SetItem(index: 1, weightKg: 80.0, reps: 8, type: SetType.NORMAL),
                          ],
                        );
                        ref
                            .read(activeWorkoutProvider.notifier)
                            .addExercise(newLog);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRpePicker(BuildContext context, WidgetRef ref, String exerciseId, int setIdx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final rpeValues = [6.0, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0];
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RATE OF PERCEIVED EXERTION (RPE)',
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rpeValues.map((val) {
                  return ActionChip(
                    label: Text('@ RPE $val',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.3),
                    side: const BorderSide(color: Color(0xFF6C5CE7)),
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getSetTypeLabel(SetType type) {
    switch (type) {
      case SetType.WARMUP:
        return 'W';
      case SetType.DROPSET:
        return 'D';
      case SetType.FAILURE:
        return 'F';
      case SetType.NORMAL:
      default:
        return '';
    }
  }

  Color _getSetTypeColor(SetType type) {
    switch (type) {
      case SetType.WARMUP:
        return Colors.orangeAccent;
      case SetType.DROPSET:
        return Colors.purpleAccent;
      case SetType.FAILURE:
        return Colors.redAccent;
      case SetType.NORMAL:
      default:
        return const Color(0xFF00B894);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWorkout = ref.watch(activeWorkoutProvider);

    if (activeWorkout == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF11111B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center,
                  size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              const Text('No Active Workout Session',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(activeWorkoutProvider.notifier)
                      .startEmptyWorkout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Start Workout Now',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF11111B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11111B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activeWorkout.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text(
              '⏱️ ${_formatDuration(activeWorkout.durationSeconds)} • ${activeWorkout.totalVolumeKg.toInt()} kg',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              ref.read(activeWorkoutProvider.notifier).finishWorkout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Workout Completed & Synced to Cloud!'),
                  backgroundColor: Color(0xFF00B894),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B894),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('FINISH',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeWorkout.exercises.length + 1,
              itemBuilder: (context, index) {
                if (index == activeWorkout.exercises.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddExerciseModal(context, ref),
                      icon: const Icon(Icons.add, color: Color(0xFF6C5CE7)),
                      label: const Text('ADD EXERCISE',
                          style: TextStyle(
                              color: Color(0xFF6C5CE7),
                              fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6C5CE7)),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  );
                }

                final exercise = activeWorkout.exercises[index];
                final isSuperset = index > 0 && index % 2 == 1;
                return _buildExerciseCard(context, ref, exercise, isSuperset: isSuperset);
              },
            ),
          ),

          // Sticky Rest Timer Widget (Isolated)
          const StickyTimerBar(),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
      BuildContext context, WidgetRef ref, ExerciseLog exercise, {bool isSuperset = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuperset ? const Color(0xFF6C5CE7) : Colors.white.withOpacity(0.05),
          width: isSuperset ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSuperset)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('🔗 SUPERSET PAIR A',
                  style: TextStyle(
                      color: Color(0xFF6C5CE7),
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exercise.exerciseName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.calculate_outlined,
                    color: Color(0xFF6C5CE7)),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => PlateCalculatorModal(
                      targetWeightKg: exercise.sets.isNotEmpty
                          ? exercise.sets.first.weightKg
                          : 60.0,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Table Header
          Row(
            children: [
              const SizedBox(width: 44, child: Text('SET', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
              const Expanded(child: Center(child: Text('KG / LBS', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)))),
              const Expanded(child: Center(child: Text('REPS', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 44, child: Center(child: Text('✓', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)))),
            ],
          ),
          const Divider(color: Colors.white10),

          // Sets Rows with Swipe-to-Delete
          ...exercise.sets.asMap().entries.map((entry) {
            final setIdx = entry.key;
            final setItem = entry.value;
            final typeTag = _getSetTypeLabel(setItem.type);

            return Dismissible(
              key: Key(setItem.setId),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.redAccent.withOpacity(0.2),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.redAccent),
              ),
              onDismissed: (direction) {
                ref
                    .read(activeWorkoutProvider.notifier)
                    .removeSet(exercise.exerciseId, setIdx);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    // Set Number & Type Pill
                    SizedBox(
                      width: 44,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: setItem.isCompleted
                              ? const Color(0xFF00B894).withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            typeTag.isNotEmpty ? '$typeTag ${setIdx + 1}' : '${setIdx + 1}',
                            style: TextStyle(
                              color: setItem.isCompleted
                                  ? _getSetTypeColor(setItem.type)
                                  : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Weight Input Field
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '${setItem.weightKg}',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            isDense: true,
                            contentPadding: const EdgeInsets.all(8),
                            filled: true,
                            fillColor: const Color(0xFF11111B),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) {
                            final w = double.tryParse(val);
                            if (w != null) {
                              ref
                                  .read(activeWorkoutProvider.notifier)
                                  .updateSetValues(exercise.exerciseId, setIdx,
                                      weight: w);
                            }
                          },
                        ),
                      ),
                    ),

                    // Reps Input Field
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '${setItem.reps}',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            isDense: true,
                            contentPadding: const EdgeInsets.all(8),
                            filled: true,
                            fillColor: const Color(0xFF11111B),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) {
                            final r = int.tryParse(val);
                            if (r != null) {
                              ref
                                  .read(activeWorkoutProvider.notifier)
                                  .updateSetValues(exercise.exerciseId, setIdx,
                                      reps: r);
                            }
                          },
                        ),
                      ),
                    ),

                    // Completion Checkbox
                    SizedBox(
                      width: 44,
                      child: IconButton(
                        icon: Icon(
                          setItem.isCompleted
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: setItem.isCompleted
                              ? const Color(0xFF00B894)
                              : Colors.grey.shade600,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(activeWorkoutProvider.notifier)
                              .toggleSetCompletion(exercise.exerciseId, setIdx);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  ref
                      .read(activeWorkoutProvider.notifier)
                      .addSet(exercise.exerciseId);
                },
                icon: const Icon(Icons.add, size: 16, color: Color(0xFF6C5CE7)),
                label: const Text('Add Set',
                    style: TextStyle(color: Color(0xFF6C5CE7))),
              ),
              TextButton(
                onPressed: () => _showRpePicker(context, ref, exercise.exerciseId, 0),
                child: Text('RPE Rating',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
