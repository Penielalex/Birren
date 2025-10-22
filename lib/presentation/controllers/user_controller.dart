import 'package:get/get.dart';
import '../../domain/entities/user.dart';
import '../../app/user_usecases.dart';

class UserController extends GetxController {
  final GetUsersUseCase getUsers;
  final AddUserUseCase addUser;
  final UpdateUserUseCase updateUser;
  final DeleteUserUseCase deleteUser;

  UserController({
    required this.getUsers,
    required this.addUser,
    required this.updateUser,
    required this.deleteUser,
  });

  var users = <User>[].obs;
  var isLoading = false.obs;

  /// Fetch all users
  void fetchUsers() async {
    isLoading.value = true;
    users.value = await getUsers.execute();
    isLoading.value = false;
  }

  /// Create a new user
  void createUser({
    required String name,
    String? email,
    String? googleId,
  }) async {
    final now = DateTime.now();
    final user = User(
      name: name,
      email: email,
      googleId: googleId,
      createdAt: now,
      updatedAt: now,
    );
    await addUser.execute(user);
    fetchUsers();
  }

  /// Update an existing user
  void editUser({
    required int id,
    required String name,
    String? email,
    String? googleId,
  }) async {
    final now = DateTime.now();
    final user = User(
      id: id,
      name: name,
      email: email,
      googleId: googleId,
      createdAt: users.firstWhere((u) => u.id == id).createdAt,
      updatedAt: now,
    );
    await updateUser.execute(user);
    fetchUsers();
  }

  /// Delete a user by ID
  void removeUser(int id) async {
    await deleteUser.execute(id);
    fetchUsers();
  }
}
