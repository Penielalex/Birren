import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../db/note_dao.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NoteDao dao;

  NoteRepositoryImpl({required this.dao});

  @override
  Future<List<Note>> getNotesByUserId(int userId) =>
      dao.getNotesByUserId(userId);

  @override
  Future<List<Note>> getAllNotes() => dao.getAllNotes();

  @override
  Future<int> createNote({
    required int userId,
    required String title,
    required String body,
  }) =>
      dao.insertNote(userId: userId, title: title, body: body);

  @override
  Future<void> updateNote({
    required int id,
    required String title,
    required String body,
  }) =>
      dao.updateNote(id: id, title: title, body: body);

  @override
  Future<void> deleteNote(int id) => dao.deleteNote(id);
}
