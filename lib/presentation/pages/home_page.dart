import 'package:birren/presentation/controllers/app_navigation_controller.dart';
import 'package:birren/presentation/pages/accounts_page.dart';
import 'package:birren/presentation/pages/loans_page.dart';
import 'package:birren/presentation/pages/my_money_page.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:birren/presentation/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final AppNavigationController navigationController =
      Get.find<AppNavigationController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(),
      body: Column(
        children: [
          Row(
            children: [
              _buildTab('Accounts', 0),
              _buildTab('My Money', 1),
              _buildTab('Loans', 2),
            ],
          ),
          Expanded(
            child: Obx(() {
              switch (navigationController.homeTabIndex.value) {
                case 2:
                  return const LoansPage();
                case 1:
                  return MyMoneyPage();
                case 0:
                default:
                  return AccountsPage();
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
        onTap: () => navigationController.homeTabIndex.value = index,
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: Colors.transparent,
                child: Center(
                  child: Text(
                    title,
                    style: navigationController.homeTabIndex.value == index
                        ? AppTextStyles.midBody1
                        : AppTextStyles.midBody3,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: navigationController.homeTabIndex.value == index
                      ? AppColors.accent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: navigationController.homeTabIndex.value == index
                          ? AppColors.accent
                          : Colors.transparent,
                      blurRadius: 4,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                height: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
