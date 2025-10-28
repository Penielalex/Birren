class Bank {
  final int? id;           // Primary key
  final int userId;        // ID of the user this bank belongs to
  final String bankName;   // Official bank name
  final String? displayName; // Custom name to display in app
  final double balance;    // Current balance
  final DateTime createdAt; // Creation timestamp
  final DateTime updatedAt; // Last update timestamp

  Bank({
    this.id,
    required this.userId,
    required this.bankName,
     this.displayName,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  // Optional: Convert from Map (for database or API)
  factory Bank.fromMap(Map<String, dynamic> map) {
    return Bank(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      bankName: map['bankName'] as String,
      displayName: map['displayName'] as String,
      balance: (map['balance'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Optional: Convert to Map (for database or API)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'bankName': bankName,
      'displayName': displayName,
      'balance': balance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
