import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String title;
  final String content;
  // Composite color string like "stone:Ý tưởng:📝"
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  String get colorId {
    final parts = color.split(':');
    return parts.isNotEmpty ? parts[0] : 'stone';
  }

  String get category {
    final parts = color.split(':');
    return parts.length > 1 ? parts[1] : 'Ý tưởng';
  }

  String get icon {
    final parts = color.split(':');
    return parts.length > 2 ? parts[2] : '📝';
  }

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      color: data['color'] ?? 'stone:Ý tưởng:📝',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
