import '../entities/loan.dart';
import '../entities/transaction.dart';

abstract class LoanRepository {
  Future<List<Loan>> getLoansByUserId(int userId);
  Future<List<Loan>> getOpenLoansByUserId(int userId);
  Future<Loan?> getLoanById(int id);
  Future<int> createLoanFromDisbursement({
    required int userId,
    required int transactionId,
    required double principalAmount,
    String? counterpartyName,
  });
  Future<void> linkReturnToLoan({
    required int returnTransactionId,
    required int loanId,
  });
  Future<int?> closeLoan({
    required int loanId,
    required double writeOffAmount,
    required int bankId,
    required String category,
    int? budgetLineItemId,
    required DateTime dateOf,
  });
  Future<List<Transaction>> getReturnTransactionsForLoan(int loanId);
}
