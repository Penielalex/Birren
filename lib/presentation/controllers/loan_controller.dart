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
  final CreateLoanFromLendUseCase createLoanFromLendUseCase;
  final LinkRepaymentToLoanUseCase linkRepaymentToLoanUseCase;
  final LinkReturnToLentLoanUseCase linkReturnToLentLoanUseCase;
  final CloseLoanUseCase closeLoanUseCase;
  final GetReturnTransactionsForLoanUseCase getReturnTransactionsForLoanUseCase;

  LoanController({
    required this.prefs,
    required this.getLoansByUserIdUseCase,
    required this.getOpenLoansByUserIdUseCase,
    required this.createLoanFromDisbursementUseCase,
    required this.createLoanFromLendUseCase,
    required this.linkRepaymentToLoanUseCase,
    required this.linkReturnToLentLoanUseCase,
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

  bool isLentLoan(Loan loan, List<Transaction> transactions) {
    final disbursement = disbursementTransaction(loan, transactions);
    return disbursement?.type == 'Expense';
  }

  bool isBorrowedLoan(Loan loan, List<Transaction> transactions) {
    final disbursement = disbursementTransaction(loan, transactions);
    return disbursement?.type == 'Income';
  }

  List<Loan> openLentLoans(List<Transaction> transactions) =>
      openLoans
          .where((loan) => isLentLoan(loan, transactions))
          .toList();

  List<Loan> openBorrowedLoans(List<Transaction> transactions) =>
      openLoans
          .where((loan) => isBorrowedLoan(loan, transactions))
          .toList();

  double totalPaidDownForLoan(Loan loan, List<Transaction> transactions) {
    final linkedType = isLentLoan(loan, transactions) ? 'Income' : 'Expense';
    return transactions
        .where(
          (t) =>
              t.loanId == loan.id &&
              t.type == linkedType &&
              t.id != loan.disbursementTransactionId,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double totalRepaidForLoan(Loan loan, List<Transaction> transactions) =>
      totalPaidDownForLoan(loan, transactions);

  double totalReturnedForLoan(Loan loan, List<Transaction> transactions) =>
      totalPaidDownForLoan(loan, transactions);

  double remainingBalance(Loan loan, List<Transaction> transactions) {
    final paidDown = totalPaidDownForLoan(loan, transactions);
    return (loan.principalAmount - paidDown).clamp(0, double.infinity);
  }

  List<Transaction> linkedPaymentsForLoan(
    Loan loan,
    List<Transaction> transactions,
  ) {
    final linkedType = isLentLoan(loan, transactions) ? 'Income' : 'Expense';
    return transactions
        .where(
          (t) =>
              t.loanId == loan.id &&
              t.type == linkedType &&
              t.id != loan.disbursementTransactionId,
        )
        .toList()
      ..sort((a, b) => b.dateOf.compareTo(a.dateOf));
  }

  List<Transaction> repaymentTransactionsForLoan(
    Loan loan,
    List<Transaction> transactions,
  ) =>
      linkedPaymentsForLoan(loan, transactions);

  List<Transaction> returnTransactionsForLoan(
    Loan loan,
    List<Transaction> transactions,
  ) =>
      linkedPaymentsForLoan(loan, transactions);

  Transaction? disbursementTransaction(
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

  Transaction? loanReceiptTransaction(
    Loan loan,
    List<Transaction> transactions,
  ) =>
      disbursementTransaction(loan, transactions);

  /// Incoming money you borrowed from outside.
  Future<void> registerBorrowedLoanFromTransaction(
    Transaction transaction, {
    String? counterpartyName,
  }) async {
    if (transaction.id == null) {
      throw ArgumentError('Transaction must be saved first');
    }
    if (transaction.type != 'Income') {
      throw ArgumentError(
        'Borrowed loans are created from incoming (income) transactions',
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

    await _refreshAfterLoanChange();
  }

  /// Outgoing money you lent to someone.
  Future<void> registerLentLoanFromTransaction(
    Transaction transaction, {
    String? counterpartyName,
  }) async {
    if (transaction.id == null) {
      throw ArgumentError('Transaction must be saved first');
    }
    if (transaction.type != 'Expense') {
      throw ArgumentError(
        'Lent loans are created from outgoing (expense) transactions',
      );
    }

    final userId = await prefs.getId();
    if (userId == null) {
      throw StateError('User not logged in');
    }

    await createLoanFromLendUseCase.execute(
      userId: int.parse(userId),
      transactionId: transaction.id!,
      principalAmount: transaction.amount,
      counterpartyName: counterpartyName?.trim().isEmpty ?? true
          ? null
          : counterpartyName!.trim(),
    );

    await _refreshAfterLoanChange();
  }

  @Deprecated('Use registerBorrowedLoanFromTransaction')
  Future<void> registerLoanFromTransaction(
    Transaction transaction, {
    String? counterpartyName,
  }) =>
      registerBorrowedLoanFromTransaction(
        transaction,
        counterpartyName: counterpartyName,
      );

  Future<void> linkRepayment(
    Transaction repaymentTransaction,
    Loan loan,
    List<Transaction> transactions,
  ) async {
    if (repaymentTransaction.id == null) {
      throw ArgumentError('Repayment transaction must be saved first');
    }
    if (repaymentTransaction.type != 'Expense') {
      throw ArgumentError('Loan repayments must be expense transactions');
    }
    if (!isBorrowedLoan(loan, transactions)) {
      throw StateError('Repayments link to borrowed loans only');
    }
    if (!loan.isOpen) {
      throw StateError('Cannot link repayment to a closed loan');
    }

    await linkRepaymentToLoanUseCase.execute(
      repaymentTransactionId: repaymentTransaction.id!,
      loanId: loan.id!,
    );

    await _refreshAfterLoanChange();
  }

  Future<void> linkReturn(
    Transaction returnTransaction,
    Loan loan,
    List<Transaction> transactions,
  ) async {
    if (returnTransaction.id == null) {
      throw ArgumentError('Return transaction must be saved first');
    }
    if (returnTransaction.type != 'Income') {
      throw ArgumentError('Loan returns must be income transactions');
    }
    if (!isLentLoan(loan, transactions)) {
      throw StateError('Returns link to lent loans only');
    }
    if (!loan.isOpen) {
      throw StateError('Cannot link return to a closed loan');
    }

    await linkReturnToLentLoanUseCase.execute(
      returnTransactionId: returnTransaction.id!,
      loanId: loan.id!,
    );

    await _refreshAfterLoanChange();
  }

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

    await _refreshAfterLoanChange();
  }

  Future<List<Transaction>> fetchReturnTransactions(Loan loan) async {
    if (loan.id == null) return [];
    return getReturnTransactionsForLoanUseCase.execute(loan.id!);
  }

  Future<void> _refreshAfterLoanChange() async {
    final transactionController = Get.find<TransactionController>();
    await transactionController.fetchSavedTransactions();
    await refreshLoans();
  }
}
