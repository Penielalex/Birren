import '../entities/budget.dart';
import '../entities/budget_line_item.dart';

abstract class BudgetRepository {
  Future<Budget?> getActiveBudget(int userId);
  Future<List<Budget>> getBudgetHistory(int userId);
  Future<Budget?> getBudgetById(int id);
  Future<int> createBudget({
    required int userId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<BudgetLineItem> lineItems,
  });
  Future<void> updateBudget({
    required int budgetId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<BudgetLineItem> lineItems,
  });
  Future<void> deleteBudget(int budgetId);
}
