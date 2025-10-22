import '../domain/entities/user.dart';
import '../domain/repositories/user_repository.dart';

class GetUsersUseCase {
  final UserRepository repository;
  GetUsersUseCase(this.repository);

  Future<List<User>> execute() async => await repository.getUsers();
}

class AddUserUseCase {
  final UserRepository repository;
  AddUserUseCase(this.repository);

  Future<void> execute(User user) async => await repository.addUser(user);
}

class UpdateUserUseCase {
  final UserRepository repository;
  UpdateUserUseCase(this.repository);

  Future<void> execute(User user) async => await repository.updateUser(user);
}

class DeleteUserUseCase {
  final UserRepository repository;
  DeleteUserUseCase(this.repository);

  Future<void> execute(int id) async => await repository.deleteUser(id);
}
