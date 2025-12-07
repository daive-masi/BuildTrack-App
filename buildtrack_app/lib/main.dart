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
import 'core/services/project_service.dart'; // 🆕 Import du service projet
import 'core/auth_wrapper.dart';

// 🎨 LE BLEU NUIT DE TON IMAGE
const Color kMidnightBlue = Color(0xFF0B2545);
const Color kLightBackground = Color(0xFFF8F9FB);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
        // ⭐ AJOUT DU PROJECT SERVICE ICI
        ChangeNotifierProvider<ProjectService>(create: (_) => ProjectService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'BuildTrack',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: kLightBackground,

          primaryColor: kMidnightBlue,
          colorScheme: ColorScheme.fromSeed(
            seedColor: kMidnightBlue,
            primary: kMidnightBlue,
            surface: Colors.white,
          ),

          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: kMidnightBlue,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: kMidnightBlue,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),

          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: kMidnightBlue,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white54,
            type: BottomNavigationBarType.fixed,
            elevation: 10,
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kMidnightBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
          ),

          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: kMidnightBlue,
            foregroundColor: Colors.white,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}