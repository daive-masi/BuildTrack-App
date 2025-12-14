import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard();

  User? get currentUser => _auth.currentUser;

  // --- 🔥 LE CŒUR DU PROBLÈME CORRIGÉ ---
  // Avant : On récupérait l'info une seule fois au login.
  // Maintenant : On écoute en temps réel (Live) les changements dans la base de données.
  Stream<Employee?> get userStream {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        // Personne n'est connecté
        return Stream.value(null);
      } else {
        // Utilisateur connecté -> On branche un écouteur sur sa fiche Firestore
        return _firestore
            .collection('employees')
            .doc(user.uid)
            .snapshots()
            .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            // À chaque changement (ex: scan QR), on renvoie le nouvel objet Employee
            return Employee.fromFirestore(snapshot.data()!);
          }
          return null;
        });
      }
    });
  }

  // --- Connexion Email/Mot de passe ---
  Future<Employee?> signInWithEmail(String email, String password) async {
    print('🔐 Tentative de connexion avec email: $email');
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw Exception('Aucun utilisateur retourné par Firebase');
      }
      print('✅ Connexion réussie pour: ${credential.user!.uid}');
      notifyListeners();
      return await _getOrCreateEmployee(credential.user!);
    } catch (e) {
      print('❌ Erreur connexion email: $e');
      throw _handleAuthError(e);
    }
  }

  // --- Connexion Google ---
  Future<Employee?> signInWithGoogle() async {
    print('🔗 Début de la connexion Google');
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Connexion Google annulée par l\'utilisateur');
      }
      print('✅ Google Sign-In réussi: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw Exception('Tokens d\'authentification manquants');
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw Exception('Aucun utilisateur Firebase retourné');
      }

      print('✅ Connexion Firebase réussie: ${userCredential.user!.uid}');
      notifyListeners();
      return await _getOrCreateEmployee(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      throw _handleAuthError(e);
    } catch (e) {
      print('❌ Erreur connexion Google: $e');
      throw _handleAuthError(e);
    }
  }

  // --- Inscription Employé ---
  Future<Employee?> signUpEmployee({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    print('📝 Inscription d\'un nouvel employé: $email');
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final employee = Employee(
        id: credential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        role: UserRole.employee,
        jobTitle: "Ouvrier Polyvalent", // Valeur par défaut
        createdAt: DateTime.now(),
      );

      await _firestore.collection('employees').doc(employee.id).set(
        employee.toFirestore(),
      );
      print('✅ Employé inscrit et enregistré dans Firestore: ${employee.id}');
      notifyListeners();
      return employee;
    } catch (e) {
      print('❌ Erreur inscription employé: $e');
      throw _handleAuthError(e);
    }
  }

  // --- Récupérer ou Créer le Profil ---
  Future<Employee> _getOrCreateEmployee(User user) async {
    print('🔄 Récupération/création employé pour: ${user.uid}');
    try {
      final doc = await _firestore.collection('employees').doc(user.uid).get();
      if (doc.exists) {
        print('✅ Employé trouvé dans Firestore');
        return Employee.fromFirestore(doc.data()!);
      } else {
        print('🆕 Création nouvel employé depuis ${user.providerData.isNotEmpty ? user.providerData.first.providerId : "Email"}');

        String derivedFirstName = 'Employé';
        String derivedLastName = '';

        if (user.displayName != null && user.displayName!.isNotEmpty) {
          final names = user.displayName!.split(' ');
          derivedFirstName = names.first;
          derivedLastName = names.length > 1 ? names.sublist(1).join(' ') : '';
        } else if (user.email != null && user.email!.contains('@')) {
          String part = user.email!.split('@')[0];
          if (part.isNotEmpty) {
            derivedFirstName = part[0].toUpperCase() + part.substring(1);
          }
        }

        final employee = Employee(
          id: user.uid,
          email: user.email!,
          firstName: derivedFirstName,
          lastName: derivedLastName,
          phone: user.phoneNumber ?? '',
          role: UserRole.employee,
          jobTitle: "Ouvrier Polyvalent",
          createdAt: DateTime.now(),
          photoUrl: user.photoURL,
        );

        await _firestore.collection('employees').doc(employee.id).set(
          employee.toFirestore(),
        );
        print('✅ Nouvel employé créé dans Firestore: ${employee.id}');
        return employee;
      }
    } catch (e) {
      print('❌ Erreur dans _getOrCreateEmployee: $e');
      throw 'Erreur lors de la récupération/création du profil';
    }
  }

  // --- Déconnexion ---
  Future<void> signOut() async {
    print('🚪 Déconnexion en cours...');
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      notifyListeners();
      print('✅ Déconnexion réussie');
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
      throw 'Erreur lors de la déconnexion';
    }
  }

  // --- Helpers pour les données ---
  Future<Employee?> getEmployeeData(String employeeId) async {
    try {
      final doc = await _firestore.collection('employees').doc(employeeId).get();
      if (doc.exists) {
        return Employee.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération employé: $e');
      return null;
    }
  }

  Future<void> updateEmployeeProfile({
    required String employeeId,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      await _firestore.collection('employees').doc(employeeId).update({
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Profil employé mis à jour: $employeeId');
    } catch (e) {
      print('❌ Erreur mise à jour profil: $e');
      throw 'Erreur lors de la mise à jour du profil';
    }
  }

  // --- Gestion des erreurs ---
  String _handleAuthError(dynamic error) {
    print('🔐 Erreur auth: $error');
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Aucun compte trouvé avec cet email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email ou mot de passe incorrect.';
        case 'email-already-in-use':
          return 'Cet email est déjà utilisé.';
        case 'weak-password':
          return 'Le mot de passe est trop faible.';
        case 'invalid-email':
          return 'Format d\'email invalide.';
        case 'network-request-failed':
          return 'Erreur de connexion internet.';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessayez plus tard.';
        default:
          return 'Erreur de connexion: ${error.message ?? "Veuillez réessayer"}';
      }
    } else if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return 'Une erreur inattendue s\'est produite.';
  }
}