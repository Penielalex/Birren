import '../entities/bank.dart';

abstract class BankRepository {
  // Create a new bank using a companion (for Drift)
  Future<void> insertBank(Bank bank);

  // Get all banks
  Future<List<Bank>> getBanks();

  // Get banks by user ID
  Future<List<Bank>> getBanksByUser(int userId);

  // Update a bank
  Future<void> updateBank(Bank bank);

  // Delete a bank
  Future<void> deleteBank(int id);
}
