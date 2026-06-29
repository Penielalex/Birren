
import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getAllTransactions();
  Future<List<Transaction>> getTransactionsByBankId(int bankId);
  Future<int> createTransaction(Transaction transaction);
  Future<void> updateTransaction(
    int id,
    int? bankId,
    String? category,
    String? type,
    double? amount,
    DateTime? dateOf, {
    int? transferId,
    int? budgetLineItemId,
    bool clearBudgetLineItemId = false,
    int? loanId,
    bool clearLoanId = false,
  });
  Future<void> linkInternalTransferPair({
    required int expenseId,
    required int incomeId,
    required double matchedAmount,
    required double feeAmount,
    required int feeBankId,
    required DateTime dateOf,
    int? feeBudgetLineItemId,
  });
  Future<void> linkInternalTransferToCash({
    required int primaryId,
    required String primaryType,
    required int cashBankId,
    required double amount,
    required DateTime dateOf,
  });
  Future<void> deleteTransaction(int id);
  Future<void> deleteTransactionWithBankId(int bankId);
}
