import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/text_style.dart';
import '../util/budget_usage.dart';

class BudgetLineItemRow extends StatelessWidget {
  final String name;
  final double spent;
  final double allocated;
  final VoidCallback? onTap;

  const BudgetLineItemRow({
    super.key,
    required this.name,
    required this.spent,
    required this.allocated,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00');
    final progress =
        allocated > 0 ? (spent / allocated).clamp(0.0, 1.0).toDouble() : 0.0;
    final barColor = budgetUsageColor(spent, allocated);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(name, style: AppTextStyles.body1),
                  ),
                  Text(
                    '${formatter.format(spent)} / ${formatter.format(allocated)}',
                    style: AppTextStyles.body1,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),            ],
          ),
        ),
      ),
    );
  }
}
