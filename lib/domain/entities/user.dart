class User {
  final int? id;
  final String name;
  final String? email;
  final String? googleId;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    this.id,
    required this.name,
    this.email,
    this.googleId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, googleId: $googleId, '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
