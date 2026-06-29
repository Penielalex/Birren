import 'package:birren/domain/entities/bank.dart';
import 'package:birren/presentation/controllers/budget_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/util/budget_defaults.dart';
import 'package:birren/presentation/util/category.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:birren/presentation/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

void showManualCashTransactionDialog(BuildContext context, Bank cashBank) {
  final amountController = TextEditingController();
  final budgetController = Get.find<BudgetController>();
  var selectedType = 'Expense';
  var selectedDate = DateTime.now();
  String? selectedCategoryIndex;
  int? selectedLineItemId;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final categories = selectedType == 'Income'
              ? incomeCategories
              : expenseCategories;
          final selectableIndices = <int>[
            for (var i = 0; i < categories.length; i++)
              if (selectedType == 'Income'
                  ? i != incomeInternalTransferIndex
                  : i != expenseInternalTransferIndex)
                i,
          ];

          final budget = budgetController.activeBudget.value;
          final lineItems = budget?.lineItems
                  .where((item) => item.id != null)
                  .toList() ??
              [];
          final needsBudgetLineItem = selectedType == 'Expense' &&
              selectedCategoryIndex != null &&
              !isTransferFeeCategory(selectedCategoryIndex!, 'Expense') &&
              !isLoanRepaymentCategory(selectedCategoryIndex!, 'Expense') &&
              lineItems.isNotEmpty &&
              budget != null &&
              !budget.isExpired &&
              budgetController.transactionFitsBudgetPeriod(
                budget,
                selectedDate,
              );

          void onCategorySelected(int index) {
            setState(() {
              selectedCategoryIndex = '$index';
              selectedLineItemId = null;
              if (isTransferFeeCategory(selectedCategoryIndex!, 'Expense')) {
                selectedLineItemId =
                    budgetController.transferFeeLineItemIdForDate(selectedDate);
              }
            });
          }

          return Dialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 620, maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add cash transaction',
                      style: AppTextStyles.headline1,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cashBank.displayName ?? cashBank.bankName,
                      style: AppTextStyles.body1,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'Expense',
                                  label: Text('Expense'),
                                  icon: Icon(Icons.remove),
                                ),
                                ButtonSegment(
                                  value: 'Income',
                                  label: Text('Income'),
                                  icon: Icon(Icons.add),
                                ),
                              ],
                              selected: {selectedType},
                              onSelectionChanged: (value) {
                                setState(() {
                                  selectedType = value.first;
                                  selectedCategoryIndex = null;
                                  selectedLineItemId = null;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: amountController,
                              hintText: 'Amount',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    selectedDate = DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                      selectedDate.hour,
                                      selectedDate.minute,
                                    );
                                    if (selectedCategoryIndex != null &&
                                        isTransferFeeCategory(
                                          selectedCategoryIndex!,
                                          'Expense',
                                        )) {
                                      selectedLineItemId = budgetController
                                          .transferFeeLineItemIdForDate(
                                        selectedDate,
                                      );
                                    }
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date',
                                  labelStyle: AppTextStyles.body1,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  suffixIcon:
                                      const Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  DateFormat.yMMMd().format(selectedDate),
                                  style: AppTextStyles.body1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('Category', style: AppTextStyles.midBody1),
                            const SizedBox(height: 8),
                            GridView.builder(
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
                                final category = categories[index];
                                final isSelected =
                                    selectedCategoryIndex == '$index';

                                return GestureDetector(
                                  onTap: () => onCategorySelected(index),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          category.icon,
                                          color: category.color,
                                          size: 22,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          category.name,
                                          style:
                                              AppTextStyles.body1.copyWith(
                                            fontSize: 10,
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
                            if (needsBudgetLineItem) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Budget line item',
                                style: AppTextStyles.midBody1,
                              ),
                              const SizedBox(height: 8),
                              ...lineItems.map((item) {
                                final isSelected =
                                    selectedLineItemId == item.id;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  selected: isSelected,
                                  title: Text(
                                    item.name,
                                    style: AppTextStyles.body1,
                                  ),
                                  onTap: () => setState(
                                    () => selectedLineItemId = item.id,
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
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
                            final amount = double.tryParse(
                              amountController.text.trim(),
                            );
                            if (amount == null || amount <= 0) {
                              AppSnackbar.showError('Enter a valid amount');
                              return;
                            }
                            if (selectedCategoryIndex == null) {
                              AppSnackbar.showError('Choose a category');
                              return;
                            }

                            int? lineItemId = selectedLineItemId;
                            if (selectedType == 'Expense' &&
                                isTransferFeeCategory(
                                  selectedCategoryIndex!,
                                  'Expense',
                                )) {
                              lineItemId ??= budgetController
                                  .transferFeeLineItemIdForDate(selectedDate);
                            } else if (needsBudgetLineItem &&
                                lineItemId == null) {
                              AppSnackbar.showError(
                                'Choose a budget line item',
                              );
                              return;
                            }

                            try {
                              final transactionController =
                                  Get.find<TransactionController>();
                              await transactionController
                                  .addManualCashTransaction(
                                bank: cashBank,
                                type: selectedType,
                                amount: amount,
                                dateOf: selectedDate,
                                categoryIndex: selectedCategoryIndex!,
                                budgetLineItemId: lineItemId,
                              );
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                              AppSnackbar.showSuccess('Transaction added');
                            } catch (e) {
                              AppSnackbar.showError(e.toString());
                            }
                          },
                          child: Text(
                            'Save',
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
  ).then((_) => amountController.dispose());
}
