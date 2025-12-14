import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<Employee?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        final employee = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mon Profil'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Carte profil
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          employee?.fullName ?? 'Employé BuildTrack',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(employee?.email ?? 'Chargement...'),
                        const SizedBox(height: 8),
                        Text(employee?.phone ?? 'Non renseigné'),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(
                            employee?.role == UserRole.admin ? 'Administrateur' : 'Employé',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.blue[700],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Bouton déconnexion
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Déconnexion'),
                          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await authService.signOut();
                              },
                              child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Se déconnecter'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}