// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'core/firebase_config.dart';
import 'core/services/auth_service.dart';
import 'core/services/qr_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/task_service.dart';
import 'core/services/attendance_service.dart';
import 'core/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const BuildTrackApp());
}

class BuildTrackApp extends StatelessWidget {
  const BuildTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ⭐⭐ VERSION CORRECTE AVEC CHANGENOTIFIER ⭐⭐
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<QrService>(
          create: (_) => QrService(),
        ),
        ChangeNotifierProvider<TaskService>(
          create: (_) => TaskService(),
        ),
        ChangeNotifierProvider<AttendanceService>(
          create: (_) => AttendanceService(),
        ),
        Provider<StorageService>(
            create: (_) => StorageService()),
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
        // ⭐⭐ OPTIONNEL: Si tu veux utiliser les routes nommées plus tard ⭐⭐
        // onGenerateRoute: AppRouter.generateRoute,
        // initialRoute: '/',
        // routes: {
        //   '/': (context) => const AuthWrapper(),
        //   '/dashboard': (context) => const EmployeeDashboard(),
        //   '/qr-scanner': (context) => const QrScannerScreen(),
        // },
      ),
    );
  }
}
