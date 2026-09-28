import 'package:birren/domain/entities/loan.dart';
import 'package:birren/presentation/controllers/bank_controller.dart';
import 'package:birren/presentation/controllers/budget_controller.dart';
import 'package:birren/presentation/controllers/loan_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/util/budget_defaults.dart';
import 'package:birren/presentation/util/category.dart';
import 'package:birren/presentation/widgets/app_dialog.dart';
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

  showAppDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final budget = budgetController.activeBudget.value;
          final lineItems = budget?.lineItems
                  .where((item) => item.id != null)
                  .toList() ??
              [];

          return AppDialog(
            title: 'Close loan',
            subtitle:
                'Remaining balance ${formatter.format(remaining)} will be '
                'recorded as an expense.',
            expandBody: true,
            scrollable: true,
            maxHeight: 600,
            actions: [
              AppDialogActions.cancel(dialogContext),
              AppDialogActions.primary(
                label: 'Close loan',
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
                  } else if (lineItems.isNotEmpty && lineItemId == null) {
                    AppSnackbar.showError('Choose a budget line item');
                    return;
                  }

                  try {
                    await loanController.closeLoanManually(
                      loan: loan,
                      transactions: transactionController.transactions,
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
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Bank', style: AppTextStyles.midBody1),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: selectedBankId,
                  dropdownColor: AppColors.surface,
                  decoration: appDialogInputDecoration(),
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
                  onChanged: (value) => setState(() => selectedBankId = value),
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

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
                        final isSelected = selectedCategoryIndex == '$index';

                        return Material(
                          color: isSelected
                              ? category.color.withValues(alpha: 0.45)
                              : category.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
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
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    category.icon,
                                    color: category.color,
                                    size: 22,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    category.name,
                                    style: AppTextStyles.body1
                                        .copyWith(fontSize: 11),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
                  ...lineItems.map((item) {
                    final isSelected = selectedLineItemId == item.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: AppDialogOptionTile(
                        title: item.name,
                        selected: isSelected,
                        onTap: () =>
                            setState(() => selectedLineItemId = item.id),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> _closeWithoutWriteOff(BuildContext context, Loan loan) async {
  final confirmed = await showAppConfirmDialog(
    context: context,
    title: 'Close loan?',
    message: 'This loan is fully repaid. Close it now?',
    confirmLabel: 'Close',
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
