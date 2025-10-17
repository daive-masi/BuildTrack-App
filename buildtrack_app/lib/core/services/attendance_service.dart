import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/task_model.dart';


class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Scanner QR code et pointer sur le chantier
  Future<void> checkInToProject(String qrCode, String employeeId) async {
    // Trouver le projet par QR code
    final projectQuery = await _firestore
        .collection('projects')
        .where('qrCode', isEqualTo: qrCode)
        .get();

    if (projectQuery.docs.isEmpty) {
      throw Exception('Chantier non trouvé');
    }

    final project = projectQuery.docs.first;

    // Mettre à jour l'employé
    await _firestore.collection('employees').doc(employeeId).update({
      'currentProjectId': project.id,
      'lastCheckIn': FieldValue.serverTimestamp(),
    });

    // Ajouter à l'historique de pointage
    await _firestore.collection('attendance').add({
      'employeeId': employeeId,
      'projectId': project.id,
      'checkInTime': FieldValue.serverTimestamp(),
      'type': 'check_in',
    });
  }

  // Récupérer les tâches de l'employé sur le chantier actuel
  Stream<List<ProjectTask>> getEmployeeTasks(String employeeId) {
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: employeeId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return ProjectTask(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        status: TaskStatus.values.firstWhere(
              (e) => e.name == data['status'],
          orElse: () => TaskStatus.pending,
        ),
        assignedTo: data['assignedTo'] ?? '',
        startTime: data['startTime']?.toDate(),
        endTime: data['endTime']?.toDate(),
        photoUrls: List<String>.from(data['photoUrls'] ?? []),
      );
    }).toList());
  }
}