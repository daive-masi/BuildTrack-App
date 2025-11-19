// navigation/app_router.dart
import 'package:flutter/material.dart';
import '../features/auth/screens/employee_login_screen.dart';
import '../features/employee/screens/employee_dashboard.dart';
import '../features/qr_scanner/screens/qr_scanner_screen.dart';


class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const EmployeeLoginScreen());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const EmployeeDashboard());
      case '/qr-scanner':  // ⭐⭐ AJOUTEZ CETTE ROUTE ⭐⭐
        return MaterialPageRoute(builder: (_) => const QrScannerScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route non trouvée: ${settings.name}'),
            ),
          ),
        );
    }
  }
}