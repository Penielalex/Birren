import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../api/user_api.dart';
import '../db/user_dao.dart';

class UserRepositoryImpl implements UserRepository {
  final UserApi api;
  final UserDao dao;

  UserRepositoryImpl({required this.api, required this.dao});

  @override
  Future<List<User>> getUsers() async {
    try {
      final remoteUsers = await api.fetchUsers();
      // Save to local db
      for (var user in remoteUsers) {
        await dao.insertUser(user);
      }
      return remoteUsers;
    } catch (_) {
      // fallback to local db
      return dao.getUsers();
    }
  }

  @override
  Future<void> addUser(User user) async {
    await api.addUser(user);
    await dao.insertUser(user);
  }

  @override
  Future<void> updateUser(User user) async {
    await api.updateUser(user);
    await dao.updateUser(user);
  }

  @override
  Future<void> deleteUser(int id) async {
    await api.deleteUser(id);
    await dao.deleteUser(id);
  }
}
