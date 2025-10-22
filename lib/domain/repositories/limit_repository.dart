
import '../entities/limit.dart';

abstract class LimitRepository {
  Future<List<Limit>> getAllLimits();
  Future<List<Limit>> getLimitsByUserId(int userId);
  Future<void> createLimit(Limit limit);
  Future<void> updateLimit(Limit limit);
  Future<void> deleteLimit(int id);
}
