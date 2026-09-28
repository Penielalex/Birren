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
    return budget.startDate;
  }

  DateTime? get periodEnd {
    final budget = activeBudget.value;
    if (budget == null) return null;
    return budget.endDate;
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
    final start = budget.startDate;
    final end = budget.endDate;
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
      if (t.dateOf.isBefore(start) || t.dateOf.isAfter(end)) continue;
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

    final start = budget.startDate;
    final end = budget.endDate;
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
      if (t.dateOf.isBefore(start) || t.dateOf.isAfter(end)) continue;
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

    final start = budget.startDate;
    final end = budget.endDate;

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
      if (t.dateOf.isBefore(start) || t.dateOf.isAfter(end)) return false;
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
    final start = budget.startDate;
    final end = budget.endDate;
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
      if (t.dateOf.isBefore(start) || t.dateOf.isAfter(end)) continue;
      total += t.amount;
    }
    return total;
  }

  double expenseTotal(List<Transaction> transactions) =>
      totalSpent(transactions);

  DateTime _dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  int get budgetDayCount {
    final start = periodStart;
    final end = periodEnd;
    if (start == null || end == null) return 1;
    final startDay = _dayStart(start);
    final endDay = _dayStart(end);
    return endDay.difference(startDay).inDays + 1;
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

    final startDay = _dayStart(start);
    final endDay = _dayStart(end);
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);
    var effectiveStart =
        monthStart.isBefore(startDay) ? startDay : monthStart;
    var effectiveEnd = monthEnd;
    if (effectiveEnd.isAfter(endDay)) {
      effectiveEnd = endDay;
    }
    if (effectiveStart.isAfter(effectiveEnd)) return 0;
    return effectiveEnd.difference(effectiveStart).inDays + 1;
  }

  double monthlyAllowanceFor(int year, int month) =>
      dailyBudgetAllowance * daysInBudgetMonth(year, month);

  bool monthOverlapsBudget(int year, int month) =>
      daysInBudgetMonth(year, month) > 0;

  bool transactionFitsBudgetPeriod(Budget budget, DateTime date) {
    return !date.isBefore(budget.startDate) && !date.isAfter(budget.endDate);
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

    if (endDate.isBefore(startDate)) {
      throw ArgumentError('End must be on or after start.');
    }

    await createBudgetUseCase.execute(
      userId: int.parse(userId),
      name: name.trim(),
      startDate: startDate,
      endDate: endDate,
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

    if (endDate.isBefore(startDate)) {
      throw ArgumentError('End must be on or after start.');
    }

    await updateBudgetUseCase.execute(
      budgetId: budgetId,
      name: name.trim(),
      startDate: startDate,
      endDate: endDate,
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

  Future<void> transferAllocatedAmount({
    required Budget budget,
    required int fromLineItemId,
    required int toLineItemId,
    required double amount,
  }) async {
    if (budget.id == null) {
      throw StateError('Budget is not saved yet');
    }
    if (fromLineItemId == toLineItemId) {
      throw ArgumentError('Choose two different budget items');
    }
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }

    final from = budget.lineItems.where((i) => i.id == fromLineItemId);
    final to = budget.lineItems.where((i) => i.id == toLineItemId);
    if (from.isEmpty || to.isEmpty) {
      throw StateError('Budget item not found');
    }

    final fromItem = from.first;
    if (amount > fromItem.allocatedAmount + 1e-9) {
      throw ArgumentError(
        'Cannot move more than ${fromItem.allocatedAmount} birr from ${fromItem.name}',
      );
    }

    final updatedItems = budget.lineItems.map((item) {
      if (item.id == fromLineItemId) {
        return item.copyWith(
          allocatedAmount: fromItem.allocatedAmount - amount,
        );
      }
      if (item.id == toLineItemId) {
        return item.copyWith(
          allocatedAmount: item.allocatedAmount + amount,
        );
      }
      return item;
    }).toList();

    await updateBudget(
      budgetId: budget.id!,
      name: budget.name,
      startDate: budget.startDate,
      endDate: budget.endDate,
      lineItems: updatedItems,
    );
  }

  Future<void> deleteBudget(int budgetId) async {
    await deleteBudgetUseCase.execute(budgetId);
    await refreshBudgets();
  }
}
