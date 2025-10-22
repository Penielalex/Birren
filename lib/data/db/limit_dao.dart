import 'package:drift/drift.dart' hide Limit;
import 'app_database.dart' hide Limit;
import '../../domain/entities/limit.dart'; // your Limit entity

part 'limit_dao.g.dart';

@DriftAccessor(tables: [Limits])
class LimitDao extends DatabaseAccessor<AppDatabase> with _$LimitDaoMixin {
  final AppDatabase db;

  LimitDao(this.db) : super(db);

  /// Fetch all limits
  Future<List<Limit>> getAllLimits() async {
    final result = await select(limits).get();
    return result.map((row) => Limit(
      id: row.id,
      userId: row.userId,
      type: row.type,
      amount: row.amount,
      monthStartDay: row.monthStartDay,
      monthStartType: row.monthStartType,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    )).toList();
  }

  /// Fetch limits by user ID
  Future<List<Limit>> getLimitsByUserId(int userId) async {
    final result = await (select(limits)..where((l) => l.userId.equals(userId))).get();
    return result.map((row) => Limit(
      id: row.id,
      userId: row.userId,
      type: row.type,
      amount: row.amount,
      monthStartDay: row.monthStartDay,
      monthStartType: row.monthStartType,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    )).toList();
  }

  /// Insert a new limit
  Future<void> insertLimit(Limit limit) async {
    final now = DateTime.now();
    await into(limits).insert(LimitsCompanion(
      userId: Value(limit.userId),
      type: Value(limit.type),
      amount: Value(limit.amount),
      monthStartDay: Value(limit.monthStartDay),
      monthStartType: Value(limit.monthStartType),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  /// Update a limit
  Future<void> updateLimit(Limit limit) async {
    final now = DateTime.now();
    await (update(limits)..where((l) => l.id.equals(limit.id!))).write(
      LimitsCompanion(
        userId: Value(limit.userId),
        type: Value(limit.type),
        amount: Value(limit.amount),
        monthStartDay: Value(limit.monthStartDay),
        monthStartType: Value(limit.monthStartType),
        updatedAt: Value(now),
      ),
    );
  }

  /// Delete a limit
  Future<void> deleteLimit(int id) async {
    await (delete(limits)..where((l) => l.id.equals(id))).go();
  }
}
