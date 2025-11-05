import 'package:birren/presentation/controllers/bank_controller.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:birren/presentation/pages/notifications_page.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/auth_controller.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onBellPressed;
  final VoidCallback? onMenuPressed;

   CustomAppBar({
    Key? key,
    this.onBellPressed,
    this.onMenuPressed,
  }) : super(key: key);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(90);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final AuthController authController = Get.find<AuthController>();
  final TransactionController transactionController= Get.find<TransactionController>();
  final BankController bankController = Get.find<BankController>();



  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      clipBehavior: Clip.none,
      title: Container(

        padding: const EdgeInsets.only(left: 12, right: 12, top: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            // 👤 Avatar with gradient border
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.green],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.lightBlue.shade50,
                        child: Icon(
                          Icons.person_outline,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    ],

                  ),
                ),
                SizedBox(width:10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      'Welcome back!',
                      style: AppTextStyles.headline1,
                    ),
                    Obx(() {
                      String userName = authController.users.isNotEmpty
                          ? authController.users.first.name
                          : 'Guest';

                      // Capitalize each word
                      String capitalizedName = userName
                          .split(' ')
                          .map((word) => word.isNotEmpty
                          ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                          : '')
                          .join(' ');

                      return Text(
                        capitalizedName,
                        style: AppTextStyles.body1,
                      );
                    }),

                  ],
                ),
              ],
            ),




            // 🔔 Bell & ⋮ Menu icons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Obx((){
                  final count =
                      transactionController.notificationTransaction.length;

                  return Stack(
                    clipBehavior: Clip.none,
                    children:[
                      IconButton(
                        icon:  Icon(Icons.notifications_sharp,
                          color: AppColors.textPrimary, ),
                        onPressed: () {
                          // 🧭 Navigate to the Notification Page
                          Get.to(() => NotificationsPage());
                        },
                      ),
                      if(count > 0)
                        Positioned(
                          right: 7,
                          top: 1,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                            ),
                          ),
                        ),
                    ]
                  );
                }),

                IconButton(
                  icon: const Icon(Icons.refresh,
                      color: AppColors.textPrimary),
                  onPressed: (){transactionController.fetchMessageTransactions();
                    bankController.fetchBanks();},

                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
