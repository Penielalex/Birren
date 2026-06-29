import 'dart:ui';

import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/widgets/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:birren/core/app_logger.dart';
import '../../domain/entities/bank.dart';
import '../controllers/bank_controller.dart';
import '../theme/colors.dart';
import '../theme/text_style.dart';
import '../util/cash_bank.dart';
import '../widgets/app_snackbar.dart';
import 'custom_textfield.dart';

class BanksGrid extends StatefulWidget {



  const BanksGrid({
    Key? key,


  }) : super(key: key);

  @override
  _BanksGridState createState() => _BanksGridState();
}



class _BanksGridState extends State<BanksGrid> {

  List<GlobalKey> bankItemKeys = [];

  String selectedBank = "";
  DateTime _importFromDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  final List<String> bankNamesAll = [
    "BOA",
    "CBE",
    "127",
    "MPESA",
    cashBankName,
  ];
  final _displayNameController = TextEditingController();
  final _startingBalanceController = TextEditingController();
  final BankController bankController = Get.find<BankController>();
  final TransactionController transactionController = Get.find<TransactionController>();
  bool showAll = false;
  bool customSelectionMode = false;

  final List<LinearGradient> gradients = [
    const LinearGradient(colors: [Color(0xFF6A0DAD), Color(0xFF4B0082)], begin: Alignment.topLeft, end: Alignment.bottomRight), // purple → indigo
    const LinearGradient(colors: [Color(0xFF4B0082), Color(0xFF00008B)], begin: Alignment.topLeft, end: Alignment.bottomRight), // indigo → dark blue
    const LinearGradient(colors: [Color(0xFF00008B), Color(0xFF0000CD)], begin: Alignment.topLeft, end: Alignment.bottomRight), // dark blue → medium blue
    const LinearGradient(colors: [Color(0xFF0000CD), Color(0xFF1E90FF)], begin: Alignment.topLeft, end: Alignment.bottomRight), // medium blue → dodger blue
    const LinearGradient(colors: [Color(0xFF1E90FF), Color(0xFF00CED1)], begin: Alignment.topLeft, end: Alignment.bottomRight), // dodger blue → dark turquoise
    const LinearGradient(colors: [Color(0xFF00CED1), Color(0xFF20B2AA)], begin: Alignment.topLeft, end: Alignment.bottomRight), // dark turquoise → light sea green
    const LinearGradient(colors: [Color(0xFF20B2AA), Color(0xFF008080)], begin: Alignment.topLeft, end: Alignment.bottomRight), // light sea green → teal
    const LinearGradient(colors: [Color(0xFF6A0DAD), Color(0xFF00008B)], begin: Alignment.topLeft, end: Alignment.bottomRight), // purple → dark blue
    const LinearGradient(colors: [Color(0xFF4B0082), Color(0xFF1E90FF)], begin: Alignment.topLeft, end: Alignment.bottomRight), // indigo → dodger blue
    const LinearGradient(colors: [Color(0xFF0000CD), Color(0xFF20B2AA)], begin: Alignment.topLeft, end: Alignment.bottomRight), // medium blue → light sea green
    const LinearGradient(colors: [Color(0xFF1E90FF), Color(0xFF008080)], begin: Alignment.topLeft, end: Alignment.bottomRight), // dodger blue → teal
    const LinearGradient(colors: [Color(0xFF6A0DAD), Color(0xFF00CED1)], begin: Alignment.topLeft, end: Alignment.bottomRight), // purple → dark turquoise
  ];


  final logger = appLogger;

  @override
  void dispose() {
    selectedBank ="";
    _displayNameController.dispose();
    _startingBalanceController.dispose();
    super.dispose();
  }


  void handleSelectAll(int total) {
    bankController.selectedIndexes
      ..clear()
      ..addAll(List.generate(total, (i) => i));
    customSelectionMode = false;
  }

