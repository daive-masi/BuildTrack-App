import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/task_model.dart';

class TaskService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ProjectTask>> getEmployeeTasks(String employeeId) {
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: employeeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ProjectTask.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<void> injectSampleTasks(String userId) async {
    final existing = await _firestore.collection('tasks').where('assignedTo', isEqualTo: userId).get();
    if (existing.docs.isNotEmpty) return;

    final tasks = [
      ProjectTask(
          id: '',
          title: 'Coulage dalle béton',
          description: 'Vérifier le coffrage avant de couler.',
          address: '12 Rue de la Construction, Paris',
          projectId: 'chantier_001',
          assignedTo: userId,
          status: TaskStatus.inProgress,
          createdAt: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(hours: 4)),
          history: [
            TaskLog(userName: 'Chef de chantier', comment: "Le camion arrive à 14h, préparez la zone.", date: DateTime.now().subtract(const Duration(hours: 2))),
          ]
      ),
      ProjectTask(
        id: '',
        title: 'Pose électricité R+1',
        description: 'Tirer les câbles dans les cloisons du premier étage.',
        address: '45 Avenue des Architectes, Lyon',
        projectId: 'chantier_002',
        assignedTo: userId,
        status: TaskStatus.completed,
        createdAt: DateTime.now(),
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        history: [],
      ),
      ProjectTask(
        id: '',
        title: 'Validation Peinture',
        description: 'Attente validation client pour la couleur du salon.',
        address: '8 Impasse du Pinceau, Lille',
        projectId: 'chantier_003',
        assignedTo: userId,
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 2)),
        history: [],
      ),
    ];

    for (final t in tasks) {
      await _firestore.collection('tasks').add(t.toFirestore());
    }
    print('✅ Tâches injectées pour $userId.');
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': describeEnum(newStatus),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ⭐ NOUVEAU : Ajouter un log (commentaire/photo)
  Future<void> addTaskLog(String taskId, TaskLog log) async {
    final taskRef = _firestore.collection('tasks').doc(taskId);
    await taskRef.update({
      'history': FieldValue.arrayUnion([log.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Méthode legacy gardée pour compatibilité si besoin
  Future<void> addTaskProof({required String taskId, required List<String> imageUrls}) async {
    // ... code existant si nécessaire, sinon peut être retiré
  }
}