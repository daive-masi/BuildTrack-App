import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/task_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../models/project_model.dart';
import '../../../models/task_model.dart';
import '../widgets/task_card.dart';

class ProjectTasksScreen extends StatelessWidget {
  final Project project;

  const ProjectTasksScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TaskService>(context);
    final employeeId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // En-tête résumé du chantier
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(project.address, style: const TextStyle(color: Colors.grey))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(project.description, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),

          // Liste des tâches
          Expanded(
            child: StreamBuilder<List<ProjectTask>>(
              // On récupère toutes les tâches de l'employé
              stream: taskService.getEmployeeTasks(employeeId ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // On filtre pour ne garder que celles du chantier actuel
                // (Assure-toi que tes tâches ont bien un projectId correspondant, par exemple 'chantier_001')
                final tasks = (snapshot.data ?? []).where((t) => t.projectId == project.id).toList();

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text("Aucune tâche sur ce chantier", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text("(ID Projet: ${project.id})", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return TaskCard(task: tasks[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}