import 'package:flutter/material.dart';
import '../../../models/project_model.dart';
import '../screens/project_tasks_screen.dart';

class ProjectCard extends StatelessWidget {
  final Project project;

  const ProjectCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectTasksScreen(project: project)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                project.imageUrl,
                height: 150, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (c,e,s) => Container(height: 150, color: Colors.grey[300]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  const SizedBox(height: 8),
                  Row(children: [Icon(Icons.location_on, size: 14, color: Colors.grey[600]), const SizedBox(width: 6), Expanded(child: Text(project.address, style: TextStyle(fontSize: 12, color: Colors.grey[600])))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}