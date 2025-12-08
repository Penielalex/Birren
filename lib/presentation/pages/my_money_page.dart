import 'package:birren/domain/entities/limit.dart';
import 'package:birren/presentation/controllers/limit_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:birren/presentation/widgets/custom_calander.dart';
import 'package:birren/presentation/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import '../theme/colors.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/limit_card.dart';

class MyMoneyPage extends StatefulWidget {
  const MyMoneyPage({super.key});

  @override
  State<MyMoneyPage> createState() => _MyMoneyPageState();
}

class _MyMoneyPageState extends State<MyMoneyPage> {
  final TextEditingController _salaryDayController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final LimitController limitController = Get.find<LimitController>();
  final TransactionController transactionController = Get.find<TransactionController>();

  String _selectedMonthType = "";

  final List<String> monthTypes = [
    "Start of the Month",
    "Salary Day",
  ];
  final logger = Logger();



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(

        child: Obx((){
      final result = limitController.limit.value;

      final double dailyLimit = result?.amount ?? 0;

      final now = DateTime.now();
      final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final double monthlyLimit = dailyLimit * daysInMonth;

      final int year = now.year;
      final bool isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      final int daysInYear = isLeapYear ? 366 : 365;
      final double yearlyLimit = dailyLimit * daysInYear;

      final formatter = NumberFormat('#,##0.00');

      final monthlyIndicators = transactionController.getMonthlyIndicators(
        dailyLimit: dailyLimit,
        month: DateTime(2025, 11),
      );

// For year 2025
          final yearlyIndicators = transactionController.getYearlyIndicators(
            monthlyLimit: monthlyLimit,
            year: 2025,
          );


          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: LimitCard(
                    dailyLimit: formatter.format(dailyLimit),
                    monthLimit: formatter.format(monthlyLimit),
                    yearlyLimit: formatter.format(yearlyLimit),
                  onSetLimit:() {
                    dailyLimit.toStringAsFixed(2) == "0.00"
                        ? _showAddLimitDialog
                        : _showEditLimitDialog(limitController.limit.value); //_showSetLimitDialog(selectedMonthType: limitController.limit.value?.monthStartType,salaryDay: "${limitController.limit.value?.monthStartDay}", amount:"${limitController.limit.value?.amount}");
                  }
                ),

              ),
              CustomCalendar(
                initialMode: CalendarMode.monthly,
                initialDate: DateTime.now(),
                monthlyIndicators: monthlyIndicators,
                yearlyIndicators: yearlyIndicators
              )

            ],
          );}
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ✅ SET LIMIT DIALOG
  // ---------------------------------------------------------------------------
  void _showAddLimitDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController salaryController = TextEditingController();
    String selectedMonthType = "";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Set Limit", style: AppTextStyles.headline1),
                  const SizedBox(height: 16),
                  CustomDropdown(
                    value: selectedMonthType,
                    hint: "Choose When Month Starts",
                    items: ["Start of the Month", "Salary Day"],
                    onChanged: (value) => setStateDialog(() => selectedMonthType = value!),
                  ),
                  const SizedBox(height: 16),
                  if (selectedMonthType == "Salary Day") ...[
                    CustomTextField(
                      controller: salaryController,
                      hintText: "Salary Day (1 - 31)",
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                  ],
                  CustomTextField(
                    controller: amountController,
                    hintText: "Daily spending limit",
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel", style: AppTextStyles.smallButton2),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          double amount = double.tryParse(amountController.text) ?? 0;
                          if (amount <= 0 || selectedMonthType.isEmpty) {
                            AppSnackbar.showError("Please fill out each field correctly");
                            return;
                          }

                          final limit = Limit(
                            userId: 1,
                            type: "daily",
                            amount: amount,
                            monthStartDay: selectedMonthType == "Salary Day"
                                ? int.parse(salaryController.text)
                                : 1,
                            monthStartType: selectedMonthType,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          limitController.addLimit(limit);
                          Navigator.pop(context);
                        },
                        child: Text("Set", style: AppTextStyles.smallButton1),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showEditLimitDialog(Limit? existingLimit) {
    final TextEditingController amountController =
    TextEditingController(text: existingLimit?.amount.toString());
    final TextEditingController salaryController =
    TextEditingController(text: existingLimit?.monthStartDay.toString());
    String selectedMonthType = existingLimit!.monthStartType;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Edit Limit", style: AppTextStyles.headline1),
                  const SizedBox(height: 16),
                  CustomDropdown(
                    value: selectedMonthType,
                    hint: selectedMonthType.isEmpty
                        ? "Choose When Month Starts"
                        : selectedMonthType,
                    items: ["Start of the Month", "Salary Day"],
                    onChanged: (value) => setStateDialog(() => selectedMonthType = value!),
                  ),
                  const SizedBox(height: 16),
                  if (selectedMonthType == "Salary Day") ...[
                    CustomTextField(
                      controller: salaryController,
                      hintText: "Salary Day (1 - 31)",
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                  ],
                  CustomTextField(
                    controller: amountController,
                    hintText: "Daily spending limit",
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel", style: AppTextStyles.smallButton2),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          double amount = double.tryParse(amountController.text) ?? 0;
                          if (amount <= 0 || selectedMonthType.isEmpty) {
                            AppSnackbar.showError("Please fill out each field correctly");
                            return;
                          }

                          final updatedLimit = Limit(
                            userId: existingLimit!.userId,
                            id: existingLimit.id,
                            type: "daily",
                            amount: amount,
                            monthStartDay: selectedMonthType == "Salary Day"
                                ? int.parse(salaryController.text)
                                : 1,
                            monthStartType: selectedMonthType,
                            createdAt: existingLimit.createdAt,
                            updatedAt: DateTime.now(),
                          );

                          limitController.editLimit(updatedLimit, existingLimit.id);
                          Navigator.pop(context);
                        },
                        child: Text("Save", style: AppTextStyles.smallButton1),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }



  void _resetDialogState() {
    if (!mounted) return;  //  Prevent setState after dispose

    setState(() {
      _selectedMonthType = "";
      _salaryDayController.clear();
      _amountController.clear();
    });
  }



}
