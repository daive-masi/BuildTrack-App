// features/employee/screens/task_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/services/task_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../models/task_model.dart';

class TaskDetailScreen extends StatefulWidget {
  final ProjectTask task;

  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isUploading = false;

  Future<void> _uploadProofImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;

    final storageService = Provider.of<StorageService>(context, listen: false);
    final taskService = Provider.of<TaskService>(context, listen: false);
    final file = File(pickedFile.path);

    setState(() => _isUploading = true);
    try {
      final url = await storageService.uploadTaskImage(file, widget.task.id, 'proof.jpg');
      await taskService.addTaskProof(widget.task.id, url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo ajoutée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur upload: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Scaffold(
      appBar: AppBar(title: Text(task.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description ?? 'Aucune description', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Statut : ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(task.status.label),
                  backgroundColor: task.status.statusColor.withOpacity(0.2),
                ),
                const Spacer(),
                PopupMenuButton<TaskStatus>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (newStatus) async {
                    await Provider.of<TaskService>(context, listen: false)
                        .updateTaskStatus(task.id, newStatus);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Statut mis à jour : ${newStatus.label}')),
                    );
                  },
                  itemBuilder: (_) => TaskStatus.values
                      .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text('Preuves photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: task.proofImages.isEmpty
                  ? const Center(child: Text('Aucune preuve ajoutée'))
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: task.proofImages.length,
                itemBuilder: (context, index) {
                  final imgUrl = task.proofImages[index];
                  return GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: Image.network(imgUrl, fit: BoxFit.cover),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(imgUrl, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (_isUploading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: () => _uploadProofImage(context),
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Ajouter une photo'),
              ),
          ],
        ),
      ),
    );
  }
}
