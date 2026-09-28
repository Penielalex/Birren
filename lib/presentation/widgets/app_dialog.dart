import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared dialog chrome used across the app.
class AppDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final double maxWidth;
  final double maxHeight;
  final bool showCloseButton;
  final EdgeInsetsGeometry contentPadding;

  /// When true, dialog fills [maxHeight] and [child] gets the remaining space
  /// (use for lists / Expanded content). When false, height shrink-wraps.
  final bool expandBody;

  /// When true and [expandBody] is true, wraps [child] in a scroll view.
  /// When [expandBody] is false, content is always scroll-capable via Flexible.
  final bool scrollable;

  const AppDialog({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.maxWidth = 420,
    this.maxHeight = 560,
    this.showCloseButton = true,
    this.contentPadding = const EdgeInsets.fromLTRB(20, 4, 20, 8),
    this.expandBody = false,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget paddedChild = Padding(padding: contentPadding, child: child);

    final Widget body;
    if (expandBody) {
      body = Expanded(
        child: scrollable
            ? SingleChildScrollView(padding: contentPadding, child: child)
            : paddedChild,
      );
    } else if (scrollable) {
      body = Flexible(
        child: SingleChildScrollView(padding: contentPadding, child: child),
      );
    } else {
      body = paddedChild;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          // Force height when expanding so Expanded children have bounds.
          minHeight: expandBody ? maxHeight * 0.55 : 0,
        ),
        child: Material(
          color: AppColors.surface,
          elevation: 8,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.surfaceBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: expandBody ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AppDialogHeader(
                title: title,
                subtitle: subtitle,
                showCloseButton: showCloseButton,
              ),
              body,
              if (actions != null && actions!.isNotEmpty) ...[
                const Divider(height: 1, color: AppColors.surfaceBorder),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Row(
                    children: [
                      for (var i = 0; i < actions!.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: actions![i]),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AppDialogHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showCloseButton;

  const _AppDialogHeader({
    required this.title,
    this.subtitle,
    required this.showCloseButton,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, showCloseButton ? 8 : 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.mutedText,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showCloseButton)
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded, color: AppColors.mutedText),
            ),
        ],
      ),
    );
  }
}

/// Standard cancel / primary action pair for dialogs.
class AppDialogActions {
  AppDialogActions._();

  static Widget cancel(
    BuildContext context, {
    String label = 'Cancel',
    VoidCallback? onPressed,
    bool enabled = true,
  }) {
    return TextButton(
      onPressed: !enabled
          ? null
          : (onPressed ?? () => Navigator.of(context).maybePop()),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.mutedText,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: AppTextStyles.midBody1.copyWith(color: AppColors.mutedText),
      ),
    );
  }

  static Widget primary({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool destructive = false,
  }) {
    final bg = destructive ? AppColors.danger : AppColors.accent;
    final fg = destructive ? Colors.white : const Color(0xFF0B1020);

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: 0.4),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: fg,
              ),
            )
          : Text(
              label,
              style: AppTextStyles.midBody1.copyWith(color: fg),
            ),
    );
  }
}

/// Filled text field styled for dialogs.
class AppDialogField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const AppDialogField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      autofocus: autofocus,
      onChanged: onChanged,
      style: AppTextStyles.midBody1,
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.body1.copyWith(color: AppColors.mutedText),
        filled: true,
        fillColor: AppColors.fieldFill,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
      ),
    );
  }
}

/// Tappable row used in picker-style dialogs.
class AppDialogOptionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  const AppDialogOptionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.midBody1),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.lightBody1.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color: selected ? AppColors.accent : AppColors.mutedText,
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration appDialogInputDecoration({
  String? labelText,
  String? hintText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    labelStyle: AppTextStyles.body1.copyWith(color: AppColors.mutedText),
    hintStyle: AppTextStyles.body1.copyWith(color: AppColors.mutedText),
    filled: true,
    fillColor: AppColors.fieldFill,
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.surfaceBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
    ),
  );
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: builder,
  );
}

/// Conventional confirm / cancel prompt.
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showAppDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AppDialog(
        title: title,
        subtitle: message,
        showCloseButton: false,
        maxHeight: 280,
        scrollable: false,
        actions: [
          AppDialogActions.cancel(
            dialogContext,
            label: cancelLabel,
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          AppDialogActions.primary(
            label: confirmLabel,
            destructive: destructive,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
        child: const SizedBox.shrink(),
      );
    },
  );
  return result == true;
}

/// Blocking progress dialog with a short message.
Future<void> showAppLoadingDialog({
  required BuildContext context,
  required String message,
}) {
  return showAppDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.surfaceBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.midBody1.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
