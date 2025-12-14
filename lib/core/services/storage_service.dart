// core/services/storage_service.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload une image pour une tâche
  Future<String> uploadTaskImage(File image, String taskId, String fileName) async {
    try {
      final ref = _storage.ref().child('task_proofs/$taskId/$fileName');
      final uploadTask = await ref.putFile(image);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw 'Erreur upload image: $e';
    }
  }

  // Upload une photo de profil
  Future<String> uploadProfileImage(File image, String userId) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId');
      final uploadTask = await ref.putFile(image);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
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