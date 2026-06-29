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

  Future<void> linkReturnToLoan({
    required int returnTransactionId,
    required int loanId,
  }) async {
    await (update(transactions)..where((t) => t.id.equals(returnTransactionId)))
        .write(
      TransactionsCompanion(
        category: Value('$expenseLoanIndex'),
        loanId: Value(loanId),
        budgetLineItemId: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

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

    final rows = await (select(transactions)
          ..where(
            (t) =>
                t.loanId.equals(loanId) &
                t.type.equals('Expense') &
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
