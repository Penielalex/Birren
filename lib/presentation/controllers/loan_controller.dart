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
  final SplitSharedExpenseUseCase splitSharedExpenseUseCase;
  final LinkRepaymentToLoanUseCase linkRepaymentToLoanUseCase;
  final LinkReturnToLentLoanUseCase linkReturnToLentLoanUseCase;
  final AllocatePaymentAcrossLoansUseCase allocatePaymentAcrossLoansUseCase;
  final CloseLoanUseCase closeLoanUseCase;
  final GetReturnTransactionsForLoanUseCase getReturnTransactionsForLoanUseCase;

  LoanController({
    required this.prefs,
    required this.getLoansByUserIdUseCase,
    required this.getOpenLoansByUserIdUseCase,
    required this.createLoanFromDisbursementUseCase,
    required this.createLoanFromLendUseCase,
    required this.splitSharedExpenseUseCase,
    required this.linkRepaymentToLoanUseCase,
    required this.linkReturnToLentLoanUseCase,
    required this.allocatePaymentAcrossLoansUseCase,
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

  /// Split a group bill: your share on budget, friends' share as a lent loan.
  Future<void> splitSharedExpense({
    required Transaction original,
    required double yourShare,
    required double friendsShare,
    required String yourCategoryIndex,
    int? budgetLineItemId,
    String? counterpartyName,
  }) async {
    if (original.id == null) {
      throw ArgumentError('Transaction must be saved first');
    }
    if (original.type != 'Expense') {
      throw ArgumentError('Only expenses can be split');
    }

    final total = yourShare + friendsShare;
    if ((total - original.amount).abs() > 0.01 && yourShare + friendsShare <= 0) {
      throw ArgumentError('Invalid share amounts');
    }
    if (yourShare <= 0 || friendsShare <= 0) {
      throw ArgumentError('Your share and friends share must both be greater than 0');
    }
    if (yourShare + friendsShare > original.amount + 0.01) {
      throw ArgumentError(
        'Shares cannot exceed the transaction amount (${original.amount})',
      );
    }

    final userId = await prefs.getId();
    if (userId == null) {
      throw StateError('User not logged in');
    }

    // If shares don't cover full amount, keep remainder on your budget share
    // by adjusting: user enters yourShare + friendsShare that should equal total.
    // Allow slight float; require they sum to original amount.
    if ((yourShare + friendsShare - original.amount).abs() > 0.05) {
      throw ArgumentError(
        'Your share + friends share must equal the total amount',
      );
    }

    await splitSharedExpenseUseCase.execute(
      originalTransactionId: original.id!,
      userId: int.parse(userId),
      yourShare: yourShare,
      friendsShare: friendsShare,
      yourCategoryIndex: yourCategoryIndex,
      budgetLineItemId: budgetLineItemId,
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

  /// Split one return / repayment across several loans (e.g. one SMS covers
  /// multiple lent amounts or shared-expense shares).
  Future<void> allocatePaymentAcrossLoans({
    required Transaction payment,
    required List<({Loan loan, double amount})> allocations,
    required bool isReturn,
  }) async {
    if (payment.id == null) {
      throw ArgumentError('Payment transaction must be saved first');
    }
    if (allocations.isEmpty) {
      throw ArgumentError('Select at least one loan');
    }

    final expectedType = isReturn ? 'Income' : 'Expense';
    if (payment.type != expectedType) {
      throw ArgumentError(
        isReturn
            ? 'Returns must be income transactions'
            : 'Repayments must be expense transactions',
      );
    }

    final total = allocations.fold<double>(0, (s, a) => s + a.amount);
    if (total > payment.amount + 0.05) {
      throw ArgumentError(
        'Allocated total cannot exceed ${payment.amount}',
      );
    }

    final transactions = Get.find<TransactionController>().transactions;
    for (final allocation in allocations) {
      final loan = allocation.loan;
      if (loan.id == null) {
        throw ArgumentError('Loan must be saved');
      }
      if (!loan.isOpen) {
        throw StateError('Cannot allocate to a closed loan');
      }
      if (isReturn && !isLentLoan(loan, transactions)) {
        throw StateError('Returns only apply to lent loans');
      }
      if (!isReturn && !isBorrowedLoan(loan, transactions)) {
        throw StateError('Repayments only apply to borrowed loans');
      }
      final remaining = remainingBalance(loan, transactions);
      if (allocation.amount > remaining + 0.05) {
        throw ArgumentError(
          'Allocation exceeds remaining balance on loan #${loan.id}',
        );
      }
    }

    await allocatePaymentAcrossLoansUseCase.execute(
      paymentTransactionId: payment.id!,
      allocations: [
        for (final a in allocations) (loanId: a.loan.id!, amount: a.amount),
      ],
      isReturn: isReturn,
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
