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
    // Conversion sécurisée du rôle
    UserRole parseRole(dynamic roleData) {
      try {
        if (roleData is String) {
          return UserRole.values.firstWhere(
                (e) => e.name == roleData,
            orElse: () => UserRole.employee,
          );
        }
      } catch (e) {
        print('Erreur lors du parsing du rôle: $e');
      }
      return UserRole.employee;
    }

    // Conversion sécurisée de la date
    DateTime parseDate(dynamic dateData) {
      try {
        if (dateData is Timestamp) {
          return dateData.toDate();
        }
        if (dateData is Map && dateData['seconds'] != null) {
          final seconds = dateData['seconds'] as int;
          final nanoseconds = dateData['nanoseconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanoseconds ~/ 1000000),
          );
        }
        if (dateData is String) {
          return DateTime.parse(dateData);
        }
      } catch (e) {
        print('Erreur lors du parsing de la date: $e');
      }
      return DateTime.now();
    }

    // Vérification des champs obligatoires avec valeurs par défaut
    final id = data['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ArgumentError('Le champ "id" est requis et ne peut pas être vide');
    }

    final email = data['email']?.toString() ?? '';
    final firstName = data['firstName']?.toString() ?? '';
    final lastName = data['lastName']?.toString() ?? '';
    final phone = data['phone']?.toString() ?? '';

    return Employee(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      role: parseRole(data['role']),
      createdAt: parseDate(data['createdAt']),
      currentProjectId: data['currentProjectId']?.toString(),
      lastCheckIn: data['lastCheckIn'] != null
          ? parseDate(data['lastCheckIn'])
          : null,
      photoUrl: data['photoUrl']?.toString(),
    );
  }

  // Version simplifiée pour les tests
  factory Employee.testFromFirestore(Map<String, dynamic> data) {
    return Employee(
      id: data['id'] as String? ?? 'test-id',
      email: data['email'] as String? ?? 'test@example.com',
      firstName: data['firstName'] as String? ?? 'Test',
      lastName: data['lastName'] as String? ?? 'User',
      phone: data['phone'] as String? ?? '+1234567890',
      role: data.containsKey('role')
          ? UserRole.values.firstWhere(
            (e) => e.name == data['role'],
        orElse: () => UserRole.employee,
      )
          : UserRole.employee,
      createdAt: data.containsKey('createdAt') && data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      currentProjectId: data['currentProjectId'] as String?,
      lastCheckIn: data.containsKey('lastCheckIn') && data['lastCheckIn'] is Timestamp
          ? (data['lastCheckIn'] as Timestamp).toDate()
          : null,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'currentProjectId': currentProjectId,
      'photoUrl': photoUrl,
    };

    // Ajouter lastCheckIn seulement s'il n'est pas null
    if (lastCheckIn != null) {
      map['lastCheckIn'] = Timestamp.fromDate(lastCheckIn!);
    }

    return map;
  }

  // Méthode pour mettre à jour certaines propriétés
  Employee copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
    String? currentProjectId,
    DateTime? lastCheckIn,
    String? photoUrl,
  }) {
    return Employee(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      currentProjectId: currentProjectId ?? this.currentProjectId,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  String toString() {
    return 'Employee{id: $id, email: $email, name: $firstName $lastName, role: ${role.name}}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Employee &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum UserRole { admin, employee }

// Extension pour des méthodes utiles sur UserRole
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.employee:
        return 'Employé';
    }
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isEmployee => this == UserRole.employee;
}