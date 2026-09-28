import 'package:birren/domain/entities/loan.dart';
import 'package:birren/presentation/controllers/loan_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/app_dialog.dart';
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
      AppSnackbar.showError(
        'Borrowed loan must be an incoming (income) transaction',
      );
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
      AppSnackbar.showError(
        'Lent loan must be an outgoing (expense) transaction',
      );
      return;
    }
    await loanController.registerLentLoanFromTransaction(txn);
  }

  transactionController.clearSelection();
  AppSnackbar.showSuccess('Loan to someone registered');
}

@Deprecated('Use applyBorrowedLoanCategoryToSelected')
Future<void> applyLoanCategoryToSelected() =>
    applyBorrowedLoanCategoryToSelected();

void showLoanReturnPairDialog(
  BuildContext context,
  Transaction returnTransaction,
) {
  showAppDialog(
    context: context,
    builder: (_) => _MultiLoanAllocationDialog(
      payment: returnTransaction,
      isReturn: true,
    ),
  );
}

void showLoanRepaymentPairDialog(
  BuildContext context,
  Transaction repaymentTransaction,
) {
  showAppDialog(
    context: context,
    builder: (_) => _MultiLoanAllocationDialog(
      payment: repaymentTransaction,
      isReturn: false,
    ),
  );
}

class _MultiLoanAllocationDialog extends StatefulWidget {
  final Transaction payment;
  final bool isReturn;

  const _MultiLoanAllocationDialog({
    required this.payment,
    required this.isReturn,
  });

  @override
  State<_MultiLoanAllocationDialog> createState() =>
      _MultiLoanAllocationDialogState();
}

class _MultiLoanAllocationDialogState extends State<_MultiLoanAllocationDialog> {
  final _formatter = NumberFormat('#,##0.00');
  final Map<int, TextEditingController> _controllers = {};
  bool _saving = false;

  LoanController get _loanController => Get.find<LoanController>();
  TransactionController get _txnController => Get.find<TransactionController>();

