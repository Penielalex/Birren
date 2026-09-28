import 'package:birren/domain/entities/transaction.dart';
import 'package:birren/presentation/controllers/budget_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/app_dialog.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../util/budget_defaults.dart';

Future<void> applyTransferFeeCategory(String categoryIndex) async {
  final budgetController = Get.find<BudgetController>();
  final transactionController = Get.find<TransactionController>();
  final selectedIds = List<int>.from(
    transactionController.selectedTransactionIds,
  );
  final selectedTransactions = transactionController.transactions
      .where((t) => selectedIds.contains(t.id))
      .toList();

  int? lineItemId;
  for (final transaction in selectedTransactions) {
    final id = budgetController.transferFeeLineItemIdForDate(transaction.dateOf);
    if (id != null) {
      lineItemId = id;
      break;
    }
  }

  await applyCategoryToSelectedTransactions(
    categoryIndex: categoryIndex,
    budgetLineItemId: lineItemId,
  );

  if (lineItemId == null) {
    AppSnackbar.showInfo(
      'Transfer Fee category saved. No active budget line item was linked.',
    );
  }
}

Future<void> applyCategoryToSelectedTransactions({
  required String categoryIndex,
  int? budgetLineItemId,
}) async {
  final transactionController = Get.find<TransactionController>();

  for (final txnId in transactionController.selectedTransactionIds) {
    await transactionController.editTransaction(
      txnId,
      null,
      categoryIndex,
      null,
      null,
      null,
      budgetLineItemId: budgetLineItemId,
      clearBudgetLineItemId: budgetLineItemId == null,
      clearLoanId: true,
    );
  }

  transactionController.clearSelection();
  AppSnackbar.showSuccess('Category updated');
}

void showBudgetLineItemDialog(
  BuildContext context, {
  required String categoryIndex,
}) {
  if (isTransferFeeCategory(categoryIndex, 'Expense')) {
    applyTransferFeeCategory(categoryIndex);
    return;
  }

  final budgetController = Get.find<BudgetController>();
  final transactionController = Get.find<TransactionController>();
  final budget = budgetController.activeBudget.value;
  final formatter = NumberFormat('#,##0.00');

  if (budget == null || budget.isExpired || budget.lineItems.isEmpty) {
    applyCategoryToSelectedTransactions(categoryIndex: categoryIndex);
    AppSnackbar.showError(
      budget == null
          ? 'No active budget — category saved without budget item.'
          : 'Budget unavailable — category saved without budget item.',
    );
    return;
  }

  final selectedIds = List<int>.from(
    transactionController.selectedTransactionIds,
  );
  final selectedTransactions = transactionController.transactions
      .where((t) => selectedIds.contains(t.id))
      .toList();

  if (selectedTransactions.any(
    (t) => !budgetController.transactionFitsBudgetPeriod(budget, t.dateOf),
  )) {
    applyCategoryToSelectedTransactions(categoryIndex: categoryIndex);
    AppSnackbar.showError(
      'Transaction date is outside the active budget period.',
    );
    return;
  }

  final applicableItems =
      budget.lineItems.where((item) => item.id != null).toList();
  final feeLineItemId =
      budgetController.transferFeeLineItemIdForDate(
        selectedTransactions.first.dateOf,
      );

  showAppDialog(
    context: context,
    builder: (dialogContext) {
      return AppDialog(
        title: 'Choose budget item',
        subtitle: 'Which budget item should this expense decrease?',
        expandBody: true,
        scrollable: false,
        maxHeight: 480,
        actions: [
          AppDialogActions.cancel(dialogContext),
        ],
        child: ListView.separated(
          itemCount: applicableItems.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final item = applicableItems[index];
            final spent = budgetController.spentForLineItemInBudget(
              budget,
              item,
              transactionController.transactions,
            );
            final remaining = item.allocatedAmount - spent;

            return AppDialogOptionTile(
              title: item.name,
              subtitle:
                  'Spent ${formatter.format(spent)} / '
                  '${formatter.format(item.allocatedAmount)} · '
                  '${formatter.format(remaining)} left',
              trailing: const Icon(
                Icons.remove_circle_outline_rounded,
                color: AppColors.mutedText,
                size: 20,
              ),
              onTap: () async {
                final canOfferFeeSplit = feeLineItemId != null &&
                    item.id != feeLineItemId &&
                    selectedTransactions.length == 1 &&
                    selectedTransactions.first.type == 'Expense' &&
                    selectedTransactions.first.id != null &&
                    transactionController
                            .transactionsInSplitGroup(
                              selectedTransactions.first,
                            )
                            .length <=
                        1;

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (canOfferFeeSplit) {
                  await _showOptionalTransferFeeDialog(
                    context: context,
                    expense: selectedTransactions.first,
                    categoryIndex: categoryIndex,
                    principalBudgetLineItemId: item.id!,
                    principalBudgetLineItemName: item.name,
                    feeBudgetLineItemId: feeLineItemId,
                  );
                } else {
                  await applyCategoryToSelectedTransactions(
                    categoryIndex: categoryIndex,
                    budgetLineItemId: item.id,
                  );
                }
              },
            );
          },
        ),
      );
    },
  );
}

