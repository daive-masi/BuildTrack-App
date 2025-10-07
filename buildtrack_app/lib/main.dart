import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'core/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const BuildTrackApp());
}

class BuildTrackApp extends StatelessWidget {
  const BuildTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuildTrack',
      home: Scaffold(
        appBar: AppBar(title: const Text('BuildTrack Test')),
        body: const Center(child: FirebaseTestWidget()),
      ),
    );
  }
}

class FirebaseTestWidget extends StatefulWidget {
  const FirebaseTestWidget({super.key});

  @override
  State<FirebaseTestWidget> createState() => _FirebaseTestWidgetState();
}

class _FirebaseTestWidgetState extends State<FirebaseTestWidget> {
  String message = "Connexion Firebase en cours...";

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }

  Future<void> _testFirebaseConnection() async {
    try {
      // Test simple : écrire dans Firestore
      final db = FirebaseFirestore.instance;
      await db.collection('tests').add({'timestamp': DateTime.now()});
      setState(() {
        message = "✅ Connexion Firebase réussie !";
      });
    } catch (e) {
      setState(() {
        message = "❌ Erreur Firebase : $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(message, style: const TextStyle(fontSize: 18));
  }
}
