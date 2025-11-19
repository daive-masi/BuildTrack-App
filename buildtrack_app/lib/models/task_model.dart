import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 🔹 Enum des statuts de tâche
enum TaskStatus {
  pending,       // En attente de validation
  todo,          // À faire
  inProgress,    // En cours
  blocked,       // Bloquée
  completed,     // Terminée
  done,          // (alias pour compatibilité)
}

extension TaskStatusX on TaskStatus {
  /// 🔹 Libellé lisible
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'En attente';
      case TaskStatus.todo:
        return 'À faire';
      case TaskStatus.inProgress:
        return 'En cours';
      case TaskStatus.blocked:
        return 'Bloquée';
      case TaskStatus.completed:
      case TaskStatus.done:
        return 'Terminée';
    }
  }

  /// 🔹 Couleur associée
  Color get statusColor {
    switch (this) {
      case TaskStatus.pending:
        return Colors.grey;
      case TaskStatus.todo:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.blocked:
        return Colors.red;
      case TaskStatus.completed:
      case TaskStatus.done:
        return Colors.green;
    }
  }

  /// 🔹 Icône associée
  IconData get statusIcon {
    switch (this) {
      case TaskStatus.pending:
        return Icons.hourglass_empty;
      case TaskStatus.todo:
        return Icons.list_alt;
      case TaskStatus.inProgress:
        return Icons.play_arrow;
      case TaskStatus.blocked:
        return Icons.block;
      case TaskStatus.completed:
      case TaskStatus.done:
        return Icons.check_circle;
    }
  }

  /// 🔹 Conversion string → enum
  static TaskStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return TaskStatus.pending;
      case 'todo':
        return TaskStatus.todo;
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'blocked':
        return TaskStatus.blocked;
      case 'completed':
      case 'done':
        return TaskStatus.completed;
      default:
        return TaskStatus.todo;
    }
  }
}

/// 🔹 Modèle de tâche
class ProjectTask {
  final String id;
  final String title;
  final String description;
  final String projectId;
  final String assignedTo;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? updatedAt;
  final List<String> proofImages;

  ProjectTask({
    required this.id,
    required this.title,
    required this.description,
    required this.projectId,
    required this.assignedTo,
    required this.status,
    required this.createdAt,
    this.dueDate,
    this.updatedAt,
    this.proofImages = const [],
  });

  /// 🔹 Convertir en map Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'projectId': projectId,
      'assignedTo': assignedTo,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'proofImages': proofImages,
    };
  }

  /// 🔹 Reconstituer depuis Firestore
  static ProjectTask fromFirestore(Map<String, dynamic> data, [String? id]) {
    return ProjectTask(
      id: id ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      projectId: data['projectId'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      status: TaskStatusX.fromString(data['status'] ?? 'todo'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      dueDate:
      data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      proofImages: List<String>.from(data['proofImages'] ?? []),
    );
  }

  /// 🔹 Date formatée
  String get formattedDueDate {
    if (dueDate == null) return 'Non définie';
    final d = dueDate!;
    return '${d.day}/${d.month}/${d.year}';
  }

  /// 🔹 En retard ?
  bool get isOverdue {
    if (dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now()) &&
        (status != TaskStatus.completed && status != TaskStatus.done);
  }
}
