import 'package:flutter/material.dart';
import '../../models/project_model.dart';

class ProjectService with ChangeNotifier {
  // Simulation de récupération de données (à remplacer par Firestore plus tard)
  Future<List<Project>> getProjects() async {
    // Simule un petit délai réseau
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      Project.mock(
        id: 'chantier_001',
        name: 'Résidence "Les Cèdres"',
        address: '128 Avenue de la République, 75011 Paris',
        imageUrl: 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      ),
      Project.mock(
        id: 'chantier_002',
        name: 'Tour Horizon - La Défense',
        address: '4 Parvis de la Défense, 92800 Puteaux',
        imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      ),
      Project.mock(
        id: 'chantier_003',
        name: 'Rénovation École Jules Ferry',
        address: '15 Rue des Écoles, 69003 Lyon',
        imageUrl: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      ),
    ];
  }
}