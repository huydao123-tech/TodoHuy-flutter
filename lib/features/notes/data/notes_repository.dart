import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import 'note_model.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(FirebaseFirestore.instance);
});

final notesProvider = StreamProvider.autoDispose<List<NoteModel>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(notesRepositoryProvider).watchNotes(user.uid);
});

class NotesRepository {
  final FirebaseFirestore _firestore;

  NotesRepository(this._firestore);

  Stream<List<NoteModel>> watchNotes(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => NoteModel.fromFirestore(doc))
              .toList();
          items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return items;
        });
  }

  Future<void> addNote(String userId, NoteModel note) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .add(note.toFirestore());
  }

  Future<void> updateNote(String userId, String noteId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(noteId)
        .update(data);
  }

  Future<void> deleteNote(String userId, String noteId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(noteId)
        .delete();
  }
}
