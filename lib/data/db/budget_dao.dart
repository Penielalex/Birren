import 'package:drift/drift.dart';
import 'app_database.dart' hide Budget, BudgetLineItem;
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_line_item.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets, BudgetLineItems])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(this.db) : super(db);

  final AppDatabase db;

  Future<Budget?> getActiveBudgetByUserId(int userId) async {
    final row = await (select(budgets)
          ..where(
            (b) => b.userId.equals(userId) & b.status.equals('active'),
          )
          ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
        .getSingleOrNull();

    if (row == null) return null;
    return _loadBudgetWithItems(row);
  }

  Future<List<Budget>> getAllBudgets() async {
    final rows = await (select(budgets)
          ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
        .get();
    final result = <Budget>[];
    for (final row in rows) {
      result.add(await _loadBudgetWithItems(row));
    }
    return result;
  }

  Future<List<Budget>> getArchivedBudgetsByUserId(int userId) async {
    final rows = await (select(budgets)
          ..where(
            (b) => b.userId.equals(userId) & b.status.equals('archived'),
          )
          ..orderBy([(b) => OrderingTerm.desc(b.endDate)]))
        .get();

    final result = <Budget>[];
    for (final row in rows) {
      result.add(await _loadBudgetWithItems(row));
    }
    return result;
  }

  Future<Budget?> getBudgetById(int id) async {
    final row =
        await (select(budgets)..where((b) => b.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _loadBudgetWithItems(row);
  }

  Future<int> createBudgetWithLineItems({
    required int userId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<BudgetLineItem> lineItems,
  }) async {
    return db.transaction(() async {
      await (update(budgets)
            ..where(
              (b) => b.userId.equals(userId) & b.status.equals('active'),
            ))
          .write(
        BudgetsCompanion(
          status: const Value('archived'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      final now = DateTime.now();
      final budgetId = await into(budgets).insert(
        BudgetsCompanion(
          userId: Value(userId),
          name: Value(name),
          startDate: Value(startDate),
          endDate: Value(endDate),
          status: const Value('active'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      for (final item in lineItems) {
        await into(budgetLineItems).insert(
          BudgetLineItemsCompanion(
            budgetId: Value(budgetId),
            name: Value(item.name),
            allocatedAmount: Value(item.allocatedAmount),
            categoryIndex: Value(item.categoryIndex),
          ),
        );
      }

      return budgetId;
    });
  }

  Future<void> updateBudgetWithLineItems({
    required int budgetId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required List<BudgetLineItem> lineItems,
  }) async {
    await db.transaction(() async {
      final now = DateTime.now();

      await (update(budgets)..where((b) => b.id.equals(budgetId))).write(
        BudgetsCompanion(
          name: Value(name),
          startDate: Value(startDate),
          endDate: Value(endDate),
          updatedAt: Value(now),
        ),
      );

      final existing = await (select(budgetLineItems)
            ..where((i) => i.budgetId.equals(budgetId)))
          .get();
      final existingIds = existing.map((e) => e.id).toSet();
      final keptIds =
          lineItems.where((i) => i.id != null).map((i) => i.id!).toSet();
      final removedIds = existingIds.difference(keptIds);

      if (removedIds.isNotEmpty) {
        await (delete(budgetLineItems)..where((i) => i.id.isIn(removedIds))).go();
      }

      for (final item in lineItems) {
        if (item.id != null) {
          await (update(budgetLineItems)..where((i) => i.id.equals(item.id!)))
              .write(
            BudgetLineItemsCompanion(
              name: Value(item.name),
              allocatedAmount: Value(item.allocatedAmount),
            ),
          );
        } else {
          await into(budgetLineItems).insert(
            BudgetLineItemsCompanion(
              budgetId: Value(budgetId),
              name: Value(item.name),
              allocatedAmount: Value(item.allocatedAmount),
              categoryIndex: Value(item.categoryIndex),
            ),
          );
        }
      }
    });
  }

  Future<List<int>> getLineItemIdsForBudget(int budgetId) async {
    final items = await (select(budgetLineItems)
          ..where((i) => i.budgetId.equals(budgetId)))
        .get();
    return items.map((i) => i.id).toList();
  }

  Future<void> deleteBudgetRecords(int budgetId) async {
    await db.transaction(() async {
      await (delete(budgetLineItems)
            ..where((i) => i.budgetId.equals(budgetId)))
          .go();
      await (delete(budgets)..where((b) => b.id.equals(budgetId))).go();
    });
  }

  Future<Budget> _loadBudgetWithItems(dynamic row) async {
    final items = await (select(budgetLineItems)
          ..where((i) => i.budgetId.equals(row.id as int)))
        .get();

    return Budget(
      id: row.id as int,
      userId: row.userId as int,
      name: row.name as String,
      startDate: row.startDate as DateTime,
      endDate: row.endDate as DateTime,
      status: row.status as String,
      createdAt: row.createdAt as DateTime,
      updatedAt: row.updatedAt as DateTime,
      lineItems: items
          .map(
            (i) => BudgetLineItem(
              id: i.id,
              budgetId: i.budgetId,
              name: i.name,
              allocatedAmount: i.allocatedAmount,
              categoryIndex: i.categoryIndex,
            ),
          )
          .toList(),
    );
  }
}
