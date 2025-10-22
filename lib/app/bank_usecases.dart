import '../domain/entities/bank.dart';
import '../domain/repositories/bank_repository.dart';
import 'package:drift/drift.dart';

class GetBanksUseCase {
  final BankRepository repository;
  GetBanksUseCase(this.repository);

  Future<List<Bank>> execute() async => await repository.getBanks();
}

class GetBanksByUserUseCase {
  final BankRepository repository;
  GetBanksByUserUseCase(this.repository);

  Future<List<Bank>> execute(int userId) async => await repository.getBanksByUser(userId);
}

class AddBankUseCase {
  final BankRepository repository;
  AddBankUseCase(this.repository);

  Future<void> execute(Bank bank) async => await repository.insertBank(bank);
}

class UpdateBankUseCase {
  final BankRepository repository;
  UpdateBankUseCase(this.repository);

  Future<void> execute(Bank bank) async => await repository.updateBank(bank);
}

class DeleteBankUseCase {
  final BankRepository repository;
  DeleteBankUseCase(this.repository);

  Future<void> execute(int id) async => await repository.deleteBank(id);
}
