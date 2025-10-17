import 'package:flutter/material.dart';
import '../features/auth/screens/employee_login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/employee/screens/employee_dashboard.dart';
import '../features/qr_scanner/sreens/qr_scanner_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const EmployeeLoginScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const EmployeeLoginScreen());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case '/employee-dashboard':
        return MaterialPageRoute(builder: (_) => const EmployeeDashboard());
      case '/qr-scanner':
        return MaterialPageRoute(builder: (_) => const QrScannerScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Erreur')),
            body: Center(
              child: Text('Page non trouvée: ${settings.name}'),
            ),
          ),
        );
    }
  }
}