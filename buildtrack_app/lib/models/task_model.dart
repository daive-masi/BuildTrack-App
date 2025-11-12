// models/task_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TaskStatus {
  pending('En attente'),
  inProgress('En cours'),
  completed('Terminé'),
  blocked('Bloqué');

  final String label;
  const TaskStatus(this.label);

  static TaskStatus fromString(String status) {
    return TaskStatus.values.firstWhere(
          (e) => e.toString().split('.').last == status,
      orElse: () => TaskStatus.pending,
    );
  }

  String get firestoreValue => toString().split('.').last;


  Color get statusColor {
    switch (this) {
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.blocked:
        return Colors.red;
      case TaskStatus.pending:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (this) {
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.inProgress:
        return Icons.play_arrow;
      case TaskStatus.blocked:
        return Icons.error;
      case TaskStatus.pending:
        return Icons.schedule;
    }
  }
}

class ProjectTask {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final String assignedTo;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> proofImages;
  final String projectId;
  final String projectName;
  final int estimatedHours;

  ProjectTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedTo,
    required this.dueDate,
    required this.createdAt,
    this.updatedAt,
    this.proofImages = const [],
    required this.projectId,
    required this.projectName,
    this.estimatedHours = 0,
  });

  factory ProjectTask.fromFirestore(Map<String, dynamic> data) {
    return ProjectTask(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: TaskStatus.fromString(data['status'] ?? 'pending'),
      assignedTo: data['assignedTo'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      proofImages: List<String>.from(data['proofImages'] ?? []),
      projectId: data['projectId'] ?? '',
      projectName: data['projectName'] ?? '',
      estimatedHours: data['estimatedHours'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.firestoreValue,
      'assignedTo': assignedTo,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'proofImages': proofImages,
      'projectId': projectId,
      'projectName': projectName,
      'estimatedHours': estimatedHours,
    };
  }


  String get formattedDueDate {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.inDays == 0) {
      return "Aujourd'hui";
    } else if (difference.inDays == 1) {
      return 'Demain';
    } else if (difference.inDays > 1 && difference.inDays <= 7) {
      return 'Dans ${difference.inDays} jours';
    } else {
      return 'Le ${dueDate.day}/${dueDate.month}/${dueDate.year}';
    }
  }

  bool get isOverdue => dueDate.isBefore(DateTime.now()) && status != TaskStatus.completed;

  ProjectTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    String? assignedTo,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? proofImages,
    String? projectId,
    String? projectName,
    int? estimatedHours,
  }) {
    return ProjectTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      proofImages: proofImages ?? this.proofImages,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      estimatedHours: estimatedHours ?? this.estimatedHours,
    );
  }
}