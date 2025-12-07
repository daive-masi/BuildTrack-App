// lib/features/employee/widgets/task_stats_widgets.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/task_model.dart';

// --- PIE CHART (CAMEMBERT) ---
class TaskPieChart extends StatelessWidget {
  final List<ProjectTask> tasks;
  const TaskPieChart({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    int pending = 0, inProgress = 0, completed = 0;
    for (var t in tasks) {
      if (t.status == TaskStatus.pending) pending++;
      else if (t.status == TaskStatus.completed) completed++;
      else inProgress++;
    }

    if (tasks.isEmpty) return const SizedBox();

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
                color: const Color(0xFFFFF3E0), // Orange Pastel
                value: pending.toDouble(),
                title: '$pending',
                radius: 50,
                titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)
            ),
            PieChartSectionData(
                color: const Color(0xFFCFD8DC), // Gris/Bleu Pastel
                value: inProgress.toDouble(),
                title: '$inProgress',
                radius: 60,
                titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)
            ),
            PieChartSectionData(
                color: const Color(0xFFE8F5E9), // Vert Pastel
                value: completed.toDouble(),
                title: '$completed',
                radius: 50,
                titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)
            ),
          ],
        ),
      ),
    );
  }
}

// --- BAR CHART (BÂTONS) ---
class TaskBarChart extends StatelessWidget {
  final List<ProjectTask> tasks;
  const TaskBarChart({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    int pending = 0, inProgress = 0, completed = 0;
    for (var t in tasks) {
      if (t.status == TaskStatus.pending) pending++;
      else if (t.status == TaskStatus.completed) completed++;
      else inProgress++;
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (tasks.length + 1).toDouble(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0: return const Text('Valid.', style: TextStyle(fontSize: 10));
                    case 1: return const Text('Cours', style: TextStyle(fontSize: 10));
                    case 2: return const Text('Fini', style: TextStyle(fontSize: 10));
                    default: return const Text('');
                  }
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            _makeGroupData(0, pending.toDouble(), Colors.orange),
            _makeGroupData(1, inProgress.toDouble(), Colors.blueGrey),
            _makeGroupData(2, completed.toDouble(), Colors.green),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 10, color: Colors.grey[100]),
        ),
      ],
    );
  }
}