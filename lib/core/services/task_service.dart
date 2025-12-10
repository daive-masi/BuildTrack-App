import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/task_model.dart';

class TaskService with ChangeNotifier {
  // 1. Change this to be a non-final variable.
  late final FirebaseFirestore _firestore;

  // 2. Add a constructor to initialize _firestore.
  //    If no firestore instance is given, it defaults to the real one.
  TaskService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
  /// 🔹 Crée une nouvelle tâche
  Future<DocumentReference> createTask({
    required String title,
    required String description,
    required String assignedTo,
    required DateTime dueDate,
    String projectId = 'chantier_001',
  }) async {
    final task = ProjectTask(
      id: '', // Firestore will generate it
      title: title,
      description: description,
      projectId: projectId,
      assignedTo: assignedTo,
      status: TaskStatus.todo,
      createdAt: DateTime.now(),
      dueDate: dueDate,
    );
    return await _firestore.collection('tasks').add(task.toFirestore());
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
    debugPrint('✅ Tâches injectées pour $userId.');
  }


  /// 🔹 Mise à jour du statut
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': newStatus.name,
      'updatedAt': Timestamp.now(),
    });
    debugPrint('🔄 Statut de la tâche $taskId mis à jour vers ${newStatus.name}');
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
      debugPrint('Erreur lors de l’ajout des preuves à la tâche : $e');
      rethrow;
    }
  }

}
