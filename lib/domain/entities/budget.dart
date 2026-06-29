import 'budget_line_item.dart';

class Budget {
  final int? id;
  final int userId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BudgetLineItem> lineItems;

  const Budget({
    this.id,
    required this.userId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lineItems = const [],
  });

  bool get isActive => status == 'active';

  bool get isExpired {
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    return DateTime.now().isAfter(end);
  }

  double get totalAllocated =>
      lineItems.fold(0.0, (sum, item) => sum + item.allocatedAmount);
}
