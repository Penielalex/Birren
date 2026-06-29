import 'package:birren/data/models/sms_message_model.dart';
import 'package:birren/presentation/controllers/bank_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/util/category.dart';
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

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final bank = bankController.banks.firstWhere(
      (b) => b.id == transaction.bankId,
      orElse: () => throw Exception('Bank not found'),
    );
    final linked = transactionController.findLinkedTransaction(transaction);
    final amountPrefix = transaction.type == 'Income' ? '+' : '-';
    final formattedAmount =
        NumberFormat('#,##0.00').format(transaction.amount);

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
                _DetailRow(
                  label: 'Bank',
                  value: bank.displayName ?? bank.bankName,
                ),
                _DetailRow(
                  label: 'Date',
                  value: DateFormat.yMMMMd().add_jm().format(transaction.dateOf),
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
            const SizedBox(height: 20),
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
