// models/attendance_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String employeeId;
  final String projectId;
  final String projectName;
  final DateTime checkInTime;
  DateTime? checkOutTime;
  final GeoPoint location;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.projectId,
    required this.projectName,
    required this.checkInTime,
    this.checkOutTime,
    required this.location,
  });

  factory Attendance.fromFirestore(Map<String, dynamic> data) {
    return Attendance(
      id: data['id'] ?? '',
      employeeId: data['employeeId'] ?? '',
      projectId: data['projectId'] ?? '',
      projectName: data['projectName'] ?? '',
      checkInTime: (data['checkInTime'] as Timestamp).toDate(),
      checkOutTime: data['checkOutTime'] != null
          ? (data['checkOutTime'] as Timestamp).toDate()
          : null,
      location: data['location'] ?? const GeoPoint(0, 0),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'employeeId': employeeId,
      'projectId': projectId,
      'projectName': projectName,
      'checkInTime': Timestamp.fromDate(checkInTime),
      'checkOutTime': checkOutTime != null
          ? Timestamp.fromDate(checkOutTime!)
          : null,
      'location': location,
    };
  }

  // Calculer la durée de présence
  Duration get duration {
    final end = checkOutTime ?? DateTime.now();
    return end.difference(checkInTime);
  }

  String get formattedDuration {
    final dur = duration;
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    return '${hours}h ${minutes}min';
  }
}