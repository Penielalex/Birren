import 'package:drift/drift.dart';

import '../../domain/entities/loan.dart' as domain;
import '../../domain/entities/transaction.dart';
import '../../presentation/util/category.dart';
import 'app_database.dart' hide Transaction;

part 'loan_dao.g.dart';

@DriftAccessor(tables: [Loans, Transactions])
class LoanDao extends DatabaseAccessor<AppDatabase> with _$LoanDaoMixin {
  LoanDao(this.db) : super(db);

  final AppDatabase db;

  domain.Loan _mapLoan(Loan row) {
    return domain.Loan(
      id: row.id,
      userId: row.userId,
      counterpartyName: row.counterpartyName,
      principalAmount: row.principalAmount,
      disbursementTransactionId: row.disbursementTransactionId,
      status: row.status,
      closeTransactionId: row.closeTransactionId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<List<domain.Loan>> getAllLoans() async {
    final rows = await (select(loans)
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
        .get();
    return rows.map(_mapLoan).toList();
  }

  Future<List<domain.Loan>> getLoansByUserId(int userId) async {
    final rows = await (select(loans)
          ..where((l) => l.userId.equals(userId))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
        .get();
    return rows.map(_mapLoan).toList();
  }

  Future<List<domain.Loan>> getOpenLoansByUserId(int userId) async {
    final rows = await (select(loans)
          ..where(
            (l) => l.userId.equals(userId) & l.status.equals('open'),
          )
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
        .get();
    return rows.map(_mapLoan).toList();
  }

  Future<domain.Loan?> getLoanById(int id) async {
    final row =
        await (select(loans)..where((l) => l.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapLoan(row);
  }

  Future<int> createLoanFromDisbursement({
    required int userId,
    required int transactionId,
    required double principalAmount,
    String? counterpartyName,
  }) async {
    return db.transaction(() async {
      final now = DateTime.now();
      final loanId = await into(loans).insert(
        LoansCompanion(
          userId: Value(userId),
          counterpartyName: Value(counterpartyName),
          principalAmount: Value(principalAmount),
          disbursementTransactionId: Value(transactionId),
          status: const Value('open'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await (update(transactions)..where((t) => t.id.equals(transactionId)))
          .write(
        TransactionsCompanion(
          category: Value('$incomeLoanIndex'),
          budgetLineItemId: const Value(null),
          loanId: Value(loanId),
          updatedAt: Value(now),
        ),
      );

      return loanId;
    });
  }

  /// Registers money lent to someone (outgoing expense).
  Future<int> createLoanFromLend({
    required int userId,
    required int transactionId,
    required double principalAmount,
    String? counterpartyName,
  }) async {
    return db.transaction(() async {
      final now = DateTime.now();
      final loanId = await into(loans).insert(
        LoansCompanion(
          userId: Value(userId),
          counterpartyName: Value(counterpartyName),
          principalAmount: Value(principalAmount),
          disbursementTransactionId: Value(transactionId),
          status: const Value('open'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await (update(transactions)..where((t) => t.id.equals(transactionId)))
          .write(
        TransactionsCompanion(
          category: Value('$expenseLendLoanIndex'),
          budgetLineItemId: const Value(null),
          loanId: Value(loanId),
          updatedAt: Value(now),
        ),
      );

      return loanId;
    });
  }

  /// Splits one expense: your share stays on the original txn (budgeted);
  /// friends' share becomes a new lent-loan expense.
  Future<void> splitSharedExpense({
    required int originalTransactionId,
    required int userId,
    required double yourShare,
    required double friendsShare,
    required String yourCategoryIndex,
    int? budgetLineItemId,
    String? counterpartyName,
  }) async {
    if (yourShare <= 0 || friendsShare <= 0) {
      throw ArgumentError('Both your share and friends share must be > 0');
    }

    await db.transaction(() async {
      final now = DateTime.now();
      final original = await (select(transactions)
            ..where((t) => t.id.equals(originalTransactionId)))
          .getSingle();

      if (original.type != 'Expense') {
        throw StateError('Only expense transactions can be split');
      }

      // If this txn was already a lent loan, remove that loan first.
      if (original.loanId != null) {
        final loan = await (select(loans)
              ..where((l) => l.id.equals(original.loanId!)))
            .getSingleOrNull();
        if (loan != null &&
            loan.disbursementTransactionId == originalTransactionId) {
          await (delete(loans)..where((l) => l.id.equals(loan.id))).go();
        }
      }

      await (update(transactions)
            ..where((t) => t.id.equals(originalTransactionId)))
          .write(
        TransactionsCompanion(
          amount: Value(yourShare),
          category: Value(yourCategoryIndex),
          budgetLineItemId: budgetLineItemId != null
              ? Value(budgetLineItemId)
              : const Value(null),
          loanId: const Value(null),
          updatedAt: Value(now),
        ),
      );

      final lendTxnId = await into(transactions).insert(
        TransactionsCompanion(
          bankId: Value(original.bankId),
          category: Value('$expenseLendLoanIndex'),
          type: const Value('Expense'),
          amount: Value(friendsShare),
          dateOf: Value(original.dateOf),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final loanId = await into(loans).insert(
        LoansCompanion(
          userId: Value(userId),
          counterpartyName: Value(counterpartyName),
          principalAmount: Value(friendsShare),
          disbursementTransactionId: Value(lendTxnId),
          status: const Value('open'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await (update(transactions)..where((t) => t.id.equals(lendTxnId))).write(
        TransactionsCompanion(
          loanId: Value(loanId),
          updatedAt: Value(now),
        ),
      );
    });
  }

  /// Links an expense repayment to a borrowed loan (money you received).
  Future<void> linkRepaymentToLoan({
    required int repaymentTransactionId,
    required int loanId,
  }) async {
    await (update(transactions)
          ..where((t) => t.id.equals(repaymentTransactionId)))
        .write(
      TransactionsCompanion(
        category: Value('$expenseLoanIndex'),
        loanId: Value(loanId),
        budgetLineItemId: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Links an income return to a lent loan (money you gave out).
  Future<void> linkReturnToLentLoan({
    required int returnTransactionId,
    required int loanId,
  }) async {
    await (update(transactions)
          ..where((t) => t.id.equals(returnTransactionId)))
        .write(
      TransactionsCompanion(
        category: Value('$incomeReturnsIndex'),
        loanId: Value(loanId),
        budgetLineItemId: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Splits one payment across one or more loans.
  /// Keeps the original transaction for the first allocation and inserts
  /// sibling transactions (same bank/date/type) for the rest, so a single
  /// SMS repayment can cover multiple lent shares / loans.
  Future<void> allocatePaymentAcrossLoans({
    required int paymentTransactionId,
    required List<({int loanId, double amount})> allocations,
    required bool isReturn,
  }) async {
    if (allocations.isEmpty) {
      throw ArgumentError('Select at least one loan');
    }
    for (final a in allocations) {
      if (a.amount <= 0) {
        throw ArgumentError('Each allocation must be greater than 0');
      }
    }

    await db.transaction(() async {
      final now = DateTime.now();
      final original = await (select(transactions)
            ..where((t) => t.id.equals(paymentTransactionId)))
          .getSingle();

      final expectedType = isReturn ? 'Income' : 'Expense';
      if (original.type != expectedType) {
        throw StateError(
          isReturn
              ? 'Returns must be income transactions'
              : 'Repayments must be expense transactions',
        );
      }

      final totalAllocated =
          allocations.fold<double>(0, (sum, a) => sum + a.amount);
      if (totalAllocated > original.amount + 0.05) {
        throw ArgumentError(
          'Allocated amounts cannot exceed the payment (${original.amount})',
        );
      }
      final remainder = original.amount - totalAllocated;
      final splitGroupId = original.splitGroupId ?? original.id;

      final category =
          isReturn ? '$incomeReturnsIndex' : '$expenseLoanIndex';
      final first = allocations.first;

      await (update(transactions)
            ..where((t) => t.id.equals(paymentTransactionId)))
          .write(
        TransactionsCompanion(
          amount: Value(first.amount),
          category: Value(category),
          splitGroupId: Value(splitGroupId),
          loanId: Value(first.loanId),
          budgetLineItemId: const Value(null),
          updatedAt: Value(now),
        ),
      );

      for (final allocation in allocations.skip(1)) {
        await into(transactions).insert(
          TransactionsCompanion(
            bankId: Value(original.bankId),
            category: Value(category),
            type: Value(original.type),
            amount: Value(allocation.amount),
            splitGroupId: Value(splitGroupId),
            loanId: Value(allocation.loanId),
            dateOf: Value(original.dateOf),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }

      if (remainder > 0.05) {
        await into(transactions).insert(
          TransactionsCompanion(
            bankId: Value(original.bankId),
            category: Value(
              isReturn ? '$incomeOtherIndex' : '$expenseOtherIndex',
            ),
            type: Value(original.type),
            amount: Value(remainder),
            splitGroupId: Value(splitGroupId),
            dateOf: Value(original.dateOf),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  @Deprecated('Use linkRepaymentToLoan or linkReturnToLentLoan')
  Future<void> linkReturnToLoan({
    required int returnTransactionId,
    required int loanId,
  }) =>
      linkRepaymentToLoan(
        repaymentTransactionId: returnTransactionId,
        loanId: loanId,
      );

  Future<int?> closeLoan({
    required int loanId,
    required double writeOffAmount,
    required int bankId,
    required String category,
    int? budgetLineItemId,
    required DateTime dateOf,
  }) async {
    return db.transaction(() async {
      final now = DateTime.now();
      int? closeTransactionId;

      if (writeOffAmount > 0.001) {
        closeTransactionId = await into(transactions).insert(
          TransactionsCompanion(
            bankId: Value(bankId),
            category: Value(category),
            type: const Value('Expense'),
            amount: Value(writeOffAmount),
            budgetLineItemId: budgetLineItemId != null
                ? Value(budgetLineItemId)
                : const Value.absent(),
            dateOf: Value(dateOf),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }

      await (update(loans)..where((l) => l.id.equals(loanId))).write(
        LoansCompanion(
          status: const Value('closed'),
          closeTransactionId: Value(closeTransactionId),
          updatedAt: Value(now),
        ),
      );

      return closeTransactionId;
    });
  }

  Future<List<Transaction>> getReturnTransactionsForLoan(int loanId) async {
    final loan = await getLoanById(loanId);
    if (loan == null) return [];

    final disbursement = await (select(transactions)
          ..where((t) => t.id.equals(loan.disbursementTransactionId)))
        .getSingleOrNull();
    final isLent = disbursement?.type == 'Expense';
    final linkedType = isLent ? 'Income' : 'Expense';

    final rows = await (select(transactions)
          ..where(
            (t) =>
                t.loanId.equals(loanId) &
                t.type.equals(linkedType) &
                t.id.isNotValue(loan.disbursementTransactionId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.dateOf)]))
        .get();

    return rows
        .map(
          (row) => Transaction(
            id: row.id,
            bankId: row.bankId,
            category: row.category,
            type: row.type,
            amount: row.amount,
            splitGroupId: row.splitGroupId,
            transferId: row.transferId,
            budgetLineItemId: row.budgetLineItemId,
            loanId: row.loanId,
            dateOf: row.dateOf,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
          ),
        )
        .toList();
  }
}
