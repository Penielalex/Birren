import 'dart:ui';

import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_style.dart';

Future<void> showBudgetContextMenu({
  required BuildContext context,
  required GlobalKey anchorKey,
  required VoidCallback onEdit,
  required Future<void> Function() onDelete,
}) async {
  final renderBox =
      anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  final position = renderBox.localToGlobal(Offset.zero);

  await showDialog(
    context: context,
    barrierColor: Colors.black26,
    builder: (dialogContext) {
      return Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left: position.dx + renderBox.size.width - 150,
            top: position.dy,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 150,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading:
                          const Icon(Icons.edit_outlined, color: Colors.white),
                      title: Text('Edit', style: AppTextStyles.body1),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        onEdit();
                      },
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.delete_outline, color: Colors.red),
                      title: Text('Delete', style: AppTextStyles.body1),
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        await Future<void>.delayed(Duration.zero);
                        try {
                          await onDelete();
                        } catch (e) {
                          AppSnackbar.showError(e.toString());
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
