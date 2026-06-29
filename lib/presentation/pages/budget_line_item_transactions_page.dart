import 'package:birren/domain/entities/budget.dart';
import 'package:birren/domain/entities/budget_line_item.dart';
import 'package:birren/presentation/controllers/budget_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/transaction_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BudgetLineItemTransactionsPage extends StatelessWidget {
  final Budget budget;
  final BudgetLineItem lineItem;

  const BudgetLineItemTransactionsPage({
    super.key,
    required this.budget,
    required this.lineItem,
  });

  @override
  Widget build(BuildContext context) {
    final budgetController = Get.find<BudgetController>();
    final transactionController = Get.find<TransactionController>();
    final formatter = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lineItem.name, style: AppTextStyles.headline1),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final spent = budgetController.spentForLineItemInBudget(
          budget,
          lineItem,
          transactionController.transactions,
        );
        final filtered = budgetController.transactionsForLineItemInBudget(
          budget,
          lineItem,
          transactionController.transactions,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                '${formatter.format(spent)} / ${formatter.format(lineItem.allocatedAmount)} birr',
                style: AppTextStyles.body1,
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No transactions linked to this item yet.',
                        style: AppTextStyles.body1,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return TransactionCard(
                          transaction: filtered[index],
                          fromNotification: false,
                          onSetCategoryPressed: () {},
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}
