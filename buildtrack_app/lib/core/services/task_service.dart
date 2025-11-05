// core/services/task_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/task_model.dart';

class TaskService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer les tâches d'un employé
  Stream<List<ProjectTask>> getEmployeeTasks(String employeeId) {
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: employeeId)
        .where('status', whereIn: ['pending', 'inProgress'])
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ProjectTask.fromFirestore(doc.data()))
        .toList());
  }

  // Mettre à jour le statut d'une tâche
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': newStatus.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners(); // ⭐ Notifie les écouteurs après mise à jour
    } catch (e) {
      throw 'Erreur mise à jour tâche: $e';
    }
  }

  // Ajouter une preuve photo
  Future<void> addTaskProof(String taskId, String imageUrl) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'proofImages': FieldValue.arrayUnion([imageUrl]),
        'lastUpdate': FieldValue.serverTimestamp(),
      });
      notifyListeners(); // ⭐ Notifie les écouteurs après ajout de preuve
    } catch (e) {
      throw 'Erreur ajout preuve: $e';
    }
  }
}
