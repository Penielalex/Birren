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
  Future<void> updateTransaction({
    required int id,
    int? bankId,
    String? category,
    String? type,
    double? amount,
    DateTime? dateOf,
  }) async {
    final now = DateTime.now();

    final companion = TransactionsCompanion(
      bankId: bankId != null ? Value(bankId) : Value.absent(),
      category: category != null ? Value(category) : Value.absent(),
      type: type != null ? Value(type) : Value.absent(),
      amount: amount != null ? Value(amount) : Value.absent(),
      dateOf: dateOf != null ? Value(dateOf) : Value.absent(),
      updatedAt: Value(now), // always update updatedAt
    );

    await (update(transactions)..where((t) => t.id.equals(id))).write(companion);
  }


  /// Delete a transaction
  Future<void> deleteTransaction(int id) async {
    await (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteTransactionsByBankId(int bankId) async {
    await (delete(transactions)..where((t) => t.bankId.equals(bankId))).go();
  }

}


