import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; // Package GPS
import '../../models/project_model.dart';
import '../../models/attendance_model.dart';

class QrService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- 🔴 CONFIGURATION TEST ---
  // Mets sur 'false' quand tu passeras en production !
  final bool _isTestMode = true;
  // ----------------------------

  // --- Scanner et Vérifier l'accès ---
  Future<Project> verifyAndCheckIn({
    required String qrData,
    required String employeeId
  }) async {
    try {
      print('🔍 Analyse du QR Code: $qrData');

      // 1. Récupération du projet via l'ID contenu dans le QR Code
      final projectDoc = await _firestore.collection('projects').doc(qrData).get();

      if (!projectDoc.exists) {
        throw "Ce QR code ne correspond à aucun chantier connu.";
      }

      final project = Project.fromFirestore(projectDoc.data()!..['id'] = projectDoc.id);

      // 2. Vérification de l'assignation
      // Si la liste est vide ou nulle, on considère que c'est ouvert à tous (optionnel)
      // Sinon, on vérifie que l'ID est dans la liste
      if (project.assignedEmployees.isNotEmpty && !project.assignedEmployees.contains(employeeId)) {
        throw "Accès refusé : Vous n'êtes pas assigné à ce chantier.";
      }

      // 3. Vérification de la Géolocalisation
      // 🔥 LOGIQUE MODIFIÉE POUR LE TEST 🔥
      Position position;

      if (_isTestMode) {
        print("⚠️ MODE TEST ACTIVÉ : Vérification GPS ignorée !");
        // On simule une position valide (0,0 ou Paris, peu importe)
        position = Position(
          longitude: 0,
          latitude: 0,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
          isMocked: true,
        );
      } else {
        // --- VRAIE LOGIQUE DE PROD ---
        print('📍 Vérification de la position GPS...');

        // Permissions
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw "La localisation est requise pour valider votre présence.";
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw "La localisation est définitivement refusée. Activez-la dans les paramètres.";
        }

        // Position actuelle
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high
        );

        // Calcul distance
        double distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          project.location.latitude,
          project.location.longitude,
        );

        print("📏 Distance du chantier : ${distanceInMeters.toStringAsFixed(0)} m");

        // Seuil de tolérance (ex: 200m)
        // Si le projet n'a pas de coordonnées (0,0), on ignore la vérif GPS pour éviter le blocage
        bool hasValidCoordinates = project.location.latitude != 0 && project.location.longitude != 0;

        if (hasValidCoordinates && distanceInMeters > 200) {
          throw "Vous êtes trop loin du chantier (${distanceInMeters.toStringAsFixed(0)}m). Rapprochez-vous pour pointer.";
        }
      }

      // 4. Pointage (Check-in)
      await _performCheckIn(project, employeeId, position);

      return project;

    } catch (e) {
      print('❌ Erreur Scan/GPS: $e');
      rethrow;
    }
  }

  // --- Enregistrement en base ---
  Future<void> _performCheckIn(Project project, String employeeId, Position position) async {
    // Vérifier les pointages actifs
    final activeSnapshot = await _firestore.collection('attendances')
        .where('employeeId', isEqualTo: employeeId)
        .where('checkOutTime', isNull: true)
        .get();

    // Dépointer des autres chantiers si nécessaire
    for (var doc in activeSnapshot.docs) {
      if (doc['projectId'] != project.id) {
        await _firestore.collection('attendances').doc(doc.id).update({
          'checkOutTime': Timestamp.now(),
          'notes': 'Dépointage automatique (changement de site)'
        });
      }
    }

    // Créer le pointage si pas déjà actif ICI
    final alreadyHere = activeSnapshot.docs.any((d) => d['projectId'] == project.id);

    if (!alreadyHere) {
      final attendance = Attendance(
        id: '${employeeId}_${DateTime.now().millisecondsSinceEpoch}',
        employeeId: employeeId,
        projectId: project.id,
        projectName: project.name,
        checkInTime: DateTime.now(),
        location: GeoPoint(position.latitude, position.longitude),
      );

      await _firestore.collection('attendances').doc(attendance.id).set(attendance.toFirestore());

      // Mettre à jour l'employé
      await _firestore.collection('employees').doc(employeeId).update({
        'currentProjectId': project.id,
        'currentProjectName': project.name,
        'lastCheckIn': FieldValue.serverTimestamp(),
      });

      notifyListeners();
    }
  }
}