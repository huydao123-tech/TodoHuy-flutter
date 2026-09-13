import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../../task_groups/data/task_group_model.dart';
import 'work_item_model.dart';
import 'weekly_goal_model.dart';

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepository(FirebaseFirestore.instance);
});

// Stream provider for fetching task groups with autoDispose
final taskGroupsProvider = StreamProvider.autoDispose<List<TaskGroupModel>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();

  return ref.watch(plannerRepositoryProvider).watchTaskGroups(user.uid);
});

// Shared family stream provider for work items of a specific week
final workItemsForWeekProvider =
    StreamProvider.autoDispose.family<List<WorkItemModel>, String>((ref, weekStartDate) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();

  return ref.watch(plannerRepositoryProvider).watchWorkItemsForWeek(user.uid, weekStartDate);
});

class PlannerRepository {
  final FirebaseFirestore _firestore;

  PlannerRepository(this._firestore);

  Stream<List<TaskGroupModel>> watchTaskGroups(String userId) {
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

  Stream<List<WeeklyGoalModel>> watchWeeklyGoalsForWeek(String userId, String weekStartDate) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('weekly_goals')
        .where('weekStartDate', isEqualTo: weekStartDate)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WeeklyGoalModel.fromFirestore(doc))
            .toList());
  }

  Future<void> upsertWeeklyGoal(String userId, String taskGroupId, String weekStartDate, String goalText) async {
    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('weekly_goals')
        .where('taskGroupId', isEqualTo: taskGroupId)
        .where('weekStartDate', isEqualTo: weekStartDate)
        .get();

    if (query.docs.isNotEmpty) {
      // Update existing
      await query.docs.first.reference.update({
        'goalText': goalText,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Create new
      final newGoal = WeeklyGoalModel(
        id: '',
        taskGroupId: taskGroupId,
        weekStartDate: weekStartDate,
        goalText: goalText,
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('weekly_goals')
          .add(newGoal.toFirestore());
    }
  }

  Stream<List<WorkItemModel>> watchWorkItemsForWeek(String userId, String weekStartDate) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('work_items')
        .where('weekStartDate', isEqualTo: weekStartDate)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => WorkItemModel.fromFirestore(doc))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  Future<void> addWorkItem(String userId, WorkItemModel item) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('work_items')
        .add(item.toFirestore());
  }

  Future<void> updateWorkItem(String userId, String itemId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('work_items')
        .doc(itemId)
        .update(data);
  }

  Future<void> updateWorkItemStatus(String userId, String itemId, WorkItemStatus newStatus) async {
    await updateWorkItem(userId, itemId, {
      'status': newStatus.name,
    });
  }

  Future<void> deleteWorkItem(String userId, String itemId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('work_items')
        .doc(itemId)
        .delete();
  }
}

