class BudgetLineItem {
  final int? id;
  final int budgetId;
  final String name;
  final double allocatedAmount;
  final String? categoryIndex;

  const BudgetLineItem({
    this.id,
    required this.budgetId,
    required this.name,
    required this.allocatedAmount,
    this.categoryIndex,
  });

  BudgetLineItem copyWith({
    int? id,
    int? budgetId,
    String? name,
    double? allocatedAmount,
    String? categoryIndex,
  }) {
    return BudgetLineItem(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      name: name ?? this.name,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      categoryIndex: categoryIndex ?? this.categoryIndex,
    );
  }
}
