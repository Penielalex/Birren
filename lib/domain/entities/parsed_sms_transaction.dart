class ParsedSmsTransaction {
  final String transactionType;
  final double? amount;
  final double? balance;
  final String? currency;

  const ParsedSmsTransaction({
    required this.transactionType,
    this.amount,
    this.balance,
    this.currency,
  });

  bool get isActionable =>
      transactionType != 'unknown' && amount != null && balance != null;

  factory ParsedSmsTransaction.unknown() {
    return const ParsedSmsTransaction(transactionType: 'unknown');
  }

  Map<String, dynamic> toSmsMap({
    required DateTime date,
    String? address,
  }) {
    return {
      'transactionType': transactionType,
      'firstAmount': amount,
      'balanceAmount': balance,
      'currency': currency,
      'date': date,
      if (address != null) 'address': address,
    };
  }
}
