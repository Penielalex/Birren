import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'app_database.dart' hide Bank;
import '../../domain/entities/bank.dart';

part 'bank_dao.g.dart';

@DriftAccessor(tables: [Banks])
class BankDao extends DatabaseAccessor<AppDatabase> with _$BankDaoMixin {
  final AppDatabase db;

  BankDao(this.db) : super(db);

  /// Fetch all banks
  Future<List<Bank>> getBanks() async {
    final result = await (select(banks)
      ..orderBy([(b) => OrderingTerm(expression: b.createdAt, mode: OrderingMode.desc)]))
        .get();
    return result.map((row) => Bank(
      id: row.id,
      userId: row.userId,
      bankName: row.bankName,
      displayName: row.displayName,
      balance: row.balance,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    )).toList();
  }

  /// Fetch banks by user ID
  Future<List<Bank>> getBanksByUser(int userId) async {
    final result = await (select(banks)..where((tbl) => tbl.userId.equals(userId))).get();
    return result.map((row) => Bank(
      id: row.id,
      userId: row.userId,
      bankName: row.bankName,
      displayName: row.displayName,
      balance: row.balance,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    )).toList();
  }

  /// Insert a new bank
  Future<void> insertBank(Bank bank) async {
    try{

    await into(banks).insert(BanksCompanion(
      userId: Value(bank.userId),
      bankName: Value(bank.bankName),
      displayName: Value(bank.displayName),
      balance: Value(bank.balance),
      createdAt: Value(bank.createdAt),
      updatedAt: Value(bank.updatedAt),
    ));}on SqliteException catch (e) {
      if (e.message.contains('UNIQUE') ?? false) {
        throw Exception('Bank name must be unique per user');
      }
      rethrow;
    }
  }

  /// Update an existing bank
  Future<void> updateBank(Bank bank) async {
    final now = DateTime.now();
     await (update(banks)..where((tbl) => tbl.id.equals(bank.id!))).write(
      BanksCompanion(
        bankName: Value(bank.bankName),
        displayName: Value(bank.displayName),
        balance: Value(bank.balance),
        updatedAt: Value(now),
      ),
    );
  }

  /// Delete a bank by ID
  Future<int> deleteBank(int id) async {
    return await (delete(banks)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Fetch a single bank by ID
  Future<Bank?> getBankById(int id) async {
    final row = await (select(banks)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return Bank(
      id: row.id,
      userId: row.userId,
      bankName: row.bankName,
      displayName: row.displayName,
      balance: row.balance,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
