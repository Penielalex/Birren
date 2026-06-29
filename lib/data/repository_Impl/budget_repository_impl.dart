import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_line_item.dart';
import '../../domain/repositories/budget_repository.dart';
import '../db/budget_dao.dart';
import '../db/transaction_dao.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetDao budgetDao;
  final TransactionDao transactionDao;

  BudgetRepositoryImpl({
    required this.budgetDao,
    required this.transactionDao,
  });

  @override
  Future<Budget?> getActiveBudget(int userId) =>
      budgetDao.getActiveBudgetByUserId(userId);

  @override
  Future<List<Budget>> getBudgetHistory(int userId) =>
      budgetDao.getArchivedBudgetsByUserId(userId);

  @override
  Future<Budget?> getBudgetById(int id) => budgetDao.getBudgetById(id);

  @override
  Future<int> createBudget({
    required int userId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<BudgetLineItem> lineItems,
  }) =>
      budgetDao.createBudgetWithLineItems(
        userId: userId,
        name: name,
        startDate: startDate,
        endDate: endDate,
        lineItems: lineItems,
      );

  @override
  Future<void> updateBudget({
    required int budgetId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<BudgetLineItem> lineItems,
  }) async {
    final existingIds = await budgetDao.getLineItemIdsForBudget(budgetId);
    final keptIds =
        lineItems.where((i) => i.id != null).map((i) => i.id!).toSet();
    final removedIds = existingIds.toSet().difference(keptIds);

    if (removedIds.isNotEmpty) {
      await transactionDao.clearBudgetLineItemIds(removedIds);
    }

    await budgetDao.updateBudgetWithLineItems(
      budgetId: budgetId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      lineItems: lineItems,
    );
  }

  @override
  Future<void> deleteBudget(int budgetId) async {
    final lineItemIds = await budgetDao.getLineItemIdsForBudget(budgetId);
    if (lineItemIds.isNotEmpty) {
      await transactionDao.clearBudgetLineItemIds(lineItemIds);
    }
    await budgetDao.deleteBudgetRecords(budgetId);
  }
}
