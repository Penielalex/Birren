import 'package:birren/domain/entities/bank.dart';
import 'package:birren/presentation/controllers/bank_controller.dart';
import 'package:birren/presentation/controllers/budget_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/util/budget_defaults.dart';
import 'package:birren/presentation/util/cash_bank.dart';
import 'package:birren/presentation/util/category.dart';
import 'package:birren/presentation/widgets/app_dialog.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Manual income/expense entry for any account (Cash or bank).
/// Use when an SMS was missed or for cash wallet entries.
void showManualTransactionDialog(
  BuildContext context, {
  Bank? initialBank,
}) {
  final bankController = Get.find<BankController>();
  final banks = bankController.banks.where((b) => b.id != null).toList();
  if (banks.isEmpty) {
    AppSnackbar.showError('Add an account first');
    return;
  }

  Bank resolveInitial() {
    if (initialBank?.id != null) {
      for (final bank in banks) {
        if (bank.id == initialBank!.id) return bank;
      }
    }
    for (final index in bankController.selectedIndexes) {
      if (index >= 0 && index < bankController.banks.length) {
        final bank = bankController.banks[index];
        if (bank.id != null) return bank;
      }
    }
    return banks.first;
  }

  final amountController = TextEditingController();
  final budgetController = Get.find<BudgetController>();
  var selectedBank = resolveInitial();
  var selectedType = 'Expense';
  var selectedDate = DateTime.now();
  String? selectedCategoryIndex;
  int? selectedLineItemId;

  showAppDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final categories = selectedType == 'Income'
              ? incomeCategories
              : expenseCategories;
          final selectableIndices = <int>[
            for (var i = 0; i < categories.length; i++)
              if (selectedType == 'Income'
                  ? i != incomeInternalTransferIndex
                  : i != expenseInternalTransferIndex)
                i,
          ];

          final budget = budgetController.activeBudget.value;
          final lineItems = budget?.lineItems
                  .where((item) => item.id != null)
                  .toList() ??
              [];
          final needsBudgetLineItem = selectedType == 'Expense' &&
              selectedCategoryIndex != null &&
              !isTransferFeeCategory(selectedCategoryIndex!, 'Expense') &&
              !isLoanRepaymentCategory(selectedCategoryIndex!, 'Expense') &&
              !isOutgoingLendCategory(selectedCategoryIndex!, 'Expense') &&
              lineItems.isNotEmpty &&
              budget != null &&
              !budget.isExpired &&
              budgetController.transactionFitsBudgetPeriod(
                budget,
                selectedDate,
              );

          void onCategorySelected(int index) {
            setState(() {
              selectedCategoryIndex = '$index';
              selectedLineItemId = null;
              if (isTransferFeeCategory(selectedCategoryIndex!, 'Expense')) {
                selectedLineItemId =
                    budgetController.transferFeeLineItemIdForDate(selectedDate);
              }
            });
          }

          final accountLabel = selectedBank.displayName ?? selectedBank.bankName;
          final isCash = isCashBankName(selectedBank.bankName);

          return AppDialog(
            title: 'Add transaction',
            subtitle: isCash
                ? 'Manual cash entry'
                : 'Use this when an SMS was missed',
            expandBody: true,
            scrollable: true,
            maxHeight: 660,
            actions: [
              AppDialogActions.cancel(dialogContext),
              AppDialogActions.primary(
                label: 'Save',
                onPressed: () async {
                  final amount = double.tryParse(
                    amountController.text.trim().replaceAll(',', ''),
                  );
                  if (amount == null || amount <= 0) {
                    AppSnackbar.showError('Enter a valid amount');
                    return;
                  }
                  if (selectedCategoryIndex == null) {
                    AppSnackbar.showError('Choose a category');
                    return;
                  }

                  int? lineItemId = selectedLineItemId;
                  if (selectedType == 'Expense' &&
                      isTransferFeeCategory(
                        selectedCategoryIndex!,
                        'Expense',
                      )) {
                    lineItemId ??= budgetController
                        .transferFeeLineItemIdForDate(selectedDate);
                  } else if (needsBudgetLineItem && lineItemId == null) {
                    AppSnackbar.showError('Choose a budget line item');
                    return;
                  }

                  try {
                    final transactionController =
                        Get.find<TransactionController>();
                    await transactionController.addManualTransaction(
                      bank: selectedBank,
                      type: selectedType,
                      amount: amount,
                      dateOf: selectedDate,
                      categoryIndex: selectedCategoryIndex!,
                      budgetLineItemId: lineItemId,
                    );
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    AppSnackbar.showSuccess(
                      'Transaction added to $accountLabel',
                    );
                  } catch (e) {
                    AppSnackbar.showError(e.toString());
                  }
                },
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Account', style: AppTextStyles.midBody1),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedBank.id,
                  dropdownColor: AppColors.surface,
                  decoration: appDialogInputDecoration(),
                  items: banks
                      .map(
                        (bank) => DropdownMenuItem(
                          value: bank.id,
                          child: Text(
                            bank.displayName ?? bank.bankName,
                            style: AppTextStyles.body1,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    setState(() {
                      selectedBank = banks.firstWhere((b) => b.id == id);
                    });
                  },
                ),
                const SizedBox(height: 14),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Expense',
                      label: Text('Expense'),
                      icon: Icon(Icons.remove_rounded),
                    ),
                    ButtonSegment(
                      value: 'Income',
                      label: Text('Income'),
                      icon: Icon(Icons.add_rounded),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (value) {
                    setState(() {
                      selectedType = value.first;
                      selectedCategoryIndex = null;
                      selectedLineItemId = null;
                    });
                  },
                ),
                const SizedBox(height: 14),
                AppDialogField(
                  controller: amountController,
                  hintText: 'Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          selectedDate.hour,
                          selectedDate.minute,
                        );
                        if (selectedCategoryIndex != null &&
                            isTransferFeeCategory(
                              selectedCategoryIndex!,
                              'Expense',
                            )) {
                          selectedLineItemId =
                              budgetController.transferFeeLineItemIdForDate(
                            selectedDate,
                          );
                        }
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: appDialogInputDecoration(
                      labelText: 'Date',
                      suffixIcon: const Icon(Icons.calendar_today_rounded),
                    ),
                    child: Text(
                      DateFormat.yMMMd().format(selectedDate),
                      style: AppTextStyles.body1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Category', style: AppTextStyles.midBody1),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: selectableIndices.length,
                  itemBuilder: (context, listIndex) {
                    final index = selectableIndices[listIndex];
                    final category = categories[index];
                    final isSelected = selectedCategoryIndex == '$index';

                    return Material(
                      color: isSelected
                          ? category.color.withValues(alpha: 0.45)
                          : category.color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onCategorySelected(index),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                category.icon,
                                color: category.color,
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                category.name,
                                style: AppTextStyles.body1.copyWith(
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (needsBudgetLineItem) ...[
                  const SizedBox(height: 16),
                  Text('Budget line item', style: AppTextStyles.midBody1),
                  const SizedBox(height: 8),
                  ...lineItems.map((item) {
                    final isSelected = selectedLineItemId == item.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: AppDialogOptionTile(
                        title: item.name,
                        selected: isSelected,
                        onTap: () =>
                            setState(() => selectedLineItemId = item.id),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      );
    },
  ).then((_) => amountController.dispose());
}

@Deprecated('Use showManualTransactionDialog')
void showManualCashTransactionDialog(BuildContext context, Bank cashBank) {
  showManualTransactionDialog(context, initialBank: cashBank);
}
