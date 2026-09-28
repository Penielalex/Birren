import 'package:birren/data/models/sms_message_model.dart';
import 'package:birren/presentation/controllers/bank_controller.dart';
import 'package:birren/presentation/controllers/budget_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/util/category.dart';
import 'package:birren/presentation/widgets/app_dialog.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:birren/presentation/widgets/category_picker_dialog.dart';
import 'package:birren/presentation/widgets/shared_expense_split_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../domain/entities/transaction.dart';

class TransactionDetailPage extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  final TransactionController transactionController =
      Get.find<TransactionController>();
  final BankController bankController = Get.find<BankController>();
  final BudgetController budgetController = Get.find<BudgetController>();

  SmsMessageModel? _sms;
  bool _isLoadingSms = true;

  @override
  void initState() {
    super.initState();
    _loadSms();
  }

  Future<void> _loadSms() async {
    final sms =
        await transactionController.findSmsForTransaction(widget.transaction);
    if (mounted) {
      setState(() {
        _sms = sms;
        _isLoadingSms = false;
      });
    }
  }

  Transaction get _currentTransaction {
    try {
      return transactionController.transactions.firstWhere(
        (t) => t.id == widget.transaction.id,
      );
    } catch (_) {
      return widget.transaction;
    }
  }

  String? _budgetLineItemName(Transaction transaction) {
    if (transaction.budgetLineItemId == null) return null;
    final budget = budgetController.activeBudget.value;
    if (budget == null) return 'Budget item #${transaction.budgetLineItemId}';
    for (final item in budget.lineItems) {
      if (item.id == transaction.budgetLineItemId) return item.name;
    }
    for (final past in budgetController.budgetHistory) {
      for (final item in past.lineItems) {
        if (item.id == transaction.budgetLineItemId) return item.name;
      }
    }
    return 'Budget item #${transaction.budgetLineItemId}';
  }

  Future<void> _editAmount(BuildContext context, Transaction transaction) async {
    if (transaction.id == null) return;
    final controller = TextEditingController(
      text: transaction.amount.toStringAsFixed(2),
    );
    final formatter = NumberFormat('#,##0.00');

    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AppDialog(
          title: 'Edit amount',
          subtitle: 'Update the amount for this transaction',
          showCloseButton: false,
          scrollable: false,
          maxHeight: 280,
          actions: [
            AppDialogActions.cancel(
              dialogContext,
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            AppDialogActions.primary(
              label: 'Save',
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
          child: AppDialogField(
            controller: controller,
            hintText: 'Amount in birr',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
        );
      },
    );

    if (confirmed != true) {
      controller.dispose();
      return;
    }

    final parsed = double.tryParse(controller.text.replaceAll(',', '').trim());
    controller.dispose();
    if (parsed == null || parsed <= 0) {
      AppSnackbar.showError('Enter a valid amount greater than 0');
      return;
    }
    if ((parsed - transaction.amount).abs() < 0.0001) return;

    await transactionController.editTransaction(
      transaction.id!,
      null,
      null,
      null,
      parsed,
      null,
    );
    AppSnackbar.showSuccess(
      'Amount updated to ${formatter.format(parsed)} birr',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final transaction = _currentTransaction;
      final bank = bankController.banks.firstWhere(
        (b) => b.id == transaction.bankId,
        orElse: () => throw Exception('Bank not found'),
      );
      final linked = transactionController.findLinkedTransaction(transaction);
      final amountPrefix = transaction.type == 'Income' ? '+' : '-';
      final formattedAmount =
          NumberFormat('#,##0.00').format(transaction.amount);
      final budgetItemName = _budgetLineItemName(transaction);
      final splitTransactions =
          transactionController.transactionsInSplitGroup(transaction);
      final splitTotal = splitTransactions.fold<double>(
        0,
        (sum, item) => sum + item.amount,
      );

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text('Transaction Details', style: AppTextStyles.headline1),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailCard(
                children: [
                  _DetailRow(
                    label: 'Amount',
                    value: '$amountPrefix$formattedAmount birr',
                    emphasize: true,
                  ),
                  _DetailRow(
                    label: 'Type',
                    value: transaction.type,
                  ),
                  _DetailRow(
                    label: 'Category',
                    value: categoryDisplayName(
                      transaction.category,
                      transaction.type,
                    ),
                  ),
                  if (budgetItemName != null)
                    _DetailRow(
                      label: 'Budget item',
                      value: budgetItemName,
                    ),
                  _DetailRow(
                    label: 'Bank',
                    value: bank.displayName ?? bank.bankName,
                  ),
                  _DetailRow(
                    label: 'Date',
                    value:
                        DateFormat.yMMMMd().add_jm().format(transaction.dateOf),
                  ),
                  if (transaction.transferId != null) ...[
                    const Divider(color: Colors.white24),
                    _DetailRow(
                      label: 'Linked transfer',
                      value: linked != null
                          ? '${linked.type} • ${NumberFormat('#,##0.00').format(linked.amount)} birr'
                          : 'Transaction #${transaction.transferId}',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => editTransactionCategory(context, transaction),
                child: Text(
                  transactionHasNoCategory(transaction.category)
                      ? 'Set Category'
                      : 'Edit Category / Budget Item',
                  style: AppTextStyles.smallButton1.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                ),
                onPressed: () => _editAmount(context, transaction),
                child: Text(
                  'Edit amount',
                  style: AppTextStyles.smallButton1.copyWith(color: Colors.white),
                ),
              ),
              if (transaction.type == 'Expense') ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                  onPressed: () =>
                      showSharedExpenseSplitDialog(context, transaction),
                  icon: const Icon(Icons.call_split, size: 18),
                  label: Text(
                    'Split shared expense',
                    style: AppTextStyles.smallButton1
                        .copyWith(color: AppColors.accent),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (splitTransactions.length > 1) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.call_split_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This transaction is one of '
                          '${splitTransactions.length} entries split from the '
                          'same ${NumberFormat('#,##0.00').format(splitTotal)} '
                          'birr payment. They share the original SMS below.',
                          style: AppTextStyles.body1.copyWith(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text('Original SMS', style: AppTextStyles.headline1),
              const SizedBox(height: 8),
              _DetailCard(
                children: [
                  if (_isLoadingSms)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: LoadingAnimationWidget.progressiveDots(
                          color: AppColors.accent,
                          size: 48,
                        ),
                      ),
                    )
                  else if (_sms?.body != null && _sms!.body!.trim().isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_sms!.date != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Received ${DateFormat.yMMMMd().add_jm().format(_sms!.date!)}',
                              style: AppTextStyles.body1,
                            ),
                          ),
                        SelectableText(
                          _sms!.body!,
                          style: AppTextStyles.body1.copyWith(height: 1.5),
                        ),
                      ],
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No matching SMS found for this transaction.',
                        style: AppTextStyles.body1,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.body1,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: emphasize
                  ? AppTextStyles.headline2.copyWith(fontSize: 20)
                  : AppTextStyles.body1,
            ),
          ),
        ],
      ),
    );
  }
}
