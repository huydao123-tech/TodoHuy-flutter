import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import 'task_group_model.dart';

final taskGroupRepositoryProvider = Provider<TaskGroupRepository>((ref) {
  return TaskGroupRepository(FirebaseFirestore.instance);
});

final activeTaskGroupsProvider = StreamProvider<List<TaskGroupModel>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(taskGroupRepositoryProvider).watchActiveTaskGroups(user.uid);
});

class TaskGroupRepository {
  final FirebaseFirestore _firestore;

  TaskGroupRepository(this._firestore);

  Stream<List<TaskGroupModel>> watchActiveTaskGroups(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('task_groups')
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => TaskGroupModel.fromFirestore(doc))
              .toList();
          items.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
          return items;
        });
  }

  Stream<List<TaskGroupModel>> watchArchivedTaskGroups(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('task_groups')
        .where('isArchived', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => TaskGroupModel.fromFirestore(doc))
              .toList();
          items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return items;
        });
  }

  Future<void> createTaskGroup(String userId, String name, String color, int displayOrder, {TaskGroupType type = TaskGroupType.MAIN}) async {
    final group = TaskGroupModel(
      id: '',
      name: name,
      type: type,
      color: color,
      displayOrder: displayOrder,
      isArchived: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('task_groups')
        .add(group.toFirestore());
  }

  Future<void> updateTaskGroup(String userId, String groupId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('task_groups')
        .doc(groupId)
        .update(data);
  }

  Future<void> archiveTaskGroup(String userId, String groupId) async {
    await updateTaskGroup(userId, groupId, {
      'isArchived': true,
      'archivedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> restoreTaskGroup(String userId, String groupId) async {
    await updateTaskGroup(userId, groupId, {
      'isArchived': false,
      'archivedAt': null,
    });
  }

  Future<void> permanentDeleteTaskGroup(String userId, String groupId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('task_groups')
        .doc(groupId)
        .delete();
  }
}
