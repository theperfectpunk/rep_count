import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';

class RoutineEditorScreen extends StatefulWidget {
  final Routine? existingRoutine;

  const RoutineEditorScreen({Key? key, this.existingRoutine}) : super(key: key);

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> {
  final ExerciseRepository _exerciseRepo = ExerciseRepository();

  late TextEditingController _titleController;
  late TextEditingController _folderController;
  int _selectedDuration = 45;
  final List<int> _durationOptions = [30, 45, 60, 75, 90];

  List<Exercise> _allExercises = [];
  List<Exercise> _selectedExercises = [];
  bool _isLoadingExercises = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final routine = widget.existingRoutine;
    _titleController = TextEditingController(text: routine?.title ?? '');
    _folderController = TextEditingController(
      text: (routine != null && routine.folderName.isNotEmpty)
          ? routine.folderName
          : 'Custom Workouts',
    );
    _selectedDuration = routine?.estimatedDurationMinutes ?? 45;

    _loadExercises();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _folderController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    final master = _exerciseRepo.getMasterExercises();
    setState(() {
      _allExercises = List.from(master);
      _populateSelectedExercises();
      _isLoadingExercises = false;
    });

    try {
      final fetched = await _exerciseRepo.fetchExercisesFromFirebase();
      if (mounted && fetched.isNotEmpty) {
        setState(() {
          _allExercises = fetched;
          _populateSelectedExercises();
        });
      }
    } catch (e) {
      debugPrint('Error fetching exercises in editor: $e');
    }
  }

  void _populateSelectedExercises() {
    if (widget.existingRoutine != null &&
        widget.existingRoutine!.exerciseIds.isNotEmpty) {
      final ids = widget.existingRoutine!.exerciseIds;
      final List<Exercise> matched = [];
      for (final id in ids) {
        final found = _allExercises.firstWhere(
          (e) => e.id == id,
          orElse: () => Exercise(
            id: id,
            name: id,
            category: 'Custom',
            equipment: 'N/A',
            primaryMuscle: 'Custom',
            secondaryMuscles: [],
          ),
        );
        matched.add(found);
      }
      _selectedExercises = matched;
    }
  }

