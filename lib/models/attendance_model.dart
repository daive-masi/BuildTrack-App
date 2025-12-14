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
  final String? notes;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.projectId,
    required this.projectName,
    required this.checkInTime,
    this.checkOutTime,
    required this.location,
    this.notes,
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
      notes: data['notes'],
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
      'notes': notes,
    };
  }

  // ⭐⭐ AJOUTEZ LA MÉTHODE COPYWITH ICI ⭐⭐
  Attendance copyWith({
    String? id,
    String? employeeId,
    String? projectId,
    String? projectName,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    GeoPoint? location,
    String? notes,
  }) {
    return Attendance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
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

  String get formattedCheckInTime {
    return '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}';
  }

  String get formattedCheckOutTime {
    if (checkOutTime == null) return 'En cours';
    return '${checkOutTime!.hour.toString().padLeft(2, '0')}:${checkOutTime!.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDate {
    return '${checkInTime.day}/${checkInTime.month}/${checkInTime.year}';
  }

  bool get isActive => checkOutTime == null;
}