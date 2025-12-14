import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/task_service.dart';
import '../../../core/services/project_service.dart';
import '../../../core/services/attendance_service.dart';
import '../../../models/project_model.dart';
import '../../../models/task_model.dart';
import '../../../models/user_model.dart'; // Import pour Employee
import '../../profile/screen/employee_profile_screen.dart';
import '../widgets/project_card.dart';
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
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final taskService = Provider.of<TaskService>(context);
    final projectService = Provider.of<ProjectService>(context);
    final attendanceService = Provider.of<AttendanceService>(context);

    // On écoute le Stream pour avoir les mises à jour en temps réel (scan)
    return StreamBuilder<Employee?>(
        stream: authService.userStream,
        builder: (context, snapshot) {
          final employee = snapshot.data;
          if (employee == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

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

            // On passe l'employé au body pour savoir s'il est pointé
            body: _buildBody(
                index: _currentIndex,
                employee: employee,
                taskService: taskService,
                projectService: projectService,
                attendanceService: attendanceService
            ),

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
    );
  }

  Widget _buildBody({
    required int index,
    required Employee employee,
    required TaskService taskService,
    required ProjectService projectService,
    required AttendanceService attendanceService,
  }) {
    switch (index) {
      case 0: return _buildProjectsList(projectService, employee.id);
    // Onglet Scan Intelligent
      case 1: return _buildScanTab(context, employee);
      case 2: return _buildStatsTab(employee.id, taskService, attendanceService);
      default: return const Center(child: Text("Erreur"));
    }
  }

  // Onglet Chantiers (inchangé)
  Widget _buildProjectsList(ProjectService projectService, String employeeId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Mes Chantiers',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Project>>(
            stream: projectService.getAssignedProjectsStream(employeeId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final projects = snapshot.data ?? [];
              if (projects.isEmpty) return const Center(child: Text("Aucun chantier assigné."));

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

  // 🔥 ONGLET SCANNER INTELLIGENT 🔥
  Widget _buildScanTab(BuildContext context, Employee employee) {
    // Vérification : L'employé est-il actuellement pointé quelque part ?
    final isCheckedIn = employee.currentProjectId != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
              isCheckedIn ? Icons.timelapse : Icons.qr_code_2,
              size: 120,
              color: isCheckedIn ? Colors.orange.withOpacity(0.5) : Theme.of(context).primaryColor.withOpacity(0.2)
          ),
          const SizedBox(height: 30),

          Text(
            isCheckedIn ? 'En cours : ${employee.currentProjectName}' : 'Pointage Rapide',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          Text(
            isCheckedIn ? 'Scannez le code pour sortir.' : 'Scannez pour commencer.',
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: 250,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                // Couleur change selon l'état : Bleu si entrée, Orange si sortie
                backgroundColor: isCheckedIn ? Colors.orange : Theme.of(context).primaryColor,
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen())),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isCheckedIn ? Icons.logout : Icons.camera_alt),
                  const SizedBox(width: 10),
                  Text(isCheckedIn ? 'SCANNER SORTIE' : 'SCANNER ENTRÉE', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Onglet Stats (inchangé)
  Widget _buildStatsTab(String employeeId, TaskService taskService, AttendanceService attendanceService) {
    // (Copier ton code _buildStatsTab existant ici, il ne change pas)
    // Pour gagner de la place, je mets juste un placeholder fonctionnel, remets ton code Stats ici
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tableau de Bord', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
          const SizedBox(height: 24),
          // ... Ton code de stats existant ...
          const Text("Vos statistiques s'afficheront ici."),
        ],
      ),
    );
  }
}