import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/transaction_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction.dart';

class DateTransactionsPage extends StatelessWidget {
  final DateTime filterDate;
  final bool isMonthlyView;

  const DateTransactionsPage({
    Key? key,
    required this.filterDate,
    required this.isMonthlyView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TransactionController transactionController = Get.find<TransactionController>();

    // Determine Page Title
    final String pageTitle = isMonthlyView
        ? DateFormat.yMMMM().format(filterDate) // e.g. "November 2025"
        : DateFormat.yMMMMd().format(filterDate); // e.g. "November 12, 2025"

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(pageTitle, style: AppTextStyles.headline1),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        // Filter transactions for the requested day or month
        final List<Transaction> filteredTransactions = transactionController.transactions.where((t) {
          if (isMonthlyView) {
            return t.dateOf.year == filterDate.year && t.dateOf.month == filterDate.month;
          } else {
            return t.dateOf.year == filterDate.year &&
                t.dateOf.month == filterDate.month &&
                t.dateOf.day == filterDate.day;
          }
        }).toList();

        if (filteredTransactions.isEmpty) {
          return Center(
            child: Text(
              "No transactions found.",
              style: AppTextStyles.body1,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8.0),
          itemCount: filteredTransactions.length,
          itemBuilder: (context, index) {
            return TransactionCard(
              transaction: filteredTransactions[index],
              fromNotification: false,
              onSetCategoryPressed: () {},
            );
          },
        );
      }),
    );
  }
}
