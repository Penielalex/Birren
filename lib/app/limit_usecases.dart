import '../domain/repositories/limit_repository.dart';
import '../domain/entities/limit.dart';

class GetAllLimitsUseCase {
  final LimitRepository repository;
  GetAllLimitsUseCase(this.repository);

  Future<List<Limit>> execute() async => await repository.getAllLimits();
}

class GetLimitByUserIdUseCase {
  final LimitRepository repository;
  GetLimitByUserIdUseCase(this.repository);

  Future<Limit?> execute(int userId) async => await repository.getLimitByUserId(userId);
}

class CreateLimitUseCase {
  final LimitRepository repository;
  CreateLimitUseCase(this.repository);

  Future<void> execute(Limit limit) async => await repository.createLimit(limit);
}

class UpdateLimitUseCase {
  final LimitRepository repository;
  UpdateLimitUseCase(this.repository);

  Future<void> execute(Limit limit) async => await repository.updateLimit(limit);
}

class DeleteLimitUseCase {
  final LimitRepository repository;
  DeleteLimitUseCase(this.repository);

  Future<void> execute(int id) async => await repository.deleteLimit(id);
}
