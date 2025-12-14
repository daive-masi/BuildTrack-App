import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String name;
  final String address;
  final String description;
  final String imageUrl;
  final GeoPoint location;
  final DateTime createdAt;
  final List<String> assignedEmployees;
  final bool isActive;

  // --- NOUVEAUX CHAMPS (Chef de projet) ---
  final String projectManagerName;
  final String projectManagerPhone;

  Project({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.createdAt,
    this.assignedEmployees = const [],
    this.isActive = true,
    // Valeurs par défaut
    this.projectManagerName = "Jean Dupont (Chef)",
    this.projectManagerPhone = "0612345678",
  });

  factory Project.fromFirestore(Map<String, dynamic> data) {
    return Project(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      description: data['description'] ?? 'Aucune description',
      imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/400x200',
      location: data['location'] ?? const GeoPoint(0, 0),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      assignedEmployees: List<String>.from(data['assignedEmployees'] ?? []),
      isActive: data['isActive'] ?? true,
      // Récupération
      projectManagerName: data['projectManagerName'] ?? 'Chef de Chantier',
      projectManagerPhone: data['projectManagerPhone'] ?? '',
    );
  }

  // Pour les tests
  factory Project.mock({required String id, required String name, required String address, required String imageUrl}) {
    return Project(
      id: id,
      name: name,
      address: address,
      description: "Chantier résidentiel complet",
      imageUrl: imageUrl,
      location: const GeoPoint(48.8566, 2.3522),
      createdAt: DateTime.now(),
      projectManagerName: "Marc Durand",
      projectManagerPhone: "0102030405",
    );
  }
}