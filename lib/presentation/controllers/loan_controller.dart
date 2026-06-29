import 'package:get/get.dart';

import '../../app/loan_usecases.dart';
import '../../data/service/shared_prefs_service.dart';
import '../../domain/entities/loan.dart';
import '../../domain/entities/transaction.dart';
import 'transaction_controller.dart';

class LoanController extends GetxController {
  final SharedPrefsService prefs;
  final GetLoansByUserIdUseCase getLoansByUserIdUseCase;
  final GetOpenLoansByUserIdUseCase getOpenLoansByUserIdUseCase;
  final CreateLoanFromDisbursementUseCase createLoanFromDisbursementUseCase;
  final LinkReturnToLoanUseCase linkReturnToLoanUseCase;
  final CloseLoanUseCase closeLoanUseCase;
  final GetReturnTransactionsForLoanUseCase getReturnTransactionsForLoanUseCase;

  LoanController({
    required this.prefs,
    required this.getLoansByUserIdUseCase,
    required this.getOpenLoansByUserIdUseCase,
    required this.createLoanFromDisbursementUseCase,
    required this.linkReturnToLoanUseCase,
    required this.closeLoanUseCase,
    required this.getReturnTransactionsForLoanUseCase,
  });

  final loans = <Loan>[].obs;
  final openLoans = <Loan>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshLoans();
  }

  Future<void> refreshLoans() async {
    final userId = await prefs.getId();
    if (userId == null) return;

    isLoading.value = true;
    try {
      final id = int.parse(userId);
      loans.assignAll(await getLoansByUserIdUseCase.execute(id));
      openLoans.assignAll(await getOpenLoansByUserIdUseCase.execute(id));
    } finally {
      isLoading.value = false;
    }
  }

  double totalRepaidForLoan(Loan loan, List<Transaction> transactions) {
    return transactions
        .where(
          (t) =>
              t.loanId == loan.id &&
              t.type == 'Expense' &&
              t.id != loan.disbursementTransactionId,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double totalReturnedForLoan(Loan loan, List<Transaction> transactions) =>
      totalRepaidForLoan(loan, transactions);

  double remainingBalance(Loan loan, List<Transaction> transactions) {
    final repaid = totalRepaidForLoan(loan, transactions);
    return (loan.principalAmount - repaid).clamp(0, double.infinity);
  }

  List<Transaction> repaymentTransactionsForLoan(
    Loan loan,
    List<Transaction> transactions,
  ) {
    return transactions
        .where(
          (t) =>
              t.loanId == loan.id &&
              t.type == 'Expense' &&
              t.id != loan.disbursementTransactionId,
        )
        .toList()
      ..sort((a, b) => b.dateOf.compareTo(a.dateOf));
  }

  List<Transaction> returnTransactionsForLoan(
    Loan loan,
    List<Transaction> transactions,
  ) =>
      repaymentTransactionsForLoan(loan, transactions);

  Transaction? loanReceiptTransaction(
    Loan loan,
    List<Transaction> transactions,
  ) {
    try {
      return transactions.firstWhere(
        (t) => t.id == loan.disbursementTransactionId,
      );
    } catch (_) {
      return null;
    }
  }

  Transaction? disbursementTransaction(
    Loan loan,
    List<Transaction> transactions,
  ) =>
      loanReceiptTransaction(loan, transactions);

  Future<void> registerLoanFromTransaction(
    Transaction transaction, {
    String? counterpartyName,
  }) async {
    if (transaction.id == null) {
      throw ArgumentError('Transaction must be saved first');
    }
    if (transaction.type != 'Income') {
      throw ArgumentError(
        'Loans are created when you receive borrowed money (income)',
      );
    }

    final userId = await prefs.getId();
    if (userId == null) {
      throw StateError('User not logged in');
    }

    await createLoanFromDisbursementUseCase.execute(
      userId: int.parse(userId),
      transactionId: transaction.id!,
      principalAmount: transaction.amount,
      counterpartyName: counterpartyName?.trim().isEmpty ?? true
          ? null
          : counterpartyName!.trim(),
    );

    final transactionController = Get.find<TransactionController>();
    await transactionController.fetchSavedTransactions();
    await refreshLoans();
  }

  Future<void> linkRepayment(
    Transaction repaymentTransaction,
    Loan loan,
  ) async {
    if (repaymentTransaction.id == null) {
      throw ArgumentError('Repayment transaction must be saved first');
    }
    if (repaymentTransaction.type != 'Expense') {
      throw ArgumentError('Loan repayments must be expense transactions');
    }
    if (!loan.isOpen) {
      throw StateError('Cannot link repayment to a closed loan');
    }

    await linkReturnToLoanUseCase.execute(
      returnTransactionId: repaymentTransaction.id!,
      loanId: loan.id!,
    );

    final transactionController = Get.find<TransactionController>();
    await transactionController.fetchSavedTransactions();
    await refreshLoans();
  }

  Future<void> linkReturn(Transaction returnTransaction, Loan loan) =>
      linkRepayment(returnTransaction, loan);

  Future<void> closeLoanManually({
    required Loan loan,
    required List<Transaction> transactions,
    required int bankId,
    required String category,
    int? budgetLineItemId,
  }) async {
    if (loan.id == null) return;

    final remaining = remainingBalance(loan, transactions);
    await closeLoanUseCase.execute(
      loanId: loan.id!,
      writeOffAmount: remaining,
      bankId: bankId,
      category: category,
      budgetLineItemId: budgetLineItemId,
      dateOf: DateTime.now(),
    );

    final transactionController = Get.find<TransactionController>();
    await transactionController.fetchSavedTransactions();
    await refreshLoans();
  }

  Future<List<Transaction>> fetchReturnTransactions(Loan loan) async {
    if (loan.id == null) return [];
    return getReturnTransactionsForLoanUseCase.execute(loan.id!);
  }
}
