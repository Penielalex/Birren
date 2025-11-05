import 'package:birren/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../controllers/transaction_controller.dart';
import '../theme/colors.dart';
import '../theme/text_style.dart';
import '../util/category.dart';
import '../widgets/transaction_card.dart';

class NotificationsPage extends StatefulWidget {

  NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final TransactionController transactionController = Get.find<TransactionController>();
  final logger = Logger();

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      transactionController.clearSelection();
    });
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final txns = transactionController.notificationTransaction;
      final selectedCount = transactionController.selectedTransactionIds.length;



      final selectedTransactions = transactionController.transactions
          .where((txn) => transactionController.selectedTransactionIds.contains(txn.id))
          .toList();

// Default values
      final bool allSameType;
      final String? commonType;

      if (selectedTransactions.isEmpty) {
        allSameType = false;
        commonType = null;
      } else {
        final firstType = selectedTransactions.first.type;
        allSameType = selectedTransactions.every((txn) => txn.type == firstType);
        commonType = allSameType ? firstType : null;
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          //title: Text("Notifications", style: AppTextStyles.headline1),
          centerTitle: false,
          backgroundColor: AppColors.background,
          elevation: 1,
          iconTheme: const IconThemeData(
            color: Colors.white, // white back arrow
          ),
          title: selectedCount > 0
              ? Text(
            "$selectedCount selected",
            style: AppTextStyles.headline1,
          )
              : Text("Notifications", style: AppTextStyles.headline1),
          actions: selectedCount > 0
              ? [
            TextButton(
              onPressed: () {
                // Clear selection
                transactionController.clearSelection();
              },
              child: Text(
                "Clear",
                style: AppTextStyles.body1.copyWith(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {

                if(allSameType){
                showCategoryDialog(context,commonType!);}else{
                  AppSnackbar.showError("Can not select multiple transactions with different types(Income or Expense)");
                }

                // Handle setting categories for selected transactions
                // Example: open a bottom sheet or page to set categories
                //transactionController.setCategoryForSelected(context);
              },
              child: Text(
                "Set Category",
                style: AppTextStyles.body1.copyWith(color: Colors.white),
              ),
            ),
          ]
              : null,
        ),

        body: Obx(() {
          final txns = transactionController.notificationTransaction;

          if (txns.isEmpty) {
            return Center(
              child: Text(
                "No notifications yet",
                style: AppTextStyles.body1.copyWith(color: Colors.grey),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👇 Text above the list
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Please set categories for the transactions loaded from your messages.",
                  style: AppTextStyles.body1,
                ),
              ),
              const SizedBox(height: 10),

              // 👇 Transaction list
              Expanded(
                child: ListView.builder(
                  itemCount: txns.length,
                  itemBuilder: (context, index) {
                    return TransactionCard(
                      transaction: txns[index], fromNotification: true, onSetCategoryPressed: () {
                      transactionController.toggleSelection(txns[index].id);
                      showCategoryDialog(context,txns[index].type);
                    },);
                  },
                ),
              ),
            ],
          );
        }),
      );
    });
  }
}




void showCategoryDialog(BuildContext context, String type) {
  final TransactionController transactionController = Get.find<TransactionController>();

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Category",
                style: AppTextStyles.headline1,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: type =="Income"?incomeCategories.length : expenseCategories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    Category category;
                    if(type == "Income"){
                      category = incomeCategories[index];
                    }else{
                      category = expenseCategories[index];
                    }

                    return GestureDetector(
                      onTap: () async {
                        // Update all selected transactions
                        for (var txnId in transactionController.selectedTransactionIds) {
                          await transactionController.editTransaction(
                            txnId,
                            null,
                            "$index",
                            null,
                            null,
                            null
                          );
                        }

                        // Clear selection after updating
                        transactionController.clearSelection();

                        Get.back(); // Close the dialog
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(category.icon, color: category.color, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              category.name,
                              style: AppTextStyles.body1,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
