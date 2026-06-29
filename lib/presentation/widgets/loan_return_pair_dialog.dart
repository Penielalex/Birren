import 'package:birren/presentation/controllers/loan_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';

Future<void> applyLoanCategoryToSelected() async {
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
      AppSnackbar.showError('Loan must be an incoming (income) transaction');
      return;
    }
    await loanController.registerLoanFromTransaction(txn);
  }

  transactionController.clearSelection();
  AppSnackbar.showSuccess('Borrowed loan registered');
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
                  'on $dateLabel. Choose which open loan this pays down.',
                  style: AppTextStyles.body1,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Obx(() {
                    final openLoans = loanController.openLoans;
                    final transactions = transactionController.transactions;

                    if (openLoans.isEmpty) {
                      return Center(
                        child: Text(
                          'No open loans. Register incoming money as Loan (income) first.',
                          style: AppTextStyles.body1,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: openLoans.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final loan = openLoans[index];
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

/// Backwards-compatible alias.
void showLoanReturnPairDialog(
  BuildContext context,
  Transaction repaymentTransaction,
) =>
    showLoanRepaymentPairDialog(context, repaymentTransaction);
