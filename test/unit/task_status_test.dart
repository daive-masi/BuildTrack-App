// test/unit/task_status_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:buildtrack_app/models/task_model.dart';

void main() {
  group('TaskStatus Extension Tests', () {
    test('TaskStatus.label returns correct label', () {
      expect(TaskStatus.pending.label, 'En attente');
      expect(TaskStatus.todo.label, 'À faire');
      expect(TaskStatus.inProgress.label, 'En cours');
      expect(TaskStatus.blocked.label, 'Bloquée');
      expect(TaskStatus.completed.label, 'Terminée');
    });

    test('TaskStatus.statusColor returns correct color', () {
      expect(TaskStatus.pending.statusColor, Colors.grey);
      expect(TaskStatus.todo.statusColor, Colors.orange);
      expect(TaskStatus.inProgress.statusColor, Colors.blue);
      expect(TaskStatus.blocked.statusColor, Colors.red);
      expect(TaskStatus.completed.statusColor, Colors.green);
    });

    test('TaskStatus.statusIcon returns correct icon', () {
      expect(TaskStatus.pending.statusIcon, Icons.hourglass_empty);
      expect(TaskStatus.todo.statusIcon, Icons.list_alt);
      expect(TaskStatus.inProgress.statusIcon, Icons.play_arrow);
      expect(TaskStatus.blocked.statusIcon, Icons.block);
      expect(TaskStatus.completed.statusIcon, Icons.check_circle);
    });

    test('TaskStatus.fromString converts string to enum correctly', () {
      expect(TaskStatusX.fromString('pending'), TaskStatus.pending);
      expect(TaskStatusX.fromString('todo'), TaskStatus.todo);
      expect(TaskStatusX.fromString('inProgress'), TaskStatus.inProgress);
      expect(TaskStatusX.fromString('blocked'), TaskStatus.blocked);
      expect(TaskStatusX.fromString('completed'), TaskStatus.completed);
      expect(TaskStatusX.fromString('done'), TaskStatus.completed);
      expect(TaskStatusX.fromString('unknown'), TaskStatus.todo);
    });
  });
}
