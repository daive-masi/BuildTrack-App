import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';
import '../core/services/project_service.dart'; // Import nécessaire pour le seed
import '../features/auth/screens/employee_login_screen.dart';
import '../features/employee/screens/employee_dashboard.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../models/user_model.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<Employee?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        // 1. Chargement
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

        // 2. Erreur
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Erreur: ${snapshot.error}")));
        }

        final employee = snapshot.data;

        // 3. Utilisateur Connecté
        if (employee != null) {

          // 🔥 AUTOMATISATION : On tente de remplir la base si elle est vide
          // On utilise addPostFrameCallback pour ne pas bloquer l'affichage
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<ProjectService>(context, listen: false).seedDatabase();
          });

          // Redirection selon le rôle
          if (employee.role == UserRole.admin) {
            print('👑 Admin connecté -> Dashboard Web');
            return const AdminDashboardScreen();
          } else {
            print('👷 Employé connecté -> Dashboard Mobile');
            return const EmployeeDashboard();
          }
        }

        // 4. Pas connecté
        else {
          return const EmployeeLoginScreen();
        }
      },
    );
  }
}