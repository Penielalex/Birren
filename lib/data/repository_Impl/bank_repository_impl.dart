import 'package:logger/logger.dart';

import '../../domain/entities/bank.dart';
import '../../domain/repositories/bank_repository.dart';
import '../db/bank_dao.dart';

class BankRepositoryImpl implements BankRepository {
  final BankDao dao;

  BankRepositoryImpl({required this.dao});

  var logger =Logger();

  @override
  Future<List<Bank>> getBanks() async {
    return dao.getBanks();
  }

  @override
  Future<List<Bank>> getBanksByUser(int userId) async {
    return dao.getBanksByUser(userId);
  }

  @override
  Future<void> insertBank(Bank bank) async {
    try{
     await dao.insertBank(bank);
    }catch (e) {
      // Convert to domain error
      if (e.toString().contains('unique')) {
        throw Exception('You already have a bank with this name.');
      }
      rethrow;
    }

  }

  @override
  Future<void> updateBank(Bank bank) async {
    return dao.updateBank(bank);
  }

  @override
  Future<int> deleteBank(int id) async {
    return dao.deleteBank(id);
  }
}
