// test/unit/project_task_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:buildtrack_app/models/task_model.dart';

void main() {
  group('ProjectTask Model Tests', () {
    final now = DateTime(2025, 12, 10); // Date fixe pour éviter les variations
    final task = ProjectTask(
      id: '1',
      title: 'Test Task',
      description: 'Test Description',
      projectId: 'project1',
      assignedTo: 'emp1',
      status: TaskStatus.todo,
      createdAt: now,
      dueDate: now,
      proofImages: ['http://image.com/proof.jpg'],
    );

    test('ProjectTask.toFirestore() serializes correctly', () {
      final map = task.toFirestore();
      expect(map['title'], 'Test Task');
      expect(map['description'], 'Test Description');
      expect(map['status'], 'todo');
      expect((map['createdAt'] as Timestamp).toDate(), now);
      expect((map['dueDate'] as Timestamp).toDate(), now);
      expect(map['proofImages'], ['http://image.com/proof.jpg']);
    });

    test('ProjectTask.fromFirestore() deserializes correctly', () {
      final map = task.toFirestore();
      final newTask = ProjectTask.fromFirestore(map, '1');
      expect(newTask.id, '1');
      expect(newTask.title, 'Test Task');
      expect(newTask.status, TaskStatus.todo);
      expect(newTask.dueDate, now);
    });

    test('ProjectTask.formattedDueDate returns correct format', () {
      expect(task.formattedDueDate, '10/12/2025');
    });

    test('ProjectTask.isOverdue returns true if task is overdue', () {
      final overdueTask = ProjectTask(
        id: '2',
        title: 'Overdue Task',
        description: 'Overdue Description',
        projectId: 'project1',
        assignedTo: 'emp1',
        status: TaskStatus.todo,
        createdAt: now.subtract(const Duration(days: 2)),
        dueDate: now.subtract(const Duration(days: 1)),
      );
      expect(overdueTask.isOverdue, true);
    });

    test('ProjectTask.isOverdue returns false if task is not overdue', () {
      expect(task.isOverdue, false);
    });
  });
}
