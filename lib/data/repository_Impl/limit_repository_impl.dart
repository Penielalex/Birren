

import '../../domain/entities/limit.dart';
import '../../domain/repositories/limit_repository.dart';
import '../db/limit_dao.dart';

class LimitRepositoryImpl implements LimitRepository {
  final LimitDao dao;

  LimitRepositoryImpl({required this.dao});

  @override
  Future<List<Limit>> getAllLimits() => dao.getAllLimits();

  @override
  Future<List<Limit>> getLimitsByUserId(int userId) => dao.getLimitsByUserId(userId);

  @override
  Future<void> createLimit(Limit limit) =>
      dao.insertLimit(Limit(
        id: null,
        userId: limit.userId,
        type: limit.type,
        amount: limit.amount,
        monthStartDay: limit.monthStartDay,
        monthStartType: limit.monthStartType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

  @override
  Future<void> updateLimit(Limit limit) => dao.updateLimit(limit);

  @override
  Future<void> deleteLimit(int id) => dao.deleteLimit(id);
}
