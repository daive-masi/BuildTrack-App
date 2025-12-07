import 'package:flutter/material.dart';
import '../../../models/task_model.dart';
import '../screens/task_detail_screen.dart';

class TaskCard extends StatelessWidget {
  final ProjectTask task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    // Couleur de fond et texte basées sur le statut
    final backgroundColor = task.status.backgroundColor;
    final textColor = task.status.textColor;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de la tâche
            Text(
              task.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),

            // Ligne 1 : Heure + Personnel + Statut
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: textColor.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(
                    task.formattedDueDate,
                    style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.6))
                ),
                const SizedBox(width: 16),
                Icon(Icons.person_outline, size: 18, color: textColor.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(
                    "1/2",
                    style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.6))
                ),
                const Spacer(),
                // Label Statut à droite
                Text(
                  task.status.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Ligne 2 : Adresse
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 16, color: textColor.withOpacity(0.6)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.address,
                    style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.6)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
