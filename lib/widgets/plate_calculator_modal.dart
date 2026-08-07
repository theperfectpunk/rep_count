import 'package:flutter/material.dart';

class PlateCalculatorModal extends StatefulWidget {
  final double targetWeightKg;

  const PlateCalculatorModal({Key? key, required this.targetWeightKg})
      : super(key: key);

  @override
  State<PlateCalculatorModal> createState() => _PlateCalculatorModalState();
}

class _PlateCalculatorModalState extends State<PlateCalculatorModal> {
  late double _weight;
  double _barWeight = 20.0; // Standard Olympic Barbell

  @override
  void initState() {
    super.initState() ;
    _weight = widget.targetWeightKg > _barWeight ? widget.targetWeightKg : 60.0;
  }

  Map<double, int> _calculatePlatesPerSide() {
    double weightPerSide = (_weight - _barWeight) / 2.0;
    if (weightPerSide <= 0) return {};

    final availablePlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];
    final Map<double, int> plateCounts = {};

    for (final plate in availablePlates) {
      if (weightPerSide >= plate) {
        int count = (weightPerSide / plate).floor();
        plateCounts[plate] = count;
        weightPerSide -= count * plate;
      }
    }
    return plateCounts;
  }

  Color _getPlateColor(double weight) {
    if (weight >= 25.0) return Colors.redAccent;
    if (weight >= 20.0) return Colors.blueAccent;
    if (weight >= 15.0) return Colors.yellow.shade700;
    if (weight >= 10.0) return Colors.greenAccent;
    if (weight >= 5.0) return Colors.white;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final platesPerSide = _calculatePlatesPerSide();

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'PLATE CALCULATOR',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_weight.toStringAsFixed(1)} kg',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '(${_barWeight.toStringAsFixed(0)}kg Olympic Bar + Plates)',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Visual Barbell Representation
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF11111B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Bar Left Sleeve
                Container(width: 20, height: 6, color: Colors.grey.shade400),
                // Plates on left side
                ...platesPerSide.entries.expand((entry) {
                  return List.generate(entry.value, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 10 + (entry.key * 0.4),
                      height: 45 + (entry.key * 1.2),
                      decoration: BoxDecoration(
                        color: _getPlateColor(entry.key),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  });
                }),
                // Main Barbell Shaft
                Container(width: 80, height: 10, color: Colors.grey.shade300),
                // Plates on right side
                ...platesPerSide.entries.expand((entry) {
                  return List.generate(entry.value, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 10 + (entry.key * 0.4),
                      height: 45 + (entry.key * 1.2),
                      decoration: BoxDecoration(
                        color: _getPlateColor(entry.key),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  });
                }),
                // Bar Right Sleeve
                Container(width: 20, height: 6, color: Colors.grey.shade400),
              ],
            ),
          ),

          const SizedBox(height: 20),
          // Breakdown Table
          Text(
            'Plates per Side:',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: platesPerSide.isEmpty
                ? [
                    Text('Just the empty bar!',
                        style: TextStyle(color: Colors.grey.shade500))
                  ]
                : platesPerSide.entries.map((entry) {
                    return Chip(
                      backgroundColor: const Color(0xFF2E2E3E),
                      avatar: CircleAvatar(
                        backgroundColor: _getPlateColor(entry.key),
                        radius: 8,
                      ),
                      label: Text(
                        '${entry.value}x ${entry.key}kg',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
