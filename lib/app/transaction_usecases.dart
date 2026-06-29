import '../domain/repositories/transaction_repository.dart';
import '../domain/entities/transaction.dart';

class GetAllTransactionsUseCase {
  final TransactionRepository repository;
  GetAllTransactionsUseCase(this.repository);

  Future<List<Transaction>> execute() async => await repository.getAllTransactions();
}

class GetTransactionsByBankIdUseCase {
  final TransactionRepository repository;
  GetTransactionsByBankIdUseCase(this.repository);

  Future<List<Transaction>> execute(int bankId) async =>
      await repository.getTransactionsByBankId(bankId);
}

class CreateTransactionUseCase {
  final TransactionRepository repository;
  CreateTransactionUseCase(this.repository);

  Future<int> execute(Transaction transaction) async =>
      await repository.createTransaction(transaction);
}

class UpdateTransactionUseCase {
  final TransactionRepository repository;
  UpdateTransactionUseCase(this.repository);

  Future<void> execute(
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
  }) async =>
      await repository.updateTransaction(
        id,
        bankId,
        category,
        type,
        amount,
        dateOf,
        transferId: transferId,
        budgetLineItemId: budgetLineItemId,
        clearBudgetLineItemId: clearBudgetLineItemId,
        loanId: loanId,
        clearLoanId: clearLoanId,
      );
}

class LinkInternalTransferUseCase {
  final TransactionRepository repository;
  LinkInternalTransferUseCase(this.repository);

  Future<void> execute({
    required int expenseId,
    required int incomeId,
    required double matchedAmount,
    required double feeAmount,
    required int feeBankId,
    required DateTime dateOf,
    int? feeBudgetLineItemId,
  }) async =>
      await repository.linkInternalTransferPair(
        expenseId: expenseId,
        incomeId: incomeId,
        matchedAmount: matchedAmount,
        feeAmount: feeAmount,
        feeBankId: feeBankId,
        dateOf: dateOf,
        feeBudgetLineItemId: feeBudgetLineItemId,
      );
}

class LinkInternalTransferToCashUseCase {
  final TransactionRepository repository;
  LinkInternalTransferToCashUseCase(this.repository);

  Future<void> execute({
    required int primaryId,
    required String primaryType,
    required int cashBankId,
    required double amount,
    required DateTime dateOf,
  }) async =>
      await repository.linkInternalTransferToCash(
        primaryId: primaryId,
        primaryType: primaryType,
        cashBankId: cashBankId,
        amount: amount,
        dateOf: dateOf,
      );
}

class DeleteTransactionUseCase {
  final TransactionRepository repository;
  DeleteTransactionUseCase(this.repository);

  Future<void> execute(int id) async => await repository.deleteTransaction(id);
}

class DeleteTransactionWithBankIdUseCase {
  final TransactionRepository repository;
  DeleteTransactionWithBankIdUseCase(this.repository);

  Future<void> execute(int bankId) async =>
      await repository.deleteTransactionWithBankId(bankId);
}
