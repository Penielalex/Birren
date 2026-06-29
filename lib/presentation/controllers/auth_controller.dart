import 'package:get/get.dart';

import '../../data/service/backup_service.dart';
import '../../data/service/shared_prefs_service.dart';
import '../../app/user_usecases.dart';
import '../../domain/entities/user.dart';
import 'bank_controller.dart';
import 'budget_controller.dart';
import 'transaction_controller.dart';
import 'user_controller.dart';
import 'package:birren/core/app_logger.dart';

class AuthController extends GetxController {
  final SharedPrefsService prefs;
  final GetUsersUseCase getUsers;
  final AddUserUseCase addUser;
  final UpdateUserUseCase updateUser;

  AuthController({
    required this.getUsers,
    required this.addUser,
    required this.updateUser,
    required this.prefs,
  });

  var isLoading = false.obs;
  var loginType = ''.obs;
  var users = <User>[].obs;
  var isUnlocked = false.obs;
  var pinEnabled = false.obs;
  var logger = appLogger;

  Future<void> initAuth() async {
    logger.i('auth controller initialized');
    isLoading.value = true;
    final type = await prefs.getLoginType();
    final id = await prefs.getId();
    loginType.value = type ?? '';
    pinEnabled.value = await prefs.isPinEnabled();

    if (loginType.value.isNotEmpty) {
      users.value = await getUsers.execute();
      if (id == null && users.isNotEmpty) {
        await prefs.setLoginType(
          loginType.value,
          users.first.id.toString(),
        );
      }
      isUnlocked.value = !pinEnabled.value;
    } else {
      isUnlocked.value = true;
    }

    isLoading.value = false;
  }

  Future<void> loginWithName(String name, {String? pin}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Enter your name');
    }

    if (pin != null && pin.isNotEmpty) {
      if (pin.length < 4) {
        throw ArgumentError('PIN must be at least 4 digits');
      }
      await prefs.setPin(pin);
      pinEnabled.value = true;
    }

    try {
      users.value = await getUsers.execute();
      if (users.isEmpty) {
        final now = DateTime.now();
        await addUser.execute(
          User(
            name: trimmed,
            createdAt: now,
            updatedAt: now,
          ),
        );
        users.value = await getUsers.execute();
      } else {
        final existing = users.first;
        await updateUser.execute(
          User(
            id: existing.id,
            name: trimmed,
            email: existing.email,
            googleId: existing.googleId,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
        users.value = await getUsers.execute();
      }
    } finally {
      await prefs.setLoginType('local', users.first.id.toString());
      loginType.value = 'local';
      isUnlocked.value = true;
    }
  }

  Future<void> setPin(String pin) async {
    if (pin.length < 4) {
      throw ArgumentError('PIN must be at least 4 digits');
    }
    await prefs.setPin(pin);
    pinEnabled.value = true;
    isUnlocked.value = true;
  }

  Future<void> removePin(String currentPin) async {
    if (!await prefs.verifyPin(currentPin)) {
      throw StateError('Incorrect PIN');
    }
    await prefs.removePin();
    pinEnabled.value = false;
    isUnlocked.value = true;
  }

  Future<void> changePin(String currentPin, String newPin) async {
    if (!await prefs.verifyPin(currentPin)) {
      throw StateError('Incorrect PIN');
    }
    if (newPin.length < 4) {
      throw ArgumentError('PIN must be at least 4 digits');
    }
    await prefs.setPin(newPin);
    pinEnabled.value = true;
  }

  Future<bool> verifyPin(String pin) => prefs.verifyPin(pin);

  Future<void> unlockWithPin(String pin) async {
    if (await prefs.verifyPin(pin)) {
      isUnlocked.value = true;
    } else {
      throw StateError('Incorrect PIN');
    }
  }

  void lockApp() {
    if (pinEnabled.value) {
      isUnlocked.value = false;
    }
  }

  Future<void> refreshUsers() async {
    users.value = await getUsers.execute();
  }

  Future<void> logout() async {
    final backupService = Get.find<BackupService>();
    await backupService.clearAllLocalData();
    _resetInMemoryState();
  }

  void _resetInMemoryState() {
    loginType.value = '';
    users.value = <User>[];
    pinEnabled.value = false;
    isUnlocked.value = true;

    if (Get.isRegistered<UserController>()) {
      Get.find<UserController>().users.clear();
    }
    if (Get.isRegistered<BankController>()) {
      final bankController = Get.find<BankController>();
      bankController.banks.clear();
      bankController.selectedIndexes.clear();
    }
    if (Get.isRegistered<TransactionController>()) {
      final transactionController = Get.find<TransactionController>();
      transactionController.transactions.clear();
      transactionController.filteredTransactions.clear();
      transactionController.notificationTransaction.clear();
      transactionController.selectedTransactionIds.clear();
      transactionController.banks.clear();
    }
    if (Get.isRegistered<BudgetController>()) {
      final budgetController = Get.find<BudgetController>();
      budgetController.activeBudget.value = null;
      budgetController.budgetHistory.clear();
    }
  }
}
