class Limit {
  final int? id;            // Primary key
  final int userId;         // The user this limit belongs to
  final String type;        // Type of limit (e.g., Daily, Monthly)
  final double amount;      // Limit amount
  final int monthStartDay;  // Day of the month the limit starts (1-31)
  final String monthStartType; // Type of month start (e.g., fixed, rolling)
  final DateTime createdAt; // Creation timestamp
  final DateTime updatedAt; // Last update timestamp

  Limit({
    this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.monthStartDay,
    required this.monthStartType,
    required this.createdAt,
    required this.updatedAt,
  });

  // Optional: Convert from Map (for database or API)
  factory Limit.fromMap(Map<String, dynamic> map) {
    return Limit(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      monthStartDay: map['monthStartDay'] as int,
      monthStartType: map['monthStartType'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Optional: Convert to Map (for database or API)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'monthStartDay': monthStartDay,
      'monthStartType': monthStartType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
