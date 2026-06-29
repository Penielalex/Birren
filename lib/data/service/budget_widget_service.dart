import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../presentation/controllers/budget_controller.dart';
import '../../presentation/controllers/transaction_controller.dart';
import '../../presentation/util/budget_usage.dart';

class BudgetWidgetService {
  static const androidWidgetReceiver =
      'com.example.birren.BudgetHomeWidgetReceiver';
  static const snapshotKey = 'budget_snapshot';

  static Future<void> syncFromControllers() async {
    if (!Platform.isAndroid) return;

    try {
      if (!Get.isRegistered<BudgetController>() ||
          !Get.isRegistered<TransactionController>()) {
        return;
      }

      final budgetController = Get.find<BudgetController>();
      final transactionController = Get.find<TransactionController>();
      final budget = budgetController.activeBudget.value;
      final formatter = NumberFormat('#,##0.00');

      final Map<String, dynamic> snapshot;
      if (budget == null) {
        snapshot = {'hasBudget': false};
      } else {
        final totalAllocated = budgetController.totalAllocated;
        final totalSpent = budgetController.totalSpent(
          transactionController.transactions,
        );
        final remaining = totalAllocated - totalSpent;

        snapshot = {
          'hasBudget': true,
          'name': budget.name,
          'dateRange':
              '${DateFormat.yMMMd().format(budget.startDate)} – '
              '${DateFormat.yMMMd().format(budget.endDate)}',
          'total': formatter.format(totalAllocated),
          'spent': formatter.format(totalSpent),
          'remaining': formatter.format(remaining),
          'isExpired': budget.isExpired,
          'lineItems': budget.lineItems.map((item) {
            final spent = budgetController.spentForLineItem(
              item,
              transactionController.transactions,
            );
            final allocated = item.allocatedAmount;
            final progress = allocated > 0
                ? (spent / allocated).clamp(0.0, 1.0)
                : 0.0;
            return {
              'name': item.name,
              'spent': formatter.format(spent),
              'allocated': formatter.format(allocated),
              'progress': progress,
              'color': budgetUsageColorName(spent, allocated),
            };
          }).toList(),
        };
      }

      await HomeWidget.saveWidgetData(snapshotKey, jsonEncode(snapshot));
      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidWidgetReceiver,
      );
    } catch (_) {
      // Widget may not be installed yet.
    }
  }
}
