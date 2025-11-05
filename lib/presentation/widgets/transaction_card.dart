import 'dart:ui';

import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/util/category.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/transaction.dart'; // Adjust the import path
import '../controllers/bank_controller.dart';
import '../theme/colors.dart';
import '../theme/text_style.dart';

class TransactionCard extends StatefulWidget {
  final Transaction transaction;
  final bool fromNotification;
  final VoidCallback? onSetCategoryPressed;

  const TransactionCard({Key? key, required this.transaction, required this.fromNotification, required this.onSetCategoryPressed}) : super(key: key);

  @override
  State<TransactionCard> createState() => _TransactionCardState();

}

class _TransactionCardState extends State<TransactionCard> {
  final GlobalKey cardKey = GlobalKey();

  final BankController bankController = Get.find<BankController>();
  final TransactionController transactionController =Get.find<TransactionController>();
  final logger = Logger();
  @override
  Widget build(BuildContext context) {
    // Choose icon based on transaction type
    IconData icon;
    Color circleColor;
    String value;

    var categoryIndex= int.parse(widget.transaction.category);


    switch (widget.transaction.type) {
      case "Income":
        icon = incomeCategories[categoryIndex].icon;
        circleColor = incomeCategories[categoryIndex].color;
        value = "+";
        break;
      case "Expense":
        icon = expenseCategories[categoryIndex].icon;
        circleColor = expenseCategories[categoryIndex].color;
        value ="-";
        break;
      default:
        icon = Icons.swap_horiz;
        circleColor = Colors.grey;
        value ="";
    }

    final formattedAmount = NumberFormat('#,##0.00').format(widget.transaction.amount);
    final formattedDate = DateFormat('yyyy-MM-dd').format(widget.transaction.dateOf);

    final tranBank = bankController.banks.firstWhere(
          (b) => b.id == widget.transaction.bankId,
      orElse: () => throw Exception("bank not found"),
    );



    return Obx(() {
      bool isSelected = transactionController.selectedTransactionIds.contains(widget.transaction.id);
      return Card(
        key: cardKey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(80), side: const BorderSide(
          color: Colors.white, // white border
          width: 0.1, // thickness of the border
        ),),
        color: isSelected ? AppColors.textPrimary.withOpacity(0.3) : AppColors
            .background, // your theme card color
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onLongPress: () async {
            if(widget.fromNotification) {
              transactionController.toggleSelection(widget.transaction.id);
            }else{


                final renderBox = cardKey.currentContext!.findRenderObject() as RenderBox;
                final position = renderBox.localToGlobal(Offset.zero);
                await showDialog(
                  context: context,
                  barrierColor: Colors.black26,
                  builder: (_) {
                    return Stack(
                      children: [
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(color: Colors.transparent),
                        ),

                        Positioned(
                          left: position.dx + renderBox.size.width - 150,
                          top: position.dy,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: 150,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: Icon(Icons.delete_outline, color: Colors.red),
                                    title: Text("Delete", style: AppTextStyles.body1),
                                    onTap: () {
                                      Navigator.pop(context);
                                      transactionController.removeTransaction(widget.transaction.id!);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    );
                  },
                );


            }
          },
          onTap: () {
            if(widget.fromNotification){
            if (transactionController.selectedTransactionIds.isNotEmpty) {
              // If selection mode is active, toggle this item
              transactionController.toggleSelection(widget.transaction.id);
            } else {

            }}
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Left Circle with Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: circleColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: circleColor, size: 24),
                        ),
                        const SizedBox(width: 16),

                        // Right Column with Amount, Bank Name and Date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${tranBank.displayName ?? tranBank.bankName} ",
                              style: AppTextStyles.headline1,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  formattedDate,
                                  style: AppTextStyles.body1,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    Text(
                      "$value $formattedAmount birr",
                      style: AppTextStyles.body1,
                    ),
                  ],
                ),
                if(widget.fromNotification && transactionController.selectedTransactionIds.isEmpty)
                  Column(
                    children: [
                      SizedBox(height: 10),
                      GestureDetector(onTap: widget.onSetCategoryPressed,
                          child: Text("Set Category", style: AppTextStyles
                              .button2.copyWith(fontSize: 12),))
                    ],
                  )

              ],
            ),
          ),
        ),
      );
    });
  }
}
