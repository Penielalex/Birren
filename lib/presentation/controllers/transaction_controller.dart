import 'package:get/get.dart';
import '../../app/transaction_usecases.dart';
import '../../domain/entities/transaction.dart';


class TransactionController extends GetxController {
  final GetAllTransactionsUseCase getAllTransactionsUseCase;
  final CreateTransactionUseCase createTransactionUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;

  TransactionController({
    required this.getAllTransactionsUseCase,
    required this.createTransactionUseCase,
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
  });

  var transactions = <Transaction>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      isLoading.value = true;
      final result = await getAllTransactionsUseCase.execute();
      transactions.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    await createTransactionUseCase.execute(transaction);
    await fetchTransactions();
  }

  Future<void> editTransaction(Transaction transaction) async {
    await updateTransactionUseCase.execute(transaction);
    await fetchTransactions();
  }

  Future<void> removeTransaction(int id) async {
    await deleteTransactionUseCase.execute(id);
    await fetchTransactions();
  }
}
