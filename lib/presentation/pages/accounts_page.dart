import 'package:birren/presentation/controllers/bank_controller.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../domain/entities/bank.dart';
import '../theme/text_style.dart';
import '../widgets/bank_grid.dart';



class AccountsPage extends StatefulWidget {


  const AccountsPage({Key? key}) : super(key: key);

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final BankController bankController = Get.find<BankController>();


  final _bankNameController = TextEditingController();
  final _displayNameController = TextEditingController();

  @override
  void dispose() {
    _bankNameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _showAddBankDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // smaller radius
          ),
          title: Text("Add Account", style: AppTextStyles.headline1,),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(controller: _bankNameController, hintText: "Bank Name", suffixIcon:Icons.info_outline, onSuffixPressed: (){
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.background,
                    title: Text("Bank Name Info", style: AppTextStyles.headline1,),
                    content: Text(
                        "Enter the bank or wallet name as it appears on messages.", style: AppTextStyles.body1),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child:  Text("OK", style: AppTextStyles.smallButton2),
                      ),
                    ],
                  ),
                );
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
              onPressed: ()  {
                final bankName = _bankNameController.text.trim();
                final displayName = _displayNameController.text.trim();

                if (bankName.isEmpty) return; // Require bank name
                bankController.addBank(bankName, displayName);


                _bankNameController.clear();
                _displayNameController.clear();

                Navigator.pop(context);
              },
              child:  Text("Add",style: AppTextStyles.smallButton1),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              BanksGrid(

                onAddBank:_showAddBankDialog,
              ),
              Divider(color: Colors.white24,),
              SizedBox(height: 24),

              Center(
                child: Text(
                  'Other content goes here',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
