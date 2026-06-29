import '../domain/entities/loan.dart';
import '../domain/entities/transaction.dart';
import '../domain/repositories/loan_repository.dart';

class GetLoansByUserIdUseCase {
  final LoanRepository repository;
  GetLoansByUserIdUseCase(this.repository);

  Future<List<Loan>> execute(int userId) => repository.getLoansByUserId(userId);
}

class GetOpenLoansByUserIdUseCase {
  final LoanRepository repository;
  GetOpenLoansByUserIdUseCase(this.repository);

  Future<List<Loan>> execute(int userId) =>
      repository.getOpenLoansByUserId(userId);
}

class CreateLoanFromDisbursementUseCase {
  final LoanRepository repository;
  CreateLoanFromDisbursementUseCase(this.repository);

  Future<int> execute({
    required int userId,
    required int transactionId,
    required double principalAmount,
    String? counterpartyName,
  }) =>
      repository.createLoanFromDisbursement(
        userId: userId,
        transactionId: transactionId,
        principalAmount: principalAmount,
        counterpartyName: counterpartyName,
      );
}

class CreateLoanFromLendUseCase {
  final LoanRepository repository;
  CreateLoanFromLendUseCase(this.repository);

  Future<int> execute({
    required int userId,
    required int transactionId,
    required double principalAmount,
    String? counterpartyName,
  }) =>
      repository.createLoanFromLend(
        userId: userId,
        transactionId: transactionId,
        principalAmount: principalAmount,
        counterpartyName: counterpartyName,
      );
}

class LinkRepaymentToLoanUseCase {
  final LoanRepository repository;
  LinkRepaymentToLoanUseCase(this.repository);

  Future<void> execute({
    required int repaymentTransactionId,
    required int loanId,
  }) =>
      repository.linkRepaymentToLoan(
        repaymentTransactionId: repaymentTransactionId,
        loanId: loanId,
      );
}

class LinkReturnToLentLoanUseCase {
  final LoanRepository repository;
  LinkReturnToLentLoanUseCase(this.repository);

  Future<void> execute({
    required int returnTransactionId,
    required int loanId,
  }) =>
      repository.linkReturnToLentLoan(
        returnTransactionId: returnTransactionId,
        loanId: loanId,
      );
}

class CloseLoanUseCase {
  final LoanRepository repository;
  CloseLoanUseCase(this.repository);

  Future<int?> execute({
    required int loanId,
    required double writeOffAmount,
    required int bankId,
    required String category,
    int? budgetLineItemId,
    required DateTime dateOf,
  }) =>
      repository.closeLoan(
        loanId: loanId,
        writeOffAmount: writeOffAmount,
        bankId: bankId,
        category: category,
        budgetLineItemId: budgetLineItemId,
        dateOf: dateOf,
      );
}

class GetReturnTransactionsForLoanUseCase {
  final LoanRepository repository;
  GetReturnTransactionsForLoanUseCase(this.repository);

  Future<List<Transaction>> execute(int loanId) =>
      repository.getReturnTransactionsForLoan(loanId);
}
