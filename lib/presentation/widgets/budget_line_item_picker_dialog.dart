import 'package:birren/presentation/controllers/budget_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
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
    );
  }

  transactionController.clearSelection();
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

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420, maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Deduct from budget item', style: AppTextStyles.headline1),
                const SizedBox(height: 8),
                Text(
                  'Which budget item should this expense decrease?',
                  style: AppTextStyles.body1,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: applicableItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = applicableItems[index];
                      final spent = budgetController.spentForLineItemInBudget(
                        budget,
                        item,
                        transactionController.transactions,
                      );
                      final remaining = item.allocatedAmount - spent;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.name, style: AppTextStyles.body1),
                        subtitle: Text(
                          'Spent ${formatter.format(spent)} / '
                          '${formatter.format(item.allocatedAmount)} · '
                          '${formatter.format(remaining)} left',
                          style: AppTextStyles.body1,
                        ),
                        trailing: const Icon(Icons.remove_circle_outline),
                        onTap: () async {
                          await applyCategoryToSelectedTransactions(
                            categoryIndex: categoryIndex,
                            budgetLineItemId: item.id,
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text('Cancel', style: AppTextStyles.smallButton2),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
