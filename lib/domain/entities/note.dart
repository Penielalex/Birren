class Note {
  final int? id;
  final int userId;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      title: map['title'] as String,
      body: map['body'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
