import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TaskStatus { pending, todo, inProgress, blocked, completed }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending: return 'Validation';
      case TaskStatus.todo: return 'À faire';
      case TaskStatus.inProgress: return 'En cours';
      case TaskStatus.blocked: return 'Bloquée';
      case TaskStatus.completed: return 'Terminée';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case TaskStatus.pending: return const Color(0xFFFFF3E0);
      case TaskStatus.inProgress: return const Color(0xFFCFD8DC);
      case TaskStatus.completed: return const Color(0xFFE8F5E9);
      case TaskStatus.blocked: return const Color(0xFFFFEBEE);
      default: return const Color(0xFFF5F5F5);
    }
  }

  Color get textColor {
    switch (this) {
      case TaskStatus.pending: return Colors.orange[900]!;
      case TaskStatus.inProgress: return Colors.blueGrey[900]!;
      case TaskStatus.completed: return Colors.green[900]!;
      case TaskStatus.blocked: return Colors.red[900]!;
      default: return Colors.black87;
    }
  }
}

class TaskLog {
  final String userName;
  final String comment;
  final List<String> photos;
  final DateTime date;

  TaskLog({
    required this.userName,
    required this.comment,
    this.photos = const [],
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'userName': userName,
    'comment': comment,
    'photos': photos,
    'date': Timestamp.fromDate(date),
  };

  factory TaskLog.fromMap(Map<String, dynamic> data) {
    List<String> loadedPhotos = [];
    if (data['photos'] != null) {
      loadedPhotos = List<String>.from(data['photos']);
    } else if (data['photoUrl'] != null) {
      loadedPhotos.add(data['photoUrl']);
    }

    return TaskLog(
      userName: data['userName'] ?? 'Inconnu',
      comment: data['comment'] ?? '',
      photos: loadedPhotos,
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}

class ProjectTask {
  final String id;
  final String title;
  final String description;
  final String address;
  final String projectId;
  final String assignedTo;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? updatedAt;
  final List<String> proofImages;
  final List<TaskLog> history;

  // --- NOUVEAUX CHAMPS TIMER ---
  final String? currentWorkerId; // ID de celui qui a lancé le chrono
  final DateTime? lastWorkStartTime; // Date de début du dernier "Start"
  final int totalTimeSpentMinutes; // Temps total accumulé (en minutes)

  ProjectTask({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.projectId,
    required this.assignedTo,
    required this.status,
    required this.createdAt,
    this.dueDate,
    this.updatedAt,
    this.proofImages = const [],
    this.history = const [],
    this.currentWorkerId,
    this.lastWorkStartTime,
    this.totalTimeSpentMinutes = 0,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'address': address,
      'projectId': projectId,
      'assignedTo': assignedTo,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'proofImages': proofImages,
      'history': history.map((e) => e.toMap()).toList(),
      // Sauvegarde Timer
      'currentWorkerId': currentWorkerId,
      'lastWorkStartTime': lastWorkStartTime != null ? Timestamp.fromDate(lastWorkStartTime!) : null,
      'totalTimeSpentMinutes': totalTimeSpentMinutes,
    };
  }

  static ProjectTask fromFirestore(Map<String, dynamic> data, [String? id]) {
    return ProjectTask(
      id: id ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? 'Adresse non spécifiée',
      projectId: data['projectId'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      status: TaskStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => TaskStatus.todo),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      proofImages: List<String>.from(data['proofImages'] ?? []),
      history: (data['history'] as List<dynamic>?)
          ?.map((e) => TaskLog.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      // Récupération Timer
      currentWorkerId: data['currentWorkerId'],
      lastWorkStartTime: data['lastWorkStartTime'] != null ? (data['lastWorkStartTime'] as Timestamp).toDate() : null,
      totalTimeSpentMinutes: data['totalTimeSpentMinutes'] ?? 0,
    );
  }

  // Helper : Le chrono tourne-t-il ?
  bool get isTimerRunning => currentWorkerId != null && lastWorkStartTime != null && status == TaskStatus.inProgress;

  String get formattedDueDate {
    if (dueDate == null) return 'Aucune';
    return '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}';
  }
}