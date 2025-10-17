class ProjectTask {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final String assignedTo; // Employee ID
  final DateTime? startTime;
  final DateTime? endTime;
  final List<String>? photoUrls;

  ProjectTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedTo,
    this.startTime,
    this.endTime,
    this.photoUrls,
  });

  factory ProjectTask.fromFirestore(Map<String, dynamic> data) {
    return ProjectTask(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      status: TaskStatus.values.firstWhere(
            (e) => e.name == data['status'],
        orElse: () => TaskStatus.pending,
      ),
      assignedTo: data['assignedTo'],
      startTime: data['startTime']?.toDate(),
      endTime: data['endTime']?.toDate(),
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'assignedTo': assignedTo,
      'startTime': startTime,
      'endTime': endTime,
      'photoUrls': photoUrls,
    };
  }
}

enum TaskStatus { pending, inProgress, completed, blocked }