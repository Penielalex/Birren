import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:birren/core/app_logger.dart';
import '../controllers/transaction_controller.dart';
import '../theme/colors.dart';
import '../theme/text_style.dart';
import '../widgets/category_picker_dialog.dart';
import '../widgets/transaction_card.dart';

class NotificationsPage extends StatefulWidget {
  NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final TransactionController transactionController =
      Get.find<TransactionController>();
  final logger = appLogger;

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      transactionController.clearSelection();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedCount = transactionController.selectedTransactionIds.length;

      final selectedTransactions = transactionController.transactions
          .where(
            (txn) =>
                transactionController.selectedTransactionIds.contains(txn.id),
          )
          .toList();

      final bool allSameType;
      final String? commonType;

      if (selectedTransactions.isEmpty) {
        allSameType = false;
        commonType = null;
      } else {
        final firstType = selectedTransactions.first.type;
        allSameType =
            selectedTransactions.every((txn) => txn.type == firstType);
        commonType = allSameType ? firstType : null;
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          centerTitle: false,
          backgroundColor: AppColors.background,
          elevation: 1,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          title: selectedCount > 0
              ? Text(
                  '$selectedCount selected',
                  style: AppTextStyles.headline1,
                )
              : Text('Notifications', style: AppTextStyles.headline1),
          actions: selectedCount > 0
              ? [
                  TextButton(
                    onPressed: () {
                      transactionController.clearSelection();
                    },
                    child: Text(
                      'Clear',
                      style: AppTextStyles.body1.copyWith(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (allSameType) {
                        showCategoryDialog(context, commonType!);
                      } else {
                        AppSnackbar.showError(
                          'Can not select multiple transactions with different types(Income or Expense)',
                        );
                      }
                    },
                    child: Text(
                      'Set Category',
                      style: AppTextStyles.body1.copyWith(color: Colors.white),
                    ),
                  ),
                ]
              : null,
        ),
        body: Obx(() {
          final txns = transactionController.notificationTransaction;

          if (txns.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet',
                style: AppTextStyles.body1,
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Please set categories for imported transactions. Outgoing Loan (expense) tracks money you lent; link incoming Returns to it. Incoming Loan (income) tracks money you borrowed; link outgoing Loan Repayment to it. Transfer Fee uses its budget item automatically.',
                  style: AppTextStyles.body1,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: txns.length,
                  itemBuilder: (context, index) {
                    return TransactionCard(
                      transaction: txns[index],
                      fromNotification: true,
                      onSetCategoryPressed: () {
                        editTransactionCategory(context, txns[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }),
      );
    });
  }
}
