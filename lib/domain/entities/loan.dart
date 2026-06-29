class Loan {
  final int? id;
  final int userId;
  final String? counterpartyName;
  final double principalAmount;
  final int disbursementTransactionId;
  final String status;
  final int? closeTransactionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Loan({
    this.id,
    required this.userId,
    this.counterpartyName,
    required this.principalAmount,
    required this.disbursementTransactionId,
    required this.status,
    this.closeTransactionId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'counterpartyName': counterpartyName,
      'principalAmount': principalAmount,
      'disbursementTransactionId': disbursementTransactionId,
      'status': status,
      'closeTransactionId': closeTransactionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      counterpartyName: map['counterpartyName'] as String?,
      principalAmount: (map['principalAmount'] as num).toDouble(),
      disbursementTransactionId: map['disbursementTransactionId'] as int,
      status: map['status'] as String,
      closeTransactionId: map['closeTransactionId'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
