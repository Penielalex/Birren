import 'package:birren/domain/entities/transaction.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/util/category.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:birren/presentation/widgets/budget_line_item_picker_dialog.dart';
import 'package:birren/presentation/widgets/internal_transfer_pair_dialog.dart';
import 'package:birren/presentation/widgets/loan_return_pair_dialog.dart';
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

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Category',
                style: AppTextStyles.headline1,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: type == 'Income'
                      ? incomeCategories.length
                      : expenseCategories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final category = type == 'Income'
                        ? incomeCategories[index]
                        : expenseCategories[index];

                    return GestureDetector(
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
                      child: Container(
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(category.icon, color: category.color, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              category.name,
                              style: AppTextStyles.body1,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
