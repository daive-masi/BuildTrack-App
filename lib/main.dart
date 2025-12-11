import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // N'oublie pas d'ajouter flutter_localizations dans pubspec.yaml
import 'package:intl/date_symbol_data_local.dart';

import 'core/firebase_config.dart';
import 'core/services/auth_service.dart';
import 'core/services/qr_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/task_service.dart';
import 'core/services/attendance_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/project_service.dart';
import 'core/auth_wrapper.dart';

// 🎨 LE BLEU NUIT DE TON IMAGE
const Color kMidnightBlue = Color(0xFF0B2545);
const Color kLightBackground = Color(0xFFF8F9FB);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}


// --- CLASSE POUR GÉRER LA LANGUE ---
class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('fr', 'FR');

  Locale get currentLocale => _currentLocale;

  void changeLocale(Locale newLocale) {
    _currentLocale = newLocale;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final notificationService = NotificationService();
  await notificationService.initNotifications();

  // Initialise les formats de date pour toutes les langues possibles
  await initializeDateFormatting();

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
        ChangeNotifierProvider<ProjectService>(create: (_) => ProjectService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        // Nouveau Provider pour la langue
        ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
      ],
      // On utilise Consumer pour reconstruire l'app quand la langue change
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'BuildTrack',
            debugShowCheckedModeBanner: false,

            // --- CONFIGURATION LANGUE ---
            locale: languageProvider.currentLocale,
            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('en', 'US'),
              Locale('sq', 'AL'), // Albanais
              Locale('sr', 'RS'), // Serbe
              Locale('ro', 'RO'), // Roumain
              Locale('ro', 'MD'), // Moldave (souvent identique au Roumain techniquement)
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

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
          );
        },
      ),
    );
  }
}