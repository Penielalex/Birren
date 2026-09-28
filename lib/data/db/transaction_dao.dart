import 'package:drift/drift.dart';
import 'app_database.dart' hide Transaction;
import '../../domain/entities/transaction.dart';
import '../../presentation/util/category.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  final AppDatabase db;

  TransactionDao(this.db) : super(db);

  /// Fetch all transactions
  Future<List<Transaction>> getAllTransactions() async {
    final result = await select(transactions).get();
    return result
        .map(
          (row) => Transaction(
            id: row.id,
            bankId: row.bankId,
            category: row.category,
            type: row.type,
            amount: row.amount,
            splitGroupId: row.splitGroupId,
            transferId: row.transferId,
            budgetLineItemId: row.budgetLineItemId,
            loanId: row.loanId,
            dateOf: row.dateOf,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
          ),
        )
        .toList();
  }

  /// Fetch transactions by bank ID
  Future<List<Transaction>> getTransactionsByBankId(int bankId) async {
    final result =
        await (select(transactions)..where((t) => t.bankId.equals(bankId))).get();
    return result
        .map(
          (row) => Transaction(
            id: row.id,
            bankId: row.bankId,
            category: row.category,
            type: row.type,
            amount: row.amount,
            splitGroupId: row.splitGroupId,
            transferId: row.transferId,
            budgetLineItemId: row.budgetLineItemId,
            loanId: row.loanId,
            dateOf: row.dateOf,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
          ),
        )
        .toList();
  }

  /// Insert a new transaction and return its id
  Future<int> insertTransaction(Transaction transaction) async {
    final now = DateTime.now();
    return into(transactions).insert(
      TransactionsCompanion(
        bankId: Value(transaction.bankId),
        category: Value(transaction.category),
        type: Value(transaction.type),
        amount: Value(transaction.amount),
        splitGroupId: Value(transaction.splitGroupId),
        transferId: Value(transaction.transferId),
        budgetLineItemId: Value(transaction.budgetLineItemId),
        loanId: Value(transaction.loanId),
        dateOf: Value(transaction.dateOf),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Update a transaction
  Future<void> updateTransaction({
    required int id,
    int? bankId,
    String? category,
    String? type,
    double? amount,
    int? transferId,
    int? budgetLineItemId,
    bool clearBudgetLineItemId = false,
    int? loanId,
    bool clearLoanId = false,
    DateTime? dateOf,
  }) async {
    final now = DateTime.now();

    final companion = TransactionsCompanion(
      bankId: bankId != null ? Value(bankId) : Value.absent(),
      category: category != null ? Value(category) : Value.absent(),
      type: type != null ? Value(type) : Value.absent(),
      amount: amount != null ? Value(amount) : Value.absent(),
      transferId: transferId != null ? Value(transferId) : Value.absent(),
      budgetLineItemId: clearBudgetLineItemId
          ? const Value(null)
          : budgetLineItemId != null
              ? Value(budgetLineItemId)
              : Value.absent(),
      loanId: clearLoanId
          ? const Value(null)
          : loanId != null
              ? Value(loanId)
              : Value.absent(),
      dateOf: dateOf != null ? Value(dateOf) : Value.absent(),
      updatedAt: Value(now),
    );

    await (update(transactions)..where((t) => t.id.equals(id))).write(companion);
  }

  /// Links an expense/income pair as an internal transfer and optionally
  /// records a transfer fee on the withdrawal bank.
  Future<void> linkInternalTransferPair({
    required int expenseId,
    required int incomeId,
    required double matchedAmount,
    required double feeAmount,
    required int feeBankId,
    required DateTime dateOf,
    int? feeBudgetLineItemId,
  }) async {
    await db.transaction(() async {
      final now = DateTime.now();
      final expenseCategory = '$expenseInternalTransferIndex';
      final incomeCategory = '$incomeInternalTransferIndex';

      await (update(transactions)..where((t) => t.id.equals(expenseId))).write(
        TransactionsCompanion(
          category: Value(expenseCategory),
          amount: Value(matchedAmount),
          transferId: Value(incomeId),
          budgetLineItemId: const Value(null),
          updatedAt: Value(now),
        ),
      );

      await (update(transactions)..where((t) => t.id.equals(incomeId))).write(
        TransactionsCompanion(
          category: Value(incomeCategory),
          amount: Value(matchedAmount),
          transferId: Value(expenseId),
          budgetLineItemId: const Value(null),
          updatedAt: Value(now),
        ),
      );

      if (feeAmount > 0.001) {
        await into(transactions).insert(
          TransactionsCompanion(
            bankId: Value(feeBankId),
            category: Value('$expenseTransferFeeIndex'),
            type: const Value('Expense'),
            amount: Value(feeAmount),
            budgetLineItemId: feeBudgetLineItemId != null
                ? Value(feeBudgetLineItemId)
                : const Value.absent(),
            dateOf: Value(dateOf),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  /// Splits one expense into principal + transfer-fee pieces that share a
  /// [splitGroupId]. Bank balance is unchanged (same total outflow).
  Future<void> splitTransferFeeFromExpense({
    required int expenseId,
    required double principalAmount,
    required double feeAmount,
    required String principalCategory,
    required int principalBudgetLineItemId,
    required int feeBudgetLineItemId,
  }) async {
    if (principalAmount <= 0 || feeAmount <= 0) {
      throw ArgumentError('Principal and fee must both be greater than 0');
    }

    await db.transaction(() async {
      final now = DateTime.now();
      final original = await (select(transactions)
            ..where((t) => t.id.equals(expenseId)))
          .getSingle();

      if (original.type != 'Expense') {
        throw StateError('Only expenses can include a transfer fee split');
      }

      final total = double.parse(
        (principalAmount + feeAmount).toStringAsFixed(2),
      );
      if ((total - original.amount).abs() > 0.05) {
        throw ArgumentError(
          'Principal + fee must equal ${original.amount}',
        );
      }

      final splitGroupId = original.splitGroupId ?? original.id;

      await (update(transactions)..where((t) => t.id.equals(expenseId))).write(
        TransactionsCompanion(
          amount: Value(principalAmount),
          category: Value(principalCategory),
          budgetLineItemId: Value(principalBudgetLineItemId),
          splitGroupId: Value(splitGroupId),
          loanId: const Value(null),
          updatedAt: Value(now),
        ),
      );

      await into(transactions).insert(
        TransactionsCompanion(
          bankId: Value(original.bankId),
          category: Value('$expenseTransferFeeIndex'),
          type: const Value('Expense'),
          amount: Value(feeAmount),
          splitGroupId: Value(splitGroupId),
          budgetLineItemId: Value(feeBudgetLineItemId),
          dateOf: Value(original.dateOf),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }

  /// Links a bank transaction to Cash by creating the cash-side counterpart.
  Future<void> linkInternalTransferToCash({
    required int primaryId,
    required String primaryType,
    required int cashBankId,
    required double amount,
    required DateTime dateOf,
  }) async {
    await db.transaction(() async {
      final now = DateTime.now();

      if (primaryType == 'Expense') {
        final incomeId = await into(transactions).insert(
          TransactionsCompanion(
            bankId: Value(cashBankId),
            category: Value('$incomeInternalTransferIndex'),
            type: const Value('Income'),
            amount: Value(amount),
            dateOf: Value(dateOf),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        await (update(transactions)..where((t) => t.id.equals(primaryId)))
            .write(
          TransactionsCompanion(
            category: Value('$expenseInternalTransferIndex'),
            amount: Value(amount),
            transferId: Value(incomeId),
            budgetLineItemId: const Value(null),
            updatedAt: Value(now),
          ),
        );
      } else {
        final expenseId = await into(transactions).insert(
          TransactionsCompanion(
            bankId: Value(cashBankId),
            category: Value('$expenseInternalTransferIndex'),
            type: const Value('Expense'),
            amount: Value(amount),
            dateOf: Value(dateOf),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        await (update(transactions)..where((t) => t.id.equals(primaryId)))
            .write(
          TransactionsCompanion(
            category: Value('$incomeInternalTransferIndex'),
            amount: Value(amount),
            transferId: Value(expenseId),
            budgetLineItemId: const Value(null),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  /// Delete a transaction
  Future<void> deleteTransaction(int id) async {
    await (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteTransactionsByBankId(int bankId) async {
    await (delete(transactions)..where((t) => t.bankId.equals(bankId))).go();
  }

  Future<void> clearBudgetLineItemIds(Iterable<int> lineItemIds) async {
    final ids = lineItemIds.toList();
    if (ids.isEmpty) return;

    await (update(transactions)..where((t) => t.budgetLineItemId.isIn(ids)))
        .write(
      TransactionsCompanion(
        budgetLineItemId: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
