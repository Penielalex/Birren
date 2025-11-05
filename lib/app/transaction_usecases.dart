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

  Future<void> execute( int id,
      int? bankId,
      String? category,
      String? type,
      double? amount,
      DateTime? dateOf,) async => await repository.updateTransaction(id, bankId,category,type,amount,dateOf);
}

class DeleteTransactionUseCase {
  final TransactionRepository repository;
  DeleteTransactionUseCase(this.repository);

  Future<void> execute(int id) async => await repository.deleteTransaction(id);
}


class DeleteTransactionWithBankIdUseCase {
  final TransactionRepository repository;
  DeleteTransactionWithBankIdUseCase(this.repository);

  Future<void> execute(int bankId) async => await repository.deleteTransactionWithBankId(bankId);
}