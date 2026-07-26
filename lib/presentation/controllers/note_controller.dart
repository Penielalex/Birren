import 'package:get/get.dart';

import '../../app/note_usecases.dart';
import '../../data/service/shared_prefs_service.dart';
import '../../domain/entities/note.dart';

class NoteController extends GetxController {
  final SharedPrefsService prefs;
  final GetNotesByUserIdUseCase getNotesByUserIdUseCase;
  final CreateNoteUseCase createNoteUseCase;
  final UpdateNoteUseCase updateNoteUseCase;
  final DeleteNoteUseCase deleteNoteUseCase;

  NoteController({
    required this.prefs,
    required this.getNotesByUserIdUseCase,
    required this.createNoteUseCase,
    required this.updateNoteUseCase,
    required this.deleteNoteUseCase,
  });

  final notes = <Note>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshNotes();
  }

  Future<void> refreshNotes() async {
    final userId = await prefs.getId();
    if (userId == null) return;

    isLoading.value = true;
    try {
      notes.assignAll(
        await getNotesByUserIdUseCase.execute(int.parse(userId)),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createNote({
    required String title,
    required String body,
  }) async {
    final userId = await prefs.getId();
    if (userId == null) {
      throw StateError('User not logged in');
    }

    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Enter a title');
    }
    if (trimmedBody.isEmpty) {
      throw ArgumentError('Enter a note');
    }

    await createNoteUseCase.execute(
      userId: int.parse(userId),
      title: trimmedTitle,
      body: trimmedBody,
    );
    await refreshNotes();
  }

  Future<void> updateNote({
    required int id,
    required String title,
    required String body,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Enter a title');
    }
    if (trimmedBody.isEmpty) {
      throw ArgumentError('Enter a note');
    }

    await updateNoteUseCase.execute(
      id: id,
      title: trimmedTitle,
      body: trimmedBody,
    );
    await refreshNotes();
  }

  Future<void> deleteNote(int id) async {
    await deleteNoteUseCase.execute(id);
    await refreshNotes();
  }
}
