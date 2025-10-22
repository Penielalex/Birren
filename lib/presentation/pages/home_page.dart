import 'package:birren/presentation/controllers/user_controller.dart';
import 'package:birren/presentation/pages/accounts_page.dart';
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
                return _myMoneyTab();
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

  Widget _homeTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            children: [
              TextField(controller: nameController, decoration: InputDecoration(hintText: 'Name')),
              SizedBox(height: 8),
              TextField(controller: emailController, decoration: InputDecoration(hintText: 'Email (optional)')),
              SizedBox(height: 8),
              TextField(controller: googleIdController, decoration: InputDecoration(hintText: 'Google ID (optional)')),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  controller.createUser(
                    name: nameController.text,
                    email: emailController.text.isEmpty ? null : emailController.text,
                    googleId: googleIdController.text.isEmpty ? null : googleIdController.text,
                  );
                  nameController.clear();
                  emailController.clear();
                  googleIdController.clear();
                },
                child: Text('Add User'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) return Center(child: CircularProgressIndicator());
            if (controller.users.isEmpty) return Center(child: Text('No users found.'));

            return ListView.builder(
              itemCount: controller.users.length,
              itemBuilder: (context, index) {
                final user = controller.users[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text('${user.email ?? '-'} | ${user.googleId ?? '-'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          final nameEditController = TextEditingController(text: user.name);
                          final emailEditController = TextEditingController(text: user.email);
                          final googleIdEditController = TextEditingController(text: user.googleId);

                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Edit User'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(controller: nameEditController, decoration: InputDecoration(labelText: 'Name')),
                                  TextField(controller: emailEditController, decoration: InputDecoration(labelText: 'Email')),
                                  TextField(controller: googleIdEditController, decoration: InputDecoration(labelText: 'Google ID')),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    controller.editUser(
                                      id: user.id!,
                                      name: nameEditController.text,
                                      email: emailEditController.text.isEmpty ? null : emailEditController.text,
                                      googleId: googleIdEditController.text.isEmpty ? null : googleIdEditController.text,
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: Text('Save'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => controller.removeUser(user.id!),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _myMoneyTab() {
    return Center(
      child: Text('My Money Page', style: TextStyle(fontSize: 24)),
    );
  }
}
