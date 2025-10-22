import 'package:flutter/material.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Color? cursorColor;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final Color? fillColor;
  final Color? borderColor;
  final double borderRadius;
  final double blurRadius;
  final double spreadRadius;
  final Offset shadowOffset;

  // New optional suffix icon and callback
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.cursorColor,
    this.textStyle,
    this.hintStyle,
    this.fillColor,
    this.borderColor,
    this.borderRadius = 8,
    this.blurRadius = 8,
    this.spreadRadius = 1,
    this.shadowOffset = const Offset(0, 0),
    this.suffixIcon,
    this.onSuffixPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: (borderColor ?? AppColors.accent).withOpacity(0.5),
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
            offset: shadowOffset,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        cursorColor: cursorColor ?? AppColors.accent,
        style: textStyle ?? AppTextStyles.body1,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: hintStyle ?? AppTextStyles.hint,
          filled: true,
          fillColor: fillColor ?? AppColors.background,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: borderColor ?? AppColors.accent, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: borderColor ?? AppColors.accent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),

          // Add suffix icon if provided
          suffixIcon: suffixIcon != null
              ? IconButton(
            icon: Icon(suffixIcon, color: borderColor ?? AppColors.accent),
            onPressed: onSuffixPressed,
          )
              : null,
        ),
      ),
    );
  }
}
