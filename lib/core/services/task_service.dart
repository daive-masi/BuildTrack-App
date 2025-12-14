import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/task_model.dart';

class TaskService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 ID de l'utilisateur courant (remplace plus tard par FirebaseAuth)
  String get currentUserId => 'EMPLOYEE_001'; // temporaire pour test

  /// 🔹 Récupère les tâches assignées à un employé
  Stream<List<ProjectTask>> getEmployeeTasks(String employeeId) {
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: employeeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ProjectTask.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  /// 🔹 Injection de tâche test dans Firestore
  Future<void> injectSampleTasks(String userId) async {
    final tasks = [
      ProjectTask(
        id: '',
        title: 'Préparer le terrain',
        description: 'Niveler et nettoyer la zone avant le chantier.',
        projectId: 'chantier_001',
        assignedTo: userId,
        status: TaskStatus.todo,
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 3)),
      ),
      ProjectTask(
        id: '',
        title: 'Installer les fondations',
        description: 'Coulage du béton et vérification de la stabilité.',
        projectId: 'chantier_001',
        assignedTo: userId,
        status: TaskStatus.inProgress,
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 5)),
      ),
    ];

    for (final t in tasks) {
      await _firestore.collection('tasks').add(t.toFirestore());
    }
    print('✅ Tâches injectées pour $userId.');
  }


  /// 🔹 Mise à jour du statut
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': describeEnum(newStatus),
      'updatedAt': Timestamp.now(),
    });
    print('🔄 Statut de la tâche $taskId mis à jour vers ${describeEnum(newStatus)}');
  }

  Future<void> addTaskProof({
    required String taskId,
    required List<String> imageUrls,
  }) async {
    try {
      final taskRef = _firestore.collection('tasks').doc(taskId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(taskRef);
        if (!snapshot.exists) {
          throw Exception("Tâche introuvable");
        }

        final data = snapshot.data()!;
        final existingProofs = List<String>.from(data['proofImages'] ?? []);

        final updatedProofs = [...existingProofs, ...imageUrls];

        transaction.update(taskRef, {
          'proofImages': updatedProofs,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Erreur lors de l’ajout des preuves à la tâche : $e');
      rethrow;
    }
  }

}
