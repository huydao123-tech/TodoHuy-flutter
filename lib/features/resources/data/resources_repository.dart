import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import 'resource_model.dart';

final resourcesRepositoryProvider = Provider<ResourcesRepository>((ref) {
  return ResourcesRepository(FirebaseFirestore.instance);
});

final resourcesProvider = StreamProvider.autoDispose<List<ResourceModel>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(resourcesRepositoryProvider).watchResources(user.uid);
});

class ResourcesRepository {
  final FirebaseFirestore _firestore;

  ResourcesRepository(this._firestore);

  Stream<List<ResourceModel>> watchResources(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('resources')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => ResourceModel.fromFirestore(doc))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  Future<void> addResource(String userId, String title, String link, String description, String? taskGroupId) async {
    final resource = ResourceModel(
      id: '',
      title: title,
      link: link,
      description: description,
      taskGroupId: taskGroupId,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('resources')
        .add(resource.toFirestore());
  }

  Future<void> updateResource(String userId, String resourceId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('resources')
        .doc(resourceId)
        .update(data);
  }

  Future<void> deleteResource(String userId, String resourceId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('resources')
        .doc(resourceId)
        .delete();
  }
}
