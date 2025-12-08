import 'package:birren/presentation/controllers/user_controller.dart';
import 'package:birren/presentation/pages/accounts_page.dart';
import 'package:birren/presentation/pages/my_money_page.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  final UserController controller = Get.find<UserController>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController googleIdController = TextEditingController();

  // Observable to track selected tab: 0 = Home, 1 = My Money
  final selectedTab = 0.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(),
      body: Column(
        children: [
          // --- Custom Tab Bar ---
          Obx(() => Row(
            children: [
              _buildTab('Accounts', 0),
              _buildTab('My Money', 1),
            ],
          )),


          // --- Tab Content ---
          Expanded(
            child: Obx(() {
              if (selectedTab.value == 0) {
                // --- Home Tab Content (users) ---
                return AccountsPage();
              } else {
                // --- My Money Tab Content ---
                return MyMoneyPage();
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => selectedTab.value = index,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              color: Colors.transparent,
              child: Center(
                child: Text(
                  title,
                  style: selectedTab.value == index ? AppTextStyles.midBody1:AppTextStyles.midBody3
                ),

              ),
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                  color: selectedTab.value == index  ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                  color: selectedTab.value == index  ? AppColors.accent  : Colors.transparent,
                    blurRadius: 4,
                    offset: Offset(0, 0),
                  ),]

              ),
              height: 3,

            ),
          ],
        ),
      ),
    );
  }




}
