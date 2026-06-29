import 'package:birren/presentation/controllers/app_navigation_controller.dart';
import 'package:birren/presentation/controllers/budget_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:birren/presentation/widgets/custom_calander.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:birren/presentation/pages/date_transactions_page.dart';
import 'package:birren/presentation/pages/budget_line_item_transactions_page.dart';
import '../theme/colors.dart';
import '../widgets/budget_card.dart';
import '../widgets/budget_context_menu.dart';
import '../widgets/budget_line_item_row.dart';
import '../widgets/create_budget_dialog.dart';

class MyMoneyPage extends StatefulWidget {
  const MyMoneyPage({super.key});

  @override
  State<MyMoneyPage> createState() => _MyMoneyPageState();
}

class _MyMoneyPageState extends State<MyMoneyPage> {
  final BudgetController budgetController = Get.find<BudgetController>();
  final TransactionController transactionController =
      Get.find<TransactionController>();
  final GlobalKey _budgetCardKey = GlobalKey();

  DateTime _viewDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AppNavigationController>()) {
      final navigationController = Get.find<AppNavigationController>();
      ever(navigationController.pendingCreateBudget, (pending) {
        if (pending && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _openCreateBudgetFromWidget(navigationController);
          });
        }
      });
      if (navigationController.pendingCreateBudget.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openCreateBudgetFromWidget(navigationController);
        });
      }
    }
  }

  void _openCreateBudgetFromWidget(AppNavigationController navigationController) {
    navigationController.consumeCreateBudgetRequest();
    if (!budgetController.canStartNewBudgetCycle) {
      AppSnackbar.showError(
        'Finish the current budget period before starting a new one.',
      );
      return;
    }
    showCreateBudgetDialog(context);
  }

  DateTime _clampViewDate(
    DateTime date,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      periodStart.year,
      periodStart.month,
      periodStart.day,
    );
    final end = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
    if (day.isBefore(start)) return start;
    if (day.isAfter(end)) return start;
    return day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Obx(() {
          final budget = budgetController.activeBudget.value;
          final formatter = NumberFormat('#,##0.00');
          final hasBudget = budget != null;
          final periodStart = budgetController.periodStart;
          final periodEnd = budgetController.periodEnd;

          final totalAllocated = budgetController.totalAllocated;
          final totalSpent = budgetController.totalSpent(
            transactionController.transactions,
          );
          final totalIncome = budgetController.incomeTotal(
            transactionController.transactions,
          );
          final remaining = totalAllocated - totalSpent;

          final dailyAllowance = budgetController.dailyBudgetAllowance;
          final budgetLineItemIds = hasBudget
              ? budgetController.activeBudgetLineItemIds
              : null;

          final monthlyIndicators = hasBudget
              ? transactionController.getMonthlyIndicators(
                  dailyLimit: dailyAllowance,
                  month: _viewDate,
                  periodStart: periodStart,
                  periodEnd: periodEnd,
                  budgetLineItemIds: budgetLineItemIds,
                )
              : <DateTime, Color>{};

          final yearlyIndicators = hasBudget
              ? transactionController.getYearlyIndicators(
                  year: _viewDate.year,
                  periodStart: periodStart,
                  periodEnd: periodEnd,
                  budgetLineItemIds: budgetLineItemIds,
                  monthlyLimitFor: budgetController.monthlyAllowanceFor,
                )
              : <int, Color>{};

          final lineItemRows = budget?.lineItems.map((item) {
            final spent = budgetController.spentForLineItem(
              item,
              transactionController.transactions,
            );
            return BudgetLineItemRow(
              name: item.name,
              spent: spent,
              allocated: item.allocatedAmount,
              onTap: item.id == null
                  ? null
                  : () {
                      Get.to(() => BudgetLineItemTransactionsPage(
                            budget: budget!,
                            lineItem: item,
                          ));
                    },
            );
          }).toList() ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  key: _budgetCardKey,
                  onLongPress: hasBudget && budget?.id != null
                      ? () {
                          final activeBudget = budget!;
                          showBudgetContextMenu(
                            context: context,
                            anchorKey: _budgetCardKey,
                            onEdit: () =>
                                showEditBudgetDialog(context, activeBudget),
                            onDelete: () => budgetController
                                .deleteBudget(activeBudget.id!),
                          );
                        }
                      : null,
                  child: BudgetCard(
                    budgetName: budget?.name ?? '',
                    dateRange: hasBudget
                        ? '${DateFormat.yMMMd().format(budget!.startDate)} – '
                            '${DateFormat.yMMMd().format(budget.endDate)}'
                        : '',
                    totalBudget: '${formatter.format(totalAllocated)} birr',
                    totalSpent: '${formatter.format(totalSpent)} birr',
                    remaining: '${formatter.format(remaining)} birr',
                    isExpired: budget?.isExpired ?? false,
                    hasBudget: hasBudget,
                    lineItemRows: lineItemRows,
                    onCreateBudget: () {
                      if (!budgetController.canStartNewBudgetCycle) {
                        AppSnackbar.showError(
                          'Finish the current budget period before starting a new one.',
                        );
                        return;
                      }
                      showCreateBudgetDialog(context);
                    },
                  ),
                ),
              ),
              CustomCalendar(
                key: ValueKey(budget?.id ?? 'no-budget'),
                initialMode: CalendarMode.monthly,
                initialDate: hasBudget && periodStart != null
                    ? _clampViewDate(_viewDate, periodStart!, periodEnd!)
                    : _viewDate,
                periodStart: periodStart,
                periodEnd: periodEnd,
                monthlyIndicators: monthlyIndicators,
                yearlyIndicators: yearlyIndicators,
                startDay: hasBudget && periodStart != null
                    ? periodStart!.day
                    : 1,
                onDateChanged: (newDate) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _viewDate = newDate);
                    }
                  });
                },
                onDaySelected: (date) {
                  Get.to(() => DateTransactionsPage(
                        filterDate: date,
                        isMonthlyView: false,
                      ));
                },
                onMonthSelected: (month) {
                  final drillDate = DateTime(_viewDate.year, month, 1);
                  Get.to(() => DateTransactionsPage(
                        filterDate: drillDate,
                        isMonthlyView: true,
                      ));
                },
              ),
              if (hasBudget)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Budget period: ${DateFormat.yMMMd().format(budget!.startDate)} – '
                    '${DateFormat.yMMMd().format(budget.endDate)}',
                    style: AppTextStyles.body1.copyWith(fontSize: 13),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Create a budget to track spending for a custom date range.',
                    style: AppTextStyles.body1,
                    textAlign: TextAlign.center,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: const Color(0xFF262450),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined,
                                  color: AppColors.accent, size: 20),
                              const SizedBox(height: 8),
                              Text('Budget', style: AppTextStyles.body2),
                              const SizedBox(height: 4),
                              Text(
                                hasBudget
                                    ? '${formatter.format(totalSpent)} / ${formatter.format(totalAllocated)} Birr'
                                    : '—',
                                style: AppTextStyles.headline1
                                    .copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        color: const Color(0xFF262450),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.arrow_downward,
                                  color: Colors.green, size: 20),
                              const SizedBox(height: 8),
                              Text('Income', style: AppTextStyles.body2),
                              const SizedBox(height: 4),
                              Text(
                                hasBudget
                                    ? '${formatter.format(totalIncome)} Birr'
                                    : '—',
                                style: AppTextStyles.headline1
                                    .copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        color: const Color(0xFF262450),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.arrow_upward,
                                  color: Colors.red, size: 20),
                              const SizedBox(height: 8),
                              Text('Expense', style: AppTextStyles.body2),
                              const SizedBox(height: 4),
                              Text(
                                hasBudget
                                    ? '${formatter.format(totalSpent)} Birr'
                                    : '—',
                                style: AppTextStyles.headline1
                                    .copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        }),
      ),
    );
  }
}