  void _showAddBankDialog() {
    var importFromDate = _importFromDate;
    _startingBalanceController.clear();

    final availableBanks = bankNamesAll
        .where(
          (name) => !bankController.banks.any((b) => b.bankName == name),
        )
        .toList();

    if (availableBanks.isEmpty) {
      AppSnackbar.showError('All account types are already added');
      return;
    }

    if (!availableBanks.contains(selectedBank)) {
      selectedBank = availableBanks.first;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // smaller radius
          ),
          title: Text("Add Account", style: AppTextStyles.headline1,),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomDropdown(
                value: selectedBank,
                hint: "Bank Name",
                items: availableBanks,
                onChanged: (value) {
                  setDialogState(() {
                    selectedBank = value!;
                  });
                },
              ),
              // Bank Name Field

              const SizedBox(height: 16),

              if (isCashBankName(selectedBank)) ...[
                CustomTextField(
                  controller: _startingBalanceController,
                  hintText: 'Starting cash balance',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cash transactions are entered manually — no SMS import.',
                  style: AppTextStyles.lightBody1,
                ),
              ] else
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: importFromDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      helpText: 'Import transactions from',
                    );
                    if (picked != null) {
                      setDialogState(() {
                        importFromDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                        );
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Import from date',
                      labelStyle: AppTextStyles.body1,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat.yMMMd().format(importFromDate),
                      style: AppTextStyles.body1,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Display Name Field
              CustomTextField(controller: _displayNameController, hintText: "Display Name", suffixIcon:Icons.info_outline, onSuffixPressed: (){
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.background,
                    title:  Text("Display Name Info", style: AppTextStyles.headline1,),
                    content: Text(
                        "Enter a friendly name for the account.",style: AppTextStyles.body1 ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child:  Text("OK", style: AppTextStyles.smallButton2),
                      ),
                    ],
                  ),
                );
              },),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel", style: AppTextStyles.smallButton2),
            ),
            ElevatedButton(
              onPressed: () async {
                final bankName = selectedBank;
                String? displayName = _displayNameController.text.trim();

                if (bankName.isEmpty) return;

                final initialBalance = isCashBankName(bankName)
                    ? (double.tryParse(
                          _startingBalanceController.text.trim(),
                        ) ??
                        0)
                    : 0.0;

                if (isCashBankName(bankName) && initialBalance < 0) {
                  AppSnackbar.showError('Starting balance cannot be negative');
                  return;
                }

                if (displayName.isEmpty) {
                  displayName = null;
                }
                _importFromDate = importFromDate;
                await bankController.addBank(
                  bankName,
                  displayName,
                  importFromDate,
                  initialBalance: initialBalance,
                );

                selectedBank = "";
                _displayNameController.clear();
                _startingBalanceController.clear();
                _importFromDate = DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  1,
                );

                await transactionController.fetchSavedTransactions();

                setState(() {
                  bankController.selectedIndexes.clear();
                  bankController.selectedIndexes.addAll(List.generate(bankController.banks.length, (index) => index));

                });

                Navigator.pop(context);
              },
              child:  Text("Add",style: AppTextStyles.smallButton1),
            ),
          ],
        );
          },
        );
      },
    );
  }



  void _showEditBankDialog(Bank bank) {
    showDialog(
      context: context,
      builder: (context) {
        selectedBank = bank.bankName;
        _displayNameController.text = bank.displayName ?? "";

        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // smaller radius
          ),
          title: Text("Update Account", style: AppTextStyles.headline1,),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomDropdown(isEnabled: false, value: selectedBank, hint:"Bank Name", items: bankNamesAll, onChanged: (value) {
                setState(() {
                  selectedBank = value!;

                });
              },),
              // Bank Name Field

              const SizedBox(height: 16),



              // Display Name Field
              CustomTextField(controller: _displayNameController, hintText: "Display Name", suffixIcon:Icons.info_outline, onSuffixPressed: (){
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.background,
                    title:  Text("Display Name Info", style: AppTextStyles.headline1,),
                    content: Text(
                        "Enter a friendly name for the account.",style: AppTextStyles.body1 ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child:  Text("OK", style: AppTextStyles.smallButton2),
                      ),
                    ],
                  ),
                );
              },),

              const SizedBox(height: 16),

            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel", style: AppTextStyles.smallButton2),
            ),
            ElevatedButton(
              onPressed: () async {
                final bankName = selectedBank;
                String? displayName = _displayNameController.text.trim();

                if (displayName.isEmpty){
                  displayName = null;
                }

                    var editBank = Bank(userId: bank.userId,
                        id: bank.id,
                        displayName: displayName,
                        bankName: bank.bankName,
                        balance: bank.balance,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now());
                    bankController.editBank(editBank);







                Navigator.pop(context);
              },
              child:  Text("Edit",style: AppTextStyles.smallButton1),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {


    return Obx(() {

      logger.i("obx reloaded ${bankController.selectedIndexes}");

      final banks = bankController.banks;
      //selectedIndexes.addAll(List.generate(banks.length, (index) => index));
      final banksToShow = showAll
          ? banks
          : banks.length > 4
          ? banks.sublist(0, 4)
          : banks;

      final canAddBank = banks.length < 12;

      bankItemKeys = List.generate(
        banksToShow.length,
            (_) => GlobalKey(),
      );

      return Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
            ),
            itemCount: banksToShow.length + (canAddBank ? 1 : 0),
            itemBuilder: (context, index) {
              if (canAddBank && index == banksToShow.length) {
                return AddBankItem(onTap: _showAddBankDialog);
              }

              final bank = banksToShow[index];
              final gradient = gradients[index % gradients.length];
              final isSelected = bankController.selectedIndexes.contains(index);
              final key = bankItemKeys[index];

              return GestureDetector(
                key: key,
                onLongPress: ()async{

                  final renderBox = key.currentContext!.findRenderObject() as RenderBox;
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
                                      leading: Icon(Icons.edit_outlined, color: Colors.white),
                                      title: Text("Edit", style: AppTextStyles.body1),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showEditBankDialog(banks[index]);

                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.delete_outline, color: Colors.red),
                                      title: Text("Delete", style: AppTextStyles.body1),
                                      onTap: ()async {
                                        Navigator.pop(context);
                                        await bankController.removeBank(bank.id!);
                                        transactionController.fetchSavedTransactions();
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

                },
                onTap: () {
                  setState(() {
                    if (!customSelectionMode) {
                      bankController.selectedIndexes
                        ..clear()
                        ..add(index);
                      customSelectionMode = true;
                    } else {
                      if (isSelected) {
                        bankController.selectedIndexes.remove(index);
                      } else {
                        bankController.selectedIndexes.add(index);
                      }
                    }

                    // ✅ If all selected manually, same as pressing “Select All”
                    if (bankController.selectedIndexes.length == banks.length) {
                      handleSelectAll(banks.length);
                    }
                  });
                },
                child: BankItem(

                  bank: bank,
                  gradient: gradient,
                  isSelected: isSelected,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (banks.length > 4)
                TextButton(
                  onPressed: () {
                    setState(() {
                      showAll = !showAll;
                    });
                  },
                  child: Text(
                    showAll ? "Show Less" : "See All",
                    style: AppTextStyles.body1,
                  ),
                ),
              if (customSelectionMode &&
                  (bankController.selectedIndexes.length < banks.length))
                TextButton(
                  onPressed: () {
                    setState(() {
                      handleSelectAll(banks.length);
                    });
                  },
                  child: Text(
                    "Select All",
                    style: AppTextStyles.body1,
                  ),
                ),
            ],
          ),
        ],
      );

    });
  }
}

// ----------------- Single Bank Item -----------------
class BankItem extends StatelessWidget {
  final Bank bank;
  final LinearGradient gradient;
  final bool isSelected;

  const BankItem({
    Key? key,
    required this.bank,
    required this.gradient,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key:key,
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: isSelected
            ? gradient
            : const LinearGradient(colors: [Colors.grey, Colors.grey]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isSelected ? AppColors.accent : Colors.transparent,
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bank.displayName ?? bank.bankName,
              style: AppTextStyles.body1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              "${bank.balance.toStringAsFixed(2)} Birr",
              style: AppTextStyles.lightBody1,
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- Add Bank Item -----------------
class AddBankItem extends StatelessWidget {
  final VoidCallback onTap;

  const AddBankItem({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent,
              blurRadius: 4,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 5, 0, 0),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, color: AppColors.accent),
              const SizedBox(width: 10),
              Text(
                "Add Account",
                style: AppTextStyles.body1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}