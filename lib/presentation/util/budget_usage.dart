import 'package:flutter/material.dart';

Color budgetUsageColor(double spent, double allocated) {
  if (allocated <= 0) return Colors.green;
  final ratio = spent / allocated;
  if (ratio > 0.75) return Colors.red;
  if (ratio > 0.50) return Colors.amber;
  return Colors.green;
}

String budgetUsageColorName(double spent, double allocated) {
  if (allocated <= 0) return 'green';
  final ratio = spent / allocated;
  if (ratio > 0.75) return 'red';
  if (ratio > 0.50) return 'amber';
  return 'green';
}
