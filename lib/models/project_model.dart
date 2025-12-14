// models/project_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String name;
  final String address;
  final String qrCode;
  final GeoPoint location;
  final DateTime createdAt;
  final List<String> assignedEmployees;
  final bool isActive;

  Project({
    required this.id,
    required this.name,
    required this.address,
    required this.qrCode,
    required this.location,
    required this.createdAt,
    this.assignedEmployees = const [],
    this.isActive = true,
  });

  factory Project.fromFirestore(Map<String, dynamic> data) {
    return Project(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      qrCode: data['qrCode'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      assignedEmployees: List<String>.from(data['assignedEmployees'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'qrCode': qrCode,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'assignedEmployees': assignedEmployees,
      'isActive': isActive,
    };
  }
}