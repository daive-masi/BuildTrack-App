// lib/core/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AuthService with ChangeNotifier {
  FirebaseAuth _auth;
  FirebaseFirestore _firestore;
  GoogleSignIn _googleSignIn;

  // Constructeur principal
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.standard();

  // Setters pour les tests
  @visibleForTesting
  set setFirebaseAuth(FirebaseAuth auth) {
    _auth = auth;
  }

  @visibleForTesting
  set setFirestore(FirebaseFirestore firestore) {
    _firestore = firestore;
  }

  @visibleForTesting
  set setGoogleSignIn(GoogleSignIn googleSignIn) {
    _googleSignIn = googleSignIn;
  }

  User? get currentUser => _auth.currentUser;

  // --- Connexion avec email/mot de passe ---
  Future<Employee?> signInWithEmail(String email, String password) async {
    debugPrint('🔐 Tentative de connexion avec email: $email');
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw Exception('Aucun utilisateur retourné par Firebase');
      }
      debugPrint('✅ Connexion réussie pour: ${credential.user!.uid}');
      notifyListeners();
      return await _getOrCreateEmployee(credential.user!);
    } catch (e) {
      debugPrint('❌ Erreur connexion email: $e');
      throw _handleAuthError(e);
    }
  }

  // --- Connexion avec Google ---
  Future<Employee?> signInWithGoogle() async {
    debugPrint('🔗 Début de la connexion Google');
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Connexion Google annulée par l\'utilisateur');
      }
      debugPrint('✅ Google Sign-In réussi: ${googleUser.email}');
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
      debugPrint('✅ Connexion Firebase réussie: ${userCredential.user!.uid}');
      notifyListeners();
      return await _getOrCreateEmployee(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      throw _handleAuthError(e);
    } catch (e) {
      debugPrint('❌ Erreur connexion Google: $e');
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
    debugPrint('📝 Inscription d\'un nouvel employé: $email');
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
      debugPrint('✅ Employé inscrit et enregistré dans Firestore: ${employee.id}');
      notifyListeners();
      return employee;
    } catch (e) {
      debugPrint('❌ Erreur inscription employé: $e');
      throw _handleAuthError(e);
    }
  }

  // --- Récupérer ou créer l'employé ---
  Future<Employee> _getOrCreateEmployee(User user) async {
    debugPrint('🔄 Récupération/création employé pour: ${user.uid}');
    try {
      final doc = await _firestore.collection('employees').doc(user.uid).get();
      if (doc.exists) {
        debugPrint('✅ Employé trouvé dans Firestore');
        final data = doc.data()!;
        return Employee.fromFirestore(data);
      } else {
        debugPrint('🆕 Création nouvel employé depuis ${user.providerData.first.providerId}');
        final names = user.displayName?.split(' ') ?? ['Employé'];
        final employee = Employee(
          id: user.uid,
          email: user.email ?? '',
          firstName: names.isNotEmpty ? names.first : 'Employé',
          lastName: names.length > 1 ? names.sublist(1).join(' ') : '',
          phone: user.phoneNumber ?? '',
          role: UserRole.employee,
          createdAt: DateTime.now(),
          photoUrl: user.photoURL,
        );
        await _firestore.collection('employees').doc(employee.id).set(
          employee.toFirestore(),
        );
        debugPrint('✅ Nouvel employé créé dans Firestore: ${employee.id}');
        return employee;
      }
    } catch (e) {
      debugPrint('❌ Erreur dans _getOrCreateEmployee: $e');
      throw Exception('Erreur lors de la récupération/création du profil: $e');
    }
  }

  // --- Déconnexion ---
  Future<void> signOut() async {
    debugPrint('🚪 Déconnexion en cours...');
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      notifyListeners();
      debugPrint('✅ Déconnexion réussie');
    } catch (e) {
      debugPrint('❌ Erreur déconnexion: $e');
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  // --- Stream utilisateur ---
  Stream<Employee?> get userStream {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        debugPrint('🔄 Utilisateur déconnecté');
        return null;
      }
      try {
        debugPrint('🔄 Récupération données employé pour: ${user.uid}');
        return await _getOrCreateEmployee(user);
      } catch (e) {
        debugPrint('❌ Erreur dans userStream: $e');
        return null;
      }
    });
  }

  // --- Gestion des erreurs d'authentification ---
  @visibleForTesting
  String handleAuthError(dynamic error) {
    return _handleAuthError(error);
  }

  String _handleAuthError(dynamic error) {
    debugPrint('🔐 Erreur auth: $error');
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

  // --- Méthode utilitaire: Récupérer l'utilisateur actuel ---
  Employee? getCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return null;
    final names = user.displayName?.split(' ') ?? ['Employé'];
    return Employee(
      id: user.uid,
      email: user.email ?? '',
      firstName: names.isNotEmpty ? names.first : 'Employé',
      lastName: names.length > 1 ? names.sublist(1).join(' ') : '',
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

  // --- Méthode utilitaire: Récupérer les données d'un employé ---
  Future<Employee?> getEmployeeData(String employeeId) async {
    try {
      final doc = await _firestore.collection('employees').doc(employeeId).get();
      if (doc.exists) {
        return Employee.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur récupération employé: $e');
      return null;
    }
  }

  // --- Méthode utilitaire: Mettre à jour le profil d'un employé ---
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
      debugPrint('✅ Profil employé mis à jour: $employeeId');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour profil: $e');
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }
}
