import 'package:birren/app/transaction_usecases.dart';
import 'package:birren/data/service/sms_service.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/bank_usecases.dart';
import '../../data/service/shared_prefs_service.dart';
import '../../domain/entities/bank.dart';
import '../../domain/entities/transaction.dart';
import '../widgets/app_snackbar.dart';


class BankController extends GetxController {
  final SharedPrefsService prefs;
  final SmsService smsService;
  final GetBanksUseCase getBanksUseCase;
  final GetBanksByUserUseCase getBanksByUserUseCase;
  final AddBankUseCase addBankUseCase;
  final UpdateBankUseCase updateBankUseCase;
  final DeleteBankUseCase deleteBankUseCase;
  final CreateTransactionUseCase createTransactionUseCase;
  final DeleteTransactionWithBankIdUseCase deleteTransactionWithBankIdUseCase;

  BankController( {
    required this.smsService,
    required this.getBanksUseCase,
    required this.getBanksByUserUseCase,
    required this.addBankUseCase,
    required this.updateBankUseCase,
    required this.deleteBankUseCase,
    required this.prefs,
    required this.createTransactionUseCase,
    required this.deleteTransactionWithBankIdUseCase,
  });

  var banks = <Bank>[].obs;
  var isLoading = false.obs;
  var isAddingBank = false.obs;

  final RxSet<int> selectedIndexes = <int>{}.obs;



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
      if(result.isNotEmpty){
      banks.assignAll(result);}else{
        banks.clear();
      }
    } finally {
      //await Future.delayed(const Duration(milliseconds: 500));
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

  Future<void> addBank(String bankName, String? displayName) async {
    isAddingBank.value  = true;
    final id = await prefs.getId();
    logger.i("${int.parse(id!)}");
    final amount = await smsService.fetchLastAmount(sender: bankName);
    if(amount != null) {
      logger.i("${amount == null}");
      final now = DateTime.now();
      final bank = Bank(
        userId: int.parse(id!),
        bankName: bankName,
        displayName: displayName,
        balance: amount["balanceAmount"],
        createdAt: now,
        updatedAt: now,
      );
      try {
        await addBankUseCase.execute(bank);
        await fetchBanks();
        final newBank = banks.firstWhere(
              (b) => b.bankName == bankName,
          orElse: () => throw Exception("Newly added bank not found"),
        );


        final fromDate = DateTime.now().subtract(const Duration(days: 3));

        final result = await smsService.fetchTransactionsForBank(
            address: newBank.bankName, fromDate: fromDate);
        if (result.isNotEmpty) {
          for (var transaction in result) {
            var type;
            if (transaction['transactionType'] == "credited" ||
                transaction['transactionType'] == "received") {
              type = "Income";
            } else {
              type = "Expense";
            }
            final tran = Transaction(
                bankId: newBank.id!,
                type: type,
                category: type == "Income" ? "5" : "17",
                amount: transaction['firstAmount'],
                dateOf: transaction['date'],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now()

            );
            await createTransactionUseCase.execute(tran);
          }
        }
        await prefs.setLastFetch(bank.bankName, DateTime.now());
        await Future.delayed(const Duration(seconds: 3));
        isAddingBank.value = false;
      } catch (e) {
        logger.e("ereeee uuuu $e");
        AppSnackbar.showError(e.toString());
        await Future.delayed(const Duration(seconds: 3));
        isAddingBank.value = false;
      }

    }else{
      isAddingBank.value = false;
      AppSnackbar.showError("Bank not found in messages");
    }

  }

  Future<void> editBank(Bank bank) async {
    await updateBankUseCase.execute(bank);
    await fetchBanks();
  }

  Future<DateTime?> getLatestLastFetchDate() async {
    DateTime? latestDate;

    for (var bank in banks) {
      final date = await prefs.getLastFetch(bank.bankName);

      if (date != null) {
        // First valid date → set it
        if (latestDate == null) {
          latestDate = date;
        }
        // Compare & update latest
        else if (date.isAfter(latestDate)) {
          latestDate = date;
        }
      }
    }

    return latestDate; // can be null if no banks have a lastFetch
  }


  Future<void> removeBank(int id) async {
    final bank = banks.firstWhere(
          (b) => b.id == id,
      orElse: () => throw Exception("Bank not found"),
    );

    if (bank.bankName != null) {
      await prefs.removeLastFetch(bank.bankName);
    }

    await deleteBankUseCase.execute(id);
    await deleteTransactionWithBankIdUseCase.execute(id);

    await fetchBanks();

    selectedIndexes.clear();

    selectedIndexes.addAll(List.generate(banks.length, (index) => index));
  }
}
