



import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../db/transaction_dao.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDao dao;

  TransactionRepositoryImpl({required this.dao});

  @override
  Future<List<Transaction>> getAllTransactions() => dao.getAllTransactions();

  @override
  Future<List<Transaction>> getTransactionsByBankId(int bankId) =>
      dao.getTransactionsByBankId(bankId);

  @override
  Future<void> createTransaction(Transaction transaction) =>
      dao.insertTransaction(Transaction(
        id: null,
        bankId: transaction.bankId,
        category: transaction.category,
        type: transaction.type,
        amount: transaction.amount,
        dateOf: transaction.dateOf,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

  @override
  Future<void> updateTransaction(Transaction transaction) =>
      dao.updateTransaction(transaction);

  @override
  Future<void> deleteTransaction(int id) => dao.deleteTransaction(id);
}
