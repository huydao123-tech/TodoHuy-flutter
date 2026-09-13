import 'package:cloud_firestore/cloud_firestore.dart';

enum WorkItemStatus { TODO, IN_PROGRESS, DONE }

class WorkItemModel {
  final String id;
  final String taskGroupId;
  final String weekStartDate; // Format: YYYY-MM-DD
  final String content;
  final WorkItemStatus status;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkItemModel({
    required this.id,
    required this.taskGroupId,
    required this.weekStartDate,
    required this.content,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    WorkItemStatus parsedStatus = WorkItemStatus.TODO;
    if (data['status'] == 'IN_PROGRESS') parsedStatus = WorkItemStatus.IN_PROGRESS;
    if (data['status'] == 'DONE') parsedStatus = WorkItemStatus.DONE;

    return WorkItemModel(
      id: doc.id,
      taskGroupId: data['taskGroupId'] ?? '',
      weekStartDate: data['weekStartDate'] ?? '',
      content: data['content'] ?? '',
      status: parsedStatus,
      note: data['note'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskGroupId': taskGroupId,
      'weekStartDate': weekStartDate,
      'content': content,
      'status': status.name,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
