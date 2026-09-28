import 'package:birren/domain/entities/budget_line_item.dart';
import 'package:birren/domain/entities/transaction.dart';
import 'package:birren/presentation/controllers/budget_controller.dart';
import 'package:birren/presentation/controllers/loan_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/util/category.dart';
import 'package:birren/presentation/widgets/app_dialog.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

const _excludedYourShareIndexes = {
  expenseInternalTransferIndex,
  expenseTransferFeeIndex,
  expenseLoanIndex,
  expenseLendLoanIndex,
};

/// Opens the shared-expense split flow for one expense transaction.
/// Works for new and previously categorized / fully budgeted expenses.
void showSharedExpenseSplitDialog(
  BuildContext context,
  Transaction expense,
) {
  if (expense.type != 'Expense') {
    AppSnackbar.showError('Only expenses can be split');
    return;
  }
  if (expense.id == null) {
    AppSnackbar.showError('Save the transaction first');
    return;
  }
  if (isOutgoingLendCategory(expense.category, expense.type) &&
      expense.loanId != null) {
    AppSnackbar.showError(
      'This is already a lent loan. Split a normal expense instead.',
    );
    return;
  }
  if (isInternalTransferCategory(expense.category, expense.type)) {
    AppSnackbar.showError('Internal transfers cannot be split');
    return;
  }

  showAppDialog(
    context: context,
    builder: (dialogContext) => _SharedExpenseSplitDialog(expense: expense),
  );
}

class _SharedExpenseSplitDialog extends StatefulWidget {
  final Transaction expense;

  const _SharedExpenseSplitDialog({required this.expense});

  @override
  State<_SharedExpenseSplitDialog> createState() =>
      _SharedExpenseSplitDialogState();
}

class _SharedExpenseSplitDialogState extends State<_SharedExpenseSplitDialog> {
  final _formatter = NumberFormat('#,##0.00');
  late final TextEditingController _yourShareController;
  late final TextEditingController _friendsShareController;
  late final TextEditingController _nameController;
  bool _syncingShares = false;
  bool _saving = false;
  int? _selectedCategoryIndex;
  int? _selectedBudgetLineItemId;

  double get _total => widget.expense.amount;

  @override
  void initState() {
    super.initState();
    final half = _total / 2;
    final yourDefault = double.parse(half.toStringAsFixed(2));
    final friendsDefault =
        double.parse((_total - yourDefault).toStringAsFixed(2));
    _yourShareController =
        TextEditingController(text: yourDefault.toStringAsFixed(2));
    _friendsShareController =
        TextEditingController(text: friendsDefault.toStringAsFixed(2));
    _nameController = TextEditingController();

    final existing = int.tryParse(widget.expense.category.trim());
    if (existing != null &&
        existing >= 0 &&
        existing < expenseCategories.length &&
        !_excludedYourShareIndexes.contains(existing)) {
      _selectedCategoryIndex = existing;
    }
    _selectedBudgetLineItemId = widget.expense.budgetLineItemId;
  }

