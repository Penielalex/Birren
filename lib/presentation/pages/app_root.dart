import 'dart:async';
import 'dart:io';

import 'package:birren/presentation/controllers/app_navigation_controller.dart';
import 'package:birren/presentation/controllers/auth_controller.dart';
import 'package:birren/presentation/pages/home_page.dart';
import 'package:birren/presentation/pages/login_page.dart';
import 'package:birren/presentation/pages/pin_lock_page.dart';
import 'package:birren/presentation/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  final AuthController authController = Get.find<AuthController>();
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initWidgetLaunchHandling();
  }

  Future<void> _initWidgetLaunchHandling() async {
    if (!Platform.isAndroid) return;

    final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    _handleWidgetUri(initialUri);

    _widgetClickSubscription =
        HomeWidget.widgetClicked.listen(_handleWidgetUri);
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri?.host != 'add-budget') return;
    if (!Get.isRegistered<AppNavigationController>()) return;
    Get.find<AppNavigationController>().navigateToCreateBudget();
  }

  @override
  void dispose() {
    _widgetClickSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      authController.lockApp();
      if (Platform.isAndroid) {
        HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (authController.isLoading.value) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (authController.loginType.value.isEmpty) {
        return const LoginPage();
      }

      if (authController.pinEnabled.value && !authController.isUnlocked.value) {
        return const PinLockPage();
      }

      return HomePage();
    });
  }
}
