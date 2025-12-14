// core/services/attendance_service.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/attendance_model.dart';

class AttendanceService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Pointage sur un chantier
  Future<Attendance> checkInToProject({
    required String projectId,
    required String projectName,
    required String employeeId,
    required GeoPoint location,
  }) async {
    try {
      debugPrint('📍 Pointage employé $employeeId sur projet $projectId');
      // Vérifier si l'employé est déjà pointé
      final activeAttendance = await _getActiveAttendance(employeeId);
      if (activeAttendance != null) {
        throw 'Vous êtes déjà pointé sur le chantier: ${activeAttendance.projectName}';
      }
      // Créer le pointage
      final attendance = Attendance(
        id: '${employeeId}_${DateTime.now().millisecondsSinceEpoch}',
        employeeId: employeeId,
        projectId: projectId,
        projectName: projectName,
        checkInTime: DateTime.now(),
        location: location,
      );
      // Sauvegarder dans Firestore
      await _firestore
          .collection('attendances')
          .doc(attendance.id)
          .set(attendance.toFirestore());
      // Mettre à jour le projet actuel de l'employé
      await _firestore.collection('employees').doc(employeeId).update({
        'currentProjectId': projectId,
        'currentProjectName': projectName,
        'lastCheckIn': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Pointage réussi: ${attendance.id}');
      notifyListeners(); // ⭐ Notifie les écouteurs après un pointage réussi
      return attendance;
    } catch (e) {
      debugPrint('❌ Erreur pointage: $e');
      rethrow;
    }
  }

  // Pointage de sortie
  Future<Attendance> checkOutFromProject(String employeeId) async {
    try {
      debugPrint('🚪 Pointage de sortie pour: $employeeId');
      final activeAttendance = await _getActiveAttendance(employeeId);
      if (activeAttendance == null) {
        throw 'Aucun pointage actif trouvé';
      }
      // Mettre à jour le pointage
      await _firestore
          .collection('attendances')
          .doc(activeAttendance.id)
          .update({
        'checkOutTime': Timestamp.fromDate(DateTime.now()),
      });
      // Réinitialiser le projet actuel de l'employé
      await _firestore.collection('employees').doc(employeeId).update({
        'currentProjectId': null,
        'currentProjectName': null,
        'lastCheckOut': FieldValue.serverTimestamp(),
      });
      final updatedAttendance = activeAttendance.copyWith(
        checkOutTime: DateTime.now(),
      );
      debugPrint('✅ Pointage de sortie réussi');
      notifyListeners(); // Notifie les écouteurs après un pointage de sortie réussi
      return updatedAttendance;
    } catch (e) {
      debugPrint('❌ Erreur pointage sortie: $e');
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
    if (querySnapshot.docs.isEmpty) return null;
    return Attendance.fromFirestore(querySnapshot.docs.first.data());
  }

  // Récupérer l'historique des pointages
  Stream<List<Attendance>> getEmployeeAttendances(String employeeId) {
    return _firestore
        .collection('attendances')
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('checkInTime', descending: true)
        .limit(50) // Limiter pour les performances
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
      if (snapshot.docs.isEmpty) return null;
      return Attendance.fromFirestore(snapshot.docs.first.data());
    });
  }

  // Statistiques de travail
  Stream<Map<String, dynamic>> getWorkStats(String employeeId) {
    return getEmployeeAttendances(employeeId).map((attendances) {
      final totalHours = attendances.fold<double>(0, (previousValue, attendance) {
        return previousValue + attendance.duration.inHours;
      });
      final currentWeekHours = attendances.where((a) {
        return a.checkInTime.isAfter(DateTime.now().subtract(const Duration(days: 7)));
      }).fold<double>(0, (previousValue, attendance) {
        return previousValue + attendance.duration.inHours;
      });
      final currentMonthHours = attendances.where((a) {
        return a.checkInTime.isAfter(DateTime.now().subtract(const Duration(days: 30)));
      }).fold<double>(0, (previousValue, attendance) {
        return previousValue + attendance.duration.inHours;
      });
      return {
        'totalHours': totalHours,
        'currentWeekHours': currentWeekHours,
        'currentMonthHours': currentMonthHours,
        'totalAttendances': attendances.length,
        'averageHoursPerDay': totalHours / (attendances.isNotEmpty ? attendances.length : 1),
      };
    });
  }

  // Récupérer le projet actuel de l'employé
  Stream<Map<String, dynamic>?> getCurrentProject(String employeeId) {
    return _firestore
        .collection('employees')
        .doc(employeeId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null || data['currentProjectId'] == null) return null;
      return {
        'projectId': data['currentProjectId'],
        'projectName': data['currentProjectName'] ?? 'Chantier inconnu',
        'lastCheckIn': data['lastCheckIn']?.toDate(),
      };
    });
  }
}