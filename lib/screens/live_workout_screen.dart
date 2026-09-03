import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/active_workout_provider.dart';
import '../models/exercise_log.dart';
import '../models/set_item.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/workout_repository.dart';
import '../widgets/plate_calculator_modal.dart';
import '../widgets/sticky_timer_bar.dart';
import 'workout_summary_screen.dart';

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

  Widget _buildTypeChip(
    BuildContext ctx,
    WidgetRef ref,
    String exerciseId,
    int setIdx,
    SetType type,
    String label,
    Color color,
    SetType currentType,
  ) {
    final isSelected = currentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(activeWorkoutProvider.notifier).updateSetType(exerciseId, setIdx, type);
          Navigator.pop(ctx);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.white10,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSetDetailsModal(
    BuildContext context,
    WidgetRef ref,
    String exerciseId,
    int setIdx,
    SetItem setItem,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final rpeValues = [6.0, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0];
        final estimated1RM = setItem.reps > 0
            ? (setItem.weightKg * (1 + setItem.reps / 30)).round()
            : 0;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SET ${setIdx + 1} SETTINGS',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  if (estimated1RM > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF6C5CE7).withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        '⚡ Est. 1RM: $estimated1RM kg',
                        style: const TextStyle(
                          color: Color(0xFF6C5CE7),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Set Type',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTypeChip(ctx, ref, exerciseId, setIdx, SetType.NORMAL, 'Normal', const Color(0xFF00B894), setItem.type),
                  const SizedBox(width: 6),
                  _buildTypeChip(ctx, ref, exerciseId, setIdx, SetType.WARMUP, 'Warmup (W)', Colors.orangeAccent, setItem.type),
                  const SizedBox(width: 6),
                  _buildTypeChip(ctx, ref, exerciseId, setIdx, SetType.DROPSET, 'Drop (D)', Colors.purpleAccent, setItem.type),
                  const SizedBox(width: 6),
                  _buildTypeChip(ctx, ref, exerciseId, setIdx, SetType.FAILURE, 'Failure (F)', Colors.redAccent, setItem.type),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Rate of Perceived Exertion (RPE)',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Log exertion & reps in reserve (RIR)',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('None', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    backgroundColor: setItem.rpe == null
                        ? const Color(0xFF6C5CE7).withOpacity(0.4)
                        : Colors.white.withOpacity(0.05),
                    onPressed: () {
                      ref.read(activeWorkoutProvider.notifier).updateSetRpe(exerciseId, setIdx, null);
                      Navigator.pop(ctx);
                    },
                  ),
                  ...rpeValues.map((val) {
                    final isSelected = setItem.rpe == val;
                    return ActionChip(
                      label: Text(
                        '@ $val',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      backgroundColor: isSelected
                          ? const Color(0xFF6C5CE7)
                          : const Color(0xFF6C5CE7).withOpacity(0.15),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
                      ),
                      onPressed: () {
                        ref.read(activeWorkoutProvider.notifier).updateSetRpe(exerciseId, setIdx, val);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ],
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
            onPressed: () async {
              final hasCompletedSets = activeWorkout.exercises.any(
                (ex) => ex.sets.any((s) => s.isCompleted),
              );

              if (!hasCompletedSets) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E2E),
                    title: const Text('Finish Workout?',
                        style: TextStyle(color: Colors.white)),
                    content: const Text(
                      'You have 0 completed sets. Finish anyway?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B894),
                        ),
                        child: const Text('Finish',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (confirm != true) {
                  return;
                }
              }

              final completedSession =
                  ref.read(activeWorkoutProvider.notifier).finishWorkout();
              if (completedSession != null) {
                String? currentUserId;
                try {
                  currentUserId = FirebaseAuth.instance.currentUser?.uid;
                } catch (_) {}
                WorkoutRepository().saveCompletedWorkout(
                  completedSession,
                  userId: currentUserId,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 Workout Completed & Synced to Cloud!'),
                      backgroundColor: Color(0xFF00B894),
                    ),
                  );
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => WorkoutSummaryScreen(session: completedSession),
                  ));
                }
              }
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
              Expanded(
                child: Text(
                  exercise.exerciseName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.calculate_outlined,
                        color: Color(0xFF6C5CE7)),
                    tooltip: 'Plate Calculator',
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
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 20),
                    tooltip: 'Remove Exercise',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          backgroundColor: const Color(0xFF1E1E2E),
                          title: const Text('Remove Exercise',
                              style: TextStyle(color: Colors.white)),
                          content: Text(
                              'Remove "${exercise.exerciseName}" from this workout session?',
                              style: const TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: const Text('Cancel',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent),
                              onPressed: () {
                                Navigator.pop(dialogCtx);
                                ref
                                    .read(activeWorkoutProvider.notifier)
                                    .removeExercise(exercise.exerciseId);
                              },
                              child: const Text('Remove',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Table Header
          Row(
            children: [
              const SizedBox(width: 44, child: Text('SET', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
              const Expanded(child: Center(child: Text('EST 1RM', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)))),
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
                    // Set Number & Type Pill (Tap to edit Set Type & RPE)
                    SizedBox(
                      width: 44,
                      child: InkWell(
                        onTap: () => _showSetDetailsModal(
                            context, ref, exercise.exerciseId, setIdx, setItem),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: setItem.isCompleted
                                ? const Color(0xFF00B894).withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: setItem.type != SetType.NORMAL
                                ? Border.all(
                                    color: _getSetTypeColor(setItem.type)
                                        .withOpacity(0.7),
                                    width: 1.2)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              typeTag.isNotEmpty ? '$typeTag ${setIdx + 1}' : '${setIdx + 1}',
                              style: TextStyle(
                                color: setItem.isCompleted
                                    ? _getSetTypeColor(setItem.type)
                                    : (typeTag.isNotEmpty
                                        ? _getSetTypeColor(setItem.type)
                                        : Colors.white),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // EST 1RM / PREV Performance
                    Expanded(
                      child: Center(
                        child: Text(
                          setItem.isCompleted && setItem.reps > 0
                              ? '${(setItem.weightKg * (1 + setItem.reps / 30)).round()} kg'
                              : (setItem.rpe != null ? '@${setItem.rpe}' : '-- × --'),
                          style: TextStyle(
                            color: setItem.isCompleted
                                ? const Color(0xFF6C5CE7)
                                : Colors.grey,
                            fontSize: 11,
                            fontWeight: setItem.isCompleted
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),

                    // Weight Input Field with +/- 2.5 buttons
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: _WeightInputField(
                          key: ValueKey('${setItem.setId}_weight'),
                          initialWeight: setItem.weightKg,
                          onChanged: (w) {
                            ref
                                .read(activeWorkoutProvider.notifier)
                                .updateSetValues(exercise.exerciseId, setIdx,
                                    weight: w);
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
              TextButton.icon(
                onPressed: () {
                  if (exercise.sets.isNotEmpty) {
                    _showSetDetailsModal(context, ref, exercise.exerciseId, exercise.sets.length - 1, exercise.sets.last);
                  }
                },
                icon: const Icon(Icons.tune, size: 14, color: Colors.grey),
                label: Text('Set Details',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightInputField extends StatefulWidget {
  final double initialWeight;
  final ValueChanged<double> onChanged;

  const _WeightInputField({
    Key? key,
    required this.initialWeight,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<_WeightInputField> createState() => _WeightInputFieldState();
}

class _WeightInputFieldState extends State<_WeightInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialWeight == 0 ? '' : _formatWeight(widget.initialWeight),
    );
  }

  @override
  void didUpdateWidget(covariant _WeightInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialWeight != widget.initialWeight) {
      final currentParsed = double.tryParse(_controller.text);
      if (currentParsed != widget.initialWeight) {
        _controller.text = widget.initialWeight == 0 ? '' : _formatWeight(widget.initialWeight);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatWeight(double val) {
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  void _adjustWeight(double delta) {
    final current = double.tryParse(_controller.text) ?? widget.initialWeight;
    double updated = (current + delta);
    if (updated < 0) updated = 0;
    updated = (updated * 100).roundToDouble() / 100;
    final formatted = _formatWeight(updated);
    _controller.text = formatted;
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _adjustWeight(-2.5),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '-2.5',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '${widget.initialWeight}',
              hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                widget.onChanged(w);
              }
            },
          ),
        ),
        const SizedBox(width: 2),
        InkWell(
          onTap: () => _adjustWeight(2.5),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '+2.5',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

