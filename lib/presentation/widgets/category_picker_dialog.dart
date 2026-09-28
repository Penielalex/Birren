import 'package:birren/domain/entities/transaction.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/util/category.dart';
import 'package:birren/presentation/widgets/app_dialog.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:birren/presentation/widgets/budget_line_item_picker_dialog.dart';
import 'package:birren/presentation/widgets/internal_transfer_pair_dialog.dart';
import 'package:birren/presentation/widgets/loan_return_pair_dialog.dart';
import 'package:birren/presentation/widgets/shared_expense_split_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Opens the category picker for one transaction (set or change category / budget item).
void editTransactionCategory(BuildContext context, Transaction transaction) {
  final transactionController = Get.find<TransactionController>();
  transactionController.clearSelection();
  transactionController.toggleSelection(transaction.id);
  showCategoryDialog(context, transaction.type);
}

void showCategoryDialog(BuildContext context, String type) {
  final TransactionController transactionController =
      Get.find<TransactionController>();

  showAppDialog(
    context: context,
    builder: (context) {
      return AppDialog(
        title: 'Select category',
        subtitle: type == 'Expense'
            ? 'Choose how to classify this expense'
            : 'Choose how to classify this income',
        expandBody: true,
        scrollable: false,
        maxHeight: 560,
        actions: [
          AppDialogActions.cancel(context),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (type == 'Expense') ...[
              Material(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (transactionController.selectedTransactionIds.isEmpty) {
                      AppSnackbar.showError('Select a transaction first');
                      return;
                    }
                    final primaryId =
                        transactionController.selectedTransactionIds.first;
                    final primary = transactionController.transactions
                        .firstWhere((t) => t.id == primaryId);
                    Navigator.pop(context);
                    showSharedExpenseSplitDialog(context, primary);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.call_split_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Split shared expense',
                            style: AppTextStyles.midBody1
                                .copyWith(color: AppColors.accent),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: GridView.builder(
                itemCount: type == 'Income'
                    ? incomeCategories.length
                    : expenseCategories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, index) {
                  final category = type == 'Income'
                      ? incomeCategories[index]
                      : expenseCategories[index];

                  return Material(
                    color: category.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final isInternalTransfer =
                            (type == 'Income' &&
                                index == incomeInternalTransferIndex) ||
                            (type == 'Expense' &&
                                index == expenseInternalTransferIndex);
                        final isIncomingLoan =
                            type == 'Income' && index == incomeLoanIndex;
                        final isLoanReturn =
                            type == 'Income' && index == incomeReturnsIndex;
                        final isOutgoingLend =
                            type == 'Expense' && index == expenseLendLoanIndex;
                        final isLoanRepayment =
                            type == 'Expense' && index == expenseLoanIndex;

                        if (isInternalTransfer) {
                          if (transactionController
                              .selectedTransactionIds.isEmpty) {
                            AppSnackbar.showError(
                              'Select a transaction first',
                            );
                            return;
                          }

                          final primaryId = transactionController
                              .selectedTransactionIds.first;
                          final primary = transactionController.transactions
                              .firstWhere((t) => t.id == primaryId);

                          Navigator.pop(context);
                          showInternalTransferPairDialog(context, primary);
                          return;
                        }

                        if (isIncomingLoan) {
                          if (transactionController
                              .selectedTransactionIds.isEmpty) {
                            AppSnackbar.showError(
                              'Select a transaction first',
                            );
                            return;
                          }

                          Navigator.pop(context);
                          await applyBorrowedLoanCategoryToSelected();
                          return;
                        }

                        if (isOutgoingLend) {
                          if (transactionController
                              .selectedTransactionIds.isEmpty) {
                            AppSnackbar.showError(
                              'Select a transaction first',
                            );
                            return;
                          }

                          Navigator.pop(context);
                          await applyLentLoanCategoryToSelected();
                          return;
                        }

                        if (isLoanReturn) {
                          if (transactionController
                              .selectedTransactionIds.isEmpty) {
                            AppSnackbar.showError(
                              'Select a transaction first',
                            );
                            return;
                          }

                          final primaryId = transactionController
                              .selectedTransactionIds.first;
                          final primary = transactionController.transactions
                              .firstWhere((t) => t.id == primaryId);

                          Navigator.pop(context);
                          showLoanReturnPairDialog(context, primary);
                          return;
                        }

                        if (isLoanRepayment) {
                          if (transactionController
                              .selectedTransactionIds.isEmpty) {
                            AppSnackbar.showError(
                              'Select a transaction first',
                            );
                            return;
                          }

                          final primaryId = transactionController
                              .selectedTransactionIds.first;
                          final primary = transactionController.transactions
                              .firstWhere((t) => t.id == primaryId);

                          Navigator.pop(context);
                          showLoanRepaymentPairDialog(context, primary);
                          return;
                        }

                        final categoryIndex = '$index';
                        Navigator.pop(context);

                        if (type == 'Expense') {
                          showBudgetLineItemDialog(
                            context,
                            categoryIndex: categoryIndex,
                          );
                        } else {
                          await applyCategoryToSelectedTransactions(
                            categoryIndex: categoryIndex,
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(category.icon, color: category.color, size: 28),
                            const SizedBox(height: 6),
                            Text(
                              category.name,
                              style: AppTextStyles.body1,
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
            ),
          ],
        ),
      );
    },
  );
}
