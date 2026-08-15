import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/routine.dart';
import '../providers/active_workout_provider.dart';
import '../repositories/routine_repository.dart';
import 'routine_editor_screen.dart';

class RoutinePlannerScreen extends ConsumerStatefulWidget {
  const RoutinePlannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RoutinePlannerScreen> createState() =>
      _RoutinePlannerScreenState();
}

class _RoutinePlannerScreenState extends ConsumerState<RoutinePlannerScreen> {
  final RoutineRepository _routineRepo = RoutineRepository();
  List<Routine> _routines = RoutineRepository.defaultBodyPartRoutines;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRoutines();
  }

  Future<void> _loadUserRoutines() async {
    String userId = 'default_user';
    try {
      userId = FirebaseAuth.instance.currentUser?.uid ?? 'default_user';
    } catch (_) {}
    final list = await _routineRepo.fetchUserRoutines(userId);
    if (mounted) {
      setState(() {
        _routines = list;
        _isLoading = false;
      });
    }
  }


  void _confirmDeleteRoutine(Routine routine) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Routine',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${routine.title}"?',
            style: TextStyle(color: Colors.grey.shade300),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  final userId =
                      FirebaseAuth.instance.currentUser?.uid ?? 'default_user';
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('routines')
                      .doc(routine.routineId)
                      .delete();
                } catch (_) {}

                if (mounted) {
                  await _loadUserRoutines();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPreviewVolumeSheet(Routine routine) {
    final estimatedVolumeKg = routine.exerciseIds.length * 4 * 50;
    final formattedVolume = estimatedVolumeKg == 0
        ? '0 kg'
        : '${estimatedVolumeKg.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} kg';

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
                  _buildPreviewStat('Est. Volume', formattedVolume),
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
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: const Color(0xFF6C5CE7).withOpacity(0.5),
            strokeWidth: 1.5,
            gap: 6.0,
            radius: 20.0,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E).withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.folder_open,
                    size: 48,
                    color: Color(0xFF6C5CE7),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No routines yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first workout routine!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RoutineEditorScreen()),
                  ).then((_) => _loadUserRoutines()),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Create Routine',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedRoutineWidgets() {
    final Map<String, List<Routine>> grouped = {};
    for (final routine in _routines) {
      final folder =
          routine.folderName.isNotEmpty ? routine.folderName : 'General Routines';
      grouped.putIfAbsent(folder, () => []).add(routine);
    }

    final List<Widget> widgets = [];
    grouped.forEach((folderName, routines) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.folder_open, color: Color(0xFF6C5CE7), size: 20),
              const SizedBox(width: 8),
              Text(
                '$folderName (${routines.length} Routine${routines.length == 1 ? '' : 's'})',
                style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
      for (final routine in routines) {
        widgets.add(_buildRoutineCard(routine));
      }
    });

    return widgets;
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
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const RoutineEditorScreen()),
            ).then((_) => _loadUserRoutines()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
          : _routines.isEmpty
              ? _buildEmptyState()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _buildGroupedRoutineWidgets(),
                ),
    );
  }

  Widget _buildRoutineCard(Routine routine) {
    return GestureDetector(
      onLongPress: () => _confirmDeleteRoutine(routine),
      child: Container(
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
                Expanded(
                  child: Text(
                    routine.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B894).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${routine.estimatedDurationMinutes} min',
                    style: const TextStyle(
                      color: Color(0xFF00B894),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
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
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            RoutineEditorScreen(existingRoutine: routine)),
                  ).then((_) => _loadUserRoutines()),
                ),
                const SizedBox(width: 4),
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
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  DashedBorderPainter({
    this.color = const Color(0xFF6C5CE7),
    this.strokeWidth = 1.5,
    this.gap = 5.0,
    this.radius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double nextDistance = distance + 6.0;
        canvas.drawPath(
          metric.extractPath(distance, nextDistance.clamp(0.0, metric.length)),
          paint,
        );
        distance = nextDistance + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gap != gap ||
      oldDelegate.radius != radius;
}
