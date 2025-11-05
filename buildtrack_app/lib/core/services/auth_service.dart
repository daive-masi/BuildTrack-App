// core/services/auth_service.dart
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

  // --- Connexion avec email/mot de passe ---
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
      notifyListeners(); // ⭐ Notifie les écouteurs après connexion
      return await _getOrCreateEmployee(credential.user!);
    } catch (e) {
      print('❌ Erreur connexion email: $e');
      throw _handleAuthError(e);
    }
  }

  // --- Connexion avec Google (version ultra-robuste) ---
  Future<Employee?> signInWithGoogle() async {
    print('🔗 Début de la connexion Google');
    try {
      // Étape 1: Connexion Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Connexion Google annulée par l\'utilisateur');
      }
      print('✅ Google Sign-In réussi: ${googleUser.email}');
      // Étape 2: Authentification
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw Exception('Tokens d\'authentification manquants');
      }
      // Étape 3: Création credentials Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      // Étape 4: Connexion Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw Exception('Aucun utilisateur Firebase retourné');
      }
      print('✅ Connexion Firebase réussie: ${userCredential.user!.uid}');
      notifyListeners(); // ⭐ Notifie les écouteurs après connexion
      return await _getOrCreateEmployee(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      throw _handleAuthError(e);
    } catch (e) {
      print('❌ Erreur connexion Google: $e');
      throw _handleAuthError(e);
    }
  }

  // --- Inscription employé ---
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
        createdAt: DateTime.now(),
      );
      await _firestore.collection('employees').doc(employee.id).set(
        employee.toFirestore(),
      );
      print('✅ Employé inscrit et enregistré dans Firestore: ${employee.id}');
      notifyListeners(); // ⭐ Notifie les écouteurs après inscription
      return employee;
    } catch (e) {
      print('❌ Erreur inscription employé: $e');
      throw _handleAuthError(e);
    }
  }

  // --- Récupérer ou créer l'employé ---
  Future<Employee> _getOrCreateEmployee(User user) async {
    print('🔄 Récupération/création employé pour: ${user.uid}');
    try {
      final doc = await _firestore.collection('employees').doc(user.uid).get();
      if (doc.exists) {
        print('✅ Employé trouvé dans Firestore');
        return Employee.fromFirestore(doc.data()!);
      } else {
        print('🆕 Création nouvel employé depuis ${user.providerData.first.providerId}');
        final names = user.displayName?.split(' ') ?? ['Employé', ''];
        final employee = Employee(
          id: user.uid,
          email: user.email!,
          firstName: names.first,
          lastName: names.length > 1 ? names.sublist(1).join(' ') : '',
          phone: user.phoneNumber ?? '',
          role: UserRole.employee,
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
      notifyListeners(); // ⭐ Notifie les écouteurs après déconnexion
      print('✅ Déconnexion réussie');
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
      throw 'Erreur lors de la déconnexion';
    }
  }

  // --- Stream utilisateur (version corrigée et robuste) ---
  Stream<Employee?> get userStream {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        print('🔄 Utilisateur déconnecté');
        return null;
      }
      try {
        print('🔄 Récupération données employé pour: ${user.uid}');
        return await _getOrCreateEmployee(user);
      } catch (e) {
        print('❌ Erreur dans userStream: $e');
        return null;
      }
    });
  }

  // --- Gestion des erreurs d'authentification (version enrichie) ---
  String _handleAuthError(dynamic error) {
    print('🔐 Erreur auth: $error');
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Aucun compte trouvé avec cet email. Créez un compte ou vérifiez votre email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email ou mot de passe incorrect. Veuillez réessayer.';
        case 'email-already-in-use':
          return 'Un compte existe déjà avec cet email. Connectez-vous ou utilisez un autre email.';
        case 'weak-password':
          return 'Le mot de passe est trop faible. Utilisez au moins 6 caractères.';
        case 'invalid-email':
          return 'Format d\'email invalide. Vérifiez votre saisie.';
        case 'network-request-failed':
          return 'Erreur de connexion internet. Vérifiez votre connexion.';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessayez dans quelques minutes.';
        case 'account-exists-with-different-credential':
          return 'Un compte existe déjà avec cet email mais via un autre fournisseur.';
        default:
          return 'Erreur de connexion: ${error.message ?? "Veuillez réessayer"}';
      }
    } else if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
  }

  // --- Méthode utilitaire: Récupérer l'utilisateur actuel (sans Firestore) ---
  Employee? getCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return Employee(
      id: user.uid,
      email: user.email ?? '',
      firstName: user.displayName?.split(' ').first ?? 'Employé',
      lastName: user.displayName?.split(' ').last ?? '',
      phone: user.phoneNumber ?? '',
      role: UserRole.employee,
      createdAt: DateTime.now(),
      photoUrl: user.photoURL,
    );
  }

  // --- Méthode utilitaire: Vérifier si un utilisateur est connecté ---
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }
}
