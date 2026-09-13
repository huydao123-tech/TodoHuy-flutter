import 'package:cloud_firestore/cloud_firestore.dart';

class SideTaskModel {
  final String id;
  final String name;
  final bool isDone;
  final DateTime createdAt;

  SideTaskModel({
    required this.id,
    required this.name,
    required this.isDone,
    required this.createdAt,
  });

  factory SideTaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SideTaskModel(
      id: doc.id,
      name: data['name'] ?? '',
      isDone: data['isDone'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'isDone': isDone,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
