import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import 'side_task_model.dart';

final sideTasksRepositoryProvider = Provider<SideTasksRepository>((ref) {
  return SideTasksRepository(FirebaseFirestore.instance);
});

final sideTasksProvider = StreamProvider.autoDispose<List<SideTaskModel>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(sideTasksRepositoryProvider).watchSideTasks(user.uid);
});

class SideTasksRepository {
  final FirebaseFirestore _firestore;

  SideTasksRepository(this._firestore);

  Stream<List<SideTaskModel>> watchSideTasks(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('side_tasks')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => SideTaskModel.fromFirestore(doc))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  Future<void> addSideTask(String userId, String name, {bool isDone = false}) async {
    final task = SideTaskModel(
      id: '',
      name: name,
      isDone: isDone,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('side_tasks')
        .add(task.toFirestore());
  }

  Future<void> toggleSideTaskCompletion(String userId, String taskId, bool isDone) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('side_tasks')
        .doc(taskId)
        .update({'isDone': isDone});
  }

  Future<void> updateSideTaskName(String userId, String taskId, String newName) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('side_tasks')
        .doc(taskId)
        .update({'name': newName});
  }

  Future<void> deleteSideTask(String userId, String taskId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('side_tasks')
        .doc(taskId)
        .delete();
  }
}
