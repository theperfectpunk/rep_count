import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/exercise_repository.dart';
import '../models/exercise.dart';

extension ExerciseSubMuscle on Exercise {
  String? get subMuscle {
    try {
      final dynamic d = this;
      final sm = d.subMuscle;
      if (sm != null && sm is String && sm.isNotEmpty) {
        return sm as String;
      }
    } catch (_) {}
    try {
      final map = toJson();
      if (map.containsKey('subMuscle') && map['subMuscle'] != null) {
        final val = map['subMuscle'].toString();
        if (val.isNotEmpty) return val;
      }
    } catch (_) {}
    return _inferSubMuscle(name, primaryMuscle);
  }
}

String? _inferSubMuscle(String name, String primaryMuscle) {
  final n = name.toLowerCase();
  final p = primaryMuscle.toLowerCase();

  // Chest
  if (p == 'chest') {
    if (n.contains('incline')) return 'Upper Chest';
    if (n.contains('decline') || n.contains('dip') || n.contains('fly')) return 'Lower Chest';
    return 'Mid Chest';
  }

  // Back
  if (p == 'back') {
    if (n.contains('pull-up') || n.contains('pulldown') || n.contains('lat')) return 'Lats';
    if (n.contains('row')) return 'Mid Back';
    if (n.contains('shrug') || n.contains('face pull')) return 'Upper Back';
    if (n.contains('hyperextension') || n.contains('good morning')) return 'Lower Back';
    return 'Lats';
  }

  // Shoulders
  if (p == 'shoulders') {
    if (n.contains('overhead') || n.contains('arnold') || n.contains('front') || n.contains('press')) return 'Front Delt';
    if (n.contains('lateral') || n.contains('side')) return 'Side Delt';
    if (n.contains('face pull') || n.contains('rear') || n.contains('reverse')) return 'Rear Delt';
    return 'Front Delt';
  }

  // Legs
  if (p == 'quads') return 'Quads';
  if (p == 'hamstrings') return 'Hamstrings';
  if (p == 'glutes') return 'Glutes';
  if (p == 'adductors') return 'Adductors';
  if (p == 'abductors') return 'Abductors';
  if (p == 'calves') return 'Calves';

  // Arms
  if (p == 'biceps') {
    if (n.contains('hammer') || n.contains('reverse')) return 'Forearms';
    return 'Biceps';
  }
  if (p == 'triceps') return 'Triceps';
  if (p == 'forearms') return 'Forearms';

  // Core
  if (p == 'abs') {
    if (n.contains('leg raise') || n.contains('hanging')) return 'Lower Abs';
    if (n.contains('oblique') || n.contains('twist')) return 'Obliques';
    return 'Upper Abs';
  }

  if (p == 'traps') return 'Upper Back';

  return null;
}

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final ExerciseRepository _repo = ExerciseRepository();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  String _searchQuery = '';
  String _selectedMuscleGroup = 'All';
  String? _selectedSubMuscle;
  String _selectedEquipment = 'All';

  final List<String> _primaryMuscleGroups = [
    'All',
    'Chest',
    'Back',
    'Shoulders',
    'Legs',
    'Arms',
    'Core',
    'Other',
  ];

  static const Map<String, List<String>> _groupToPrimaryMuscles = {
    'Chest': ['Chest'],
    'Back': ['Back'],
    'Shoulders': ['Shoulders'],
    'Legs': ['Quads', 'Hamstrings', 'Glutes', 'Adductors', 'Abductors', 'Calves'],
    'Arms': ['Biceps', 'Triceps', 'Forearms'],
    'Core': ['Abs'],
    'Other': ['Traps'],
  };

  static const Set<String> _standardPrimaryMuscles = {
    'Chest',
    'Back',
    'Shoulders',
    'Quads',
    'Hamstrings',
    'Glutes',
    'Adductors',
    'Abductors',
    'Calves',
    'Biceps',
    'Triceps',
    'Forearms',
    'Abs',
  };

  static const Map<String, List<String>> _groupSubMusclePresets = {
    'Chest': ['All', 'Upper Chest', 'Mid Chest', 'Lower Chest'],
    'Back': ['All', 'Lats', 'Mid Back', 'Upper Back', 'Lower Back'],
    'Shoulders': ['All', 'Front Delt', 'Side Delt', 'Rear Delt'],
    'Legs': ['All', 'Quads', 'Hamstrings', 'Glutes', 'Adductors', 'Abductors', 'Calves'],
    'Arms': ['All', 'Biceps', 'Triceps', 'Forearms'],
    'Core': ['All', 'Upper Abs', 'Lower Abs', 'Obliques'],
  };

  late Future<List<Exercise>> _exercisesFuture;
  List<Exercise> _allExercises = [];

  @override
  void initState() {
    super.initState();
    _exercisesFuture = _loadExercises();
  }

  Future<List<Exercise>> _loadExercises() async {
    final list = await _repo.fetchExercisesFromFirebase();
    if (mounted) {
      setState(() {
        _allExercises = list;
      });
    }
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  List<String> _getSubMuscleOptionsForGroup(String group) {
    final presets = _groupSubMusclePresets[group] ?? ['All'];
    final result = List<String>.from(presets);

    final exercises = _getGroupExercises(group);
    for (final ex in exercises) {
      final sub = ex.subMuscle;
      if (sub != null && sub.isNotEmpty && !result.contains(sub)) {
        result.add(sub);
      }
    }
    return result;
  }

  List<Exercise> _getGroupExercises(String group) {
    final source = _allExercises.isNotEmpty ? _allExercises : _repo.getMasterExercises();
    if (group == 'All') return source;

    final allowedPrimary = _groupToPrimaryMuscles[group];
    return source.where((ex) {
      if (allowedPrimary != null) {
        return allowedPrimary.contains(ex.primaryMuscle);
      } else if (group == 'Other') {
        return !_standardPrimaryMuscles.contains(ex.primaryMuscle) || ex.primaryMuscle == 'Traps';
      }
      return false;
    }).toList();
  }

  List<Exercise> _getFilteredExercises() {
    final source = _allExercises.isNotEmpty ? _allExercises : _repo.getMasterExercises();

    return source.where((ex) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatches = ex.name.toLowerCase().contains(q);
        final primaryMatches = ex.primaryMuscle.toLowerCase().contains(q);
        final subMatches = ex.subMuscle?.toLowerCase().contains(q) ?? false;
        if (!nameMatches && !primaryMatches && !subMatches) {
          return false;
        }
      }

      // 2. Equipment Filter
      if (_selectedEquipment != 'All' && ex.equipment != _selectedEquipment) {
        return false;
      }

      // 3. Level 1 Primary Muscle Group Filter
      if (_selectedMuscleGroup != 'All') {
        final allowedPrimary = _groupToPrimaryMuscles[_selectedMuscleGroup];
        if (allowedPrimary != null) {
          if (!allowedPrimary.contains(ex.primaryMuscle)) {
            return false;
          }
        } else if (_selectedMuscleGroup == 'Other') {
          final isStandard = _standardPrimaryMuscles.contains(ex.primaryMuscle);
          if (isStandard && ex.primaryMuscle != 'Traps') {
            return false;
          }
        }
      }

      // 4. Level 2 Sub-Muscle Filter
      if (_selectedSubMuscle != null && _selectedSubMuscle != 'All') {
        final sub = ex.subMuscle;
        if (sub == null || sub.toLowerCase() != _selectedSubMuscle!.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _showOneRepMaxPopover(Exercise exercise) {
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
                'HISTORICAL 1RM RECORD',
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                exercise.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF11111B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estimated 1RM',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${exercise.historicalOneRepMax} kg',
                          style: const TextStyle(
                              color: Color(0xFF6C5CE7),
                              fontSize: 28,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const Icon(Icons.show_chart,
                        color: Color(0xFF00B894), size: 36),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Secondary Muscles: ${exercise.secondaryMuscles.join(", ")}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = _getFilteredExercises();

    return Scaffold(
      backgroundColor: const Color(0xFF11111B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11111B),
        elevation: 0,
        title: const Text('Exercise Library',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Exercise>>(
        future: _exercisesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _allExercises.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
            );
          }

          if (snapshot.hasError && _allExercises.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _exercisesFuture = _loadExercises();
                      });
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Retry', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Debounced Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search exercises (e.g. Bench Press)...',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF6C5CE7)),
                    filled: true,
                    fillColor: const Color(0xFF1E1E2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Level 1 — Primary Muscle Group Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: _primaryMuscleGroups.map((group) {
                    final isSelected = _selectedMuscleGroup == group;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(group),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedMuscleGroup = group;
                            _selectedSubMuscle = null;
                          });
                        },
                        selectedColor: const Color(0xFF6C5CE7),
                        backgroundColor: const Color(0xFF1E1E2E),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade400,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Level 2 — Sub-Muscle Chips (shown when a primary group is selected)
              if (_selectedMuscleGroup != 'All') ...[
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: _getSubMuscleOptionsForGroup(_selectedMuscleGroup).map((subMuscle) {
                      final isSelected = (_selectedSubMuscle == subMuscle) ||
                          (_selectedSubMuscle == null && subMuscle == 'All');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(subMuscle),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (subMuscle == 'All') {
                                _selectedSubMuscle = null;
                              } else {
                                _selectedSubMuscle = selected ? subMuscle : null;
                              }
                            });
                          },
                          selectedColor: const Color(0xFF00B894),
                          backgroundColor: const Color(0xFF1E1E2E),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade400,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Exercise List
              Expanded(
                child: filteredExercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off,
                                size: 64, color: Colors.white24),
                            const SizedBox(height: 16),
                            const Text(
                              'No exercises found',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _selectedMuscleGroup = 'All';
                                  _selectedSubMuscle = null;
                                  _selectedEquipment = 'All';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C5CE7),
                              ),
                              child: const Text('Clear Filters',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = filteredExercises[index];
                          final sub = exercise.subMuscle;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E2E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.05)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor:
                                    const Color(0xFF6C5CE7).withOpacity(0.2),
                                child: const Icon(Icons.fitness_center,
                                    color: Color(0xFF6C5CE7), size: 20),
                              ),
                              title: Text(exercise.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${exercise.primaryMuscle} • ${exercise.equipment}',
                                    style: TextStyle(
                                        color: Colors.grey.shade400, fontSize: 12),
                                  ),
                                  if (sub != null && sub.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00B894)
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFF00B894)
                                              .withOpacity(0.4),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        sub,
                                        style: const TextStyle(
                                          color: Color(0xFF00B894),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '1RM: ${exercise.historicalOneRepMax.toInt()}kg',
                                    style: const TextStyle(
                                        color: Color(0xFF00B894),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.grey),
                                ],
                              ),
                              onTap: () => _showOneRepMaxPopover(exercise),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
