import 'package:flutter/material.dart';
import '../../../models/task_model.dart';
import '../screens/task_work_screen.dart';

class TaskCard extends StatelessWidget {
  final ProjectTask task;
  final bool isCheckedInOnSite;

  const TaskCard({
    super.key,
    required this.task,
    required this.isCheckedInOnSite
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Redirige vers le NOUVEL écran de travail (Chrono)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskWorkScreen(
              taskId: task.id,
              isCheckedInOnSite: isCheckedInOnSite
          )),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: task.status.backgroundColor, borderRadius: BorderRadius.circular(8)),
                  child: Text(task.status.label, style: TextStyle(color: task.status.textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}