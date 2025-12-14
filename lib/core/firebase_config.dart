import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart'; // généré automatiquement

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
