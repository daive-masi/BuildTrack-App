import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/firebase_config.dart';
import 'core/services/auth_service.dart';
import 'core/auth_wrapper.dart'; // AJOUTEZ CET IMPORT

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
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        title: 'BuildTrack',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const AuthWrapper(), // REMPLACEZ LA NAVIGATION ICI
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}