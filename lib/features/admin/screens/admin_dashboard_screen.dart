import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/project_service.dart';
import '../../../core/services/task_service.dart';
import '../../../models/project_model.dart';
import '../../../models/task_model.dart';
import '../../../models/user_model.dart';
import '../../employee/screens/project_tasks_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Espace Chef de Chantier"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0B2545),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => context.read<AuthService>().signOut(),
          )
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF0B2545),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.apartment), label: "Chantiers"),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check), label: "Validations"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Équipe"),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0B2545),
        onPressed: () => _showAddProjectDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nouveau Chantier", style: TextStyle(color: Colors.white)),
      )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildProjectsList();
      case 1: return _buildValidationList();
      case 2: return _buildEmployeesList();
      default: return const SizedBox();
    }
  }

  // --- ONGLET 1 : CHANTIERS ---
  Widget _buildProjectsList() {
    final projectService = Provider.of<ProjectService>(context);
    return StreamBuilder<List<Project>>(
      stream: projectService.getProjectsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final projects = snapshot.data ?? [];

        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Aucun chantier actif."),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => projectService.seedDatabase(),
                  child: const Text("Initialiser les données de test"),
                )
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), image: DecorationImage(image: NetworkImage(project.imageUrl), fit: BoxFit.cover)),
                    ),
                    title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${project.address}\n${project.assignedEmployees.length} employés assignés"),
                    isThreeLine: true,
                  ),
                  const Divider(height: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.group_add, size: 20),
                        label: const Text("Gérer Équipe"),
                        onPressed: () => _showAssignEmployeesDialog(project),
                      ),
                      Container(width: 1, height: 24, color: Colors.grey[300]),
                      TextButton.icon(
                        icon: const Icon(Icons.visibility, size: 20),
                        label: const Text("Voir Tâches"),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectTasksScreen(project: project))),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- ONGLET 2 : VALIDATIONS (CORRIGÉ) ---
  Widget _buildValidationList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tasks')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // --- GESTION ERREUR ---
        if (snapshot.hasError) {
          print("❌ Erreur Validation : ${snapshot.error}");
          // On affiche l'erreur pour que tu puisses cliquer sur le lien dans la console
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Erreur Index manquant.\nRegarde la console (Run) et clique sur le lien 'https://console.firebase...'\n\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final tasks = snapshot.data?.docs ?? [];

        if (tasks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                SizedBox(height: 16),
                Text("Tout est à jour ! Aucune tâche à valider."),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final doc = tasks[index];
            final taskData = doc.data() as Map<String, dynamic>;
            final task = ProjectTask.fromFirestore(taskData, doc.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.withOpacity(0.5))),
              child: Column(
                children: [
                  ListTile(
                    title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.description),
                        const SizedBox(height: 4),
                        Chip(label: const Text("En attente de validation"), backgroundColor: Colors.orange[50], labelStyle: const TextStyle(fontSize: 10, color: Colors.orange)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _updateTaskStatus(task.id, TaskStatus.blocked),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text("Refuser"),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _updateTaskStatus(task.id, TaskStatus.todo),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text("Valider"),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- ONGLET 3 : ÉQUIPE ---
  Widget _buildEmployeesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('employees').orderBy('lastName').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final employees = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final data = employees[index].data() as Map<String, dynamic>;
            final emp = Employee.fromFirestore(data);

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF0B2545),
                  child: Text(emp.firstName.isNotEmpty ? emp.firstName[0] : '?', style: const TextStyle(color: Colors.white)),
                ),
                title: Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(emp.jobTitle, style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () => _showEditEmployeeDialog(emp),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- ACTIONS ---

  Future<void> _updateTaskStatus(String taskId, TaskStatus status) async {
    await Provider.of<TaskService>(context, listen: false).updateTaskStatus(taskId, status);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Statut mis à jour")));
  }

  void _showAssignEmployeesDialog(Project project) {
    showDialog(
      context: context,
      builder: (context) => _AssignEmployeesDialog(project: project),
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final managerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nouveau Chantier"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nom du chantier")),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: "Adresse")),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description")),
              const Divider(),
              TextField(controller: managerCtrl, decoration: const InputDecoration(labelText: "Nom du Chef")),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Téléphone")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              final newProject = Project(
                id: '',
                name: nameCtrl.text,
                address: addressCtrl.text,
                description: descCtrl.text,
                imageUrl: 'https://via.placeholder.com/400',
                location: const GeoPoint(0,0),
                createdAt: DateTime.now(),
                projectManagerName: managerCtrl.text,
                projectManagerPhone: phoneCtrl.text,
                assignedEmployees: [],
              );
              Provider.of<ProjectService>(context, listen: false).addProject(newProject);
              Navigator.pop(ctx);
            },
            child: const Text("Créer"),
          )
        ],
      ),
    );
  }

  void _showEditEmployeeDialog(Employee emp) {
    final jobCtrl = TextEditingController(text: emp.jobTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Modifier ${emp.firstName}"),
        content: TextField(
          controller: jobCtrl,
          decoration: const InputDecoration(labelText: "Poste / Métier"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('employees').doc(emp.id).update({'jobTitle': jobCtrl.text});
              Navigator.pop(ctx);
            },
            child: const Text("Sauvegarder"),
          )
        ],
      ),
    );
  }
}

class _AssignEmployeesDialog extends StatefulWidget {
  final Project project;
  const _AssignEmployeesDialog({required this.project});

  @override
  State<_AssignEmployeesDialog> createState() => _AssignEmployeesDialogState();
}

class _AssignEmployeesDialogState extends State<_AssignEmployeesDialog> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.project.assignedEmployees);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Assigner l'équipe"),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('employees').orderBy('lastName').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final employees = snapshot.data!.docs.map((d) => Employee.fromFirestore(d.data() as Map<String, dynamic>)).toList();

            return ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final emp = employees[index];
                final isSelected = _selectedIds.contains(emp.id);

                return CheckboxListTile(
                  title: Text(emp.fullName),
                  subtitle: Text(emp.jobTitle),
                  value: isSelected,
                  activeColor: const Color(0xFF0B2545),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedIds.add(emp.id);
                      } else {
                        _selectedIds.remove(emp.id);
                      }
                    });
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('projects')
                .doc(widget.project.id)
                .update({'assignedEmployees': _selectedIds});

            if (mounted) Navigator.pop(context);
          },
          child: const Text("Enregistrer"),
        )
      ],
    );
  }
}