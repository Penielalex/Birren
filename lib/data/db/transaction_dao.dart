import 'package:drift/drift.dart';
import 'app_database.dart' hide Transaction;
import '../../domain/entities/transaction.dart'; // your Transaction entity

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  final AppDatabase db;

  TransactionDao(this.db) : super(db);

  /// Fetch all transactions
  Future<List<Transaction>> getAllTransactions() async {
    final result = await select(transactions).get();
    return result.map((row) => Transaction(
      id: row.id,
      bankId: row.bankId,
      category: row.category,
      type: row.type,
      amount: row.amount,
      dateOf: row.dateOf,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    )).toList();
  }

  /// Fetch transactions by bank ID
  Future<List<Transaction>> getTransactionsByBankId(int bankId) async {
    final result = await (select(transactions)..where((t) => t.bankId.equals(bankId))).get();
    return result.map((row) => Transaction(
      id: row.id,
      bankId: row.bankId,
      category: row.category,
      type: row.type,
      amount: row.amount,
      dateOf: row.dateOf,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    )).toList();
  }

  /// Insert a new transaction
  Future<void> insertTransaction(Transaction transaction) async {
    final now = DateTime.now();
    await into(transactions).insert(TransactionsCompanion(
      bankId: Value(transaction.bankId),
      category: Value(transaction.category),
      type: Value(transaction.type),
      amount: Value(transaction.amount),
      dateOf: Value(transaction.dateOf),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  /// Update a transaction
  Future<void> updateTransaction(Transaction transaction) async {
    final now = DateTime.now();
    await (update(transactions)..where((t) => t.id.equals(transaction.id!))).write(
      TransactionsCompanion(
        bankId: Value(transaction.bankId),
        category: Value(transaction.category),
        type: Value(transaction.type),
        amount: Value(transaction.amount),
        dateOf: Value(transaction.dateOf),
        updatedAt: Value(now),
      ),
    );
  }

  /// Delete a transaction
  Future<void> deleteTransaction(int id) async {
    await (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}
