import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StressAnalysisPage extends StatefulWidget {
  @override
  _StressAnalysisPageState createState() => _StressAnalysisPageState();
}

class _StressAnalysisPageState extends State<StressAnalysisPage> {
  final List<double> weeklyStressLevels = [45, 70, 55, 80, 65, 40, 30];
  final List<String> stressCategories = [
    'Low',
    'Moderate',
    'High',
    'Very High'
  ];

  String _getStressInsight() {
    double averageStress =
        weeklyStressLevels.reduce((a, b) => a + b) / weeklyStressLevels.length;
    if (averageStress < 30) return 'Your stress levels are consistently low.';
    if (averageStress < 50) return 'You have mild stress levels.';
    if (averageStress < 70) return 'Your stress levels are moderately high.';
    return 'Your stress levels are concerning and need attention.';
  }

  List<String> _getStressRecommendations() {
    return [
      'Practice deep breathing exercises',
      'Ensure 7-8 hours of sleep',
      'Engage in regular physical activity',
      'Consider meditation or mindfulness techniques',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stress Analysis'),
        backgroundColor: const Color(0xFF005B5A), // Deep green
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekly Stress Line Chart
              Card(
                elevation: 4,
                color: const Color(0xFFE0F7EF), // Light green
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Weekly Stress Levels',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF005B5A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 250,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) => Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                          color: const Color(0xFF004B4A))),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final days = [
                                      'Mon',
                                      'Tue',
                                      'Wed',
                                      'Thu',
                                      'Fri',
                                      'Sat',
                                      'Sun'
                                    ];
                                    return Text(
                                      days[value.toInt()],
                                      style: TextStyle(
                                          color: const Color(0xFF004B4A)),
                                    );
                                  },
                                ),
                              ),
                            ),
                            minX: 0,
                            maxX: 6,
                            minY: 0,
                            maxY: 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                    weeklyStressLevels.length,
                                    (index) => FlSpot(index.toDouble(),
                                        weeklyStressLevels[index])),
                                isCurved: true,
                                color: const Color(0xFF388E3C), // Algae green
                                barWidth: 4,
                                dotData: FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Stress Insights Card
              Card(
                elevation: 4,
                color: const Color(0xFFB3E9D8), // Pale green
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stress Insights',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF005B5A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _getStressInsight(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Stress Reduction Recommendations
              Card(
                elevation: 4,
                color: const Color(0xFFE0F7EF), // Light green
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stress Reduction Recommendations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF005B5A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _getStressRecommendations()
                            .map((rec) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Color(0xFF2E7D32)),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(rec)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Detailed Analysis Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Future: Navigate to even more detailed analysis
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005B5A),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Generate report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
