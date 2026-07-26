import 'package:birren/domain/entities/note.dart';
import 'package:birren/presentation/controllers/note_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:birren/presentation/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final noteController = Get.find<NoteController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () => showNoteEditorDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        if (noteController.isLoading.value && noteController.notes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (noteController.notes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No notes yet.\nTap + to add a title and note about money or anything else.',
                style: AppTextStyles.body1,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          itemCount: noteController.notes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final note = noteController.notes[index];
            return _NoteCard(note: note);
          },
        );
      }),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final noteController = Get.find<NoteController>();
    final dateLabel = DateFormat.yMMMd().add_jm().format(note.updatedAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showNoteEditorDialog(context, note: note),
        onLongPress: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: AppColors.background,
              title: Text('Delete note?', style: AppTextStyles.headline1),
              content: Text(
                '“${note.title}” will be removed.',
                style: AppTextStyles.body1,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text('Cancel', style: AppTextStyles.smallButton2),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text('Delete', style: AppTextStyles.smallButton1),
                ),
              ],
            ),
          );
          if (confirm == true && note.id != null) {
            await noteController.deleteNote(note.id!);
            AppSnackbar.showSuccess('Note deleted');
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(note.title, style: AppTextStyles.midBody1),
              const SizedBox(height: 8),
              Text(
                note.body,
                style: AppTextStyles.body1,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(dateLabel, style: AppTextStyles.lightBody1),
            ],
          ),
        ),
      ),
    );
  }
}

void showNoteEditorDialog(BuildContext context, {Note? note}) {
  final noteController = Get.find<NoteController>();
  final titleController = TextEditingController(text: note?.title ?? '');
  final bodyController = TextEditingController(text: note?.body ?? '');
  final isEditing = note?.id != null;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing ? 'Edit note' : 'New note',
                  style: AppTextStyles.headline1,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: titleController,
                  hintText: 'Title',
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: CustomTextField(
                    controller: bodyController,
                    hintText: 'Write your note…',
                    keyboardType: TextInputType.multiline,
                    maxLines: 8,
                    minLines: 4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text('Cancel', style: AppTextStyles.smallButton2),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        try {
                          if (isEditing) {
                            await noteController.updateNote(
                              id: note!.id!,
                              title: titleController.text,
                              body: bodyController.text,
                            );
                          } else {
                            await noteController.createNote(
                              title: titleController.text,
                              body: bodyController.text,
                            );
                          }
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          AppSnackbar.showSuccess(
                            isEditing ? 'Note updated' : 'Note saved',
                          );
                        } catch (e) {
                          AppSnackbar.showError(e.toString());
                        }
                      },
                      child: Text(
                        isEditing ? 'Save' : 'Add',
                        style: AppTextStyles.smallButton1
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  ).whenComplete(() {
    titleController.dispose();
    bodyController.dispose();
  });
}
