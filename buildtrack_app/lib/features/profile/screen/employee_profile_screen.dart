// lib/features/profile/screens/employee_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/attendance_service.dart';
import '../../../models/attendance_model.dart';
import '../../../models/user_model.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    _firstNameController = TextEditingController(text: '');
    _lastNameController = TextEditingController(text: '');
    _phoneController = TextEditingController(text: '');
    _emailController = TextEditingController(text: currentUser?.email ?? '');

    _loadEmployeeData();
  }

  Future<void> _loadEmployeeData() async {
    final authService = context.read<AuthService>();
    final employee = await authService.getEmployeeData(authService.currentUser!.uid);

    if (employee != null) {
      setState(() {
        _firstNameController.text = employee.firstName;
        _lastNameController.text = employee.lastName;
        _phoneController.text = employee.phone;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
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
        title: const Text('Mon Profil'),
        // Le style est géré par le thème global, mais on garde tes actions d'origine
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Photo de profil et informations principales (RESTAURÉ)
            _buildProfileHeader(context, authService, employeeId),

            const SizedBox(height: 24),

            // 2. Statistiques de travail (RESTAURÉ)
            _buildWorkStats(context, attendanceService, employeeId),

            const SizedBox(height: 24),

            // 3. Informations personnelles (RESTAURÉ)
            _buildPersonalInfo(context),

            const SizedBox(height: 40),

            // 4. Bouton Déconnexion (NOUVEAU - EN BAS)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context, authService),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Se déconnecter', style: TextStyle(color: Colors.red, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS D'ORIGINE RESTAURÉS ---

  Widget _buildProfileHeader(BuildContext context, AuthService authService, String employeeId) {
    return FutureBuilder<Employee?>(
      future: authService.getEmployeeData(employeeId),
      builder: (context, snapshot) {
        final employee = snapshot.data;
        final displayName = employee != null
            ? '${employee.firstName} ${employee.lastName}'
            : 'Chargement...';

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Photo de profil
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue[100],
                      backgroundImage: employee?.photoUrl != null
                          ? NetworkImage(employee!.photoUrl!)
                          : null,
                      child: employee?.photoUrl == null
                          ? const Icon(Icons.person, size: 50, color: Colors.blue)
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            onPressed: _changeProfilePhoto,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  displayName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                if (employee != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    employee.role == UserRole.employee ? 'Employé' : 'Manager',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                Text(
                  _emailController.text,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),

                if (employee?.createdAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Membre depuis ${DateFormat('MMMM yyyy').format(employee!.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkStats(BuildContext context, AttendanceService attendanceService, String employeeId) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques de travail',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            StreamBuilder<Map<String, dynamic>>(
              stream: attendanceService.getWorkStats(employeeId),
              builder: (context, snapshot) {
                final stats = snapshot.data ?? {};
                final totalHours = stats['totalHours'] ?? 0;
                final weekHours = stats['currentWeekHours'] ?? 0;
                final avgHours = stats['averageHoursPerDay'] ?? 0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Total', '${totalHours.toStringAsFixed(0)}h', Icons.access_time),
                    _buildStatCard('Cette semaine', '${weekHours.toStringAsFixed(0)}h', Icons.calendar_today),
                    _buildStatCard('Moyenne/jour', '${avgHours.toStringAsFixed(1)}h', Icons.trending_up),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            StreamBuilder<List<Attendance>>(
              stream: attendanceService.getEmployeeAttendances(employeeId),
              builder: (context, snapshot) {
                final attendances = snapshot.data ?? [];
                final currentMonthAttendances = attendances.where((a) {
                  return a.checkInTime.month == DateTime.now().month;
                }).length;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Pointages total', '${attendances.length}', Icons.fact_check),
                    _buildStatCard('Ce mois', '$currentMonthAttendances', Icons.calendar_month),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    // J'utilise Theme.of(context).primaryColor pour garder ton bleu nuit si le thème est appliqué
    return Column(
      children: [
        Icon(icon, size: 30, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPersonalInfo(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Informations personnelles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isEditing)
                  TextButton(
                    onPressed: _saveProfile,
                    child: const Text('Enregistrer'),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildEditableField(
                    'Prénom',
                    _firstNameController,
                    Icons.person,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 12),
                  _buildEditableField(
                    'Nom',
                    _lastNameController,
                    Icons.person_outline,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 12),
                  _buildEditableField(
                    'Téléphone',
                    _phoneController,
                    Icons.phone,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildEditableField(
                    'Email',
                    _emailController,
                    Icons.email,
                    enabled: false, // Email non modifiable
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool enabled = true,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: !enabled,
        fillColor: Colors.grey[100],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ce champ est obligatoire';
        }
        return null;
      },
    );
  }

  Future<void> _changeProfilePhoto() async {
    // TODO: Implémenter la sélection de photo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité photo à implémenter')),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final authService = context.read<AuthService>();
        final employeeId = authService.currentUser!.uid;

        // Mettre à jour le profil dans Firestore
        await authService.updateEmployeeProfile(
          employeeId: employeeId,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phone: _phoneController.text,
        );

        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  // Fonction pour afficher la boîte de dialogue de déconnexion
  void _showLogoutDialog(BuildContext context, AuthService authService) {
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
              Navigator.pop(context); // Fermer le dialogue
              Navigator.pop(context); // Revenir à l'écran précédent (Dashboard) si nécessaire
              await authService.signOut();
            },
            child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}