Future<void> _showOptionalTransferFeeDialog({
  required BuildContext context,
  required Transaction expense,
  required String categoryIndex,
  required int principalBudgetLineItemId,
  required String principalBudgetLineItemName,
  required int feeBudgetLineItemId,
}) async {
  final formatter = NumberFormat('#,##0.00');
  final feeController = TextEditingController();
  var saving = false;

  await showAppDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final fee = double.tryParse(
                feeController.text.trim().replaceAll(',', ''),
              ) ??
              0;
          final principal = expense.amount - fee;
          final feeValid = fee > 0 && fee < expense.amount;

          return AppDialog(
            title: 'Transfer fee?',
            subtitle:
                'Assigning ${formatter.format(expense.amount)} birr to '
                '$principalBudgetLineItemName. Peel off a fee if this total '
                'includes service / transfer charges.',
            scrollable: true,
            maxHeight: 420,
            actions: [
              AppDialogActions.cancel(
                dialogContext,
                label: 'No fee',
                enabled: !saving,
                onPressed: () async {
                  await applyCategoryToSelectedTransactions(
                    categoryIndex: categoryIndex,
                    budgetLineItemId: principalBudgetLineItemId,
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
              ),
              AppDialogActions.primary(
                label: feeValid ? 'Split fee' : 'Save',
                isLoading: saving,
                onPressed: () async {
                  setDialogState(() => saving = true);
                  try {
                    if (feeValid) {
                      final transactionController =
                          Get.find<TransactionController>();
                      await transactionController
                          .splitTransferFeeFromExpense(
                        expense: expense,
                        feeAmount: fee,
                        principalCategory: categoryIndex,
                        principalBudgetLineItemId: principalBudgetLineItemId,
                        feeBudgetLineItemId: feeBudgetLineItemId,
                      );
                      transactionController.clearSelection();
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                      AppSnackbar.showSuccess(
                        'Split: ${formatter.format(principal)} → '
                        '$principalBudgetLineItemName, '
                        '${formatter.format(fee)} → Transfer Fee',
                      );
                    } else if (fee == 0) {
                      await applyCategoryToSelectedTransactions(
                        categoryIndex: categoryIndex,
                        budgetLineItemId: principalBudgetLineItemId,
                      );
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    } else {
                      AppSnackbar.showError(
                        'Fee must be greater than 0 and less than '
                        '${formatter.format(expense.amount)}',
                      );
                    }
                  } catch (e) {
                    AppSnackbar.showError(e.toString());
                  } finally {
                    if (dialogContext.mounted) {
                      setDialogState(() => saving = false);
                    }
                  }
                },
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Total ${formatter.format(expense.amount)} birr',
                  style: AppTextStyles.midBody1.copyWith(
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Transfer / service fee', style: AppTextStyles.body1),
                const SizedBox(height: 8),
                AppDialogField(
                  controller: feeController,
                  hintText: '0.00 (optional)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                Text(
                  feeValid
                      ? '${formatter.format(principal)} → '
                          '$principalBudgetLineItemName\n'
                          '${formatter.format(fee)} → Transfer Fee'
                      : 'Leave empty or 0 to put the full amount on '
                          '$principalBudgetLineItemName.',
                  style: AppTextStyles.lightBody1.copyWith(
                    color: AppColors.mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  feeController.dispose();
}
