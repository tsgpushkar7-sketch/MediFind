import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  List<dynamic> peakHours = [];
  List<dynamic> demandTrend = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
    });

    final peakResult = await ApiService.getPeakHours();
    final trendResult = await ApiService.getDemandTrend();

    setState(() {
      if (peakResult['success']) peakHours = peakResult['data'];
      if (trendResult['success']) demandTrend = trendResult['data'];
      isLoading = false;
    });
  }

  double getMaxPeakCount() {
    if (peakHours.isEmpty) return 10;
    return peakHours
        .map((e) => (e['count'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Peak Request Hours',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'When customers request items most, across all hours of the day',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: peakHours.isEmpty
                ? const Center(child: Text('No data yet'))
                : BarChart(
                    BarChartData(
                      maxY: getMaxPeakCount() + 5,
                      barGroups: peakHours.map((entry) {
                        final hour = entry['_id'] as int;
                        final count = (entry['count'] as num).toDouble();
                        return BarChartGroupData(
                          x: hour,
                          barRods: [
                            BarChartRodData(
                              toY: count,
                              color: Colors.teal,
                              width: 6,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 3,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}h',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                    ),
                  ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Top Requested Items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Most in-demand items overall',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          demandTrend.isEmpty
              ? const Center(child: Text('No data yet'))
              : Column(
                  children: demandTrend.take(8).map((entry) {
                    final maxCount = (demandTrend.first['count'] as num).toDouble();
                    final count = (entry['count'] as num).toDouble();
                    final barWidthFraction = count / maxCount;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry['_id'], style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('${entry['count']}', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: barWidthFraction,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}