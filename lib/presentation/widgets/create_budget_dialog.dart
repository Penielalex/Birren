import 'package:birren/domain/entities/budget.dart';
import 'package:birren/domain/entities/budget_line_item.dart';
import 'package:birren/presentation/controllers/budget_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:birren/presentation/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class _LineItemDraft {
  final int? itemId;
  final nameController = TextEditingController();
  final amountController = TextEditingController();

  _LineItemDraft({this.itemId});

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

void showCreateBudgetDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const _BudgetFormDialog(),
  );
}

void showEditBudgetDialog(BuildContext context, Budget budget) {
  showDialog(
    context: context,
    builder: (context) => _BudgetFormDialog(editBudget: budget),
  );
}

class _BudgetFormDialog extends StatefulWidget {
  final Budget? editBudget;

  const _BudgetFormDialog({this.editBudget});

  @override
  State<_BudgetFormDialog> createState() => _BudgetFormDialogState();
}

class _BudgetFormDialogState extends State<_BudgetFormDialog> {
  final BudgetController budgetController = Get.find<BudgetController>();
  late final TextEditingController _nameController;
  late DateTime _startDate;
  late DateTime _endDate;
  final List<_LineItemDraft> _lineItems = [];

  bool get _isEditing => widget.editBudget != null;

  @override
  void initState() {
    super.initState();
    final budget = widget.editBudget;
    _nameController = TextEditingController(text: budget?.name ?? '');
    _startDate = budget?.startDate ??
        DateTime(DateTime.now().year, DateTime.now().month, 1);
    _endDate = budget?.endDate ??
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

    if (budget != null && budget.lineItems.isNotEmpty) {
      for (final item in budget.lineItems) {
        final draft = _LineItemDraft(itemId: item.id);
        draft.nameController.text = item.name;
        draft.amountController.text =
            item.allocatedAmount.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
        _lineItems.add(draft);
      }
    } else {
      _lineItems.add(_LineItemDraft());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final draft in _lineItems) {
      draft.dispose();
    }
    super.dispose();
  }

  void _removeLineItem(int index) {
    final removed = _lineItems.removeAt(index);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removed.dispose();
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _submit() async {
    final items = <BudgetLineItem>[];
    for (final draft in _lineItems) {
      final amount = double.tryParse(draft.amountController.text);
      final name = draft.nameController.text.trim();
      if (name.isEmpty || amount == null || amount <= 0) {
        AppSnackbar.showError('Each item needs a name and amount');
        return;
      }
      items.add(
        BudgetLineItem(
          id: draft.itemId,
          budgetId: widget.editBudget?.id ?? 0,
          name: name,
          allocatedAmount: amount,
        ),
      );
    }

    if (_nameController.text.trim().isEmpty) {
      AppSnackbar.showError('Enter a budget name');
      return;
    }

    try {
      if (_isEditing) {
        await budgetController.updateBudget(
          budgetId: widget.editBudget!.id!,
          name: _nameController.text,
          startDate: _startDate,
          endDate: _endDate,
          lineItems: items,
        );
      } else {
        await budgetController.createBudget(
          name: _nameController.text,
          startDate: _startDate,
          endDate: _endDate,
          lineItems: items,
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      AppSnackbar.showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560, maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit Budget' : 'Create Budget',
                style: AppTextStyles.headline1,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        hintText: 'Budget name',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickStartDate,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: AppColors.accent),
                              ),
                              child: Text(
                                'Start: ${DateFormat.yMMMd().format(_startDate)}',
                                style: AppTextStyles.body1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickEndDate,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: AppColors.accent),
                              ),
                              child: Text(
                                'End: ${DateFormat.yMMMd().format(_endDate)}',
                                style: AppTextStyles.body1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Budget items',
                          style: AppTextStyles.body1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._lineItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final draft = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              CustomTextField(
                                controller: draft.nameController,
                                hintText: 'Name (e.g. Food)',
                              ),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: draft.amountController,
                                hintText: 'Amount',
                                keyboardType: TextInputType.number,
                              ),
                              if (_lineItems.length > 1)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => _removeLineItem(index),
                                    child: Text(
                                      'Remove',
                                      style: AppTextStyles.smallButton2,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _lineItems.add(_LineItemDraft());
                            });
                          },
                          icon: const Icon(Icons.add, color: AppColors.accent),
                          label: Text(
                            'Add item',
                            style: AppTextStyles.smallButton1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: AppTextStyles.smallButton2),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _submit,
                    child: Text(
                      _isEditing ? 'Save' : 'Create',
                      style: AppTextStyles.smallButton1.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
