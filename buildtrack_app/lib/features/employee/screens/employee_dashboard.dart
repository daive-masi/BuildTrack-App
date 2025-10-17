import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../models/task_model.dart';
import '../widgets/task_cart.dart';

class EmployeeDashboard extends StatelessWidget {
  const EmployeeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Données mock pour le développement
    final mockTasks = [
      ProjectTask(
        id: '1',
        title: 'Préparation du terrain',
        description: 'Niveler et préparer la surface pour les fondations',
        status: TaskStatus.completed,
        assignedTo: 'mock-employee',
      ),
      ProjectTask(
        id: '2',
        title: 'Coulage des fondations',
        description: 'Réaliser le coffrage et couler le béton',
        status: TaskStatus.inProgress,
        assignedTo: 'mock-employee',
      ),
      ProjectTask(
        id: '3',
        title: 'Montage des murs',
        description: 'Assembler la structure porteuse',
        status: TaskStatus.pending,
        assignedTo: 'mock-employee',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Espace'),
        actions: [
          // Menu profil
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                // TODO: Naviguer vers le profil
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil - À implémenter')),
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
      body: Column(
        children: [
          // Carte chantier actuel
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chantier actuel', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  const Text('Résidence Les Cèdres', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('123 Avenue de la Construction, Paris', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/qr-scanner'),
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Scanner QR Code'),
                  ),
                ],
              ),
            ),
          ),

          // En-tête tâches
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Mes tâches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Chip(
                  label: Text('${mockTasks.length} tâches'),
                  backgroundColor: Colors.blue[50],
                ),
              ],
            ),
          ),

          // Liste des tâches
          Expanded(
            child: ListView.builder(
              itemCount: mockTasks.length,
              itemBuilder: (context, index) {
                final task = mockTasks[index];
                return TaskCard(task: task);
              },
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          // TODO: Implémenter la navigation entre les onglets
          if (index == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Historique - À implémenter')),
            );
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
                  // La redirection est gérée par AuthWrapper
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