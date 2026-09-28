import 'dart:ui';

import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';

Future<void> showBudgetContextMenu({
  required BuildContext context,
  required GlobalKey anchorKey,
  required VoidCallback onEdit,
  required Future<void> Function() onDelete,
  VoidCallback? onTransfer,
}) async {
  final renderBox =
      anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  final position = renderBox.localToGlobal(Offset.zero);
  final size = MediaQuery.sizeOf(context);
  final left = (position.dx + renderBox.size.width - 168)
      .clamp(16.0, size.width - 184);

  await showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (dialogContext) {
      return Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: left,
            top: position.dy,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 168,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.surfaceBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      title: Text('Edit', style: AppTextStyles.midBody1),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        onEdit();
                      },
                    ),
                    if (onTransfer != null) ...[
                      const Divider(height: 1, color: AppColors.surfaceBorder),
                      ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.swap_horiz_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        title: Text('Transfer', style: AppTextStyles.midBody1),
                        onTap: () {
                          Navigator.pop(dialogContext);
                          onTransfer();
                        },
                      ),
                    ],
                    const Divider(height: 1, color: AppColors.surfaceBorder),
                    ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      title: Text(
                        'Delete',
                        style: AppTextStyles.midBody1
                            .copyWith(color: AppColors.danger),
                      ),
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
