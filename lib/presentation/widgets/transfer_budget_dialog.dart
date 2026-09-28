import 'package:birren/domain/entities/budget.dart';
import 'package:birren/domain/entities/budget_line_item.dart';
import 'package:birren/presentation/controllers/budget_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/app_dialog.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

Future<void> showTransferBudgetDialog(
  BuildContext context, {
  required Budget budget,
}) async {
  final lineItems = budget.lineItems.where((i) => i.id != null).toList();
  if (lineItems.length < 2) {
    AppSnackbar.showError('Need at least two budget items to transfer');
    return;
  }

  final budgetController = Get.find<BudgetController>();
  final transactionController = Get.find<TransactionController>();
  final formatter = NumberFormat('#,##0.00');
  final amountController = TextEditingController();

  var fromId = lineItems.first.id!;
  var toId = lineItems[1].id!;

  BudgetLineItem itemById(int id) =>
      lineItems.firstWhere((i) => i.id == id);

  await showAppDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final fromItem = itemById(fromId);
          final spent = budgetController.spentForLineItemInBudget(
            budget,
            fromItem,
            transactionController.transactions,
          );
          final unspent = (fromItem.allocatedAmount - spent)
              .clamp(0.0, fromItem.allocatedAmount)
              .toDouble();

          return AppDialog(
            title: 'Transfer allocation',
            subtitle: 'Move budget from one item to another',
            scrollable: true,
            maxHeight: 480,
            actions: [
              AppDialogActions.cancel(dialogContext),
              AppDialogActions.primary(
                label: 'Transfer',
                onPressed: () async {
                  final amount = double.tryParse(
                    amountController.text.trim().replaceAll(',', ''),
                  );
                  if (amount == null || amount <= 0) {
                    AppSnackbar.showError('Enter an amount greater than 0');
                    return;
                  }
                  if (fromId == toId) {
                    AppSnackbar.showError('Pick two different budget items');
                    return;
                  }

                  try {
                    await budgetController.transferAllocatedAmount(
                      budget: budget,
                      fromLineItemId: fromId,
                      toLineItemId: toId,
                      amount: amount,
                    );
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    AppSnackbar.showSuccess(
                      'Moved ${formatter.format(amount)} birr',
                    );
                  } catch (e) {
                    AppSnackbar.showError(e.toString());
                  }
                },
              ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('From', style: AppTextStyles.body1),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: fromId,
                  dropdownColor: AppColors.surface,
                  decoration: appDialogInputDecoration(),
                  style: AppTextStyles.midBody1,
                  items: lineItems
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            '${item.name} (${formatter.format(item.allocatedAmount)})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() {
                      fromId = value;
                      if (toId == fromId) {
                        toId = lineItems
                            .firstWhere((i) => i.id != fromId)
                            .id!;
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Allocated ${formatter.format(fromItem.allocatedAmount)} · '
                  'Spent ${formatter.format(spent)} · '
                  'Unspent ${formatter.format(unspent)}',
                  style: AppTextStyles.lightBody1.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 16),
                Text('To', style: AppTextStyles.body1),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: toId,
                  dropdownColor: AppColors.surface,
                  decoration: appDialogInputDecoration(),
                  style: AppTextStyles.midBody1,
                  items: lineItems
                      .where((i) => i.id != fromId)
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            '${item.name} (${formatter.format(item.allocatedAmount)})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => toId = value);
                  },
                ),
                const SizedBox(height: 16),
                AppDialogField(
                  controller: amountController,
                  hintText: 'Amount to move',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: unspent <= 0
                        ? null
                        : () {
                            amountController.text =
                                unspent.toStringAsFixed(2);
                          },
                    child: Text(
                      'Use unspent (${formatter.format(unspent)})',
                      style: AppTextStyles.body1.copyWith(
                        color: unspent <= 0
                            ? AppColors.mutedText
                            : AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  amountController.dispose();
}
