import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final UserRole role;
  final DateTime createdAt;
  final String? currentProjectId;
  final DateTime? lastCheckIn;
  final String? photoUrl;

  Employee({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.currentProjectId,
    this.lastCheckIn,
    this.photoUrl,
  });

  String get fullName => '$firstName $lastName';
  String get displayName => firstName;

  factory Employee.fromFirestore(Map<String, dynamic> data) {
    return Employee(
      id: data['id'],
      email: data['email'],
      firstName: data['firstName'],
      lastName: data['lastName'],
      phone: data['phone'],
      role: UserRole.values.firstWhere(
            (e) => e.name == data['role'],
        orElse: () => UserRole.employee,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      currentProjectId: data['currentProjectId'],
      lastCheckIn: data['lastCheckIn']?.toDate(),
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'currentProjectId': currentProjectId,
      'lastCheckIn': lastCheckIn != null ? Timestamp.fromDate(lastCheckIn!) : null,
      'photoUrl': photoUrl,
    };
  }
}

enum UserRole { admin, employee }