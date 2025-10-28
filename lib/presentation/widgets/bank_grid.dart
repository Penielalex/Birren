import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../domain/entities/bank.dart';
import '../controllers/bank_controller.dart';
import '../theme/colors.dart';
import '../theme/text_style.dart';

class BanksGrid extends StatefulWidget {

  final VoidCallback onAddBank;

  const BanksGrid({
    Key? key,

    required this.onAddBank,
  }) : super(key: key);

  @override
  _BanksGridState createState() => _BanksGridState();
}

class _BanksGridState extends State<BanksGrid> {
  final BankController bankController = Get.find<BankController>();
  bool showAll = false;
  bool customSelectionMode = false;

  final List<LinearGradient> gradients = [
    const LinearGradient(colors: [Color(0xFF6A0DAD), Color(0xFF4B0082)], begin: Alignment.topLeft, end: Alignment.bottomRight), // purple → indigo
    const LinearGradient(colors: [Color(0xFF4B0082), Color(0xFF00008B)], begin: Alignment.topLeft, end: Alignment.bottomRight), // indigo → dark blue
    const LinearGradient(colors: [Color(0xFF00008B), Color(0xFF0000CD)], begin: Alignment.topLeft, end: Alignment.bottomRight), // dark blue → medium blue
    const LinearGradient(colors: [Color(0xFF0000CD), Color(0xFF1E90FF)], begin: Alignment.topLeft, end: Alignment.bottomRight), // medium blue → dodger blue
    const LinearGradient(colors: [Color(0xFF1E90FF), Color(0xFF00CED1)], begin: Alignment.topLeft, end: Alignment.bottomRight), // dodger blue → dark turquoise
    const LinearGradient(colors: [Color(0xFF00CED1), Color(0xFF20B2AA)], begin: Alignment.topLeft, end: Alignment.bottomRight), // dark turquoise → light sea green
    const LinearGradient(colors: [Color(0xFF20B2AA), Color(0xFF008080)], begin: Alignment.topLeft, end: Alignment.bottomRight), // light sea green → teal
    const LinearGradient(colors: [Color(0xFF6A0DAD), Color(0xFF00008B)], begin: Alignment.topLeft, end: Alignment.bottomRight), // purple → dark blue
    const LinearGradient(colors: [Color(0xFF4B0082), Color(0xFF1E90FF)], begin: Alignment.topLeft, end: Alignment.bottomRight), // indigo → dodger blue
    const LinearGradient(colors: [Color(0xFF0000CD), Color(0xFF20B2AA)], begin: Alignment.topLeft, end: Alignment.bottomRight), // medium blue → light sea green
    const LinearGradient(colors: [Color(0xFF1E90FF), Color(0xFF008080)], begin: Alignment.topLeft, end: Alignment.bottomRight), // dodger blue → teal
    const LinearGradient(colors: [Color(0xFF6A0DAD), Color(0xFF00CED1)], begin: Alignment.topLeft, end: Alignment.bottomRight), // purple → dark turquoise
  ];

  final Set<int> selectedIndexes = {};

  @override
  void initState() {
    super.initState();
    // Initially, all banks are selected
    selectedIndexes.addAll(List.generate(bankController.banks.length, (index) => index));
  }

  void handleSelectAll(int total) {
    selectedIndexes
      ..clear()
      ..addAll(List.generate(total, (i) => i));
    customSelectionMode = false;
  }

  @override
  Widget build(BuildContext context) {


    return Obx(() {
      final banks = bankController.banks;

      final banksToShow = showAll
          ? banks
          : banks.length > 4
          ? banks.sublist(0, 4)
          : banks;

      final canAddBank = banks.length < 12;

      return Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
            ),
            itemCount: banksToShow.length + (canAddBank ? 1 : 0),
            itemBuilder: (context, index) {
              if (canAddBank && index == banksToShow.length) {
                return AddBankItem(onTap: widget.onAddBank);
              }

              final bank = banksToShow[index];
              final gradient = gradients[index % gradients.length];
              final isSelected = selectedIndexes.contains(index);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (!customSelectionMode) {
                      selectedIndexes
                        ..clear()
                        ..add(index);
                      customSelectionMode = true;
                    } else {
                      if (isSelected) {
                        selectedIndexes.remove(index);
                      } else {
                        selectedIndexes.add(index);
                      }
                    }

                    // ✅ If all selected manually, same as pressing “Select All”
                    if (selectedIndexes.length == banks.length) {
                      handleSelectAll(banks.length);
                    }
                  });
                },
                child: BankItem(
                  bank: bank,
                  gradient: gradient,
                  isSelected: isSelected,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (banks.length > 4)
                TextButton(
                  onPressed: () {
                    setState(() {
                      showAll = !showAll;
                    });
                  },
                  child: Text(
                    showAll ? "Show Less" : "See All",
                    style: AppTextStyles.body1,
                  ),
                ),
              if (customSelectionMode &&
                  (selectedIndexes.length < banks.length))
                TextButton(
                  onPressed: () {
                    setState(() {
                      handleSelectAll(banks.length);
                    });
                  },
                  child: Text(
                    "Select All",
                    style: AppTextStyles.body1,
                  ),
                ),
            ],
          ),
        ],
      );

    });
  }
}

// ----------------- Single Bank Item -----------------
class BankItem extends StatelessWidget {
  final Bank bank;
  final LinearGradient gradient;
  final bool isSelected;

  const BankItem({
    Key? key,
    required this.bank,
    required this.gradient,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: isSelected
            ? gradient
            : const LinearGradient(colors: [Colors.grey, Colors.grey]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isSelected ? AppColors.accent : Colors.transparent,
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bank.displayName ?? bank.bankName,
              style: AppTextStyles.body1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              "${bank.balance.toStringAsFixed(2)} Birr",
              style: AppTextStyles.lightBody1,
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- Add Bank Item -----------------
class AddBankItem extends StatelessWidget {
  final VoidCallback onTap;

  const AddBankItem({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent,
              blurRadius: 4,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, color: AppColors.accent),
              const SizedBox(width: 10),
              Text(
                "Add Account",
                style: AppTextStyles.body1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}