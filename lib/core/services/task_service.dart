import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/task_model.dart';

class TaskService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer les tâches par projet
  Stream<List<ProjectTask>> getProjectTasks(String projectId) {
    return _firestore
        .collection('tasks')
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ProjectTask.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // Récupérer une tâche (Live)
  Stream<ProjectTask> getTaskStream(String taskId) {
    return _firestore.collection('tasks').doc(taskId).snapshots().map((doc) {
      if (!doc.exists) throw Exception("Tâche introuvable");
      return ProjectTask.fromFirestore(doc.data()!, doc.id);
    });
  }

  // Récupérer les tâches assignées à un employé (Global)
  Stream<List<ProjectTask>> getEmployeeTasks(String employeeId) {
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: employeeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ProjectTask.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // Créer une tâche
  Future<void> createTask(ProjectTask task) async {
    await _firestore.collection('tasks').add(task.toFirestore());
  }

  // --- LOGIQUE CHRONOMÈTRE ---

  // 1. Démarrer
  Future<void> startTaskWork(String taskId, String workerId) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': TaskStatus.inProgress.name,
      'currentWorkerId': workerId,
      'lastWorkStartTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. Pause
  Future<void> pauseTaskWork(String taskId) async {
    final docRef = _firestore.collection('tasks').doc(taskId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Tâche non trouvée");
      final task = ProjectTask.fromFirestore(snapshot.data()!, snapshot.id);

      if (task.lastWorkStartTime == null) return;

      // Calcul temps session (en minutes)
      // Note: Pour plus de précision, on pourrait stocker en secondes ou millisecondes, mais minutes suffit souvent.
      // Firestore Timestamp -> DateTime conversion locale pour diff
      final startTime = task.lastWorkStartTime!;
      final now = DateTime.now();
      final sessionMinutes = now.difference(startTime).inMinutes;

      transaction.update(docRef, {
        'currentWorkerId': null,
        'lastWorkStartTime': null,
        'totalTimeSpentMinutes': task.totalTimeSpentMinutes + sessionMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // 3. Finir
  Future<void> finishTaskWork(String taskId, String finalComment) async {
    await pauseTaskWork(taskId); // Arrête le chrono d'abord

    final finishLog = TaskLog(
      userName: 'Système',
      comment: "Tâche terminée : $finalComment",
      date: DateTime.now(),
    );

    await _firestore.collection('tasks').doc(taskId).update({
      'status': TaskStatus.pending.name, // En attente de validation
      'history': FieldValue.arrayUnion([finishLog.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- UTILITAIRES ---
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': describeEnum(newStatus),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addTaskLog(String taskId, TaskLog log) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'history': FieldValue.arrayUnion([log.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> injectSampleTasks(String userId) async {
    // Vide pour éviter les erreurs, plus nécessaire avec la vraie logique
  }
}