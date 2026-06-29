import 'package:birren/app/transaction_usecases.dart';
import 'package:birren/data/service/bank_sms_log_service.dart';
import 'package:birren/data/service/sms_service.dart';
import 'package:birren/presentation/controllers/transaction_controller.dart';
import 'package:get/get.dart';
import 'package:birren/core/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/bank_usecases.dart';
import '../../data/service/shared_prefs_service.dart';
import '../../domain/entities/bank.dart';
import '../../domain/entities/transaction.dart';
import '../util/category.dart';
import '../util/cash_bank.dart';
import '../widgets/app_snackbar.dart';


class BankController extends GetxController {
  final SharedPrefsService prefs;
  final SmsService smsService;
  final BankSmsLogService bankSmsLogService;
  final GetBanksUseCase getBanksUseCase;
  final GetBanksByUserUseCase getBanksByUserUseCase;
  final AddBankUseCase addBankUseCase;
  final UpdateBankUseCase updateBankUseCase;
  final DeleteBankUseCase deleteBankUseCase;
  final CreateTransactionUseCase createTransactionUseCase;
  final DeleteTransactionWithBankIdUseCase deleteTransactionWithBankIdUseCase;

  BankController( {
    required this.smsService,
    required this.bankSmsLogService,
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



  var logger = appLogger;

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
      if (result.isNotEmpty) {
        banks.assignAll(result);
        _ensureDefaultSelection(result.length);
      } else {
        banks.clear();
        selectedIndexes.clear();
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
      _ensureDefaultSelection(result.length);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addBank(
    String bankName,
    String? displayName,
    DateTime importFromDate, {
    double initialBalance = 0,
  }) async {
    if (isCashBankName(bankName)) {
      final id = await prefs.getId();
      if (id == null) {
        AppSnackbar.showError('User not logged in');
        return;
      }

      final now = DateTime.now();
      final bank = Bank(
        userId: int.parse(id),
        bankName: bankName,
        displayName: displayName,
        balance: initialBalance,
        createdAt: now,
        updatedAt: now,
      );

      try {
        await addBankUseCase.execute(bank);
        await fetchBanks();
      } catch (e) {
        logger.e('Failed to add cash account: $e');
        AppSnackbar.showError(e.toString());
      }
      return;
    }

    isAddingBank.value = true;
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
        final logPath = await bankSmsLogService.exportBankSmsToMarkdown(
          bankName: bankName,
        );
        if (logPath != null) {
          logger.i('Bank SMS log file: $logPath');
        }

        await addBankUseCase.execute(bank);
        await fetchBanks();
        final newBank = banks.firstWhere(
              (b) => b.bankName == bankName,
          orElse: () => throw Exception("Newly added bank not found"),
        );


        final fromDate = DateTime(
          importFromDate.year,
          importFromDate.month,
          importFromDate.day,
        );
        final result = await smsService.fetchTransactionsForBank(
          address: newBank.bankName,
          fromDate: fromDate,
        );
        if (result.isNotEmpty) {
          for (var transaction in result) {
            final rawType = transaction['transactionType'] as String?;
            if (rawType == 'unknown') continue;
            final String type;
            if (rawType == 'income') {
              type = 'Income';
            } else if (rawType == 'withdrawal') {
              type = 'Expense';
            } else {
              continue;
            }
            final tran = Transaction(
                bankId: newBank.id!,
                type: type,
                category: noCategory,
                amount: transaction['firstAmount'],
                dateOf: transaction['date'],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now()

            );
            await createTransactionUseCase.execute(tran);
          }
          final newestDate = result.first['date'] as DateTime;
          await prefs.setLastFetch(newBank.bankName, newestDate);
          logger.i(
            'Saved last transaction date for ${newBank.bankName}: $newestDate',
          );
        } else {
          await prefs.setLastFetch(newBank.bankName, fromDate);
          logger.i(
            'No actionable SMS from $fromDate for ${newBank.bankName}; '
            'checkpoint set for incremental sync',
          );
        }
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

  void _ensureDefaultSelection(int bankCount) {
    if (bankCount == 0) {
      selectedIndexes.clear();
      return;
    }
    if (selectedIndexes.isEmpty) {
      selectedIndexes.addAll(List.generate(bankCount, (index) => index));
    }
  }
}
