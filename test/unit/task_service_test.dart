// test/unit/task_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:buildtrack_app/core/services/task_service.dart';
import 'package:buildtrack_app/models/task_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late TaskService taskService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    taskService = TaskService(firestore: fakeFirestore);
  });

  group('TaskService Tests', () {
    test('Créer une tâche', () async {
      await taskService.createTask(
        title: 'Test',
        description: 'Description',
        assignedTo: 'emp1',
        dueDate: DateTime.now(),
      );
      final snapshot = await fakeFirestore.collection('tasks').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first['title'], 'Test');
    });

    test('Mettre à jour un statut', () async {
      final doc = await fakeFirestore.collection('tasks').add({
        'title': 'Task',
        'status': 'pending',
      });
      await taskService.updateTaskStatus(doc.id, TaskStatus.inProgress);
      final updated = await fakeFirestore.collection('tasks').doc(doc.id).get();
      expect(updated['status'], 'inProgress');
    });

    test('Ajouter une preuve', () async {
      final doc = await fakeFirestore.collection('tasks').add({
        'title': 'Task',
        'proofImages': [],
      });
      await taskService.addTaskProof(
        taskId: doc.id,
        imageUrls: ['http://image.com/proof.jpg'],
      );
      final updated = await fakeFirestore.collection('tasks').doc(doc.id).get();
      expect(updated['proofImages'].length, 1);
    });
  });
}
