import 'package:birren/domain/entities/budget.dart';
import 'package:birren/presentation/controllers/budget_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/pages/budget_line_item_transactions_page.dart';
import 'package:birren/presentation/widgets/budget_context_menu.dart';
import 'package:birren/presentation/widgets/budget_line_item_row.dart';
import 'package:birren/presentation/widgets/create_budget_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BudgetHistoryPage extends StatefulWidget {
  const BudgetHistoryPage({super.key});

  @override
  State<BudgetHistoryPage> createState() => _BudgetHistoryPageState();
}

class _BudgetHistoryPageState extends State<BudgetHistoryPage> {
  final List<GlobalKey> _cardKeys = [];

  void _ensureKeys(int count) {
    while (_cardKeys.length < count) {
      _cardKeys.add(GlobalKey());
    }
    if (_cardKeys.length > count) {
      _cardKeys.removeRange(count, _cardKeys.length);
    }
  }

  void _showBudgetActions(Budget budget, GlobalKey cardKey) {
    if (budget.id == null) return;

    showBudgetContextMenu(
      context: context,
      anchorKey: cardKey,
      onEdit: () => showEditBudgetDialog(context, budget),
      onDelete: () async {
        final budgetController = Get.find<BudgetController>();
        await budgetController.deleteBudget(budget.id!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetController = Get.find<BudgetController>();
    final transactionController = Get.find<TransactionController>();
    final formatter = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: const Color(0xFF19173D),
      appBar: AppBar(
        title: Text('Budget history', style: AppTextStyles.headline1),
        backgroundColor: const Color(0xFF19173D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (budgetController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = budgetController.budgetHistory;
        _ensureKeys(history.length);

        if (history.isEmpty) {
          return Center(
            child: Text(
              'No past budgets yet.',
              style: AppTextStyles.body1,
            ),
          );
        }

        return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final budget = history[index];
          final cardKey = _cardKeys[index];
          final spent = budgetController.totalSpentForBudget(
            budget,
            transactionController.transactions,
          );
          final income = budgetController.incomeTotalForBudget(
            budget,
            transactionController.transactions,
          );

          return GestureDetector(
            key: cardKey,
            onLongPress: () => _showBudgetActions(budget, cardKey),
            child: Card(
              color: const Color(0xFF262450),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                iconColor: Colors.white,
                collapsedIconColor: Colors.white,
                title: Text(budget.name, style: AppTextStyles.headline1),
                subtitle: Text(
                  '${DateFormat.yMMMd().format(budget.startDate)} – '
                  '${DateFormat.yMMMd().format(budget.endDate)}',
                  style: AppTextStyles.body1,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HistoryRow(
                          label: 'Total budget',
                          value:
                              '${formatter.format(budget.totalAllocated)} birr',
                        ),
                        _HistoryRow(
                          label: 'Total spent',
                          value: '${formatter.format(spent)} birr',
                        ),
                        _HistoryRow(
                          label: 'Income',
                          value: '${formatter.format(income)} birr',
                        ),
                        const SizedBox(height: 8),
                        Text('Items', style: AppTextStyles.body1),
                        const SizedBox(height: 8),
                        ...budget.lineItems.map((item) {
                          final itemSpent =
                              budgetController.spentForLineItemInBudget(
                            budget,
                            item,
                            transactionController.transactions,
                          );
                          return BudgetLineItemRow(
                            name: item.name,
                            spent: itemSpent,
                            allocated: item.allocatedAmount,
                            onTap: item.id == null
                                ? null
                                : () {
                                    Get.to(() =>
                                        BudgetLineItemTransactionsPage(
                                          budget: budget,
                                          lineItem: item,
                                        ));
                                  },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      }),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String label;
  final String value;

  const _HistoryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body1),
          Text(value, style: AppTextStyles.body1),
        ],
      ),
    );
  }
}
