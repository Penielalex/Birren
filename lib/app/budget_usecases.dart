import '../domain/entities/budget.dart';
import '../domain/entities/budget_line_item.dart';
import '../domain/repositories/budget_repository.dart';

class GetActiveBudgetUseCase {
  final BudgetRepository repository;
  GetActiveBudgetUseCase(this.repository);

  Future<Budget?> execute(int userId) => repository.getActiveBudget(userId);
}

class GetBudgetHistoryUseCase {
  final BudgetRepository repository;
  GetBudgetHistoryUseCase(this.repository);

  Future<List<Budget>> execute(int userId) =>
      repository.getBudgetHistory(userId);
}

class CreateBudgetUseCase {
  final BudgetRepository repository;
  CreateBudgetUseCase(this.repository);

  Future<int> execute({
    required int userId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<BudgetLineItem> lineItems,
  }) =>
      repository.createBudget(
        userId: userId,
        name: name,
        startDate: startDate,
        endDate: endDate,
        lineItems: lineItems,
      );
}

class UpdateBudgetUseCase {
  final BudgetRepository repository;
  UpdateBudgetUseCase(this.repository);

  Future<void> execute({
    required int budgetId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<BudgetLineItem> lineItems,
  }) =>
      repository.updateBudget(
        budgetId: budgetId,
        name: name,
        startDate: startDate,
        endDate: endDate,
        lineItems: lineItems,
      );
}

class DeleteBudgetUseCase {
  final BudgetRepository repository;
  DeleteBudgetUseCase(this.repository);

  Future<void> execute(int budgetId) => repository.deleteBudget(budgetId);
}
