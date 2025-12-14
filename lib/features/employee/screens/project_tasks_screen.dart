import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/task_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/attendance_service.dart'; // Pour la sortie
import '../../../models/project_model.dart';
import '../../../models/task_model.dart';
import '../../../models/user_model.dart';
import '../widgets/task_card.dart';
import 'add_task_screen.dart';
import '../../qr_scanner/screens/qr_scanner_screen.dart';

class ProjectTasksScreen extends StatelessWidget {
  final Project project;

  const ProjectTasksScreen({super.key, required this.project});

  void _launchURL(String url, BuildContext context) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  void _showProjectInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Infos Chantier", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
            const SizedBox(height: 20),
            Text(project.description),
            const SizedBox(height: 20),
            ListTile(leading: const Icon(Icons.map), title: const Text("Adresse"), subtitle: Text(project.address), onTap: () => _launchURL("geo:0,0?q=${Uri.encodeComponent(project.address)}", context)),
            ListTile(leading: const Icon(Icons.phone), title: const Text("Chef"), subtitle: Text(project.projectManagerPhone), onTap: () => _launchURL("tel:${project.projectManagerPhone}", context)),
          ],
        ),
      ),
    );
  }

  // Fonction de sortie directe depuis l'écran
  Future<void> _handleDirectCheckout(BuildContext context, String employeeId) async {
    final attendanceService = Provider.of<AttendanceService>(context, listen: false);
    try {
      await attendanceService.checkOutFromProject(employeeId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sortie enregistrée. Fin de journée.")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur sortie: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TaskService>(context);
    final authService = Provider.of<AuthService>(context);
    // On ajoute AttendanceService pour pouvoir sortir
    final attendanceService = Provider.of<AttendanceService>(context, listen: false);
    final primaryColor = Theme.of(context).primaryColor;

    return StreamBuilder<Employee?>(
        stream: authService.userStream, // Écoute temps réel
        builder: (context, userSnapshot) {
          final employee = userSnapshot.data;

          // Vérification si on est pointé SUR CE chantier précis
          final isCheckedInOnSite = employee?.currentProjectId == project.id;
          // Vérification si on est pointé AILLEURS (pour bloquer ou informer)
          final isCheckedInElsewhere = employee?.currentProjectId != null && !isCheckedInOnSite;

          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FB),
            appBar: AppBar(
              title: Text(project.name),
              backgroundColor: Colors.transparent,
              foregroundColor: primaryColor,
              elevation: 0,
              actions: [
                IconButton(icon: const Icon(Icons.info_outline), onPressed: () => _showProjectInfo(context)),
              ],
            ),
            body: Column(
              children: [
                // BANDEAU D'ÉTAT
                if (isCheckedInOnSite)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.green[100],
                    child: Row(children: [Icon(Icons.check_circle, color: Colors.green[800], size: 20), const SizedBox(width: 10), Text("Vous êtes présent sur ce chantier.", style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold, fontSize: 12))]),
                  )
                else if (isCheckedInElsewhere)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.red[100],
                    child: Row(children: [Icon(Icons.warning, color: Colors.red[800], size: 20), const SizedBox(width: 10), Expanded(child: Text("Attention : Vous êtes pointé sur '${employee?.currentProjectName}'.", style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold, fontSize: 12)))]),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.orange[100],
                    child: Row(children: [Icon(Icons.lock_clock, color: Colors.orange[800], size: 20), const SizedBox(width: 10), Text("Scan requis pour intervenir.", style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold, fontSize: 12))]),
                  ),

                // Liste des tâches
                Expanded(
                  child: StreamBuilder<List<ProjectTask>>(
                    stream: taskService.getProjectTasks(project.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final tasks = snapshot.data ?? [];
                      if (tasks.isEmpty) return const Center(child: Text("Aucune tâche"));

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          return TaskCard(task: tasks[index], isCheckedInOnSite: isCheckedInOnSite);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            // 🔥 NOUVEAU : DOUBLE BOUTON SI CONNECTÉ 🔥
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
              child: SizedBox(
                height: 50,
                child: isCheckedInOnSite
                    ? Row(
                  children: [
                    // Bouton 1 : Ajouter Tâche
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskScreen(project: project))),
                        icon: const Icon(Icons.add_task),
                        label: const Text("AJOUTER"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bouton 2 : Sortie
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        onPressed: () => _handleDirectCheckout(context, employee!.id),
                        icon: const Icon(Icons.logout),
                        label: const Text("FINIR"),
                      ),
                    ),
                  ],
                )
                    : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
                  onPressed: () => _showScanRequiredDialog(context),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text("SCANNER POUR DÉBLOQUER"),
                ),
              ),
            ),
          );
        }
    );
  }

  void _showScanRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pointage requis"),
        content: const Text("Vous devez scanner le QR Code du chantier pour prouver votre présence."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
            },
            child: const Text("Scanner maintenant"),
          )
        ],
      ),
    );
  }
}