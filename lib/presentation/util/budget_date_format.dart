import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Formats a budget date/time using the device 24-hour preference.
String formatBudgetDateTime(DateTime date, {BuildContext? context}) {
  final use24Hour = context != null
      ? MediaQuery.alwaysUse24HourFormatOf(context)
      : WidgetsBinding.instance.platformDispatcher.alwaysUse24HourFormat;

  final pattern = use24Hour ? 'MMM d, y • HH:mm' : 'MMM d, y • h:mm a';
  return DateFormat(pattern).format(date);
}
