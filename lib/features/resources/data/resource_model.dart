import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceModel {
  final String id;
  final String title;
  final String link;
  final String description;
  final String? taskGroupId; // Nullable if not linked to a specific group
  final DateTime createdAt;

  ResourceModel({
    required this.id,
    required this.title,
    required this.link,
    required this.description,
    this.taskGroupId,
    required this.createdAt,
  });

  factory ResourceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ResourceModel(
      id: doc.id,
      title: data['title'] ?? '',
      link: data['link'] ?? '',
      description: data['description'] ?? '',
      taskGroupId: data['taskGroupId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'link': link,
      'description': description,
      'taskGroupId': taskGroupId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
