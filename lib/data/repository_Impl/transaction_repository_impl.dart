
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
  Future<int> createTransaction(Transaction transaction) =>
      dao.insertTransaction(
        Transaction(
          id: null,
          bankId: transaction.bankId,
          category: transaction.category,
          type: transaction.type,
          amount: transaction.amount,
          transferId: transaction.transferId,
          budgetLineItemId: transaction.budgetLineItemId,
          loanId: transaction.loanId,
          dateOf: transaction.dateOf,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

  @override
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
  }) =>
      dao.updateTransaction(
        id: id,
        bankId: bankId,
        category: category,
        type: type,
        amount: amount,
        transferId: transferId,
        budgetLineItemId: budgetLineItemId,
        clearBudgetLineItemId: clearBudgetLineItemId,
        loanId: loanId,
        clearLoanId: clearLoanId,
        dateOf: dateOf,
      );

  @override
  Future<void> linkInternalTransferPair({
    required int expenseId,
    required int incomeId,
    required double matchedAmount,
    required double feeAmount,
    required int feeBankId,
    required DateTime dateOf,
    int? feeBudgetLineItemId,
  }) =>
      dao.linkInternalTransferPair(
        expenseId: expenseId,
        incomeId: incomeId,
        matchedAmount: matchedAmount,
        feeAmount: feeAmount,
        feeBankId: feeBankId,
        dateOf: dateOf,
        feeBudgetLineItemId: feeBudgetLineItemId,
      );

  @override
  Future<void> linkInternalTransferToCash({
    required int primaryId,
    required String primaryType,
    required int cashBankId,
    required double amount,
    required DateTime dateOf,
  }) =>
      dao.linkInternalTransferToCash(
        primaryId: primaryId,
        primaryType: primaryType,
        cashBankId: cashBankId,
        amount: amount,
        dateOf: dateOf,
      );

  @override
  Future<void> deleteTransaction(int id) => dao.deleteTransaction(id);

  @override
  Future<void> deleteTransactionWithBankId(int bankId) =>
      dao.deleteTransactionsByBankId(bankId);
}
