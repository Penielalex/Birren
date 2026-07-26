import '../domain/entities/note.dart';
import '../domain/repositories/note_repository.dart';

class GetNotesByUserIdUseCase {
  final NoteRepository repository;
  GetNotesByUserIdUseCase(this.repository);

  Future<List<Note>> execute(int userId) => repository.getNotesByUserId(userId);
}

class CreateNoteUseCase {
  final NoteRepository repository;
  CreateNoteUseCase(this.repository);

  Future<int> execute({
    required int userId,
    required String title,
    required String body,
  }) =>
      repository.createNote(userId: userId, title: title, body: body);
}

class UpdateNoteUseCase {
  final NoteRepository repository;
  UpdateNoteUseCase(this.repository);

  Future<void> execute({
    required int id,
    required String title,
    required String body,
  }) =>
      repository.updateNote(id: id, title: title, body: body);
}

class DeleteNoteUseCase {
  final NoteRepository repository;
  DeleteNoteUseCase(this.repository);

  Future<void> execute(int id) => repository.deleteNote(id);
}
