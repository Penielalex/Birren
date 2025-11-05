import 'package:birren/data/service/sms_service.dart';
import 'package:birren/presentation/controllers/bank_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import '../../app/bank_usecases.dart';
import '../../app/transaction_usecases.dart';
import '../../data/service/shared_prefs_service.dart';
import '../../domain/entities/bank.dart';
import '../../domain/entities/transaction.dart';


class TransactionController extends GetxController {
  final SharedPrefsService prefs;
  final GetAllTransactionsUseCase getAllTransactionsUseCase;
  final CreateTransactionUseCase createTransactionUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;
  final GetBanksUseCase getBanksUseCase;
  final SmsService smsService;
  final UpdateBankUseCase updateBankUseCase;

  TransactionController({
    required this.getAllTransactionsUseCase,
    required this.createTransactionUseCase,
    required this.updateTransactionUseCase,
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
  var logger = Logger();
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
    logger.i(result);
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

    final filtered = transactions.where((t) {
      final date = t.category;
      return date == "17" || date == "5";
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
         final fromDate = await prefs.getFromDate(bank.bankName);
         final result = await smsService.fetchTransactionsForBank(address: bank.bankName, fromDate: fromDate);
         if(result.isNotEmpty){
           logger.i("this is last result ${result.first["balanceAmount"]}");
           for(var transaction in result){
             var type;
             if(transaction['transactionType']=="credited" || transaction['transactionType']=="received" ){
               type ="Income";
             }else{type="Expense";}
             final tran = Transaction(
               bankId: bank.id!,
               type:type,
               category: type == "Income"?"5":"17",
               amount: transaction['firstAmount'],
               dateOf: transaction['date'],
               createdAt: DateTime.now(),
               updatedAt: DateTime.now()

             );
             addTransaction(tran);
           }
           logger.i("hello ${result.first["balanceAmount"]} ${bank.balance}");
           if(result.first["balanceAmount"] != bank.balance){

             var banking =Bank(id:bank.id,userId: bank.userId, bankName: bank.bankName, balance: result.first["balanceAmount"] , createdAt: bank.createdAt, updatedAt: DateTime.now());
             controller.editBank(banking);

           }

         }
         await prefs.setLastFetch(bank.bankName, DateTime.now());

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

  Future<void> editTransaction(int id,
      int? bankId,
      String? category,
      String? type,
      double? amount,
      DateTime? dateOf,) async {
    await updateTransactionUseCase.execute(id,bankId,category,type,amount,dateOf);
    await fetchSavedTransactions();
  }

  Future<void> removeTransaction(int id) async {
    await deleteTransactionUseCase.execute(id);
    await fetchSavedTransactions();
  }
}
