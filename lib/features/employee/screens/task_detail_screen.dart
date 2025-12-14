import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/task_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../models/task_model.dart';

class TaskDetailScreen extends StatefulWidget {
  final ProjectTask task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  // Changement : Liste de fichiers au lieu d'un seul
  final List<File> _selectedImages = [];

  bool _isUploading = false;
  late TaskStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.task.status;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // --- SÉLECTION MULTIPLE D'IMAGES ---
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    // Utilisation de pickMultiImage
    final List<XFile> pickedFiles = await picker.pickMultiImage(imageQuality: 70);

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((x) => File(x.path)));
      });
    }
  }

  // Ajout pour prendre UNE photo avec la caméra (car multi-image ne marche souvent que galerie)
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  // Affiche une image en plein écran (Zoomable)
  void _showFullScreenImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PANNEAU HISTORIQUE GLOBAL ---
  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 50, height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.public, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Fil d'actualité du Chantier", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                        Text("L'activité de tous les employés", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .where('projectId', isEqualTo: widget.task.projectId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

                  final allTasks = snapshot.data!.docs.map((doc) => ProjectTask.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
                  final List<Map<String, dynamic>> globalHistory = [];

                  for (var task in allTasks) {
                    for (var log in task.history) {
                      globalHistory.add({'log': log, 'taskTitle': task.title});
                    }
                  }

                  globalHistory.sort((a, b) => (b['log'] as TaskLog).date.compareTo((a['log'] as TaskLog).date));

                  if (globalHistory.isEmpty) return _buildEmptyState();

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: globalHistory.length,
                    itemBuilder: (context, index) {
                      final item = globalHistory[index];
                      return _buildGlobalHistoryItem(context, item['log'], item['taskTitle']);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Aucune activité sur ce chantier", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildGlobalHistoryItem(BuildContext context, TaskLog log, String taskTitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              log.userName.isNotEmpty ? log.userName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(log.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
                    ),
                    Text(DateFormat('dd/MM HH:mm').format(log.date), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
                Text("Sur : $taskTitle", style: TextStyle(fontSize: 11, color: Theme.of(context).primaryColor, fontStyle: FontStyle.italic)),
                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (log.comment.isNotEmpty) Text(log.comment, style: const TextStyle(color: Colors.black87, height: 1.4)),

                      // --- AFFICHAGE DES PHOTOS (GRID) ---
                      if (log.photos.isNotEmpty) ...[
                        if (log.comment.isNotEmpty) const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: log.photos.map((url) {
                            // On adapte la taille selon le nombre de photos
                            double size = log.photos.length == 1 ? 200 : 100;
                            double width = log.photos.length == 1 ? double.infinity : 100;

                            return GestureDetector(
                              onTap: () => _showFullScreenImage(url),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  height: size,
                                  width: width,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (c, child, p) => p == null ? child : Container(height: size, width: width, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitUpdate() async {
    if (_commentController.text.isEmpty && _selectedImages.isEmpty && _currentStatus == widget.task.status) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aucune modification à enregistrer")));
      return;
    }

    setState(() => _isUploading = true);
    try {
      final taskService = context.read<TaskService>();
      final storageService = context.read<StorageService>();
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;

      List<String> photoUrls = [];

      // Upload Multiple
      if (_selectedImages.isNotEmpty) {
        // On upload toutes les images en parallèle
        photoUrls = await Future.wait(_selectedImages.map((file) async {
          return await storageService.uploadTaskImage(
              file,
              widget.task.id,
              'log_${DateTime.now().millisecondsSinceEpoch}_${file.hashCode}.jpg'
          );
        }));
      }

      final log = TaskLog(
        userName: currentUser?.displayName ?? 'Compagnon',
        comment: _commentController.text.isEmpty ? "Mise à jour statut : ${_currentStatus.label}" : _commentController.text,
        photos: photoUrls, // Liste d'URLs
        date: DateTime.now(),
      );

      await taskService.addTaskLog(widget.task.id, log);

      if (_currentStatus != widget.task.status) {
        await taskService.updateTaskStatus(widget.task.id, _currentStatus);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mise à jour publiée !")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Détail de la tâche"),
        backgroundColor: Colors.transparent,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(primaryColor),
            const SizedBox(height: 24),
            Text("Mise à jour avancement", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 12),
            _buildUpdateForm(primaryColor),
            const SizedBox(height: 80),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 10, top: 15, left: 20, right: 20),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _showHistorySheet,
              icon: const Icon(Icons.history, color: Colors.white),
              label: const Text("Historique Chantier", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            ),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _submitUpdate,
              icon: _isUploading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.send, color: primaryColor),
              label: Text(_isUploading ? "Envoi..." : "Publier", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Color color) {
    // ... (Code identique à avant, inchangé)
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.task.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: widget.task.status.backgroundColor, borderRadius: BorderRadius.circular(10)),
                child: Text(widget.task.status.label, style: TextStyle(color: widget.task.status.textColor, fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(widget.task.description, style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.5)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
          Row(children: [Icon(Icons.location_on, size: 18, color: color), const SizedBox(width: 8), Expanded(child: Text(widget.task.address, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)))]),
        ],
      ),
    );
  }

  Widget _buildUpdateForm(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Statut :", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TaskStatus>(
                value: _currentStatus,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down_circle, color: primaryColor),
                items: TaskStatus.values.map((s) => DropdownMenuItem(
                    value: s,
                    child: Row(children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: s.backgroundColor, shape: BoxShape.circle, border: Border.all(color: s.textColor, width: 2))),
                      const SizedBox(width: 12),
                      Text(s.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ]))).toList(),
                onChanged: (v) => setState(() => _currentStatus = v!),
              ),
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Commentaire...",
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
            ),
          ),
          const SizedBox(height: 16),

          // --- LISTE HORIZONTALE DES IMAGES SÉLECTIONNÉES ---
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + 1, // +1 pour le bouton Add
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    // Bouton Ajouter plus
                    return InkWell(
                      onTap: () => _showImageSourceModal(primaryColor), // Choix Camera/Galerie
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Icon(Icons.add, color: primaryColor),
                      ),
                    );
                  }

                  // Vignette image
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(image: FileImage(_selectedImages[index]), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4, right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImages.removeAt(index)),
                          child: const CircleAvatar(radius: 10, backgroundColor: Colors.white, child: Icon(Icons.close, size: 14, color: Colors.red)),
                        ),
                      )
                    ],
                  );
                },
              ),
            )
          else
          // Bouton Vide (Ajouter)
            InkWell(
              onTap: () => _showImageSourceModal(primaryColor),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, color: primaryColor),
                    const SizedBox(width: 8),
                    Text("Ajouter photos", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Petit menu pour choisir entre Caméra et Galerie
  void _showImageSourceModal(Color color) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: color),
              title: const Text('Galerie (Multiple)'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: color),
              title: const Text('Caméra'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }
}