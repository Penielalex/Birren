import 'package:birren/data/db/app_database.dart';
import 'package:birren/data/service/shared_prefs_service.dart';
import 'package:birren/presentation/controllers/bank_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../domain/entities/bank.dart';
import '../theme/text_style.dart';
import '../widgets/bank_grid.dart';
import '../widgets/transaction_card.dart';
import '../widgets/transaction_list.dart';



class AccountsPage extends StatefulWidget {


  const AccountsPage({Key? key}) : super(key: key);

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final BankController bankController = Get.find<BankController>();
  final TransactionController transactionController = Get.find<TransactionController>();



  var selectedFilter="This Month";


  @override
  void initState() {
    super.initState();

    ever(bankController.isAddingBank, (bool isAdding) {
      if (isAdding) {
        Future.delayed(Duration.zero, () {
          _showAddingBankDialog();
        });
      } else {
        // ✅ Close dialog safely
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });

    ever(transactionController.isLoading, (bool isLoading) {
      if (isLoading) {
        Future.delayed(Duration.zero, () {
          _showTransactionDialog();
        });
      } else {
        // ✅ Close dialog safely
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });

  }


  void _showAddingBankDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // user cannot dismiss by tapping outside
      builder: (context) {
        return Center(
          child: Container(
            height: 290,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LoadingAnimationWidget.progressiveDots(color: AppColors.accent, size: 100),
                const SizedBox(height: 16),
                Text(
                  'Loading transactions for the past three days.',
                  style: AppTextStyles.body1.copyWith(
                    decoration: TextDecoration.none, // remove any underline
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTransactionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // user cannot dismiss by tapping outside
      builder: (context) {
        return Center(
          child: Container(
            height: 290,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LoadingAnimationWidget.progressiveDots(color: AppColors.accent, size: 100),
                const SizedBox(height: 16),
                Text(
                  'Loading transactions',
                  style: AppTextStyles.body1.copyWith(
                    decoration: TextDecoration.none, // remove any underline
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }






  void _applyDateFilter(String filter) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (filter) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);

        break;
      case 'This Week':
        start = now.subtract(Duration(days: now.weekday - 1)); // Monday
        start = DateTime(start.year, start.month, start.day);
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'Past 3 Months':
        start = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'Past 6 Months':
        start = DateTime(now.year, now.month - 6, now.day);
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        break;
      default:
        transactionController.filteredTransactions.assignAll(transactionController.transactions);
        return;
    }

    transactionController.filterTransactionsByDateRange(start, end);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: bankController.isLoading.value ? Center(child: LoadingAnimationWidget.inkDrop(color: AppColors.accent, size: 25)): SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.background,
          onRefresh: () async {
            // 🔁 This function runs when user swipes down
            await transactionController.fetchMessageTransactions();
            await bankController.fetchBanks();
          },
          child: SingleChildScrollView(
            //padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BanksGrid(
                  ),
                ),
                Divider(color: Colors.white24,),
                SizedBox(height: 100),
          
                Center(
                  child: Obx(() {
                    double totalBalance = 0;
          
          // Loop through selected indexes and sum only those banks
                    for (final index in bankController.selectedIndexes) {
                      if (index < bankController.banks.length) {
                        totalBalance += bankController.banks[index].balance ?? 0;
                      }
                    }






          
          // Format nicely
                    final formattedBalance = NumberFormat('#,##0.00').format(totalBalance);
                    return RoundedCardWithCircle(
                      circleChild: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("${formattedBalance} Birr", style:AppTextStyles.headline1),
                          SizedBox(height: 4),
                        Text("Total Balance", style: AppTextStyles.midBody1),
          
          
                      ],),
                      circleColor: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 150),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 0, 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Transactions",
                                      style: AppTextStyles.headline1,
                                    ),
                                    FutureBuilder<DateTime?>(
                                      future: bankController.getLatestLastFetchDate(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return Text(
                                            "Last Fetched: loading...",
                                            style: AppTextStyles.body1.copyWith(color: Colors.grey, fontSize: 9),
                                          );
                                        }

                                        final date = snapshot.data;

                                        return Text(
                                          date == null
                                              ? "Last Fetched: No data"
                                              : "Last Fetched: ${DateFormat('yyyy-MM-dd HH:mm').format(date)}",
                                          style: AppTextStyles.body1.copyWith(color: Colors.grey, fontSize: 9),
                                        );
                                      },
                                    )

                                  ],
                                ),
                                Container(
                                  margin: EdgeInsetsGeometry.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    border: Border.all(color:AppColors.accent),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (AppColors.accent).withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                        offset:  const Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(3, 0, 3, 0),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedFilter,
                                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                        style: const TextStyle(fontSize: 14, color: Colors.white),
                                        dropdownColor: AppColors.background,
                                        items: const [
                                          DropdownMenuItem(value: 'All', child: Text('All')),
                                          DropdownMenuItem(value: 'Today', child: Text('Today')),
                                          DropdownMenuItem(value: 'Yesterday', child: Text('Yesterday')),
                                          DropdownMenuItem(value: 'This Week', child: Text('This Week')),
                                          DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                                          DropdownMenuItem(value: 'Past 3 Months', child: Text('Past 3 Months')),
                                          DropdownMenuItem(value: 'Past 6 Months', child: Text('Past 6 Months')),
                                          DropdownMenuItem(value: 'This Year', child: Text('This Year')),
                                          DropdownMenuItem(value: 'Custom Range', child: Text('Custom Range')),
                                        ],
                                        onChanged: (value) async {
                                          if (value == null) return;
                                          setState(() => selectedFilter = value);
          
                                          if (value == 'Custom Range') {
                                            final pickedRange =  await showDateRangePicker(
                                              context: context,
                                              firstDate: DateTime(2020),
                                              lastDate: DateTime.now(),
                                              initialDateRange: DateTimeRange(
                                                start: DateTime.now().subtract(const Duration(days: 7)),
                                                end: DateTime.now(),
                                              ),
                                              builder: (context, child) {
                                                return Theme(
                                                  data: ThemeData(
                                                    colorScheme: ColorScheme.dark(
                                                      primary: Colors.blue, // ✅ Selection color (range highlight)
                                                      onPrimary: Colors.white, // ✅ Text color on selected date
                                                      surface: AppColors.background, // ✅ Dialog background color
                                                      secondary:  AppColors.accent,
                                                      onSurface: Colors.white
                                                    ), // ✅ Background color of the picker
                                                    textButtonTheme: TextButtonThemeData(
                                                      style: TextButton.styleFrom(
                                                        foregroundColor: Colors.white, // ✅ "CANCEL" and "OK" button text
                                                      ),
                                                    ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
                                                  ),
                                                  child: child!,
                                                );
                                              },
                                            );
          
          
                                            if (pickedRange != null) {
                                              await transactionController.filterTransactionsByDateRange(
                                                pickedRange.start,
                                                pickedRange.end,
                                              );
                                            }
                                          } else {
                                            _applyDateFilter(value);
                                          }
          
          
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
          
                          SizedBox(height: 4),
                          Obx(() {
                      if (bankController.banks.isNotEmpty) {


                      final selectedBankIds = bankController
                          .selectedIndexes
                          .map((index) => bankController.banks[index].id)
                          .toSet(); // convert to set for faster lookup

                      final txns = transactionController.filteredTransactions
                          .where((txn) => selectedBankIds.contains(txn.bankId))
                          .toList();

                      if (txns.length == 0) {
                        return Center(child: Padding(
                          padding: const EdgeInsets.all(70.0),
                          child: Text(
                            "No Transactions.", style: AppTextStyles.body1,),
                        ));
                      } else {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: txns.length,
                          itemBuilder: (context, index) {
                            return TransactionCard(transaction: txns[index],
                              fromNotification: false,
                              onSetCategoryPressed: () {},);
                          },
                        );
                      }
                    }else{return Center(child: Padding(
                        padding: const EdgeInsets.all(70.0),
                        child: Text(
                          "No Transactions.", style: AppTextStyles.body1,),
                      ));} })
          
                        ],
                      ),
                    );
            }),
          
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




