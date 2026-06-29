class Transaction {
  final int? id;          // Primary key
  final int bankId;       // The bank this transaction belongs to
  final String category;  // Category of transaction (e.g., Food, Rent)
  final String type;      // Type of transaction (e.g., income, expense)
  final double amount;    // Transaction amount
  final int? transferId; // Linked counterpart for internal transfers
  final int? budgetLineItemId; // Which budget line item this expense counts against
  final int? loanId; // Linked loan for disbursements or returns
  final DateTime dateOf;  // Date of the transaction
  final DateTime createdAt; // Creation timestamp
  final DateTime updatedAt; // Last update timestamp

  Transaction({
    this.id,
    required this.bankId,
    required this.category,
    required this.type,
    required this.amount,
    this.transferId,
    this.budgetLineItemId,
    this.loanId,
    required this.dateOf,
    required this.createdAt,
    required this.updatedAt,
  });

  // Optional: Convert from Map (for database or API)
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      bankId: map['bankId'] as int,
      category: map['category'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      transferId: map['transferId'] as int?,
      budgetLineItemId: map['budgetLineItemId'] as int?,
      loanId: map['loanId'] as int?,
      dateOf: DateTime.parse(map['dateOf'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Optional: Convert to Map (for database or API)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bankId': bankId,
      'category': category,
      'type': type,
      'amount': amount,
      'transferId': transferId,
      'budgetLineItemId': budgetLineItemId,
      'loanId': loanId,
      'dateOf': dateOf.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
