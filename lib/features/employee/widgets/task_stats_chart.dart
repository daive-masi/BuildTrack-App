import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../models/task_model.dart';

class TaskStatsChart extends StatelessWidget {
  final List<ProjectTask> tasks;

  const TaskStatsChart({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final statusCount = {
      TaskStatus.pending: 0,
      TaskStatus.inProgress: 0,
      TaskStatus.completed: 0,
      TaskStatus.blocked: 0,
    };

    for (final t in tasks) {
      statusCount[t.status] = (statusCount[t.status] ?? 0) + 1;
    }

    final total = tasks.length.toDouble();

    if (total == 0) {
      return const Center(
        child: Text("Aucune tâche pour l’instant."),
      );
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: statusCount.entries.map((entry) {
            final status = entry.key;
            final value = entry.value.toDouble();
            final percent = (value / total) * 100;
            return PieChartSectionData(
              color: status.statusColor,
              value: value,
              title: "${percent.toStringAsFixed(1)}%",
              radius: 70,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
