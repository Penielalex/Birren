import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/user.dart';

class UserApi {
  final String baseUrl = 'https://jsonplaceholder.typicode.com/users';

  /// Fetch users from API
  Future<List<User>> fetchUsers() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],           // optional
        googleId: json['googleId'],     // optional
        createdAt: DateTime.parse(json['createdAt']), // required
        updatedAt: DateTime.parse(json['updatedAt']), // required
      )).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  /// Add a new user
  Future<void> addUser(User user) async {
    final now = DateTime.now();
    await http.post(
      Uri.parse(baseUrl),
      body: json.encode({
        'name': user.name,
        'email': user.email,
        'googleId': user.googleId,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Update an existing user
  Future<void> updateUser(User user) async {
    final now = DateTime.now();
    await http.put(
      Uri.parse('$baseUrl/${user.id}'),
      body: json.encode({
        'name': user.name,
        'email': user.email,
        'googleId': user.googleId,
        'updatedAt': now.toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Delete a user by ID
  Future<void> deleteUser(int id) async {
    await http.delete(Uri.parse('$baseUrl/$id'));
  }
}
