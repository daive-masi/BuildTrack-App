import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String name;
  final String address;
  final String description; // Nouveau
  final String imageUrl;    // Nouveau
  final GeoPoint location;
  final DateTime createdAt;
  final List<String> assignedEmployees;
  final bool isActive;

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
  });

  factory Project.fromFirestore(Map<String, dynamic> data) {
    return Project(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      description: data['description'] ?? 'Aucune description',
      imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/400x200', // Image par défaut
      // Le qrCode est peut-être stocké mais on ne l'utilise plus ici pour l'affichage
      location: data['location'] ?? const GeoPoint(0, 0),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      assignedEmployees: List<String>.from(data['assignedEmployees'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }

  // Factory pour créer des faux projets (Mock)
  factory Project.mock({
    required String id,
    required String name,
    required String address,
    required String imageUrl
  }) {
    return Project(
      id: id,
      name: name,
      address: address,
      description: "Chantier résidentiel complet",
      imageUrl: imageUrl,
      location: const GeoPoint(0, 0),
      createdAt: DateTime.now(),
    );
  }
}