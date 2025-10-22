import 'package:birren/presentation/theme/colors.dart';
import 'package:birren/presentation/theme/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/auth_controller.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AuthController authController = Get.find<AuthController>();
  final VoidCallback? onBellPressed;
  final VoidCallback? onMenuPressed;

   CustomAppBar({
    Key? key,
    this.onBellPressed,
    this.onMenuPressed,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(90);

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
                IconButton(
                  icon:  Icon(Icons.notifications_sharp,
                      color: AppColors.textPrimary, ),
                  onPressed: onBellPressed,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.textPrimary),
                  onPressed: onMenuPressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
