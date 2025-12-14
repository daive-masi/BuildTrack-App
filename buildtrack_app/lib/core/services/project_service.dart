import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/project_model.dart';

class ProjectService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- FILTRE : PROJETS ASSIGNÉS À L'EMPLOYÉ ---
  Stream<List<Project>> getAssignedProjectsStream(String employeeId) {
    return _firestore
        .collection('projects')
        .where('isActive', isEqualTo: true)
    // Note: Si tu veux voir TOUS les chantiers en mode test, tu peux commenter la ligne ci-dessous
        .where('assignedEmployees', arrayContains: employeeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Project.fromFirestore(doc.data()..['id'] = doc.id))
        .toList());
  }

  // --- ADMIN : TOUS LES PROJETS ---
  Stream<List<Project>> getProjectsStream() {
    return _firestore
        .collection('projects')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Project.fromFirestore(doc.data()..['id'] = doc.id))
        .toList());
  }

  Future<List<Project>> getProjects() async {
    final snapshot = await _firestore.collection('projects').get();
    return snapshot.docs
        .map((doc) => Project.fromFirestore(doc.data()..['id'] = doc.id))
        .toList();
  }

  Future<void> addProject(Project project) async {
    try {
      final data = {
        'name': project.name,
        'address': project.address,
        'description': project.description,
        'imageUrl': project.imageUrl,
        'location': project.location,
        'createdAt': Timestamp.now(),
        'isActive': true,
        'projectManagerName': project.projectManagerName,
        'projectManagerPhone': project.projectManagerPhone,
        'assignedEmployees': project.assignedEmployees,
      };
      await _firestore.collection('projects').add(data);
      notifyListeners();
    } catch (e) {
      print("❌ Erreur ajout: $e");
      throw e;
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      await _firestore.collection('projects').doc(projectId).delete();
      notifyListeners();
    } catch (e) {
      print("❌ Erreur suppression: $e");
      throw e;
    }
  }

  // 🔥 C'EST ICI QUE CA SE PASSE (CORRIGÉ) 🔥
  Future<void> seedDatabase() async {
    // On vérifie si notre chantier "facile" existe déjà pour ne pas le créer 2 fois
    final docCheck = await _firestore.collection('projects').doc('CHANTIER-PARIS').get();

    if (docCheck.exists) {
      print("⚠️ Les chantiers de test avec CODES FACILES existent déjà.");
      return;
    }

    print("🚀 Injection des chantiers avec IDENTIFIANTS MANUELS...");

    // 1. Chantier PARIS (Code : CHANTIER-PARIS)
    await _firestore.collection('projects').doc('CHANTIER-PARIS').set({
      'name': 'Résidence "Les Cèdres"',
      'address': '128 Avenue de la République, 75011 Paris',
      'description': 'Rénovation complète de 45 appartements.',
      'imageUrl': 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      'location': const GeoPoint(48.866, 2.378),
      'createdAt': Timestamp.now(),
      'isActive': true,
      'projectManagerName': "Marc Durand",
      'projectManagerPhone': "0612345678",
      'assignedEmployees': [],
    });

    // 2. Chantier DÉFENSE (Code : CHANTIER-DEFENSE)
    await _firestore.collection('projects').doc('CHANTIER-DEFENSE').set({
      'name': 'Tour Horizon - La Défense',
      'address': '4 Parvis de la Défense, 92800 Puteaux',
      'description': 'Construction des étages 12 à 15 (Bureaux).',
      'imageUrl': 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      'location': const GeoPoint(48.892, 2.238),
      // CORRECTION ICI : On calcule la date en Dart (DateTime) avant de la convertir en Timestamp
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      'isActive': true,
      'projectManagerName': "Sophie Martin",
      'projectManagerPhone': "0798765432",
      'assignedEmployees': [],
    });

    print("✅ Données injectées ! Tu peux utiliser 'CHANTIER-PARIS' ou 'CHANTIER-DEFENSE'");
    notifyListeners();
  }
}