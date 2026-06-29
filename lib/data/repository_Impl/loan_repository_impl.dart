import '../../domain/entities/loan.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/loan_repository.dart';
import '../db/loan_dao.dart';

class LoanRepositoryImpl implements LoanRepository {
  final LoanDao dao;

  LoanRepositoryImpl({required this.dao});

  @override
  Future<List<Loan>> getLoansByUserId(int userId) =>
      dao.getLoansByUserId(userId);

  @override
  Future<List<Loan>> getOpenLoansByUserId(int userId) =>
      dao.getOpenLoansByUserId(userId);

  @override
  Future<Loan?> getLoanById(int id) => dao.getLoanById(id);

  @override
  Future<int> createLoanFromDisbursement({
    required int userId,
    required int transactionId,
    required double principalAmount,
    String? counterpartyName,
  }) =>
      dao.createLoanFromDisbursement(
        userId: userId,
        transactionId: transactionId,
        principalAmount: principalAmount,
        counterpartyName: counterpartyName,
      );

  @override
  Future<int> createLoanFromLend({
    required int userId,
    required int transactionId,
    required double principalAmount,
    String? counterpartyName,
  }) =>
      dao.createLoanFromLend(
        userId: userId,
        transactionId: transactionId,
        principalAmount: principalAmount,
        counterpartyName: counterpartyName,
      );

  @override
  Future<void> linkRepaymentToLoan({
    required int repaymentTransactionId,
    required int loanId,
  }) =>
      dao.linkRepaymentToLoan(
        repaymentTransactionId: repaymentTransactionId,
        loanId: loanId,
      );

  @override
  Future<void> linkReturnToLentLoan({
    required int returnTransactionId,
    required int loanId,
  }) =>
      dao.linkReturnToLentLoan(
        returnTransactionId: returnTransactionId,
        loanId: loanId,
      );

  @override
  Future<int?> closeLoan({
    required int loanId,
    required double writeOffAmount,
    required int bankId,
    required String category,
    int? budgetLineItemId,
    required DateTime dateOf,
  }) =>
      dao.closeLoan(
        loanId: loanId,
        writeOffAmount: writeOffAmount,
        bankId: bankId,
        category: category,
        budgetLineItemId: budgetLineItemId,
        dateOf: dateOf,
      );

  @override
  Future<List<Transaction>> getReturnTransactionsForLoan(int loanId) =>
      dao.getReturnTransactionsForLoan(loanId);
}
