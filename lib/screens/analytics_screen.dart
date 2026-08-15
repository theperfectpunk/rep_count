import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // Task 1: Dropdown state
  String _selectedExercise = 'Barbell Bench Press';

  // Task 2: Time filter state
  String _selectedTimeRange = '3M';

  // Task 1: Exercise dropdown options
  final List<String> _exercises = const [
    'Barbell Bench Press',
    'Barbell Back Squat',
    'Conventional Deadlift',
    'Overhead Press',
  ];

  // Task 2: Time range options
  final List<String> _timeRanges = const ['1M', '3M', '6M', '1Y', 'All Time'];

  // Task 1 Data: Sample 1RM data per exercise
  final Map<String, Map<String, dynamic>> _exerciseDataMap = const {
    'Barbell Bench Press': {
      'pr': '125 kg',
      'spots': [
        FlSpot(0, 100),
        FlSpot(1, 105),
        FlSpot(2, 110),
        FlSpot(3, 115),
        FlSpot(4, 120),
        FlSpot(5, 125),
      ],
      'minY': 90.0,
      'maxY': 135.0,
      'xLabels': ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'],
    },
    'Barbell Back Squat': {
      'pr': '160 kg',
      'spots': [
        FlSpot(0, 130),
        FlSpot(1, 135),
        FlSpot(2, 142.5),
        FlSpot(3, 148),
        FlSpot(4, 155),
        FlSpot(5, 160),
      ],
      'minY': 120.0,
      'maxY': 170.0,
      'xLabels': ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'],
    },
    'Conventional Deadlift': {
      'pr': '200 kg',
      'spots': [
        FlSpot(0, 160),
        FlSpot(1, 170),
        FlSpot(2, 175),
        FlSpot(3, 185),
        FlSpot(4, 192.5),
        FlSpot(5, 200),
      ],
      'minY': 150.0,
      'maxY': 210.0,
      'xLabels': ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'],
    },
    'Overhead Press': {
      'pr': '80 kg',
      'spots': [
        FlSpot(0, 62.5),
        FlSpot(1, 65),
        FlSpot(2, 70),
        FlSpot(3, 72.5),
        FlSpot(4, 77.5),
        FlSpot(5, 80),
      ],
      'minY': 55.0,
      'maxY': 90.0,
      'xLabels': ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'],
    },
  };

  // Task 3: Weekly Set Volume per Muscle Group
  final List<Map<String, dynamic>> _muscleGroupVolumes = const [
    {
      'name': 'Chest',
      'sets': 16,
      'color': Color(0xFFFF7675),
      'status': 'Optimal',
    },
    {
      'name': 'Back',
      'sets': 18,
      'color': Color(0xFF74B9FF),
      'status': 'Optimal',
    },
    {
      'name': 'Shoulders',
      'sets': 12,
      'color': Color(0xFFA29BFE),
      'status': 'Optimal',
    },
    {
      'name': 'Legs',
      'sets': 15,
      'color': Color(0xFF55E6C1),
      'status': 'Optimal',
    },
    {
      'name': 'Arms',
      'sets': 8,
      'color': Color(0xFFFDCB6E),
      'status': 'Below Target',
    },
    {
      'name': 'Core',
      'sets': 10,
      'color': Color(0xFFE84393),
      'status': 'Optimal',
    },
  ];

  // Task 4: Heatmap workout activity intensity (0=none, 1=light, 2=moderate, 3=high)
  final List<int> _heatmapIntensities = const [
    0, 3, 2, 0, 3, 1, 0,
    2, 3, 0, 3, 3, 0, 1,
    3, 0, 2, 3, 0, 3, 0,
    0, 3, 3, 0, 2, 3, 1,
  ];

  // Task 5: PR History Log
  final List<Map<String, String>> _prHistory = const [
    {
      'exercise': 'Barbell Bench Press',
      'weight': '125 kg',
      'date': '3 days ago',
      'detail': 'Estimated 1RM PR (+5 kg)',
    },
    {
      'exercise': 'Barbell Back Squat',
      'weight': '160 kg',
      'date': '1 week ago',
      'detail': '5 Rep Max PR',
    },
    {
      'exercise': 'Conventional Deadlift',
      'weight': '200 kg',
      'date': '2 weeks ago',
      'detail': '200kg Milestone Reached',
    },
    {
      'exercise': 'Overhead Press',
      'weight': '80 kg',
      'date': '3 weeks ago',
      'detail': 'New 1RM Record (+2.5 kg)',
    },
    {
      'exercise': 'Incline Dumbbell Press',
      'weight': '42 kg x 8',
      'date': '1 month ago',
      'detail': 'Volume PR',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF11111B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11111B),
        elevation: 0,
        title: const Text(
          'Analytics & Records',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task 4: Consistency Heatmap Card
            _buildConsistencyHeatmapCard(),
            const SizedBox(height: 24),

            // Task 1 & Task 2: 1RM Trend Card with Dropdown & Time Filters
            _build1RMTrendCard(),
            const SizedBox(height: 24),

            // Task 3: Muscle Group Volume Chart
            _buildMuscleGroupVolumeCard(),
            const SizedBox(height: 24),

            // Task 5: PR History List
            _buildPRHistorySection(),
          ],
        ),
      ),
    );
  }

  // --- Task 4 Widget: Consistency Heatmap ---
  Widget _buildConsistencyHeatmapCard() {
    return Container(
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
              Text(
                'WORKOUT CONSISTENCY HEATMAP',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00B894).withOpacity(0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Color(0xFF00B894),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '4 Wk Streak',
                      style: TextStyle(
                        color: Color(0xFF00B894),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Days of the week headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (day) => SizedBox(
                    width: 24,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),

          // GitHub style heat grid (4 weeks x 7 days = 28 squares)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(28, (index) {
              final intensity = _heatmapIntensities[index];
              Color color;
              switch (intensity) {
                case 1:
                  color = const Color(0xFF00B894).withOpacity(0.35);
                  break;
                case 2:
                  color = const Color(0xFF00B894).withOpacity(0.65);
                  break;
                case 3:
                  color = const Color(0xFF00B894);
                  break;
                case 0:
                default:
                  color = Colors.white.withOpacity(0.06);
                  break;
              }

              return Tooltip(
                message: intensity == 0
                    ? 'Day ${index + 1}: Rest Day'
                    : 'Day ${index + 1}: $intensity Workout Session(s)',
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: intensity > 0
                          ? const Color(0xFF00B894).withOpacity(0.3)
                          : Colors.transparent,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Heatmap Intensity Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              ),
              const SizedBox(width: 6),
              _buildLegendSquare(Colors.white.withOpacity(0.06)),
              _buildLegendSquare(const Color(0xFF00B894).withOpacity(0.35)),
              _buildLegendSquare(const Color(0xFF00B894).withOpacity(0.65)),
              _buildLegendSquare(const Color(0xFF00B894)),
              const SizedBox(width: 6),
              Text(
                'More',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendSquare(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // --- Task 1 & 2 Widget: 1RM Progression & Exercise Dropdown & Filters ---
  Widget _build1RMTrendCard() {
    final currentData =
        _exerciseDataMap[_selectedExercise] ?? _exerciseDataMap['Barbell Bench Press']!;
    final String prText = currentData['pr'] as String;
    final List<FlSpot> spots = currentData['spots'] as List<FlSpot>;
    final double minY = currentData['minY'] as double;
    final double maxY = currentData['maxY'] as double;
    final List<String> xLabels = currentData['xLabels'] as List<String>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ESTIMATED 1RM PROGRESSION',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),

          // Task 1: Exercise Selector Dropdown Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11111B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedExercise,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E1E2E),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF6C5CE7),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedExercise = newValue;
                          });
                        }
                      },
                      items: _exercises.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00B894).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Color(0xFF00B894),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$prText (PR)',
                      style: const TextStyle(
                        color: Color(0xFF00B894),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Task 2: Time Range Filter Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _timeRanges.map((range) {
              final isSelected = _selectedTimeRange == range;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTimeRange = range;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6C5CE7)
                        : const Color(0xFF11111B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6C5CE7)
                          : Colors.white.withOpacity(0.08),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF6C5CE7).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    range,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Line Chart
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.04),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final int index = value.toInt();
                        if (index >= 0 && index < xLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              xLabels[index],
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => const Color(0xFF11111B),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y} kg',
                          const TextStyle(
                            color: Color(0xFF00B894),
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF6C5CE7),
                    barWidth: 3.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFF6C5CE7),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF6C5CE7).withOpacity(0.18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Task 3 Widget: Muscle Group Volume Chart ---
  Widget _buildMuscleGroupVolumeCard() {
    const double maxSets = 25.0;
    const double minTarget = 10.0;
    const double maxTarget = 20.0;

    return Container(
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
              Text(
                'WEEKLY SET VOLUME BY MUSCLE GROUP',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Target: 10-20 Sets',
                  style: TextStyle(
                    color: Color(0xFF00B894),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Muscle bars
          ..._muscleGroupVolumes.map((item) {
            final String name = item['name'] as String;
            final int sets = item['sets'] as int;
            final Color barColor = item['color'] as Color;
            final String status = item['status'] as String;
            final bool isOptimal = sets >= minTarget && sets <= maxTarget;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '$sets sets',
                            style: TextStyle(
                              color: isOptimal
                                  ? const Color(0xFF00B894)
                                  : Colors.amber.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isOptimal
                                  ? const Color(0xFF00B894).withOpacity(0.15)
                                  : Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: isOptimal
                                    ? const Color(0xFF00B894)
                                    : Colors.amber.shade400,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Horizontal Bar with Target Range Indicator Zone
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = constraints.maxWidth;
                      final double targetLeft = width * (minTarget / maxSets);
                      final double targetWidth =
                          width * ((maxTarget - minTarget) / maxSets);
                      final double fillWidth =
                          (width * (sets / maxSets)).clamp(0.0, width);

                      return Stack(
                        children: [
                          // Base track
                          Container(
                            height: 10,
                            width: width,
                            decoration: BoxDecoration(
                              color: const Color(0xFF11111B),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),

                          // Target Range (10-20 sets) Highlight Zone (Green Zone)
                          Positioned(
                            left: targetLeft,
                            width: targetWidth,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B894).withOpacity(0.15),
                                border: Border.symmetric(
                                  vertical: BorderSide(
                                    color: const Color(0xFF00B894).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Filled Progress Bar
                          Container(
                            height: 10,
                            width: fillWidth,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: barColor.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // --- Task 5 Widget: PR History List ---
  Widget _buildPRHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Personal Records (PR Log)',
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_prHistory.length} Unlocked',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Scrollable list of PR Cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _prHistory.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final pr = _prHistory[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Color(0xFFFFD700),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pr['exercise']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pr['detail']!,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        pr['weight']!,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pr['date']!,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
