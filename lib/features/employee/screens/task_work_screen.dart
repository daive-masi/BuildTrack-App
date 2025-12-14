import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/task_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../models/task_model.dart';

class TaskWorkScreen extends StatefulWidget {
  final String taskId;
  final bool isCheckedInOnSite; // On le passe pour bloquer l'action si pas pointé

  const TaskWorkScreen({
    super.key,
    required this.taskId,
    required this.isCheckedInOnSite,
  });

  @override
  State<TaskWorkScreen> createState() => _TaskWorkScreenState();
}

class _TaskWorkScreenState extends State<TaskWorkScreen> {
  Timer? _uiTimer;
  String _displayTime = "00:00:00";

  @override
  void initState() {
    super.initState();
    // Met à jour l'affichage chaque seconde
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  // Calcul du temps à afficher
  String _calculateDisplayTime(ProjectTask task) {
    int totalSeconds = task.totalTimeSpentMinutes * 60;

    if (task.isTimerRunning && task.lastWorkStartTime != null) {
      final currentSessionSeconds = DateTime.now().difference(task.lastWorkStartTime!).inSeconds;
      totalSeconds += currentSessionSeconds;
    }

    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    return "$hours:$minutes:$seconds";
  }

  Future<void> _handleAction(ProjectTask task, String action, String userId) async {
    if (!widget.isCheckedInOnSite) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Action impossible : Vous devez scanner le QR Code du chantier."), backgroundColor: Colors.red)
      );
      return;
    }

    final taskService = context.read<TaskService>();
    try {
      switch (action) {
        case 'start':
          if (task.currentWorkerId != null && task.currentWorkerId != userId) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quelqu'un d'autre travaille déjà dessus."), backgroundColor: Colors.orange));
            return;
          }
          await taskService.startTaskWork(task.id, userId);
          break;
        case 'pause':
          await taskService.pauseTaskWork(task.id);
          break;
        case 'finish':
          _showFinishDialog(task.id);
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
    }
  }

  void _showFinishDialog(String taskId) {
    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Terminer la tâche ?"),
        content: TextField(
          controller: commentCtrl,
          decoration: const InputDecoration(labelText: "Commentaire final", border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<TaskService>().finishTaskWork(taskId, commentCtrl.text);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TaskService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    final primaryColor = Theme.of(context).primaryColor;

    if (userId == null) return const Scaffold(body: Center(child: Text("Erreur utilisateur")));

    return StreamBuilder<ProjectTask>(
      stream: taskService.getTaskStream(widget.taskId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (snapshot.hasError || !snapshot.hasData) return const Scaffold(body: Center(child: Text("Erreur tâche")));

        final task = snapshot.data!;
        _displayTime = _calculateDisplayTime(task);
        final isWorkingByMe = task.isTimerRunning && task.currentWorkerId == userId;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          appBar: AppBar(title: const Text("Travail en cours"), backgroundColor: Colors.transparent, foregroundColor: primaryColor, elevation: 0),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Info Tâche
                Text(task.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(task.description, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 40),

                // Chronomètre
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
                  child: Column(
                    children: [
                      Icon(Icons.timer, size: 40, color: isWorkingByMe ? Colors.green : Colors.grey),
                      const SizedBox(height: 10),
                      Text(_displayTime, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      if (isWorkingByMe) const Text("EN COURS", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                    ],
                  ),
                ),

                const Spacer(),

                // Boutons
                if (task.status == TaskStatus.completed || task.status == TaskStatus.pending)
                  Text("Tâche terminée ou en validation", style: TextStyle(fontSize: 18, color: primaryColor, fontWeight: FontWeight.bold))
                else if (!isWorkingByMe)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("DÉMARRER"),
                      onPressed: () => _handleAction(task, 'start', userId),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.pause),
                          label: const Text("PAUSE"),
                          onPressed: () => _handleAction(task, 'pause', userId),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.stop),
                          label: const Text("FINIR"),
                          onPressed: () => _handleAction(task, 'finish', userId),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        ),
                      ),
                    ],
                  )
              ],
            ),
          ),
        );
      },
    );
  }
}