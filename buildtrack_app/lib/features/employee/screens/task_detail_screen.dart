import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/services/task_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../models/task_model.dart';

class TaskDetailScreen extends StatefulWidget {
  final ProjectTask task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;
  late TaskStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.task.status;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Sélectionner une photo
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  // Soumettre l'intervention
  Future<void> _submitUpdate() async {
    if (_commentController.text.isEmpty && _selectedImage == null && _currentStatus == widget.task.status) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aucune modification à enregistrer")));
      return;
    }

    setState(() => _isUploading = true);
    try {
      final taskService = context.read<TaskService>();
      final storageService = context.read<StorageService>();
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;

      String? photoUrl;

      if (_selectedImage != null) {
        photoUrl = await storageService.uploadTaskImage(
            _selectedImage!,
            widget.task.id,
            'log_${DateTime.now().millisecondsSinceEpoch}.jpg'
        );
      }

      final log = TaskLog(
        userName: currentUser?.displayName ?? 'Moi',
        comment: _commentController.text.isEmpty ? "Mise à jour statut : ${_currentStatus.label}" : _commentController.text,
        photoUrl: photoUrl,
        date: DateTime.now(),
      );

      await taskService.addTaskLog(widget.task.id, log);
      if (_currentStatus != widget.task.status) {
        await taskService.updateTaskStatus(widget.task.id, _currentStatus);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mise à jour enregistrée !")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title),
        backgroundColor: Colors.transparent,
        foregroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- INFO TÂCHE ---
            _buildInfoCard(primaryColor),
            const SizedBox(height: 24),

            // --- CHANGEMENT STATUT ---
            Text("Modifier le Statut", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 10),
            _buildStatusSelector(),
            const SizedBox(height: 24),

            // --- NOUVELLE ENTRÉE ---
            Text("Ajouter un rapport", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 10),
            _buildInputSection(),
            const SizedBox(height: 24),

            // --- HISTORIQUE ---
            Text("Historique du chantier", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 10),
            _buildHistoryList(),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitUpdate,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("ENREGISTRER", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.task.description, style: const TextStyle(fontSize: 16)),
          const Divider(height: 20),
          Row(children: [const Icon(Icons.location_on, size: 16, color: Colors.grey), const SizedBox(width: 8), Expanded(child: Text(widget.task.address))]),
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.calendar_today, size: 16, color: Colors.grey), const SizedBox(width: 8), Text("Échéance: ${widget.task.formattedDueDate}")]),
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskStatus>(
          value: _currentStatus,
          isExpanded: true,
          items: TaskStatus.values.map((s) => DropdownMenuItem(
              value: s,
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: s.backgroundColor, radius: 6),
                  const SizedBox(width: 10),
                  Text(s.label),
                ],
              )
          )).toList(),
          onChanged: (v) => setState(() => _currentStatus = v!),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        TextField(
          controller: _commentController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Ex: J'ai fini le mur nord, il reste les plinthes...",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
            ),
            child: _selectedImage != null
                ? Image.file(_selectedImage!, fit: BoxFit.cover)
                : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.camera_alt, color: Colors.grey), Text("Ajouter une photo preuve")],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    if (widget.task.history.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16), child: Text("Aucun historique pour le moment.", style: TextStyle(color: Colors.grey)));
    }
    final reversedHistory = widget.task.history.reversed.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reversedHistory.length,
      itemBuilder: (context, index) {
        final log = reversedHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(log.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("${log.date.day}/${log.date.month} à ${log.date.hour}h${log.date.minute}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(log.comment),
                if (log.photoUrl != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(log.photoUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}