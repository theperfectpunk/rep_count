import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF11111B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11111B),
        elevation: 0,
        title: const Text('Analytics & Records',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Consistency Heatmap Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WORKOUT CONSISTENCY HEATMAP',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1)),
                  const SizedBox(height: 12),

                  // GitHub Style Heatmap Grid
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(28, (index) {
                      final hasWorkout = index % 3 == 0 || index % 7 == 1;
                      return Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: hasWorkout
                              ? const Color(0xFF6C5CE7)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Estimated 1RM Trend Line Chart
            Container(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ESTIMATED 1RM PROGRESSION',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1)),
                          const SizedBox(height: 4),
                          const Text('Barbell Bench Press',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Text('125 kg (PR)',
                          style: TextStyle(
                              color: Color(0xFF00B894),
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 100),
                              FlSpot(1, 105),
                              FlSpot(2, 110),
                              FlSpot(3, 115),
                              FlSpot(4, 120),
                              FlSpot(5, 125),
                            ],
                            isCurved: true,
                            color: const Color(0xFF6C5CE7),
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF6C5CE7).withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Personal Record Trophy Badges
            Text('Personal Records (PR Badges)',
                style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildBadge('100kg Bench Press', 'Unlocked 3 days ago'),
                const SizedBox(width: 12),
                _buildBadge('150kg Squat', 'Unlocked 1 week ago'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.amber,
              radius: 20,
              child: Icon(Icons.emoji_events, color: Colors.black, size: 24),
            ),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
