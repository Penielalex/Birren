import '../entities/note.dart';

abstract class NoteRepository {
  Future<List<Note>> getNotesByUserId(int userId);
  Future<List<Note>> getAllNotes();
  Future<int> createNote({
    required int userId,
    required String title,
    required String body,
  });
  Future<void> updateNote({
    required int id,
    required String title,
    required String body,
  });
  Future<void> deleteNote(int id);
}
