import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyGoalModel {
  final String id;
  final String taskGroupId;
  final String weekStartDate; // Format: YYYY-MM-DD
  final String goalText;
  final DateTime updatedAt;

  WeeklyGoalModel({
    required this.id,
    required this.taskGroupId,
    required this.weekStartDate,
    required this.goalText,
    required this.updatedAt,
  });

  factory WeeklyGoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeeklyGoalModel(
      id: doc.id,
      taskGroupId: data['taskGroupId'] ?? '',
      weekStartDate: data['weekStartDate'] ?? '',
      goalText: data['goalText'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'taskGroupId': taskGroupId,
      'weekStartDate': weekStartDate,
      'goalText': goalText,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
