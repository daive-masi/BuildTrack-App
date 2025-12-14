// core/services/storage_service.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload une image pour une tâche
  Future<String> uploadTaskImage(File image, String taskId, String fileName) async {
    // 1. Vérification que l'ID n'est pas vide (cause fréquente de bugs de chemin)
    if (taskId.isEmpty) {
      throw "Impossible d'uploader : L'ID de la tâche est introuvable.";
    }

    try {
      // Création de la référence du fichier
      final ref = _storage.ref().child('task_proofs/$taskId/$fileName');

      // 2. Lancement de l'upload avec plus de contrôle
      // On utilise putFile et on attend explicitement la fin
      final UploadTask uploadTask = ref.putFile(image);

      // On attend que la tâche soit complètement terminée
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

      // 3. Vérification du succès avant de demander l'URL
      if (snapshot.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        return downloadUrl;
      } else {
        throw 'L\'upload a échoué avec le statut : ${snapshot.state}';
      }

    } catch (e) {
      // Traduction de l'erreur courante pour le débogage
      if (e.toString().contains('object-not-found')) {
        throw 'Erreur Permissions : Vérifiez les Règles Firebase Storage (Règles "allow write").';
      } else if (e.toString().contains('unauthorized')) {
        throw 'Accès refusé : Vous n\'avez pas la permission d\'uploader.';
      }

      print('❌ Erreur Storage détaillée : $e');
      throw 'Erreur technique upload : $e';
    }
  }

  // Upload une photo de profil (Même logique si besoin)
  Future<String> uploadProfileImage(File image, String userId) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId');
      final UploadTask uploadTask = ref.putFile(image);
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Erreur upload photo profil: $e';
    }
  }

  // Supprimer une image
  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Erreur suppression image: $e');
    }
  }
}