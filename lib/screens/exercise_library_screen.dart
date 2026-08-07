import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/exercise_repository.dart';
import '../models/exercise.dart';

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
  String _selectedMuscle = 'All';
  String _selectedEquipment = 'All';

  final List<String> _muscleFilters = [
    'All',
    'Chest',
    'Back',
    'Quads',
    'Hamstrings',
    'Shoulders',
    'Biceps',
    'Triceps'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    // 300ms structural debouncer to prevent UI thread stuttering
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
      });
    });
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
    final filteredExercises = _repo.searchExercises(
      _searchQuery,
      muscle: _selectedMuscle,
      equipment: _selectedEquipment,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF11111B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11111B),
        elevation: 0,
        title: const Text('Exercise Library',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Debounced Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search 100+ exercises (e.g. Bench Press)...',
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

          // Muscle Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: _muscleFilters.map((muscle) {
                final isSelected = _selectedMuscle == muscle;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(muscle),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMuscle = muscle;
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

          const SizedBox(height: 8),

          // Exercise List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = filteredExercises[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                      child: const Icon(Icons.fitness_center,
                          color: Color(0xFF6C5CE7), size: 20),
                    ),
                    title: Text(exercise.name,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${exercise.primaryMuscle} • ${exercise.equipment}',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
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
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: () => _showOneRepMaxPopover(exercise),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
