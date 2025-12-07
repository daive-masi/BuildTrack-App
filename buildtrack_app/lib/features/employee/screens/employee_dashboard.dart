import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/task_service.dart';
import '../../../core/services/project_service.dart'; // Import du service projet
import '../../../models/project_model.dart';
import '../../../models/task_model.dart';
import '../../profile/screen/employee_profile_screen.dart';
import '../widgets/project_card.dart'; // Carte chantier
import '../../qr_scanner/screens/qr_scanner_screen.dart';
import '../widgets/task_stats_widgets.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // On garde l'injection de tâches pour le test
      final taskService = Provider.of<TaskService>(context, listen: false);
      final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
      if (currentUser != null) {
        taskService.injectSampleTasks(currentUser.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final taskService = Provider.of<TaskService>(context);
    final projectService = Provider.of<ProjectService>(context); // Accès au ProjectService
    final employeeId = authService.currentUser?.uid;

    if (employeeId == null) {
      return const Scaffold(body: Center(child: Text('Utilisateur non connecté')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BuildTrack'),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.notifications_none, size: 28),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aucune notification")));
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.account_circle_outlined, size: 28),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()));
              },
            ),
          ),
        ],
      ),

      body: _buildBody(_currentIndex, employeeId, taskService, projectService),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Theme.of(context).primaryColor,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white54,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.apartment, size: 28), label: 'Chantiers'),
              BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner, size: 28), label: 'Scanner'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart, size: 28), label: 'Stats'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(int index, String employeeId, TaskService taskService, ProjectService projectService) {
    switch (index) {
      case 0: return _buildProjectsList(projectService); // Vue Chantiers
      case 1: return _buildScanTab(context);
      case 2: return _buildStatsTab(employeeId, taskService);
      default: return const Center(child: Text("Erreur"));
    }
  }

  // --- VUE 1 : LISTE DES CHANTIERS (Accueil) ---
  Widget _buildProjectsList(ProjectService projectService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Mes Chantiers',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Project>>(
            future: projectService.getProjects(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final projects = snapshot.data ?? [];

              if (projects.isEmpty) {
                return const Center(child: Text("Aucun chantier affecté"));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  return ProjectCard(project: projects[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- VUE 2 : SCANNER ---
  Widget _buildScanTab(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2, size: 120, color: Theme.of(context).primaryColor.withOpacity(0.2)),
          const SizedBox(height: 30),
          const Text('Pointage Rapide', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Scannez un code QR pour vous localiser', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),
          SizedBox(
            width: 250,
            height: 55,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen())),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 10),
                  Text('SCANNER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- VUE 3 : STATS ---
  Widget _buildStatsTab(String employeeId, TaskService taskService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mes Performances', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
          const SizedBox(height: 20),
          StreamBuilder<List<ProjectTask>>(
            stream: taskService.getEmployeeTasks(employeeId),
            builder: (context, snapshot) {
              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) return const Text("Pas de données");
              return Column(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text("Répartition globale", style: TextStyle(fontWeight: FontWeight.bold)),
                          TaskPieChart(tasks: tasks),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text("État par statut", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          TaskBarChart(tasks: tasks),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}