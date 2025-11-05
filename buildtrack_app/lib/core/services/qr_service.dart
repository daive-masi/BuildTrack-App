// core/services/qr_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/project_model.dart';
import '../../models/attendance_model.dart';

class QrService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Scanner un QR code et récupérer le projet
  Future<Project?> scanQrCode(String qrData) async {
    try {
      print('🔍 Scan QR code: $qrData');
      final querySnapshot = await _firestore
          .collection('projects')
          .where('qrCode', isEqualTo: qrData)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (querySnapshot.docs.isEmpty) {
        print('❌ Aucun projet trouvé pour ce QR code');
        return null;
      }
      final doc = querySnapshot.docs.first;
      final project = Project.fromFirestore(doc.data());
      print('✅ Projet trouvé: ${project.name}');
      return project;
    } catch (e) {
      print('❌ Erreur scan QR: $e');
      throw 'Erreur lors du scan du QR code';
    }
  }

  // Pointage sur un chantier
  Future<Attendance> checkInToProject({
    required String projectId,
    required String projectName,
    required String employeeId,
    required GeoPoint location,
  }) async {
    try {
      print('📍 Pointage employé $employeeId sur projet $projectId');
      final activeAttendance = await _getActiveAttendance(employeeId);
      if (activeAttendance != null) {
        throw 'Vous êtes déjà pointé sur le chantier: ${activeAttendance.projectName}';
      }
      final attendance = Attendance(
        id: '${employeeId}_${DateTime.now().millisecondsSinceEpoch}',
        employeeId: employeeId,
        projectId: projectId,
        projectName: projectName,
        checkInTime: DateTime.now(),
        location: location,
      );
      await _firestore
          .collection('attendances')
          .doc(attendance.id)
          .set(attendance.toFirestore());
      print('✅ Pointage réussi: ${attendance.id}');
      notifyListeners(); // ⭐ Notifie les écouteurs après un pointage réussi
      return attendance;
    } catch (e) {
      print('❌ Erreur pointage: $e');
      rethrow;
    }
  }

  // Pointage de sortie
  Future<void> checkOutFromProject(String employeeId) async {
    try {
      print('🚪 Pointage de sortie pour: $employeeId');
      final activeAttendance = await _getActiveAttendance(employeeId);
      if (activeAttendance == null) {
        throw 'Aucun pointage actif trouvé';
      }
      await _firestore
          .collection('attendances')
          .doc(activeAttendance.id)
          .update({
        'checkOutTime': Timestamp.fromDate(DateTime.now()),
      });
      print('✅ Pointage de sortie réussi');
      notifyListeners(); // ⭐ Notifie les écouteurs après un pointage de sortie réussi
    } catch (e) {
      print('❌ Erreur pointage sortie: $e');
      rethrow;
    }
  }

  // Récupérer le pointage actif
  Future<Attendance?> _getActiveAttendance(String employeeId) async {
    final querySnapshot = await _firestore
        .collection('attendances')
        .where('employeeId', isEqualTo: employeeId)
        .where('checkOutTime', isNull: true)
        .limit(1)
        .get();
    if (querySnapshot.docs.isEmpty) {
      return null;
    }
    return Attendance.fromFirestore(querySnapshot.docs.first.data());
  }

  // Récupérer l'historique des pointages
  Stream<List<Attendance>> getEmployeeAttendances(String employeeId) {
    return _firestore
        .collection('attendances')
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Attendance.fromFirestore(doc.data()))
        .toList());
  }

  // Vérifier si l'employé est actuellement pointé
  Stream<Attendance?> getCurrentAttendance(String employeeId) {
    return _firestore
        .collection('attendances')
        .where('employeeId', isEqualTo: employeeId)
        .where('checkOutTime', isNull: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return Attendance.fromFirestore(snapshot.docs.first.data());
    });
  }
}
