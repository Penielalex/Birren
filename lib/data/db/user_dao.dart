import 'package:drift/drift.dart';
import 'app_database.dart' hide User;
import '../../domain/entities/user.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  final AppDatabase db;

  UserDao(this.db) : super(db);

  /// Fetch all users
  Future<List<User>> getUsers() async {
    final result = await select(users).get();
    return result.map((row) => User(
      id: row.id,
      name: row.name,
      email: row.email,
      googleId: row.googleId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    )).toList();
  }

  /// Insert a new user
  Future<void> insertUser(User user) async {
    final now = DateTime.now();
    await into(users).insert(UsersCompanion(
      name: Value(user.name),
      email: Value(user.email),
      googleId: Value(user.googleId),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  /// Update an existing user
  Future<void> updateUser(User user) async {
    final now = DateTime.now();
    await (update(users)..where((tbl) => tbl.id.equals(user.id!))).write(
      UsersCompanion(
        name: Value(user.name),
        email: Value(user.email),
        googleId: Value(user.googleId),
        updatedAt: Value(now),
      ),
    );
  }

  /// Delete a user by ID
  Future<void> deleteUser(int id) async {
    await (delete(users)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Fetch a single user by ID
  Future<User?> getUserById(int id) async {
    final row = await (select(users)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return User(
      id: row.id,
      name: row.name,
      email: row.email,
      googleId: row.googleId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
