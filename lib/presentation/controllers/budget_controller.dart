import 'package:get/get.dart';
import '../../app/budget_usecases.dart';
import '../../data/service/budget_widget_service.dart';
import '../../data/service/shared_prefs_service.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_line_item.dart';
import '../../domain/entities/transaction.dart';
import '../util/category.dart';
import '../util/budget_defaults.dart';

class BudgetController extends GetxController {
  final SharedPrefsService prefs;
  final GetActiveBudgetUseCase getActiveBudgetUseCase;
  final GetBudgetHistoryUseCase getBudgetHistoryUseCase;
  final CreateBudgetUseCase createBudgetUseCase;
  final UpdateBudgetUseCase updateBudgetUseCase;
  final DeleteBudgetUseCase deleteBudgetUseCase;

  BudgetController({
    required this.prefs,
    required this.getActiveBudgetUseCase,
    required this.getBudgetHistoryUseCase,
    required this.createBudgetUseCase,
    required this.updateBudgetUseCase,
    required this.deleteBudgetUseCase,
  });

  final Rx<Budget?> activeBudget = Rx<Budget?>(null);
  final RxList<Budget> budgetHistory = <Budget>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshBudgets();
  }

  Future<void> refreshBudgets() async {
    final userId = await prefs.getId();
    if (userId == null) return;

    isLoading.value = true;
    try {
      final id = int.parse(userId);
      activeBudget.value = await getActiveBudgetUseCase.execute(id);
      budgetHistory.assignAll(await getBudgetHistoryUseCase.execute(id));
    } finally {
      isLoading.value = false;
      await BudgetWidgetService.syncFromControllers();
    }
  }

  bool get canStartNewBudgetCycle {
    final budget = activeBudget.value;
    if (budget == null) return true;
    return budget.isExpired;
  }

  DateTime? get periodStart {
    final budget = activeBudget.value;
    if (budget == null) return null;
    return _dayStart(budget.startDate);
  }

  DateTime? get periodEnd {
    final budget = activeBudget.value;
    if (budget == null) return null;
    return _dayEnd(budget.endDate);
  }

  double get totalAllocated => activeBudget.value?.totalAllocated ?? 0;

  double totalSpent(List<Transaction> transactions) {
    final budget = activeBudget.value;
    if (budget == null) return 0;
    return totalSpentForBudget(budget, transactions);
  }

  double totalSpentForBudget(
    Budget budget,
    List<Transaction> transactions,
  ) {
    final start = _dayStart(budget.startDate);
    final end = _dayEnd(budget.endDate);
    final lineItemIds =
        budget.lineItems.map((i) => i.id).whereType<int>().toSet();

    double total = 0;
    for (final t in transactions) {
      if (t.type != 'Expense') continue;
      if (!countsTransactionInIncomeExpenseSummary(
        t.category,
        t.type,
        loanId: t.loanId,
      )) {
        continue;
      }
      if (t.budgetLineItemId == null ||
          !lineItemIds.contains(t.budgetLineItemId)) {
        continue;
      }
      final day = DateTime(t.dateOf.year, t.dateOf.month, t.dateOf.day);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      total += t.amount;
    }
    return total;
  }

  double spentForLineItem(
    BudgetLineItem item,
    List<Transaction> transactions,
  ) {
    final budget = activeBudget.value;
    if (budget == null) return 0;
    return spentForLineItemInBudget(budget, item, transactions);
  }

  double spentForLineItemInBudget(
    Budget budget,
    BudgetLineItem item,
    List<Transaction> transactions,
  ) {
    if (item.id == null) return 0;

    final start = _dayStart(budget.startDate);
    final end = _dayEnd(budget.endDate);
    double total = 0;

    for (final t in transactions) {
      if (t.type != 'Expense') continue;
      if (!countsTransactionInIncomeExpenseSummary(
        t.category,
        t.type,
        loanId: t.loanId,
      )) {
        continue;
      }
      if (t.budgetLineItemId != item.id) continue;
      final day = DateTime(t.dateOf.year, t.dateOf.month, t.dateOf.day);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      total += t.amount;
    }
    return total;
  }

  List<Transaction> transactionsForLineItemInBudget(
    Budget budget,
    BudgetLineItem item,
    List<Transaction> transactions,
  ) {
    if (item.id == null) return [];

    final start = _dayStart(budget.startDate);
    final end = _dayEnd(budget.endDate);

    return transactions.where((t) {
      if (t.type != 'Expense') return false;
      if (!countsTransactionInIncomeExpenseSummary(
        t.category,
        t.type,
        loanId: t.loanId,
      )) {
        return false;
      }
      if (t.budgetLineItemId != item.id) return false;
      final day = DateTime(t.dateOf.year, t.dateOf.month, t.dateOf.day);
      if (day.isBefore(start) || day.isAfter(end)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.dateOf.compareTo(a.dateOf));
  }

  double incomeTotal(List<Transaction> transactions) {
    final budget = activeBudget.value;
    if (budget == null) return 0;
    return incomeTotalForBudget(budget, transactions);
  }

  double incomeTotalForBudget(
    Budget budget,
    List<Transaction> transactions,
  ) {
    final start = _dayStart(budget.startDate);
    final end = _dayEnd(budget.endDate);
    double total = 0;

    for (final t in transactions) {
      if (t.type != 'Income') continue;
      if (!countsTransactionInIncomeExpenseSummary(
        t.category,
        t.type,
        loanId: t.loanId,
      )) {
        continue;
      }
      final day = DateTime(t.dateOf.year, t.dateOf.month, t.dateOf.day);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      total += t.amount;
    }
    return total;
  }

  double expenseTotal(List<Transaction> transactions) =>
      totalSpent(transactions);

  DateTime _dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _dayEnd(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59);

  int get budgetDayCount {
    final start = periodStart;
    final end = periodEnd;
    if (start == null || end == null) return 1;
    return end.difference(start).inDays + 1;
  }

  double get dailyBudgetAllowance =>
      totalAllocated / budgetDayCount.clamp(1, 10000);

  Set<int> get activeBudgetLineItemIds {
    final budget = activeBudget.value;
    if (budget == null) return {};
    return budget.lineItems.map((i) => i.id).whereType<int>().toSet();
  }

  int daysInBudgetMonth(int year, int month) {
    final start = periodStart;
    final end = periodEnd;
    if (start == null || end == null) return 0;

    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);
    var effectiveStart =
        monthStart.isBefore(start) ? start : _dayStart(monthStart);
    var effectiveEnd = _dayEnd(monthEnd);
    if (effectiveEnd.isAfter(end)) {
      effectiveEnd = end;
    }
    if (effectiveStart.isAfter(effectiveEnd)) return 0;
    return effectiveEnd.difference(effectiveStart).inDays + 1;
  }

  double monthlyAllowanceFor(int year, int month) =>
      dailyBudgetAllowance * daysInBudgetMonth(year, month);

  bool monthOverlapsBudget(int year, int month) =>
      daysInBudgetMonth(year, month) > 0;

  bool transactionFitsBudgetPeriod(Budget budget, DateTime date) {
    final day = _dayStart(date);
    return !day.isBefore(_dayStart(budget.startDate)) &&
        !day.isAfter(_dayEnd(budget.endDate));
  }

  int? transferFeeLineItemIdForDate(DateTime date) {
    final budget = activeBudget.value;
    if (budget == null || budget.isExpired) return null;
    if (!transactionFitsBudgetPeriod(budget, date)) return null;
    return findTransferFeeLineItem(budget)?.id;
  }

  Future<void> createBudget({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<BudgetLineItem> lineItems,
  }) async {
    final userId = await prefs.getId();
    if (userId == null) return;

    if (!canStartNewBudgetCycle) {
      throw StateError('Finish the current budget before starting a new one.');
    }

    if (lineItems.isEmpty) {
      throw ArgumentError('Add at least one budget item.');
    }

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    if (end.isBefore(start)) {
      throw ArgumentError('End date must be on or after start date.');
    }

    await createBudgetUseCase.execute(
      userId: int.parse(userId),
      name: name.trim(),
      startDate: start,
      endDate: end,
      lineItems: withDefaultTransferFeeLineItem(
        lineItems
            .map(
              (item) => BudgetLineItem(
                budgetId: 0,
                name: item.name.trim(),
                allocatedAmount: item.allocatedAmount,
              ),
            )
            .toList(),
      ),
    );

    await refreshBudgets();
  }

  Future<void> updateBudget({
    required int budgetId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<BudgetLineItem> lineItems,
  }) async {
    if (lineItems.isEmpty) {
      throw ArgumentError('Add at least one budget item.');
    }

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    if (end.isBefore(start)) {
      throw ArgumentError('End date must be on or after start date.');
    }

    await updateBudgetUseCase.execute(
      budgetId: budgetId,
      name: name.trim(),
      startDate: start,
      endDate: end,
      lineItems: lineItems
          .map(
            (item) => BudgetLineItem(
              id: item.id,
              budgetId: budgetId,
              name: item.name.trim(),
              allocatedAmount: item.allocatedAmount,
            ),
          )
          .toList(),
    );

    await refreshBudgets();
  }

  Future<void> deleteBudget(int budgetId) async {
    await deleteBudgetUseCase.execute(budgetId);
    await refreshBudgets();
  }
}
