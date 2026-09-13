import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskGroupType { MAIN, SIDE }

class TaskGroupModel {
  final String id;
  final String name;
  final TaskGroupType type;
  final String color;
  final int displayOrder;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskGroupModel({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.displayOrder,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskGroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskGroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] == 'SIDE' ? TaskGroupType.SIDE : TaskGroupType.MAIN,
      color: data['color'] ?? '#16A34A',
      displayOrder: data['displayOrder'] ?? 0,
      isArchived: data['isArchived'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.name,
      'color': color,
      'displayOrder': displayOrder,
      'isArchived': isArchived,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
