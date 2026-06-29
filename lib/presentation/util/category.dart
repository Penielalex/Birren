import 'package:flutter/material.dart';

/// SMS-imported transactions have no category until the user assigns one.
const String noCategory = '';

bool transactionHasNoCategory(String category) => category.trim().isEmpty;

/// Index of "Non-categorized" in [incomeCategories].
const int incomeNonCategorizedIndex = 5;

/// Index of "Non-categorized" in [expenseCategories].
const int expenseNonCategorizedIndex = 17;

/// Index of "Internal Transfer" in [incomeCategories].
const int incomeInternalTransferIndex = 6;

/// Index of "Internal Transfer" in [expenseCategories].
const int expenseInternalTransferIndex = 23;

/// Index of "Transfer Fee" in [expenseCategories] (after fee category is added).
const int expenseTransferFeeIndex = 24;

/// Index of "Returns" in [incomeCategories].
const int incomeReturnsIndex = 2;

/// Index of "Loan" in [incomeCategories] — money borrowed from outside.
const int incomeLoanIndex = 7;

/// Index of "Loan Repayment" in [expenseCategories] — paying back borrowed money.
const int expenseLoanIndex = 13;

/// Index of "Loan" in [expenseCategories] — money you lend to someone.
const int expenseLendLoanIndex = 25;

bool isInternalTransferCategory(String category, String type) {
  if (type == 'Income') {
    return category == '$incomeInternalTransferIndex';
  }
  if (type == 'Expense') {
    return category == '$expenseInternalTransferIndex';
  }
  return false;
}

bool isIncomingLoanCategory(String category, String type) {
  return type == 'Income' && category == '$incomeLoanIndex';
}

bool isLoanRepaymentCategory(String category, String type) {
  return type == 'Expense' && category == '$expenseLoanIndex';
}

bool isOutgoingLendCategory(String category, String type) {
  return type == 'Expense' && category == '$expenseLendLoanIndex';
}

/// @deprecated Use [isLoanRepaymentCategory] or [isIncomingLoanCategory].
bool isLoanCategory(String category, String type) =>
    isLoanRepaymentCategory(category, type);

bool isReturnsCategory(String category, String type) {
  return type == 'Income' && category == '$incomeReturnsIndex';
}

bool countsInIncomeExpenseSummary(String category, String type) {
  if (isInternalTransferCategory(category, type)) return false;
  if (isIncomingLoanCategory(category, type)) return false;
  if (isLoanRepaymentCategory(category, type)) return false;
  if (isOutgoingLendCategory(category, type)) return false;
  return true;
}

bool countsTransactionInIncomeExpenseSummary(
  String category,
  String type, {
  int? loanId,
}) {
  if (!countsInIncomeExpenseSummary(category, type)) return false;
  if (loanId != null) return false;
  return true;
}

String categoryDisplayName(String category, String type) {
  if (transactionHasNoCategory(category)) return 'Uncategorized';
  final index = int.tryParse(category);
  if (index == null) return category;
  if (type == 'Income' && index >= 0 && index < incomeCategories.length) {
    return incomeCategories[index].name;
  }
  if (type == 'Expense' && index >= 0 && index < expenseCategories.length) {
    return expenseCategories[index].name;
  }
  return category;
}

class Category {
  final String name;
  final IconData icon;
  final Color color;

  Category({required this.name, required this.icon, required this.color});
}

// Income Categories
final List<Category> incomeCategories = [
  Category(name: 'Salary', icon: Icons.attach_money, color: Colors.green),
  Category(name: 'Gifts', icon: Icons.card_giftcard, color: Colors.pink),
  Category(name: 'Returns', icon: Icons.replay, color: Colors.blue),
  Category(name: 'Savings/Investment', icon: Icons.savings, color: Colors.teal),
  Category(name: 'Other', icon: Icons.more_horiz, color: Colors.yellow),
  Category(name: 'Non-categorized', icon: Icons.help_outline, color: Colors.grey),
  Category(name: 'Internal Transfer', icon: Icons.compare_arrows_outlined, color: Color(0XFF016B3C)),
  Category(name: 'Loan', icon: Icons.account_balance_wallet, color: Colors.blueGrey),
];

// Spending Categories
final List<Category> expenseCategories = [
  Category(name: 'Groceries', icon: Icons.shopping_cart_outlined, color: Colors.orange),
  Category(name: 'Restaurants', icon: Icons.fastfood_outlined, color: Colors.red),
  Category(name: 'Fuel', icon: Icons.local_gas_station, color: Colors.deepPurple),
  Category(name: 'Taxi', icon: Icons.directions_bus, color: Colors.lightBlue),
  Category(name: 'Ride', icon: Icons.local_taxi, color: Colors.blueAccent),
  Category(name: 'Medical', icon: Icons.medical_services, color: Colors.deepOrangeAccent),
  Category(name: 'Fitness', icon: Icons.fitness_center, color: Colors.greenAccent),
  Category(name: 'School', icon: Icons.school, color: Colors.indigo),
  Category(name: 'Hobbies', icon: Icons.brush, color: Colors.purple),
  Category(name: 'Clothing', icon: Icons.checkroom, color: Colors.brown),
  Category(name: 'Hair', icon: Icons.content_cut, color: Colors.pinkAccent),
  Category(name: 'Nails', icon: Icons.palette, color: Colors.purpleAccent),
  Category(name: 'Feminine Products', icon: Icons.female, color: Colors.pink),
  Category(name: 'Loan Repayment', icon: Icons.account_balance, color: Colors.blueGrey),
  Category(name: 'Bills', icon: Icons.receipt_long, color: Colors.cyan),
  Category(name: 'Savings/Investment', icon: Icons.savings, color: Colors.teal),
  Category(name: 'Other', icon: Icons.more_horiz, color: Colors.yellow),
  Category(name: 'Non-categorized', icon: Icons.help_outline, color: Colors.grey),
  Category(name: 'Gifts', icon: Icons.card_giftcard, color: Colors.lightGreen),
  Category(name: 'Care products', icon: Icons.self_improvement, color: Color(0XFFE7DDFF)),
  Category(name: 'Phone Bill', icon: Icons.phone, color: Color(0XFF898BD5)),
  Category(name: 'Shopping', icon: Icons.shopping_bag, color: Color(0XFFFEA7A7)),
  Category(name: 'Entertainment', icon: Icons.movie_creation_outlined, color: Color(0XFFFFF9C9)),
  Category(name: 'Internal Transfer', icon: Icons.compare_arrows_outlined, color: Color(0XFF016B3C)),
  Category(name: 'Transfer Fee', icon: Icons.receipt, color: Colors.blueGrey),
  Category(name: 'Loan', icon: Icons.payments_outlined, color: Colors.blueGrey),

];
