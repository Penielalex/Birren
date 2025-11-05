import 'package:flutter/material.dart';

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
];

// Spending Categories
final List<Category> expenseCategories = [
  Category(name: 'Groceries', icon: Icons.shopping_bag, color: Colors.orange),
  Category(name: 'Restaurants', icon: Icons.restaurant, color: Colors.red),
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
  Category(name: 'Loan', icon: Icons.account_balance, color: Colors.blueGrey),
  Category(name: 'Bills', icon: Icons.receipt_long, color: Colors.cyan),
  Category(name: 'Savings/Investment', icon: Icons.savings, color: Colors.teal),
  Category(name: 'Other', icon: Icons.more_horiz, color: Colors.yellow),
  Category(name: 'Non-categorized', icon: Icons.help_outline, color: Colors.grey),
  Category(name: 'Gifts', icon: Icons.card_giftcard, color: Colors.lightGreen),
  Category(name: 'Care products', icon: Icons.self_improvement, color: Color(0XFFE7DDFF)),
  Category(name: 'Phone Bill', icon: Icons.phone, color: Color(0XFF898BD5)),
  Category(name: 'Shopping', icon: Icons.shopping_bag, color: Color(0XFFFEA7A7)),
  Category(name: 'Entertainment', icon: Icons.movie_creation_outlined, color: Color(0XFFFFF9C9)),
];
