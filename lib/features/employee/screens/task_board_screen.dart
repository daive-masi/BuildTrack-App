import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/task_model.dart';
import '../../../core/services/task_service.dart';
import '../../../core/services/auth_service.dart';

class TaskBoardScreen extends StatefulWidget {
  const TaskBoardScreen({super.key});

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen> {
  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TaskService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("Utilisateur non connecté.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau des tâches')),
      body: StreamBuilder<List<ProjectTask>>(
        stream: taskService.getEmployeeTasks(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data ?? [];

          // Groupement des tâches par statut
          final grouped = {
            for (var status in TaskStatus.values)
              status: tasks.where((t) => t.status == status).toList()
          };

          // Construction de la vue avec DragAndDropLists
          return DragAndDropLists(
            children: grouped.entries.map((entry) {
              return DragAndDropList(
                header: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    entry.key.label,
                    style: TextStyle(
                      color: entry.key.statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                children: entry.value.map((t) {
                  return DragAndDropItem(
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          t.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          t.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          t.status.statusIcon,
                          color: t.status.statusColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),

            onItemReorder: (oldItemIndex, oldListIndex, newItemIndex, newListIndex) async {
              final newStatus = TaskStatus.values[newListIndex];
              final movedTask = grouped.values.elementAt(oldListIndex)[oldItemIndex];

              await taskService.updateTaskStatus(movedTask.id, newStatus);
            },

            onListReorder: (oldListIndex, newListIndex) {
              setState(() {
                // Permet juste de reconstruire le widget sans crash
              });
            },
          );
        },
      ),
    );
  }
}
