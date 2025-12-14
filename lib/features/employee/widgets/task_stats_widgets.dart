// lib/features/employee/widgets/task_stats_widgets.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/task_model.dart';

// --- CARTE DE STATISTIQUE SIMPLE (KPI) ---
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtext;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B2545), // Bleu Nuit
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (subtext != null) ...[
              const SizedBox(height: 4),
              Text(
                subtext!,
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// --- PIE CHART (ANNEAU MODERNE) ---
class TaskPieChart extends StatelessWidget {
  final List<ProjectTask> tasks;
  const TaskPieChart({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    int pending = 0, inProgress = 0, completed = 0;
    for (var t in tasks) {
      if (t.status == TaskStatus.pending || t.status == TaskStatus.todo) pending++;
      else if (t.status == TaskStatus.completed) completed++;
      else inProgress++; // En cours + Bloqué
    }

    if (tasks.isEmpty) {
      return const SizedBox(
          height: 200,
          child: Center(child: Text("Aucune donnée"))
      );
    }

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 5,
              centerSpaceRadius: 50, // Donne l'effet "Donut"
              startDegreeOffset: -90,
              sections: [
                _buildSection(pending, const Color(0xFFFFF3E0), Colors.orange), // À faire
                _buildSection(inProgress, const Color(0xFFE3F2FD), Colors.blue), // En cours
                _buildSection(completed, const Color(0xFFE8F5E9), Colors.green), // Fini
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${tasks.length}",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0B2545)),
              ),
              const Text("Tâches", style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  PieChartSectionData _buildSection(int value, Color color, Color titleColor) {
    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      title: value > 0 ? '$value' : '',
      radius: 25,
      titleStyle: TextStyle(fontWeight: FontWeight.bold, color: titleColor, fontSize: 14),
      badgeWidget: value > 0 ? _Badge(color: titleColor, size: 8) : null,
      badgePositionPercentageOffset: 1.4,
    );
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final double size;
  const _Badge({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)]),
    );
  }
}

// --- OBJECTIF HEBDOMADAIRE (NOUVEAU) ---
class WeeklyGoalCard extends StatelessWidget {
  final double progress; // entre 0.0 et 1.0
  final String label;

  const WeeklyGoalCard({super.key, required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2545), Color(0xFF1E3A5F)], // Dégradé Bleu Nuit
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0B2545).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Objectif Hebdo", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Text("${(progress * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}