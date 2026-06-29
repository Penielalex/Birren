import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_style.dart';

class BudgetCard extends StatefulWidget {  final String budgetName;
  final String dateRange;
  final String totalBudget;
  final String totalSpent;
  final String remaining;
  final bool isExpired;
  final bool hasBudget;
  final VoidCallback onCreateBudget;
  final List<Widget> lineItemRows;

  const BudgetCard({
    super.key,
    required this.budgetName,
    required this.dateRange,
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.isExpired,
    required this.hasBudget,
    required this.onCreateBudget,
    this.lineItemRows = const [],
  });

  @override
  State<BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<BudgetCard> {
  @override
  Widget build(BuildContext context) {    if (!widget.hasBudget) {
      return Card(
        color: AppColors.background,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No active budget', style: AppTextStyles.midBody1),
                    const SizedBox(height: 4),
                    Text(
                      'Create a budget with a date range and categories.',
                      style: AppTextStyles.lightBody1,
                    ),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: widget.onCreateBudget,
                child: Text('Create', style: AppTextStyles.smallButton1),
              ),
            ],
          ),
        ),
      );
    }

    final stats = [
      ('Total', widget.totalBudget),
      ('Spent', widget.totalSpent),
      ('Left', widget.remaining),
    ];

    return Card(      color: AppColors.background,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isExpired ? Colors.grey : AppColors.accent,
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.budgetName, style: AppTextStyles.midBody1),
                      const SizedBox(height: 4),
                      Text(widget.dateRange, style: AppTextStyles.lightBody1),
                      if (widget.isExpired)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Budget period ended',
                            style: AppTextStyles.body1.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.isExpired)
                  TextButton(
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: widget.onCreateBudget,
                    child: Text(
                      'New cycle',
                      style: AppTextStyles.smallButton1,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: stats
                  .map(
                    (stat) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stat.$1, style: AppTextStyles.midBody1),
                            const SizedBox(height: 4),
                            Text(
                              stat.$2,
                              style: AppTextStyles.lightBody1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),            if (widget.lineItemRows.isNotEmpty) ...[
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Text('Budget items', style: AppTextStyles.body1),
              const SizedBox(height: 8),
              ...widget.lineItemRows,
            ],
          ],
        ),
      ),
    );
  }
}
