import 'package:birren/domain/entities/loan.dart';
import 'package:birren/presentation/controllers/bank_controller.dart';
import 'package:birren/presentation/controllers/budget_controller.dart';
import 'package:birren/presentation/controllers/loan_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/util/budget_defaults.dart';
import 'package:birren/presentation/util/category.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

void showCloseLoanDialog(BuildContext context, Loan loan) {
  final loanController = Get.find<LoanController>();
  final transactionController = Get.find<TransactionController>();
  final bankController = Get.find<BankController>();
  final budgetController = Get.find<BudgetController>();
  final formatter = NumberFormat('#,##0.00');

  final remaining = loanController.remainingBalance(
    loan,
    transactionController.transactions,
  );

  if (remaining <= 0.001) {
    _closeWithoutWriteOff(context, loan);
    return;
  }

  int? selectedBankId = bankController.banks.isNotEmpty
      ? bankController.banks.first.id
      : null;
  String? selectedCategoryIndex;
  int? selectedLineItemId;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final budget = budgetController.activeBudget.value;
          final lineItems = budget?.lineItems
                  .where((item) => item.id != null)
                  .toList() ??
              [];

          return Dialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 560, maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Close Loan', style: AppTextStyles.headline1),
                    const SizedBox(height: 8),
                    Text(
                      'Remaining balance ${formatter.format(remaining)} will be '
                      'recorded as an expense.',
                      style: AppTextStyles.body1,
                    ),
                    const SizedBox(height: 16),
                    Text('Bank', style: AppTextStyles.midBody1),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedBankId,
                      dropdownColor: AppColors.background,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: bankController.banks
                          .map(
                            (bank) => DropdownMenuItem(
                              value: bank.id,
                              child: Text(
                                bank.displayName ?? bank.bankName,
                                style: AppTextStyles.body1,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedBankId = value),
                    ),
                    const SizedBox(height: 16),
                    Text('Expense category', style: AppTextStyles.midBody1),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final selectableIndices = <int>[
                          for (var i = 0; i < expenseCategories.length; i++)
                            if (i != expenseInternalTransferIndex) i,
                        ];

                        return SizedBox(
                          height: 200,
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.95,
                            ),
                            itemCount: selectableIndices.length,
                            itemBuilder: (context, listIndex) {
                              final index = selectableIndices[listIndex];
                              final category = expenseCategories[index];
                              final isSelected =
                                  selectedCategoryIndex == '$index';

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCategoryIndex = '$index';
                                    if (isTransferFeeCategory(
                                      selectedCategoryIndex!,
                                      'Expense',
                                    )) {
                                      selectedLineItemId = budgetController
                                          .transferFeeLineItemIdForDate(
                                        DateTime.now(),
                                      );
                                    } else {
                                      selectedLineItemId = null;
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? category.color.withOpacity(0.5)
                                        : category.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected
                                        ? Border.all(color: Colors.white)
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        category.icon,
                                        color: category.color,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        category.name,
                                        style: AppTextStyles.body1.copyWith(
                                          fontSize: 11,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    if (selectedCategoryIndex != null &&
                        !isTransferFeeCategory(
                          selectedCategoryIndex!,
                          'Expense',
                        ) &&
                        lineItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Budget line item', style: AppTextStyles.midBody1),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: lineItems.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = lineItems[index];
                            final isSelected = selectedLineItemId == item.id;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              selected: isSelected,
                              title: Text(item.name, style: AppTextStyles.body1),
                              onTap: () => setState(
                                () => selectedLineItemId = item.id,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.smallButton2,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (selectedBankId == null) {
                              AppSnackbar.showError('Choose a bank');
                              return;
                            }
                            if (selectedCategoryIndex == null) {
                              AppSnackbar.showError('Choose a category');
                              return;
                            }

                            int? lineItemId = selectedLineItemId;
                            if (isTransferFeeCategory(
                              selectedCategoryIndex!,
                              'Expense',
                            )) {
                              lineItemId ??= budgetController
                                  .transferFeeLineItemIdForDate(DateTime.now());
                            } else if (lineItems.isNotEmpty &&
                                lineItemId == null) {
                              AppSnackbar.showError(
                                'Choose a budget line item',
                              );
                              return;
                            }

                            try {
                              await loanController.closeLoanManually(
                                loan: loan,
                                transactions:
                                    transactionController.transactions,
                                bankId: selectedBankId!,
                                category: selectedCategoryIndex!,
                                budgetLineItemId: lineItemId,
                              );
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              AppSnackbar.showSuccess('Loan closed');
                            } catch (e) {
                              AppSnackbar.showError(e.toString());
                            }
                          },
                          child: Text(
                            'Close loan',
                            style: AppTextStyles.smallButton1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _closeWithoutWriteOff(BuildContext context, Loan loan) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.background,
      title: Text('Close loan?', style: AppTextStyles.headline1),
      content: Text(
        'This loan is fully repaid. Close it now?',
        style: AppTextStyles.body1,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: AppTextStyles.smallButton2),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Close', style: AppTextStyles.smallButton1),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  final loanController = Get.find<LoanController>();
  final transactionController = Get.find<TransactionController>();

  final banks = Get.find<BankController>().banks;
  final bankId = banks.isNotEmpty ? banks.first.id! : 0;

  try {
    await loanController.closeLoanManually(
      loan: loan,
      transactions: transactionController.transactions,
      bankId: bankId,
      category: '$expenseLoanIndex',
      budgetLineItemId: null,
    );
    AppSnackbar.showSuccess('Loan closed');
  } catch (e) {
    AppSnackbar.showError(e.toString());
  }
}
