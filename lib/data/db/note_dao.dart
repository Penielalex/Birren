import 'package:drift/drift.dart';

import '../../domain/entities/note.dart' as domain;
import 'app_database.dart';

part 'note_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(this.db) : super(db);

  final AppDatabase db;

  domain.Note _map(Note row) {
    return domain.Note(
      id: row.id,
      userId: row.userId,
      title: row.title,
      body: row.body,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<List<domain.Note>> getNotesByUserId(int userId) async {
    final rows = await (select(notes)
          ..where((n) => n.userId.equals(userId))
          ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
        .get();
    return rows.map(_map).toList();
  }

  Future<List<domain.Note>> getAllNotes() async {
    final rows = await (select(notes)
          ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
        .get();
    return rows.map(_map).toList();
  }

  Future<int> insertNote({
    required int userId,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    return into(notes).insert(
      NotesCompanion(
        userId: Value(userId),
        title: Value(title),
        body: Value(body),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> updateNote({
    required int id,
    required String title,
    required String body,
  }) async {
    await (update(notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        title: Value(title),
        body: Value(body),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteNote(int id) async {
    await (delete(notes)..where((n) => n.id.equals(id))).go();
  }
}
