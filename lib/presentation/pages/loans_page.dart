import 'package:birren/domain/entities/loan.dart';
import 'package:birren/domain/entities/transaction.dart';
import 'package:birren/presentation/controllers/bank_controller.dart';
import 'package:birren/presentation/controllers/loan_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/close_loan_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LoansPage extends StatefulWidget {
  const LoansPage({super.key});

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  final LoanController loanController = Get.find<LoanController>();
  final TransactionController transactionController =
      Get.find<TransactionController>();
  final BankController bankController = Get.find<BankController>();

  String _filter = 'open';

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00');

    return Obx(() {
      if (loanController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final filteredLoans = loanController.loans.where((loan) {
        if (_filter == 'open') return loan.isOpen;
        if (_filter == 'closed') return loan.isClosed;
        return true;
      }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                _filterChip('Open', 'open'),
                const SizedBox(width: 8),
                _filterChip('Closed', 'closed'),
                const SizedBox(width: 8),
                _filterChip('All', 'all'),
              ],
            ),
          ),
          Expanded(
            child: filteredLoans.isEmpty
                ? Center(
                    child: Text(
                      _filter == 'open'
                          ? 'No open loans yet.\nLend: categorize outgoing money as Loan (expense).\nBorrow: categorize incoming money as Loan (income).'
                          : 'No loans in this view.',
                      style: AppTextStyles.body1,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredLoans.length,
                    itemBuilder: (context, index) {
                      final loan = filteredLoans[index];
                      return _LoanCard(
                        loan: loan,
                        formatter: formatter,
                        onClose: loan.isOpen
                            ? () => showCloseLoanDialog(context, loan)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label, style: AppTextStyles.body1),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.accent.withOpacity(0.4),
      checkmarkColor: Colors.white,
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final NumberFormat formatter;
  final VoidCallback? onClose;

  const _LoanCard({
    required this.loan,
    required this.formatter,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final loanController = Get.find<LoanController>();
    final transactionController = Get.find<TransactionController>();
    final bankController = Get.find<BankController>();
    final transactions = transactionController.transactions;

    final repaid = loanController.totalPaidDownForLoan(loan, transactions);
    final remaining = loanController.remainingBalance(loan, transactions);
    final disbursement = loanController.disbursementTransaction(loan, transactions);
    final linkedPayments =
        loanController.linkedPaymentsForLoan(loan, transactions);
    final isLent = loanController.isLentLoan(loan, transactions);
    final title = loan.counterpartyName?.isNotEmpty == true
        ? loan.counterpartyName!
        : 'Loan #${loan.id}';

    String bankLabel(Transaction? txn) {
      if (txn == null) return 'Unknown bank';
      for (final bank in bankController.banks) {
        if (bank.id == txn.bankId) {
          return bank.displayName ?? bank.bankName;
        }
      }
      return 'Unknown bank';
    }

    return Card(
      color: AppColors.background,
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.midBody1),
                      const SizedBox(height: 4),
                      Text(
                        loan.isOpen ? 'Open' : 'Closed',
                        style: AppTextStyles.lightBody1.copyWith(
                          color: loan.isOpen ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLent ? 'Lent to someone' : 'Borrowed',
                        style: AppTextStyles.lightBody1,
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  TextButton(
                    onPressed: onClose,
                    child: Text('Close', style: AppTextStyles.smallButton1),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _stat(
                    isLent ? 'Lent' : 'Borrowed',
                    formatter.format(loan.principalAmount),
                  ),
                ),
                Expanded(
                  child: _stat(
                    isLent ? 'Returned' : 'Repaid',
                    formatter.format(repaid),
                  ),
                ),
                Expanded(
                  child: _stat('Remaining', formatter.format(remaining)),
                ),
              ],
            ),
            if (disbursement != null) ...[
              const Divider(color: Colors.white24, height: 24),
              Text(
                isLent ? 'Money lent' : 'Money received',
                style: AppTextStyles.body1,
              ),
              const SizedBox(height: 8),
              _transactionRow(
                disbursement,
                bankLabel(disbursement),
                formatter,
                prefix: isLent ? '-' : '+',
              ),
            ],
            if (linkedPayments.isNotEmpty) ...[
              const Divider(color: Colors.white24, height: 24),
              Text(
                isLent
                    ? 'Returns (${linkedPayments.length})'
                    : 'Repayments (${linkedPayments.length})',
                style: AppTextStyles.body1,
              ),
              const SizedBox(height: 8),
              ...linkedPayments.map(
                (txn) => _transactionRow(
                  txn,
                  bankLabel(txn),
                  formatter,
                  prefix: isLent ? '+' : '-',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.midBody1),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.lightBody1),
      ],
    );
  }

  Widget _transactionRow(
    Transaction txn,
    String bank,
    NumberFormat formatter, {
    required String prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${DateFormat.yMMMd().format(txn.dateOf)} · $bank',
              style: AppTextStyles.lightBody1,
            ),
          ),
          Text(
            '$prefix${formatter.format(txn.amount)}',
            style: AppTextStyles.body1,
          ),
        ],
      ),
    );
  }
}
