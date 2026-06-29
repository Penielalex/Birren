import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_style.dart';

class CustomDropdown extends StatelessWidget {

  final String value;
  final List<String> items;
  final Function(String?) onChanged;
  final String hint;
  final bool isEnabled;

  const CustomDropdown({
    super.key,

    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: (AppColors.accent).withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        style: AppTextStyles.body1,

        hint: Text(isEnabled? hint : value, style: AppTextStyles.hint,),
        dropdownColor: AppColors.background,
        decoration: InputDecoration(


          filled: true,
          fillColor: AppColors.background,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.accent, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.accent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),

          // Add suffix icon if provided


        ),
        items: items
            .map((item) => DropdownMenuItem(
          value: item,
          child: Text(item, style: AppTextStyles.body1),
        ))
            .toList(),
        onChanged: isEnabled ? onChanged : null,
      ),
    );
  }
}