  void _openExercisePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _ExercisePickerSheet(
          allExercises: _allExercises,
          currentlySelected: _selectedExercises,
          onExercisesSelected: (updatedList) {
            setState(() {
              _selectedExercises = updatedList;
            });
          },
        );
      },
    );
  }

  Future<void> _saveRoutine() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a routine title'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final folder = _folderController.text.trim().isEmpty
        ? 'Custom Workouts'
        : _folderController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'default_user';
      final exerciseIds = _selectedExercises.map((e) => e.id).toList();
      final targetMuscles = _selectedExercises
          .map((e) => e.primaryMuscle)
          .toSet()
          .toList();
      if (targetMuscles.isEmpty) {
        targetMuscles.add('Custom');
      }

      final routineId = widget.existingRoutine?.routineId;
      final routine = Routine(
        routineId: routineId,
        title: title,
        folderName: folder,
        estimatedDurationMinutes: _selectedDuration,
        exerciseIds: exerciseIds,
        targetMuscles: targetMuscles,
        createdAt: widget.existingRoutine?.createdAt,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routine.routineId)
          .set(routine.toJson());

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save routine: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRoutine != null;

    return Scaffold(
      backgroundColor: const Color(0xFF11111B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11111B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Routine' : 'Create Routine',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoadingExercises
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Routine Title
                  const Text(
                    'Routine Title',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g. Upper Body Power',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: const Color(0xFF1E1E2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Folder Name
                  const Text(
                    'Folder Name',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _folderController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g. Custom Workouts',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: const Color(0xFF1E1E2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Estimated Duration
                  const Text(
                    'Estimated Duration',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedDuration,
                        dropdownColor: const Color(0xFF1E1E2E),
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF6C5CE7),
                        ),
                        items: _durationOptions.map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(
                              '$value min',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedDuration = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Header: Exercises (X selected)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Exercises (${_selectedExercises.length} selected)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ReorderableListView of selected exercises
                  if (_selectedExercises.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2E).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            color: Colors.grey.shade600,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No exercises added yet',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedExercises.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = _selectedExercises.removeAt(oldIndex);
                          _selectedExercises.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final exercise = _selectedExercises[index];
                        return Container(
                          key: ValueKey('${exercise.id}_$index'),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.drag_handle,
                                color: Colors.white38,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        _buildChip(
                                          exercise.primaryMuscle,
                                          const Color(0xFF6C5CE7),
                                        ),
                                        ...exercise.secondaryMuscles.map(
                                          (m) => _buildChip(
                                            m,
                                            const Color(0xFF2E2E3E),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      exercise.equipment,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 22,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedExercises.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 16),

                  // Add Exercises Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openExercisePicker,
                      icon: const Icon(Icons.add, color: Color(0xFF6C5CE7)),
                      label: const Text(
                        'Add Exercises',
                        style: TextStyle(
                          color: Color(0xFF6C5CE7),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF6C5CE7),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveRoutine,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Save Routine',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == const Color(0xFF6C5CE7)
              ? const Color(0xFFA29BFE)
              : Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ExercisePickerSheet extends StatefulWidget {
  final List<Exercise> allExercises;
  final List<Exercise> currentlySelected;
  final Function(List<Exercise>) onExercisesSelected;

  const _ExercisePickerSheet({
    Key? key,
    required this.allExercises,
    required this.currentlySelected,
    required this.onExercisesSelected,
  }) : super(key: key);

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedMuscleFilter = 'All';
  late Set<String> _selectedIds;

  final List<String> _muscleFilters = [
    'All',
    'Chest',
    'Back',
    'Shoulders',
    'Legs',
    'Arms',
    'Core',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.currentlySelected.map((e) => e.id).toSet();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesMuscleFilter(Exercise ex, String filter) {
    if (filter == 'All') return true;
    final primary = ex.primaryMuscle.toLowerCase();
    switch (filter.toLowerCase()) {
      case 'chest':
        return primary.contains('chest');
      case 'back':
        return primary.contains('back') || primary.contains('lat');
      case 'shoulders':
        return primary.contains('shoulder') || primary.contains('delt');
      case 'legs':
        return primary.contains('leg') ||
            primary.contains('quad') ||
            primary.contains('hamstring') ||
            primary.contains('calf') ||
            primary.contains('calves') ||
            primary.contains('glute');
      case 'arms':
        return primary.contains('arm') ||
            primary.contains('bicep') ||
            primary.contains('tricep') ||
            primary.contains('forearm');
      case 'core':
        return primary.contains('core') || primary.contains('ab');
      default:
        return primary == filter.toLowerCase();
    }
  }

  List<Exercise> get _filteredExercises {
    return widget.allExercises.where((ex) {
      final matchesSearch = _searchQuery.isEmpty ||
          ex.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ex.primaryMuscle.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMuscle = _matchesMuscleFilter(ex, _selectedMuscleFilter);
      return matchesSearch && matchesMuscle;
    }).toList();
  }

  void _applySelection() {
    final List<Exercise> updatedList = [];

    // Keep existing selected items in order if still selected
    for (final ex in widget.currentlySelected) {
      if (_selectedIds.contains(ex.id)) {
        updatedList.add(ex);
      }
    }

    // Append newly selected exercises
    for (final id in _selectedIds) {
      if (!updatedList.any((e) => e.id == id)) {
        final ex = widget.allExercises.firstWhere((e) => e.id == id);
        updatedList.add(ex);
      }
    }

    widget.onExercisesSelected(updatedList);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredExercises;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Exercises',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search exercise name or muscle...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF11111B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Muscle Group Filter Chips
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _muscleFilters.length,
              itemBuilder: (context, index) {
                final filter = _muscleFilters[index];
                final isSelected = filter == _selectedMuscleFilter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMuscleFilter = filter;
                      });
                    },
                    selectedColor: const Color(0xFF6C5CE7),
                    backgroundColor: const Color(0xFF11111B),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF6C5CE7)
                            : Colors.white10,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),

          // List of exercises
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No exercises match your search',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final ex = filtered[index];
                      final isChecked = _selectedIds.contains(ex.id);
                      return CheckboxListTile(
                        value: isChecked,
                        activeColor: const Color(0xFF00B894),
                        checkColor: Colors.white,
                        title: Text(
                          ex.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          '${ex.primaryMuscle} • ${ex.equipment}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                        onChanged: (bool? val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.add(ex.id);
                            } else {
                              _selectedIds.remove(ex.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF11111B),
              border: Border(
                top: BorderSide(color: Colors.white10),
              ),
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _applySelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Add ${_selectedIds.length} Exercises',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
