import 'package:birren/data/service/sms_service.dart';
import 'package:birren/presentation/controllers/bank_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:birren/core/app_logger.dart';
import '../../app/bank_usecases.dart';
import '../../app/transaction_usecases.dart';
import '../../data/models/sms_message_model.dart';
import '../../data/service/budget_widget_service.dart';
import '../../data/service/shared_prefs_service.dart';
import '../../domain/entities/bank.dart';
import '../../domain/entities/transaction.dart';
import '../util/category.dart';
import '../util/cash_bank.dart';
import 'budget_controller.dart';


class TransactionController extends GetxController {
  final SharedPrefsService prefs;
  final GetAllTransactionsUseCase getAllTransactionsUseCase;
  final GetTransactionsByBankIdUseCase getTransactionsByBankIdUseCase;
  final CreateTransactionUseCase createTransactionUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final LinkInternalTransferUseCase linkInternalTransferUseCase;
  final LinkInternalTransferToCashUseCase linkInternalTransferToCashUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;
  final GetBanksUseCase getBanksUseCase;
  final SmsService smsService;
  final UpdateBankUseCase updateBankUseCase;

  TransactionController({
    required this.getAllTransactionsUseCase,
    required this.getTransactionsByBankIdUseCase,
    required this.createTransactionUseCase,
    required this.updateTransactionUseCase,
    required this.linkInternalTransferUseCase,
    required this.linkInternalTransferToCashUseCase,
    required this.deleteTransactionUseCase,
    required this.getBanksUseCase,
    required this.prefs,
    required this.smsService,
    required this.updateBankUseCase,
  });

  var transactions = <Transaction>[].obs;
  var filteredTransactions = <Transaction>[].obs;
  var notificationTransaction = <Transaction>[].obs;
  var isLoading = false.obs;
  var logger = appLogger;
  var banks = <Bank>[].obs;
  var controller = Get.find<BankController>();
  var selectedTransactionIds = <int>[].obs;





  void toggleSelection(int? id) {
    if(id != null){
    if (selectedTransactionIds.contains(id)) {
      selectedTransactionIds.remove(id);
    } else {
      selectedTransactionIds.add(id);
    }}
  }

  void clearSelection() {
    selectedTransactionIds.clear();
  }


  @override
  void onInit() {
    super.onInit();

    fetchMessageTransactions();
  }




  Future<void> fetchSavedTransactions() async {
    logger.i("uuuu");
    // 1️⃣ Fetch all saved transactions
    final result = await getAllTransactionsUseCase.execute();
    logger.i('Loaded ${result.length} saved transaction(s)');
    if(result.isNotEmpty){
    result.sort((a, b) => b.dateOf.compareTo(a.dateOf));
    transactions.assignAll(result);

    // 2️⃣ Define today’s start and end
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final start = DateTime(now.year, now.month, 1);

    // 3️⃣ Filter transactions for today
    await filterTransactionsByDateRange(start, now);
    await getTransactionsWithNoCat();}else{
      transactions.clear();
      filteredTransactions.clear();
      notificationTransaction.clear();

      logger.i("No saved transactions. Cleared all lists.");
    }
    await BudgetWidgetService.syncFromControllers();
  }