  @override
  void dispose() {
    _yourShareController.dispose();
    _friendsShareController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  double? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  void _onYourShareChanged(String value) {
    if (_syncingShares) return;
    final your = _parseAmount(value);
    if (your == null) return;
    final friends = double.parse((_total - your).toStringAsFixed(2));
    _syncingShares = true;
    _friendsShareController.text = friends.toStringAsFixed(2);
    _syncingShares = false;
  }

  void _onFriendsShareChanged(String value) {
    if (_syncingShares) return;
    final friends = _parseAmount(value);
    if (friends == null) return;
    final your = double.parse((_total - friends).toStringAsFixed(2));
    _syncingShares = true;
    _yourShareController.text = your.toStringAsFixed(2);
    _syncingShares = false;
  }

  Future<void> _submit() async {
    final your = _parseAmount(_yourShareController.text);
    final friends = _parseAmount(_friendsShareController.text);
    if (your == null || friends == null) {
      AppSnackbar.showError('Enter valid share amounts');
      return;
    }
    if (your <= 0 || friends <= 0) {
      AppSnackbar.showError('Both shares must be greater than 0');
      return;
    }
    if ((your + friends - _total).abs() > 0.05) {
      AppSnackbar.showError(
        'Your share + friends share must equal ${_formatter.format(_total)}',
      );
      return;
    }
    if (_selectedCategoryIndex == null) {
      AppSnackbar.showError('Pick a category for your share');
      return;
    }

    setState(() => _saving = true);
    try {
      final loanController = Get.find<LoanController>();
      final transactionController = Get.find<TransactionController>();

      await loanController.splitSharedExpense(
        original: widget.expense,
        yourShare: your,
        friendsShare: friends,
        yourCategoryIndex: '$_selectedCategoryIndex',
        budgetLineItemId: _selectedBudgetLineItemId,
        counterpartyName: _nameController.text,
      );

      transactionController.clearSelection();
      if (mounted) Navigator.pop(context);
      AppSnackbar.showSuccess(
        'Split saved: ${_formatter.format(your)} on budget, '
        '${_formatter.format(friends)} as loan',
      );
    } catch (e) {
      AppSnackbar.showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetController = Get.find<BudgetController>();
    final budget = budgetController.activeBudget.value;
    final fitsPeriod = budget != null &&
        !budget.isExpired &&
        budgetController.transactionFitsBudgetPeriod(
          budget,
          widget.expense.dateOf,
        );
    final lineItems = fitsPeriod
        ? budget.lineItems.where((i) => i.id != null).toList()
        : <BudgetLineItem>[];

    return AppDialog(
      title: 'Split shared expense',
      subtitle:
          'Your share hits the budget. Friends’ share becomes a lent loan.',
      expandBody: true,
      scrollable: true,
      maxHeight: 640,
      actions: [
        AppDialogActions.cancel(
          context,
          enabled: !_saving,
        ),
        AppDialogActions.primary(
          label: 'Split',
          isLoading: _saving,
          onPressed: _submit,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Total ${_formatter.format(_total)} birr',
              style: AppTextStyles.midBody1.copyWith(color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 16),
          Text('Your share', style: AppTextStyles.midBody1),
          const SizedBox(height: 8),
          AppDialogField(
            controller: _yourShareController,
            hintText: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _onYourShareChanged,
          ),
          const SizedBox(height: 14),
          Text('Friends’ share (loan)', style: AppTextStyles.midBody1),
          const SizedBox(height: 8),
          AppDialogField(
            controller: _friendsShareController,
            hintText: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _onFriendsShareChanged,
          ),
          const SizedBox(height: 14),
          Text('Who owes you (optional)', style: AppTextStyles.midBody1),
          const SizedBox(height: 8),
          AppDialogField(
            controller: _nameController,
            hintText: 'Friend / group name',
          ),
          const SizedBox(height: 16),
          Text('Category for your share', style: AppTextStyles.midBody1),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < expenseCategories.length; i++)
                if (!_excludedYourShareIndexes.contains(i))
                  ChoiceChip(
                    label: Text(
                      expenseCategories[i].name,
                      style: AppTextStyles.body1.copyWith(
                        fontSize: 12,
                        color: _selectedCategoryIndex == i
                            ? const Color(0xFF0B1020)
                            : Colors.white,
                      ),
                    ),
                    selected: _selectedCategoryIndex == i,
                    selectedColor: AppColors.accent,
                    backgroundColor: AppColors.fieldFill,
                    side: BorderSide(
                      color: _selectedCategoryIndex == i
                          ? AppColors.accent
                          : AppColors.surfaceBorder,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCategoryIndex = i);
                    },
                  ),
            ],
          ),
          if (lineItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Budget item for your share', style: AppTextStyles.midBody1),
            const SizedBox(height: 8),
            ...lineItems.map((item) {
              final selected = _selectedBudgetLineItemId == item.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: AppDialogOptionTile(
                  title: item.name,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      _selectedBudgetLineItemId = selected ? null : item.id;
                    });
                  },
                ),
              );
            }),
            TextButton(
              onPressed: () {
                setState(() => _selectedBudgetLineItemId = null);
              },
              child: Text(
                'No budget item',
                style: AppTextStyles.body1.copyWith(color: AppColors.mutedText),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
