import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/firebase_config.dart';
import 'core/services/auth_service.dart';
import 'core/services/qr_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/task_service.dart';
import 'core/services/attendance_service.dart';
import 'core/services/notification_service.dart';
import 'core/auth_wrapper.dart';

/// 🔔 Gestion des messages quand l'app est fermée
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Tu peux ajouter un print ici pour tester :
  print('Message reçu en background: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialisation notifications locales
  final notificationService = NotificationService();
  await notificationService.initNotifications();

  runApp(const BuildTrackApp());
}

class BuildTrackApp extends StatelessWidget {
  const BuildTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<QrService>(create: (_) => QrService()),
        ChangeNotifierProvider<TaskService>(create: (_) => TaskService()),
        ChangeNotifierProvider<AttendanceService>(create: (_) => AttendanceService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'BuildTrack',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