  Future<void> filterTransactionsByDateRange(DateTime startDate, DateTime endDate) async {
    // Prevent filtering before transactions are loaded
    if (transactions.isEmpty) return;

    final filtered = transactions.where((t) {
      final date = t.dateOf;
      return date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          date.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();
    filtered.sort((a, b) => b.dateOf.compareTo(a.dateOf));
    filteredTransactions.assignAll(filtered);
  }

  Future<void> getTransactionsWithNoCat() async {
    // Prevent filtering before transactions are loaded
    if (transactions.isEmpty) return;

    final cashBankIds = controller.banks
        .where((b) => isCashBankName(b.bankName))
        .map((b) => b.id)
        .whereType<int>()
        .toSet();

    final filtered = transactions.where((t) {
      if (!transactionHasNoCategory(t.category)) return false;
      if (cashBankIds.contains(t.bankId)) return false;
      return true;
    }).toList();
    logger.i("$filtered");
    filtered.sort((a, b) => b.dateOf.compareTo(a.dateOf));
    notificationTransaction.assignAll(filtered);
  }

  Future<void> fetchMessageTransactions() async {
    //await prefs.setLastFetch("MPESA", DateTime(2025,10,30));

    isLoading.value = true;
    try {

      final result = await getBanksUseCase.execute();
      banks.assignAll(result);
     if(banks.isEmpty){
       logger.i("No banks found");
     }else{
       for(var bank in banks){
         if (isCashBankName(bank.bankName)) continue;

         var lastFetch = await prefs.getLastFetch(bank.bankName);

         if (lastFetch == null) {
           final saved = await getTransactionsByBankIdUseCase.execute(bank.id!);
           if (saved.isEmpty) {
             logger.i(
               'No sync checkpoint for ${bank.bankName}; skipping refresh '
               '(initial import happens when you add the bank)',
             );
             continue;
           }
           saved.sort((a, b) => b.dateOf.compareTo(a.dateOf));
           lastFetch = saved.first.dateOf;
           logger.i(
             'Recovered sync checkpoint for ${bank.bankName} from newest '
             'saved transaction: $lastFetch',
           );
         }

         final result = await smsService.fetchTransactionsForBank(
           address: bank.bankName,
           fromDate: lastFetch,
           exclusiveStart: true,
         );

         if(result.isNotEmpty){
           logger.i("this is last result ${result.first["balanceAmount"]}");
           for(var transaction in result){
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
               bankId: bank.id!,
               type:type,
               category: noCategory,
               amount: transaction['firstAmount'],
               dateOf: transaction['date'],
               createdAt: DateTime.now(),
               updatedAt: DateTime.now()

             );
             addTransaction(tran);
           }
           logger.i("hello ${result.first["balanceAmount"]} ${bank.balance}");
           if (result.first["balanceAmount"] != bank.balance){

             var banking =Bank(id:bank.id,userId: bank.userId, bankName: bank.bankName, balance: result.first["balanceAmount"] , createdAt: bank.createdAt, updatedAt: DateTime.now());
             controller.editBank(banking);

           }

           await prefs.setLastFetch(bank.bankName, DateTime.now());
         } else {
           await prefs.setLastFetch(bank.bankName, DateTime.now());
         }
       }
     }
    } finally {
      await Future.delayed(const Duration(seconds: 3));

      isLoading.value = false;
      await fetchSavedTransactions();
    }
  }


  Future<void> addTransaction(Transaction transaction) async {
    await createTransactionUseCase.execute(transaction);
  }

  Future<void> addManualCashTransaction({
    required Bank bank,
    required String type,
    required double amount,
    required DateTime dateOf,
    required String categoryIndex,
    int? budgetLineItemId,
  }) async {
    if (!isCashBankName(bank.bankName)) {
      throw ArgumentError('Manual entries are only supported for Cash');
    }
    if (bank.id == null) {
      throw StateError('Cash account is not saved yet');
    }
    if (type != 'Income' && type != 'Expense') {
      throw ArgumentError('Type must be Income or Expense');
    }

    await createTransactionUseCase.execute(
      Transaction(
        bankId: bank.id!,
        type: type,
        category: categoryIndex,
        amount: amount,
        dateOf: dateOf,
        budgetLineItemId: budgetLineItemId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final delta = type == 'Income' ? amount : -amount;
    await updateBankUseCase.execute(
      Bank(
        id: bank.id,
        userId: bank.userId,
        bankName: bank.bankName,
        displayName: bank.displayName,
        balance: bank.balance + delta,
        createdAt: bank.createdAt,
        updatedAt: DateTime.now(),
      ),
    );

    await controller.fetchBanks();
    await fetchSavedTransactions();
  }

  Future<void> editTransaction(
    int id,
    int? bankId,
    String? category,
    String? type,
    double? amount,
    DateTime? dateOf, {
    int? transferId,
    int? budgetLineItemId,
    bool clearBudgetLineItemId = false,
    int? loanId,
    bool clearLoanId = false,
  }) async {
    await updateTransactionUseCase.execute(
      id,
      bankId,
      category,
      type,
      amount,
      dateOf,
      transferId: transferId,
      budgetLineItemId: budgetLineItemId,
      clearBudgetLineItemId: clearBudgetLineItemId,
      loanId: loanId,
      clearLoanId: clearLoanId,
    );
    await fetchSavedTransactions();
  }

  Future<void> removeTransaction(int id) async {
    await deleteTransactionUseCase.execute(id);
    await fetchSavedTransactions();
  }

  /// Transactions on the same day as [primary], opposite type, not yet linked.
  List<Transaction> getSameDayPairCandidates(Transaction primary) {
    final day = DateTime(
      primary.dateOf.year,
      primary.dateOf.month,
      primary.dateOf.day,
    );
    final oppositeType = primary.type == 'Expense' ? 'Income' : 'Expense';

    return transactions.where((t) {
      if (t.id == primary.id) return false;
      if (t.type != oppositeType) return false;
      if (t.transferId != null) return false;
      if (t.loanId != null) return false;
      if (isInternalTransferCategory(t.category, t.type)) return false;
      final tDay = DateTime(t.dateOf.year, t.dateOf.month, t.dateOf.day);
      return tDay == day;
    }).toList()
      ..sort((a, b) => b.dateOf.compareTo(a.dateOf));
  }

  Future<void> linkInternalTransfer(
    Transaction primary,
    Transaction counterpart,
  ) async {
    if (primary.type == counterpart.type) {
      throw ArgumentError(
        'Internal transfer requires one income and one expense transaction',
      );
    }

    final expense = primary.type == 'Expense' ? primary : counterpart;
    final income = primary.type == 'Income' ? primary : counterpart;
    final matchedAmount = expense.amount < income.amount
        ? expense.amount
        : income.amount;
    final feeAmount = (expense.amount - income.amount).abs();
    final budgetController = Get.find<BudgetController>();
    final feeBudgetLineItemId =
        budgetController.transferFeeLineItemIdForDate(expense.dateOf);

    await linkInternalTransferUseCase.execute(
      expenseId: expense.id!,
      incomeId: income.id!,
      matchedAmount: matchedAmount,
      feeAmount: feeAmount,
      feeBankId: expense.bankId,
      dateOf: expense.dateOf,
      feeBudgetLineItemId: feeBudgetLineItemId,
    );

    clearSelection();
    await fetchSavedTransactions();
  }

  Future<void> linkInternalTransferToCash(
    Transaction primary,
    Bank cashBank,
  ) async {
    if (cashBank.id == null || primary.id == null) {
      throw StateError('Invalid cash or transaction');
    }
    if (!isCashBankName(cashBank.bankName)) {
      throw ArgumentError('Target must be the Cash account');
    }

    await linkInternalTransferToCashUseCase.execute(
      primaryId: primary.id!,
      primaryType: primary.type,
      cashBankId: cashBank.id!,
      amount: primary.amount,
      dateOf: primary.dateOf,
    );

    final cashDelta =
        primary.type == 'Expense' ? primary.amount : -primary.amount;
    await updateBankUseCase.execute(
      Bank(
        id: cashBank.id,
        userId: cashBank.userId,
        bankName: cashBank.bankName,
        displayName: cashBank.displayName,
        balance: cashBank.balance + cashDelta,
        createdAt: cashBank.createdAt,
        updatedAt: DateTime.now(),
      ),
    );

    clearSelection();
    await controller.fetchBanks();
    await fetchSavedTransactions();
  }

  Future<SmsMessageModel?> findSmsForTransaction(Transaction transaction) async {
    Bank? bank;
    for (final b in banks) {
      if (b.id == transaction.bankId) {
        bank = b;
        break;
      }
    }
    if (bank == null) {
      for (final b in controller.banks) {
        if (b.id == transaction.bankId) {
          bank = b;
          break;
        }
      }
    }
    if (bank == null) {
      logger.w('Bank not found for transaction ${transaction.id}');
      return null;
    }

    return smsService.findSmsForTransaction(
      bankAddress: bank.bankName,
      dateOf: transaction.dateOf,
      amount: transaction.amount,
      type: transaction.type,
    );
  }

  Transaction? findLinkedTransaction(Transaction transaction) {
    if (transaction.transferId == null) return null;
    try {
      return transactions.firstWhere((t) => t.id == transaction.transferId);
    } catch (_) {
      return null;
    }
  }


  /// Generates monthly indicators for the calendar.
  /// Only considers 'Expense' transactions.
  /// dailyLimit: limit per day to determine red/green
  Map<DateTime, Color> getMonthlyIndicators({
    required double dailyLimit,
    required DateTime month,
    DateTime? periodStart,
    DateTime? periodEnd,
    Set<int>? budgetLineItemIds,
  }) {
    Map<DateTime, double> dailySums = {};

    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    for (var t in transactions) {
      if (t.type != 'Expense') continue;
      if (!countsTransactionInIncomeExpenseSummary(
        t.category,
        t.type,
        loanId: t.loanId,
      )) {
        continue;
      }
      if (budgetLineItemIds != null) {
        if (t.budgetLineItemId == null ||
            !budgetLineItemIds.contains(t.budgetLineItemId)) {
          continue;
        }
      }

      final tDayStart = DateTime(t.dateOf.year, t.dateOf.month, t.dateOf.day);

      if (tDayStart.isBefore(firstDayOfMonth) ||
          tDayStart.isAfter(lastDayOfMonth)) {
        continue;
      }

      if (periodStart != null && periodEnd != null) {
        if (tDayStart.isBefore(periodStart) || tDayStart.isAfter(periodEnd)) {
          continue;
        }
      }

      dailySums[tDayStart] = (dailySums[tDayStart] ?? 0) + t.amount;
    }

    Map<DateTime, Color> indicators = {};
    dailySums.forEach((day, sum) {
      if (dailyLimit <= 0) return;
      indicators[day] = sum > dailyLimit ? Colors.red : Colors.green;
    });

    return indicators;
  }

  Map<int, Color> getYearlyIndicators({
    required int year,
    DateTime? periodStart,
    DateTime? periodEnd,
    Set<int>? budgetLineItemIds,
    required double Function(int year, int month) monthlyLimitFor,
  }) {
    Map<int, double> monthlySums = {};

    for (var t in transactions) {
      if (t.type != 'Expense') continue;
      if (!countsTransactionInIncomeExpenseSummary(
        t.category,
        t.type,
        loanId: t.loanId,
      )) {
        continue;
      }
      if (budgetLineItemIds != null) {
        if (t.budgetLineItemId == null ||
            !budgetLineItemIds.contains(t.budgetLineItemId)) {
          continue;
        }
      }
      if (t.dateOf.year != year) continue;

      final tDayStart = DateTime(t.dateOf.year, t.dateOf.month, t.dateOf.day);
      if (periodStart != null && periodEnd != null) {
        if (tDayStart.isBefore(periodStart) || tDayStart.isAfter(periodEnd)) {
          continue;
        }
      }

      final month = t.dateOf.month;
      monthlySums[month] = (monthlySums[month] ?? 0) + t.amount;
    }

    Map<int, Color> indicators = {};
    monthlySums.forEach((month, sum) {
      final limit = monthlyLimitFor(year, month);
      if (limit <= 0) return;
      indicators[month] = sum > limit ? Colors.red : Colors.green;
    });

    return indicators;
  }
}
