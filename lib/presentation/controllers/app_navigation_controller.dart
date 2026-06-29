import 'package:get/get.dart';

class AppNavigationController extends GetxController {
  final homeTabIndex = 0.obs;
  final pendingCreateBudget = false.obs;

  void navigateToCreateBudget() {
    homeTabIndex.value = 1;
    pendingCreateBudget.value = true;
  }

  void consumeCreateBudgetRequest() {
    pendingCreateBudget.value = false;
  }
}
