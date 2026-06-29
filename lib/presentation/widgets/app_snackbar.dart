import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  static void showError(String message) {
    _show(
      title: 'Error',
      message: message,
      backgroundColor: Colors.red.withOpacity(0.9),
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  static void showSuccess(String message) {
    _show(
      title: 'Success',
      message: message,
      backgroundColor: Colors.green.withOpacity(0.9),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }

  static void showInfo(String message) {
    _show(
      title: 'Info',
      message: message,
      backgroundColor: Colors.blue.withOpacity(0.9),
      icon: const Icon(Icons.info_outline, color: Colors.white),
    );
  }

  static void _show({
    required String title,
    required String message,
    required Color backgroundColor,
    required Icon icon,
  }) {
    if (Get.overlayContext == null && Get.context == null) return;

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      icon: icon,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }
}
