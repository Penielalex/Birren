



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
  Future<void> updateTransaction( int id,
      int? bankId,
      String? category,
      String? type,
      double? amount,
      DateTime? dateOf,) =>
      dao.updateTransaction(id: id, bankId: bankId, category: category, type: type, amount: amount, dateOf: dateOf);

  @override
  Future<void> deleteTransaction(int id) => dao.deleteTransaction(id);

  @override
  Future<void> deleteTransactionWithBankId(int bankId) => dao.deleteTransactionsByBankId(bankId);



}
