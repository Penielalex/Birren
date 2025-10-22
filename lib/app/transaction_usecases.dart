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

  Future<List<Transaction>> execute(int bankId) async => await repository.getTransactionsByBankId(bankId);
}

class CreateTransactionUseCase {
  final TransactionRepository repository;
  CreateTransactionUseCase(this.repository);

  Future<void> execute(Transaction transaction) async => await repository.createTransaction(
    transaction
  );
}

class UpdateTransactionUseCase {
  final TransactionRepository repository;
  UpdateTransactionUseCase(this.repository);

  Future<void> execute(Transaction transaction) async => await repository.updateTransaction(transaction);
}

class DeleteTransactionUseCase {
  final TransactionRepository repository;
  DeleteTransactionUseCase(this.repository);

  Future<void> execute(int id) async => await repository.deleteTransaction(id);
}
