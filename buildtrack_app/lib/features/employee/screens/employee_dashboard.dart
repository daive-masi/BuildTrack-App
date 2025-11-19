// features/employee/screens/employee_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/task_service.dart';
import '../../../core/services/attendance_service.dart';
import '../../../models/task_model.dart';
import '../../history/screen/attendance_history_screen.dart';
import '../../profile/screen/employee_profile_screen.dart';
import '../widgets/task_cart.dart';
import '../../qr_scanner/screens/qr_scanner_screen.dart';

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
    // Appel à l'injecteur de tâches après un court délai pour s'assurer que le contexte est prêt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskService = Provider.of<TaskService>(context, listen: false);
      final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
      if (currentUser != null) {
        taskService.injectSampleTasks(currentUser.uid); // Injection des tâches d'exemple
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final taskService = Provider.of<TaskService>(context);
    final attendanceService = Provider.of<AttendanceService>(context);
    final currentUser = authService.currentUser;
    final employeeId = currentUser?.uid;

    if (employeeId == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Espace'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmployeeProfileScreen(),
                  ),
                );
              } else if (value == 'logout') {
                _showLogoutDialog(context, authService);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 8),
                    Text('Mon profil'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Déconnexion', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildDashboardContent(context, employeeId, taskService, attendanceService),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AttendanceHistoryScreen(),
              ),
            ).then((_) {
              setState(() {
                _currentIndex = 0;
              });
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context, attendanceService, employeeId),
    );
  }

  Widget _buildDashboardContent(BuildContext context, String employeeId, TaskService taskService, AttendanceService attendanceService) {
    return Column(
      children: [
        // Carte chantier actuel
        StreamBuilder<Map<String, dynamic>?>(
          stream: attendanceService.getCurrentProject(employeeId),
          builder: (context, snapshot) {
            final currentProject = snapshot.data;
            return Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chantier actuel', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    if (currentProject != null) ...[
                      Text(
                        currentProject['projectName'] ?? 'Chantier inconnu',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      _buildProjectStatus(currentProject),
                      const SizedBox(height: 16),
                      _buildCheckOutButton(context, attendanceService, employeeId),
                    ] else ...[
                      const Text(
                        'Aucun chantier actif',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scannez un QR code pour pointer',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const QrScannerScreen()),
                          );
                        },
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Scanner QR Code'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),

        // ⭐ NOUVEAU: Statistiques des tâches
        StreamBuilder<List<ProjectTask>>(
          stream: taskService.getEmployeeTasks(employeeId),
          builder: (context, snapshot) {
            final tasks = snapshot.data ?? [];
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "Statistiques de mes tâches",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (tasks.isNotEmpty)
                        TaskStatsChart(tasks: tasks)
                      else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              "Aucune donnée disponible pour les statistiques",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // En-tête tâches
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Mes tâches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              StreamBuilder<List<ProjectTask>>(
                stream: taskService.getEmployeeTasks(employeeId),
                builder: (context, snapshot) {
                  final taskCount = snapshot.data?.length ?? 0;
                  return Chip(
                    label: Text('$taskCount tâche${taskCount > 1 ? 's' : ''}'),
                    backgroundColor: Colors.blue[50],
                  );
                },
              ),
            ],
          ),
        ),

        // Liste des tâches
        Expanded(
          child: StreamBuilder<List<ProjectTask>>(
            stream: taskService.getEmployeeTasks(employeeId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }
              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucune tâche assignée', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return TaskCard(
                    task: task,
                    onStatusChanged: (newStatus) async {
                      try {
                        await taskService.updateTaskStatus(task.id, newStatus);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tâche ${task.title} mise à jour')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e')),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ... (le reste des méthodes reste inchangé)
  Widget _buildFloatingActionButton(BuildContext context, AttendanceService attendanceService, String employeeId) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: attendanceService.getCurrentProject(employeeId),
      builder: (context, snapshot) {
        final isOnSite = snapshot.data != null;
        return FloatingActionButton(
          onPressed: () {
            if (isOnSite) {
              _showAlreadyOnSiteDialog(context);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QrScannerScreen()),
              );
            }
          },
          backgroundColor: isOnSite ? Colors.green : Colors.blue[700],
          child: Icon(
            isOnSite ? Icons.check : Icons.qr_code_scanner,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildProjectStatus(Map<String, dynamic> project) {
    final lastCheckIn = project['lastCheckIn'] as DateTime?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, size: 16, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Pointé depuis',
              style: TextStyle(fontSize: 14, color: Colors.green[700]),
            ),
          ],
        ),
        if (lastCheckIn != null) ...[
          const SizedBox(height: 4),
          Text(
            '${lastCheckIn.hour.toString().padLeft(2, '0')}:${lastCheckIn.minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckOutButton(BuildContext context, AttendanceService attendanceService, String employeeId) {
    return OutlinedButton.icon(
      onPressed: () async {
        try {
          await attendanceService.checkOutFromProject(employeeId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pointage de sortie réussi')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      },
      icon: const Icon(Icons.logout, size: 16),
      label: const Text('Pointer la sortie'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
      ),
    );
  }

  void _showAlreadyOnSiteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('Déjà sur site'),
          ],
        ),
        content: const Text('Vous êtes déjà pointé sur un chantier. '
            'Veuillez pointer la sortie avant de scanner un nouveau QR code.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await authService.signOut();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur de déconnexion: $e')),
                  );
                }
              },
              child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

// Widget pour afficher les statistiques des tâches sous forme de graphique
class TaskStatsChart extends StatelessWidget {
  final List<ProjectTask> tasks;

  const TaskStatsChart({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    // Compter le nombre de tâches par statut
    final pendingTasks = tasks.where((task) => task.status == TaskStatus.pending).length;
    final inProgressTasks = tasks.where((task) => task.status == TaskStatus.inProgress).length;
    final completedTasks = tasks.where((task) => task.status == TaskStatus.completed).length;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: tasks.length.toDouble(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0: return const Text('En attente');
                    case 1: return const Text('En cours');
                    case 2: return const Text('Terminées');
                    default: return const Text('');
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString());
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          groupsSpace: 4,
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: pendingTasks.toDouble(),
                  color: Colors.orange,
                  width: 16,
                  borderRadius: BorderRadius.zero,
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: inProgressTasks.toDouble(),
                  color: Colors.blue,
                  width: 16,
                  borderRadius: BorderRadius.zero,
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: completedTasks.toDouble(),
                  color: Colors.green,
                  width: 16,
                  borderRadius: BorderRadius.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
