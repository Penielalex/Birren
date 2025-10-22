import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/bank_usecases.dart';
import '../../data/service/shared_prefs_service.dart';
import '../../domain/entities/bank.dart';
import '../widgets/app_snackbar.dart';


class BankController extends GetxController {
  final SharedPrefsService prefs;
  final GetBanksUseCase getBanksUseCase;
  final GetBanksByUserUseCase getBanksByUserUseCase;
  final AddBankUseCase addBankUseCase;
  final UpdateBankUseCase updateBankUseCase;
  final DeleteBankUseCase deleteBankUseCase;

  BankController({
    required this.getBanksUseCase,
    required this.getBanksByUserUseCase,
    required this.addBankUseCase,
    required this.updateBankUseCase,
    required this.deleteBankUseCase,
    required this.prefs
  });

  var banks = <Bank>[].obs;
  var isLoading = false.obs;
  var logger = Logger();

  @override
  void onInit() {
    super.onInit();
    logger.i("bank controller initialized");
    fetchBanks();
  }

  Future<void> fetchBanks() async {
    try {
      isLoading.value = true;
      final result = await getBanksUseCase.execute();
      logger.i("$result");
      banks.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchBanksByUser(int userId) async {
    try {
      isLoading.value = true;
      final result = await getBanksByUserUseCase.execute(userId);
      banks.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addBank(String bankName, String displayName) async {
    final id = await prefs.getId();
    logger.i("${int.parse(id!)}");
    final now = DateTime.now();
    final bank = Bank(
      userId: int.parse(id!),
      bankName: bankName,
      displayName: displayName,
      balance: 500,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await addBankUseCase.execute(bank);
    }catch(e){
      AppSnackbar.showError(e.toString());
    }
    await fetchBanks();
  }

  Future<void> editBank(Bank bank) async {
    await updateBankUseCase.execute(bank);
    await fetchBanks();
  }

  Future<void> removeBank(int id) async {
    await deleteBankUseCase.execute(id);
    await fetchBanks();
  }
}
