import 'package:birren/presentation/controllers/loan_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';

Future<void> applyBorrowedLoanCategoryToSelected() async {
  final transactionController = Get.find<TransactionController>();
  final loanController = Get.find<LoanController>();

  if (transactionController.selectedTransactionIds.isEmpty) {
    AppSnackbar.showError('Select a transaction first');
    return;
  }

  for (final txnId in transactionController.selectedTransactionIds) {
    final txn = transactionController.transactions.firstWhere(
      (t) => t.id == txnId,
    );
    if (txn.type != 'Income') {
      AppSnackbar.showError('Borrowed loan must be an incoming (income) transaction');
      return;
    }
    await loanController.registerBorrowedLoanFromTransaction(txn);
  }

  transactionController.clearSelection();
  AppSnackbar.showSuccess('Borrowed loan registered');
}

Future<void> applyLentLoanCategoryToSelected() async {
  final transactionController = Get.find<TransactionController>();
  final loanController = Get.find<LoanController>();

  if (transactionController.selectedTransactionIds.isEmpty) {
    AppSnackbar.showError('Select a transaction first');
    return;
  }

  for (final txnId in transactionController.selectedTransactionIds) {
    final txn = transactionController.transactions.firstWhere(
      (t) => t.id == txnId,
    );
    if (txn.type != 'Expense') {
      AppSnackbar.showError('Lent loan must be an outgoing (expense) transaction');
      return;
    }
    await loanController.registerLentLoanFromTransaction(txn);
  }

  transactionController.clearSelection();
  AppSnackbar.showSuccess('Loan to someone registered');
}

@Deprecated('Use applyBorrowedLoanCategoryToSelected')
Future<void> applyLoanCategoryToSelected() => applyBorrowedLoanCategoryToSelected();

void showLoanReturnPairDialog(
  BuildContext context,
  Transaction returnTransaction,
) {
  final loanController = Get.find<LoanController>();
  final transactionController = Get.find<TransactionController>();
  final formatter = NumberFormat('#,##0.00');
  final dateLabel = DateFormat.yMMMd().format(returnTransaction.dateOf);

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520, maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Link Return', style: AppTextStyles.headline1),
                const SizedBox(height: 8),
                Text(
                  'Return of ${formatter.format(returnTransaction.amount)} '
                  'on $dateLabel. Choose which loan you gave out this pays back.',
                  style: AppTextStyles.body1,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Obx(() {
                    final transactions = transactionController.transactions;
                    final openLentLoans =
                        loanController.openLentLoans(transactions);

                    if (openLentLoans.isEmpty) {
                      return Center(
                        child: Text(
                          'No open lent loans. Categorize outgoing money as Loan (expense) first.',
                          style: AppTextStyles.body1,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: openLentLoans.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final loan = openLentLoans[index];
                        final remaining = loanController.remainingBalance(
                          loan,
                          transactions,
                        );
                        final returned = loanController.totalReturnedForLoan(
                          loan,
                          transactions,
                        );
                        final label = loan.counterpartyName?.isNotEmpty == true
                            ? loan.counterpartyName!
                            : 'Loan #${loan.id}';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(label, style: AppTextStyles.body1),
                          subtitle: Text(
                            'Lent ${formatter.format(loan.principalAmount)} · '
                            'Returned ${formatter.format(returned)} · '
                            'Remaining ${formatter.format(remaining)}',
                            style: AppTextStyles.lightBody1,
                          ),
                          trailing: const Icon(Icons.link),
                          onTap: () async {
                            try {
                              await loanController.linkReturn(
                                returnTransaction,
                                loan,
                                transactions,
                              );
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              AppSnackbar.showSuccess('Return linked to loan');
                            } catch (e) {
                              AppSnackbar.showError(e.toString());
                            }
                          },
                        );
                      },
                    );
                  }),
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

void showLoanRepaymentPairDialog(
  BuildContext context,
  Transaction repaymentTransaction,
) {
  final loanController = Get.find<LoanController>();
  final transactionController = Get.find<TransactionController>();
  final formatter = NumberFormat('#,##0.00');
  final dateLabel = DateFormat.yMMMd().format(repaymentTransaction.dateOf);

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520, maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Link Loan Repayment', style: AppTextStyles.headline1),
                const SizedBox(height: 8),
                Text(
                  'Repayment of ${formatter.format(repaymentTransaction.amount)} '
                  'on $dateLabel. Choose which borrowed loan this pays down.',
                  style: AppTextStyles.body1,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Obx(() {
                    final transactions = transactionController.transactions;
                    final openBorrowedLoans =
                        loanController.openBorrowedLoans(transactions);

                    if (openBorrowedLoans.isEmpty) {
                      return Center(
                        child: Text(
                          'No open borrowed loans. Categorize incoming money as Loan (income) first.',
                          style: AppTextStyles.body1,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: openBorrowedLoans.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final loan = openBorrowedLoans[index];
                        final remaining = loanController.remainingBalance(
                          loan,
                          transactions,
                        );
                        final repaid = loanController.totalRepaidForLoan(
                          loan,
                          transactions,
                        );
                        final label = loan.counterpartyName?.isNotEmpty == true
                            ? loan.counterpartyName!
                            : 'Loan #${loan.id}';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(label, style: AppTextStyles.body1),
                          subtitle: Text(
                            'Borrowed ${formatter.format(loan.principalAmount)} · '
                            'Repaid ${formatter.format(repaid)} · '
                            'Remaining ${formatter.format(remaining)}',
                            style: AppTextStyles.lightBody1,
                          ),
                          trailing: const Icon(Icons.link),
                          onTap: () async {
                            try {
                              await loanController.linkRepayment(
                                repaymentTransaction,
                                loan,
                                transactions,
                              );
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              AppSnackbar.showSuccess('Repayment linked to loan');
                            } catch (e) {
                              AppSnackbar.showError(e.toString());
                            }
                          },
                        );
                      },
                    );
                  }),
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
