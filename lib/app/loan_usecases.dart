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

class SplitSharedExpenseUseCase {
  final LoanRepository repository;
  SplitSharedExpenseUseCase(this.repository);

  Future<void> execute({
    required int originalTransactionId,
    required int userId,
    required double yourShare,
    required double friendsShare,
    required String yourCategoryIndex,
    int? budgetLineItemId,
    String? counterpartyName,
  }) =>
      repository.splitSharedExpense(
        originalTransactionId: originalTransactionId,
        userId: userId,
        yourShare: yourShare,
        friendsShare: friendsShare,
        yourCategoryIndex: yourCategoryIndex,
        budgetLineItemId: budgetLineItemId,
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

class AllocatePaymentAcrossLoansUseCase {
  final LoanRepository repository;
  AllocatePaymentAcrossLoansUseCase(this.repository);

  Future<void> execute({
    required int paymentTransactionId,
    required List<({int loanId, double amount})> allocations,
    required bool isReturn,
  }) =>
      repository.allocatePaymentAcrossLoans(
        paymentTransactionId: paymentTransactionId,
        allocations: allocations,
        isReturn: isReturn,
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
