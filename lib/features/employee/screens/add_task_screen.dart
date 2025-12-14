import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/services/task_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../models/task_model.dart';
import '../../../models/project_model.dart';
import '../../../models/user_model.dart'; // Nécessaire pour vérifier le rôle

class AddTaskScreen extends StatefulWidget {
  final Project project;
  const AddTaskScreen({super.key, required this.project});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  // Note: On n'utilise plus _selectedStatus par défaut dans l'UI, c'est auto-déterminé
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.project.address;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final locale = Localizations.localeOf(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: locale,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final taskService = context.read<TaskService>();

      // On récupère l'utilisateur complet pour vérifier son rôle
      final currentUserData = await authService.getEmployeeData(authService.currentUser!.uid);

      if (currentUserData == null) throw "Utilisateur introuvable";

      // LOGIQUE MÉTIER :
      // Admin -> Directement "À faire" (todo)
      // Employé -> "En attente de validation" (pending)
      final initialStatus = currentUserData.role == UserRole.admin
          ? TaskStatus.todo
          : TaskStatus.pending;

      final newTask = ProjectTask(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        address: _addressController.text.trim(),
        projectId: widget.project.id,
        assignedTo: currentUserData.id,
        status: initialStatus,
        createdAt: DateTime.now(),
        dueDate: _selectedDate,
        history: [],
      );

      await taskService.createTask(newTask);

      if (mounted) {
        String message = currentUserData.role == UserRole.admin
            ? "Tâche créée et validée !"
            : "Tâche envoyée au chef pour validation.";

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message),
            backgroundColor: currentUserData.role == UserRole.admin ? Colors.green : Colors.orange
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final localeCode = Localizations.localeOf(context).toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(title: const Text("Nouvelle Tâche"), backgroundColor: Colors.transparent, foregroundColor: primaryColor, elevation: 0, centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue[100]!)), child: Row(children: [const Icon(Icons.apartment, color: Colors.blue), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Projet associé", style: TextStyle(fontSize: 12, color: Colors.grey)), Text(widget.project.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]))])),
              const SizedBox(height: 24),

              Text("Détails de la mission", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),

              _buildTextField(controller: _titleController, label: "Titre de la tâche", icon: Icons.assignment_outlined, validator: (v) => v!.isEmpty ? "Requis" : null),
              const SizedBox(height: 16),
              _buildTextField(controller: _descController, label: "Description détaillée", icon: Icons.description_outlined, maxLines: 4, validator: (v) => v!.isEmpty ? "Requis" : null),
              const SizedBox(height: 24),

              Text("Planification", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),

              _buildTextField(controller: _addressController, label: "Lieu précis", icon: Icons.location_on_outlined),
              const SizedBox(height: 16),

              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                  child: Row(children: [
                    Icon(Icons.calendar_today, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Date d'échéance", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(DateFormat.yMMMMd(localeCode).format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                    ])),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
                  ]),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _isLoading ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ENREGISTRER LA TÂCHE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)))),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(controller: controller, maxLines: maxLines, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: Colors.grey[600]), alignLabelWithHint: maxLines > 1, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2)), contentPadding: const EdgeInsets.all(16)), validator: validator);
  }
}