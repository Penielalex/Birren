
import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getAllTransactions();
  Future<List<Transaction>> getTransactionsByBankId(int bankId);
  Future<void> createTransaction(Transaction transaction);
  Future<void> updateTransaction( int id,
      int? bankId,
      String? category,
      String? type,
      double? amount,
      DateTime? dateOf,);
  Future<void> deleteTransaction(int id);
  Future<void> deleteTransactionWithBankId(int bankId);
}