  double get _paymentTotal => widget.payment.amount;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int loanId) {
    return _controllers.putIfAbsent(
      loanId,
      () => TextEditingController(),
    );
  }

  double _parse(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  double _allocatedTotal(List<Loan> loans) {
    var sum = 0.0;
    for (final loan in loans) {
      if (loan.id == null) continue;
      sum += _parse(_controllerFor(loan.id!).text);
    }
    return sum;
  }

  void _setAmount(int loanId, double amount) {
    _controllerFor(loanId).text =
        amount <= 0 ? '' : amount.toStringAsFixed(2);
  }

  void _autoFillOldestFirst(List<Loan> loans, List<Transaction> transactions) {
    var remainingPayment = _paymentTotal;
    for (final loan in loans) {
      if (loan.id == null) continue;
      if (remainingPayment <= 0.001) {
        _setAmount(loan.id!, 0);
        continue;
      }
      final remaining = _loanController.remainingBalance(loan, transactions);
      final take = remaining < remainingPayment ? remaining : remainingPayment;
      _setAmount(loan.id!, take);
      remainingPayment =
          double.parse((remainingPayment - take).toStringAsFixed(2));
    }
    setState(() {});
  }

  void _clearAll(List<Loan> loans) {
    for (final loan in loans) {
      if (loan.id == null) continue;
      _setAmount(loan.id!, 0);
    }
    setState(() {});
  }

  Future<void> _submit(List<Loan> loans, List<Transaction> transactions) async {
    final allocations = <({Loan loan, double amount})>[];
    for (final loan in loans) {
      if (loan.id == null) continue;
      final amount = _parse(_controllerFor(loan.id!).text);
      if (amount <= 0) continue;
      final remaining = _loanController.remainingBalance(loan, transactions);
      if (amount > remaining + 0.05) {
        AppSnackbar.showError(
          'Amount for ${loan.counterpartyName ?? 'loan #${loan.id}'} '
          'exceeds remaining ${_formatter.format(remaining)}',
        );
        return;
      }
      allocations.add((loan: loan, amount: amount));
    }

    if (allocations.isEmpty) {
      AppSnackbar.showError('Enter an amount for at least one loan');
      return;
    }

    final total = allocations.fold<double>(0, (s, a) => s + a.amount);
    if (total > _paymentTotal + 0.05) {
      AppSnackbar.showError(
        'Allocated ${_formatter.format(total)} cannot exceed '
        'payment ${_formatter.format(_paymentTotal)}',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _loanController.allocatePaymentAcrossLoans(
        payment: widget.payment,
        allocations: allocations,
        isReturn: widget.isReturn,
      );
      _txnController.clearSelection();
      if (mounted) Navigator.pop(context);
      final remainder = _paymentTotal -
          allocations.fold<double>(0, (sum, item) => sum + item.amount);
      AppSnackbar.showSuccess(
        remainder > 0.05
            ? '${_formatter.format(remainder)} saved as a separate Other transaction'
            : widget.isReturn
                ? 'Return split across ${allocations.length} loan(s)'
                : 'Repayment split across ${allocations.length} loan(s)',
      );
    } catch (e) {
      AppSnackbar.showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMd().format(widget.payment.dateOf);
    final title = widget.isReturn ? 'Allocate return' : 'Allocate repayment';
    final subtitle = widget.isReturn
        ? 'Payment of ${_formatter.format(_paymentTotal)} on $dateLabel. '
            'Split it across one or more loans / shared-expense shares.'
        : 'Payment of ${_formatter.format(_paymentTotal)} on $dateLabel. '
            'Split it across one or more borrowed loans.';

    return Obx(() {
      final transactions = _txnController.transactions;
      final loans = widget.isReturn
          ? _loanController.openLentLoans(transactions)
          : _loanController.openBorrowedLoans(transactions);
      final allocated = _allocatedTotal(loans);
      final leftover = _paymentTotal - allocated;
      final isOver = leftover < -0.05;

      return AppDialog(
        title: title,
        subtitle: subtitle,
        expandBody: true,
        scrollable: false,
        maxHeight: 620,
        actions: [
          AppDialogActions.cancel(context, enabled: !_saving),
          AppDialogActions.primary(
            label: 'Apply',
            isLoading: _saving,
            onPressed: loans.isEmpty
                ? null
                : () => _submit(loans, transactions),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isOver
                    ? AppColors.danger.withValues(alpha: 0.12)
                    : AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                leftover.abs() <= 0.05
                    ? 'Allocated ${_formatter.format(allocated)} / '
                        '${_formatter.format(_paymentTotal)}'
                    : leftover > 0
                        ? 'Allocated ${_formatter.format(allocated)} / '
                            '${_formatter.format(_paymentTotal)} · '
                            '${_formatter.format(leftover)} will be saved as Other'
                        : 'Allocated ${_formatter.format(allocated)} / '
                        '${_formatter.format(_paymentTotal)} · '
                        'over '
                        '${_formatter.format(leftover.abs())}',
                style: AppTextStyles.midBody1.copyWith(
                  color: isOver ? AppColors.danger : AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: loans.isEmpty
                      ? null
                      : () => _autoFillOldestFirst(loans, transactions),
                  child: Text(
                    'Auto-fill',
                    style: AppTextStyles.body1.copyWith(color: AppColors.accent),
                  ),
                ),
                TextButton(
                  onPressed: loans.isEmpty ? null : () => _clearAll(loans),
                  child: Text(
                    'Clear',
                    style: AppTextStyles.body1
                        .copyWith(color: AppColors.mutedText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: loans.isEmpty
                  ? Center(
                      child: Text(
                        widget.isReturn
                            ? 'No open lent loans. Categorize outgoing money as Loan (expense) first.'
                            : 'No open borrowed loans. Categorize incoming money as Loan (income) first.',
                        style: AppTextStyles.body1
                            .copyWith(color: AppColors.mutedText),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: loans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final loan = loans[index];
                        final remaining = _loanController.remainingBalance(
                          loan,
                          transactions,
                        );
                        final paid = widget.isReturn
                            ? _loanController.totalReturnedForLoan(
                                loan,
                                transactions,
                              )
                            : _loanController.totalRepaidForLoan(
                                loan,
                                transactions,
                              );
                        final label =
                            loan.counterpartyName?.isNotEmpty == true
                                ? loan.counterpartyName!
                                : 'Loan #${loan.id}';
                        final controller = _controllerFor(loan.id!);

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.fieldFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(label, style: AppTextStyles.midBody1),
                              const SizedBox(height: 2),
                              Text(
                                widget.isReturn
                                    ? 'Lent ${_formatter.format(loan.principalAmount)} · '
                                        'Returned ${_formatter.format(paid)} · '
                                        'Left ${_formatter.format(remaining)}'
                                    : 'Borrowed ${_formatter.format(loan.principalAmount)} · '
                                        'Repaid ${_formatter.format(paid)} · '
                                        'Left ${_formatter.format(remaining)}',
                                style: AppTextStyles.lightBody1.copyWith(
                                  color: AppColors.mutedText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppDialogField(
                                      controller: controller,
                                      hintText: '0.00',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      final already = _allocatedTotal(loans) -
                                          _parse(controller.text);
                                      final room = _paymentTotal - already;
                                      final take = remaining < room
                                          ? remaining
                                          : (room > 0 ? room : 0.0);
                                      _setAmount(loan.id!, take);
                                      setState(() {});
                                    },
                                    child: Text(
                                      'Fill',
                                      style: AppTextStyles.body1
                                          .copyWith(color: AppColors.accent),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }
}
