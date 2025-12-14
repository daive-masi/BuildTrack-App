import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';
import '../features/auth/screens/employee_login_screen.dart';
import '../features/employee/screens/employee_dashboard.dart';
import '../models/user_model.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<Employee?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        // État de chargement initial
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement...', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        }

        // Erreur de stream
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Erreur de chargement', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        final employee = snapshot.data;

        if (employee != null) {
          print('✅ Utilisateur connecté: ${employee.email}');
          return const EmployeeDashboard();
        } else {
          print('🔒 Utilisateur non connecté - Affichage login');
          return const EmployeeLoginScreen();
        }
      },
    );
  }
}