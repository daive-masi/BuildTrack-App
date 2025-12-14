// test/unit/auth_service_test.dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:buildtrack_app/core/services/auth_service.dart';
import 'package:buildtrack_app/models/user_model.dart';
import 'auth_service_test.mocks.dart';

// Note: Pour Mockito 5.4.5, on utilise @GenerateMocks avec la liste des classes
@GenerateMocks([
  FirebaseAuth,
  UserCredential,
  User,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  FirebaseFirestore,
  DocumentReference,
  DocumentSnapshot,
  CollectionReference,
])
void main() {
  late AuthService authService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockFirebaseFirestore mockFirestore;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;
  late MockGoogleSignInAccount mockGoogleSignInAccount;
  late MockGoogleSignInAuthentication mockGoogleSignInAuthentication;
  late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;
  late MockDocumentReference<Map<String, dynamic>> mockDocRef;
  late MockCollectionReference<Map<String, dynamic>> mockCollectionRef;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();
    mockGoogleSignInAccount = MockGoogleSignInAccount();
    mockGoogleSignInAuthentication = MockGoogleSignInAuthentication();
    mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    mockDocRef = MockDocumentReference<Map<String, dynamic>>();
    mockCollectionRef = MockCollectionReference<Map<String, dynamic>>();

    authService = AuthService(
      auth: mockFirebaseAuth,
      firestore: mockFirestore,
      googleSignIn: mockGoogleSignIn,
    );
  });

  // Helper function to setup common mocks
  void _setupCommonMocks({required String userId, required String email}) {
    // Mock user
    when(mockUser.uid).thenReturn(userId);
    when(mockUser.email).thenReturn(email);
    when(mockUser.displayName).thenReturn('Test User');
    when(mockUser.photoURL).thenReturn(null);
    when(mockUser.phoneNumber).thenReturn(null);
    when(mockUserCredential.user).thenReturn(mockUser);

    // Mock firestore collection
    when(mockFirestore.collection('employees')).thenReturn(mockCollectionRef);
    when(mockCollectionRef.doc(userId)).thenReturn(mockDocRef);
    when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
  }

  group('AuthService Tests', () {
    test('signInWithEmail returns Employee on success', () async {
      // Setup
      _setupCommonMocks(userId: '123', email: 'test@example.com');

      // Mock FirebaseAuth sign in
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      // Mock Firestore document data with ALL required fields
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.data()).thenReturn({
        'id': '123',
        'firstName': 'John',
        'lastName': 'Doe',
        'email': 'test@example.com',
        'phone': '+1234567890',
        'role': 'employee',
        'createdAt': Timestamp.now(),
      });

      // Act
      final employee = await authService.signInWithEmail('test@example.com', 'password');

      // Assert
      expect(employee, isA<Employee>());
      expect(employee!.id, '123');
      expect(employee.email, 'test@example.com');
      expect(employee.firstName, 'John');
      expect(employee.lastName, 'Doe');
      expect(employee.role, UserRole.employee);

      // Verify interactions
      verify(mockFirebaseAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password',
      )).called(1);
      verify(mockFirestore.collection('employees')).called(1);
      verify(mockCollectionRef.doc('123')).called(1);
      verify(mockDocRef.get()).called(1);
    });

    test('signInWithEmail throws error on failure', () async {
      // Setup
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(
        code: 'wrong-password',
        message: 'Wrong password',
      ));

      // Act & Assert
      expect(
            () => authService.signInWithEmail('test@example.com', 'wrong'),
        throwsA(isA<String>()),
      );

      // Verify
      verify(mockFirebaseAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'wrong',
      )).called(1);
      verifyNever(mockFirestore.collection('employees'));
    });

    test('signInWithGoogle returns Employee on success', () async {
      // Setup
      _setupCommonMocks(userId: '456', email: 'google@example.com');

      // Mock GoogleSignIn
      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleSignInAccount);
      when(mockGoogleSignInAccount.email).thenReturn('google@example.com');
      when(mockGoogleSignInAccount.displayName).thenReturn('Google User');
      when(mockGoogleSignInAccount.authentication).thenAnswer((_) async => mockGoogleSignInAuthentication);
      when(mockGoogleSignInAuthentication.idToken).thenReturn('idToken');
      when(mockGoogleSignInAuthentication.accessToken).thenReturn('accessToken');

      // Mock FirebaseAuth credential
      when(mockFirebaseAuth.signInWithCredential(any)).thenAnswer((_) async => mockUserCredential);

      // Mock Firestore document data
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.data()).thenReturn({
        'id': '456',
        'firstName': 'Google',
        'lastName': 'User',
        'email': 'google@example.com',
        'phone': '+0987654321',
        'role': 'employee',
        'createdAt': Timestamp.now(),
        'photoUrl': 'https://example.com/photo.jpg',
      });

      // Act
      final employee = await authService.signInWithGoogle();

      // Assert
      expect(employee, isA<Employee>());
      expect(employee!.id, '456');
      expect(employee.email, 'google@example.com');
      expect(employee.firstName, 'Google');
      expect(employee.lastName, 'User');
      expect(employee.photoUrl, 'https://example.com/photo.jpg');

      // Verify interactions
      verify(mockGoogleSignIn.signIn()).called(1);
      verify(mockFirebaseAuth.signInWithCredential(any)).called(1);
      verify(mockFirestore.collection('employees')).called(1);
      verify(mockCollectionRef.doc('456')).called(1);
      verify(mockDocRef.get()).called(1);
    });

    test('signInWithGoogle returns null when user cancels', () async {
      // Setup
      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

      // Act & Assert
      await expectLater(
        authService.signInWithGoogle(),
        throwsA('Connexion Google annulée par l\'utilisateur'),
      );

      verify(mockGoogleSignIn.signIn()).called(1);
      verifyNever(mockFirebaseAuth.signInWithCredential(any));
    });

    test('signUpEmployee creates and returns Employee', () async {
      // Setup
      when(mockUser.uid).thenReturn('789');
      when(mockUser.email).thenReturn('new@example.com');
      when(mockUser.displayName).thenReturn('New User');
      when(mockUserCredential.user).thenReturn(mockUser);

      // Mock FirebaseAuth
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      // Mock Firestore
      when(mockFirestore.collection('employees')).thenReturn(mockCollectionRef);
      when(mockCollectionRef.doc('789')).thenReturn(mockDocRef);
      when(mockDocRef.set(any)).thenAnswer((_) async => Future.value());

      // Act
      final employee = await authService.signUpEmployee(
        email: 'new@example.com',
        password: 'password',
        firstName: 'New',
        lastName: 'User',
        phone: '123456789',
      );

      // Assert
      expect(employee, isA<Employee>());
      expect(employee!.id, '789');
      expect(employee.email, 'new@example.com');
      expect(employee.firstName, 'New');
      expect(employee.lastName, 'User');
      expect(employee.phone, '123456789');
      expect(employee.role, UserRole.employee);

      // Verify
      verify(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: 'new@example.com',
        password: 'password',
      )).called(1);

      verify(mockFirestore.collection('employees')).called(1);
      verify(mockCollectionRef.doc('789')).called(1);

      // Verify the data saved to Firestore
      final capturedData = verify(mockDocRef.set(captureAny)).captured.first;
      expect(capturedData['id'], '789');
      expect(capturedData['email'], 'new@example.com');
      expect(capturedData['firstName'], 'New');
      expect(capturedData['lastName'], 'User');
      expect(capturedData['phone'], '123456789');
      expect(capturedData['role'], 'employee');
      expect(capturedData['createdAt'], isA<Timestamp>());
    });

    test('signOut completes successfully', () async {
      // Setup
      when(mockGoogleSignIn.signOut()).thenAnswer((_) async => Future.value());
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async => Future.value());

      // Act
      await authService.signOut();

      // Assert
      verify(mockGoogleSignIn.signOut()).called(1);
      verify(mockFirebaseAuth.signOut()).called(1);
    });

    test('handleAuthError returns correct error message for FirebaseAuthException', () {
      // Test user-not-found
      expect(
        authService.handleAuthError(FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found',
        )),
        'Aucun compte trouvé avec cet email. Créez un compte ou vérifiez votre email.',
      );

      // Test wrong-password
      expect(
        authService.handleAuthError(FirebaseAuthException(
          code: 'wrong-password',
          message: 'Wrong password',
        )),
        'Email ou mot de passe incorrect. Veuillez réessayer.',
      );

      // Test email-already-in-use
      expect(
        authService.handleAuthError(FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Email already in use',
        )),
        'Un compte existe déjà avec cet email. Connectez-vous ou utilisez un autre email.',
      );

      // Test weak-password
      expect(
        authService.handleAuthError(FirebaseAuthException(
          code: 'weak-password',
          message: 'Weak password',
        )),
        'Le mot de passe est trop faible. Utilisez au moins 6 caractères.',
      );

      // Test invalid-email
      expect(
        authService.handleAuthError(FirebaseAuthException(
          code: 'invalid-email',
          message: 'Invalid email',
        )),
        'Format d\'email invalide. Vérifiez votre saisie.',
      );

      // Test unknown Firebase error
      expect(
        authService.handleAuthError(FirebaseAuthException(
          code: 'unknown-error',
          message: 'Some error',
        )),
        'Erreur de connexion: Some error',
      );
    });

    test('handleAuthError returns correct error message for generic Exception', () {
      expect(
        authService.handleAuthError(Exception('Unknown error')),
        'Unknown error',
      );

      expect(
        authService.handleAuthError('Some string error'),
        'Une erreur inattendue s\'est produite. Veuillez réessayer.',
      );
    });

    test('getCurrentUser returns null if no user is logged in', () {
      // Setup
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      // Act & Assert
      expect(authService.getCurrentUser(), null);
    });

    test('getCurrentUser returns Employee if user is logged in', () {
      // Setup
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('123');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.displayName).thenReturn('John Doe');
      when(mockUser.phoneNumber).thenReturn('+1234567890');
      when(mockUser.photoURL).thenReturn('https://example.com/photo.jpg');

      // Act
      final employee = authService.getCurrentUser();

      // Assert
      expect(employee, isA<Employee>());
      expect(employee!.id, '123');
      expect(employee.email, 'test@example.com');
      expect(employee.firstName, 'John');
      expect(employee.lastName, 'Doe');
      expect(employee.role, UserRole.employee);
    });

    test('isUserLoggedIn returns false if no user is logged in', () {
      // Setup
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      // Act & Assert
      expect(authService.isUserLoggedIn(), false);
    });

    test('isUserLoggedIn returns true if user is logged in', () {
      // Setup
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);

      // Act & Assert
      expect(authService.isUserLoggedIn(), true);
    });

    test('getEmployeeData returns Employee when found', () async {
      // Setup
      final mockEmployeeDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockEmployeeDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('employees')).thenReturn(mockCollectionRef);
      when(mockCollectionRef.doc('123')).thenReturn(mockEmployeeDocRef);
      when(mockEmployeeDocRef.get()).thenAnswer((_) async => mockEmployeeDocSnapshot);
      when(mockEmployeeDocSnapshot.exists).thenReturn(true);
      when(mockEmployeeDocSnapshot.data()).thenReturn({
        'id': '123',
        'firstName': 'John',
        'lastName': 'Doe',
        'email': 'john@example.com',
        'phone': '+1234567890',
        'role': 'employee',
        'createdAt': Timestamp.now(),
      });

      // Act
      final employee = await authService.getEmployeeData('123');

      // Assert
      expect(employee, isA<Employee>());
      expect(employee!.id, '123');
      expect(employee.firstName, 'John');
      expect(employee.email, 'john@example.com');
    });

    test('getEmployeeData returns null when not found', () async {
      // Setup
      final mockEmployeeDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockEmployeeDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('employees')).thenReturn(mockCollectionRef);
      when(mockCollectionRef.doc('999')).thenReturn(mockEmployeeDocRef);
      when(mockEmployeeDocRef.get()).thenAnswer((_) async => mockEmployeeDocSnapshot);
      when(mockEmployeeDocSnapshot.exists).thenReturn(false);

      // Act
      final employee = await authService.getEmployeeData('999');

      // Assert
      expect(employee, null);
    });

    test('updateEmployeeProfile updates employee data successfully', () async {
      // Setup
      final mockEmployeeDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockFirestore.collection('employees')).thenReturn(mockCollectionRef);
      when(mockCollectionRef.doc('123')).thenReturn(mockEmployeeDocRef);
      when(mockEmployeeDocRef.update(any)).thenAnswer((_) async => Future.value());

      // Act
      await authService.updateEmployeeProfile(
        employeeId: '123',
        firstName: 'Updated',
        lastName: 'Name',
        phone: '+9876543210',
      );

      // Assert
      verify(mockFirestore.collection('employees')).called(1);
      verify(mockCollectionRef.doc('123')).called(1);

      final capturedUpdate = verify(mockEmployeeDocRef.update(captureAny)).captured.first;
      expect(capturedUpdate['firstName'], 'Updated');
      expect(capturedUpdate['lastName'], 'Name');
      expect(capturedUpdate['phone'], '+9876543210');
      expect(capturedUpdate.containsKey('updatedAt'), true);
    });

    test('userStream emits null when user signs out', () async {
      // Setup
      final StreamController<User?> authStateController = StreamController<User?>();
      when(mockFirebaseAuth.authStateChanges()).thenAnswer((_) => authStateController.stream);

      // Listen to the stream
      final streamValues = <Employee?>[];
      final subscription = authService.userStream.listen(streamValues.add);

      // Act - Emit null (user signed out)
      authStateController.add(null);
      await Future.delayed(Duration.zero); // Allow stream to process

      // Cleanup
      await subscription.cancel();
      await authStateController.close();

      // Assert
      expect(streamValues, [null]);
    });

    test('userStream emits Employee when user signs in', () async {
      // Setup
      final StreamController<User?> authStateController = StreamController<User?>();
      when(mockFirebaseAuth.authStateChanges()).thenAnswer((_) => authStateController.stream);

      // Mock user and firestore data
      final mockStreamUser = MockUser();
      when(mockStreamUser.uid).thenReturn('stream-123');
      when(mockStreamUser.email).thenReturn('stream@example.com');
      when(mockStreamUser.displayName).thenReturn('Stream User');

      // Mock firestore response
      final mockStreamDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockStreamDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockFirestore.collection('employees')).thenReturn(mockCollectionRef);
      when(mockCollectionRef.doc('stream-123')).thenReturn(mockStreamDocRef);
      when(mockStreamDocRef.get()).thenAnswer((_) async => mockStreamDocSnapshot);
      when(mockStreamDocSnapshot.exists).thenReturn(true);
      when(mockStreamDocSnapshot.data()).thenReturn({
        'id': 'stream-123',
        'firstName': 'Stream',
        'lastName': 'User',
        'email': 'stream@example.com',
        'phone': '+1234567890',
        'role': 'employee',
        'createdAt': Timestamp.now(),
      });

      // Listen to the stream
      final streamValues = <Employee?>[];
      final subscription = authService.userStream.listen(streamValues.add);

      // Act - Emit user (user signed in)
      authStateController.add(mockStreamUser);
      await Future.delayed(Duration(milliseconds: 100)); // Allow async processing

      // Cleanup
      await subscription.cancel();
      await authStateController.close();

      // Assert
      expect(streamValues.length, 1);
      expect(streamValues[0], isA<Employee>());
      expect(streamValues[0]!.id, 'stream-123');
      expect(streamValues[0]!.email, 'stream@example.com');
    });

    test('AuthService constructor accepts mock dependencies', () {
      // Ce test vérifie que le constructeur accepte les dépendances mockées
      // ce qui est essentiel pour les tests unitaires

      // Act
      final authService = AuthService(
        auth: mockFirebaseAuth,
        firestore: mockFirestore,
        googleSignIn: mockGoogleSignIn,
      );

      // Assert
      expect(authService, isA<AuthService>());

      // Vérification supplémentaire : les setters sont disponibles
      expect(() {
        authService.setFirebaseAuth = MockFirebaseAuth();
        authService.setFirestore = MockFirebaseFirestore();
        authService.setGoogleSignIn = MockGoogleSignIn();
      }, returnsNormally);
    });
  });
}