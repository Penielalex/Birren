import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_line_item.dart';
import 'category.dart';

const String defaultTransferFeeLineItemName = 'Transfer Fee';
const double defaultTransferFeeLineItemAmount = 500;

bool isTransferFeeLineItemName(String name) =>
    name.trim().toLowerCase() == defaultTransferFeeLineItemName.toLowerCase();

bool isTransferFeeCategory(String category, String type) =>
    type == 'Expense' && category == '$expenseTransferFeeIndex';

List<BudgetLineItem> withDefaultTransferFeeLineItem(
  List<BudgetLineItem> lineItems,
) {
  if (lineItems.any((item) => isTransferFeeLineItemName(item.name))) {
    return lineItems;
  }

  return [
    ...lineItems,
    BudgetLineItem(
      budgetId: 0,
      name: defaultTransferFeeLineItemName,
      allocatedAmount: defaultTransferFeeLineItemAmount,
    ),
  ];
}

BudgetLineItem? findTransferFeeLineItem(Budget budget) {
  for (final item in budget.lineItems) {
    if (isTransferFeeLineItemName(item.name)) {
      return item;
    }
  }
  return null;
}
