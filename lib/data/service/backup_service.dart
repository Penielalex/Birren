import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../db/app_database.dart';
import '../db/bank_dao.dart';
import '../db/budget_dao.dart';
import '../db/limit_dao.dart';
import '../db/loan_dao.dart';
import '../db/transaction_dao.dart';
import '../db/user_dao.dart';
import 'shared_prefs_service.dart';

class BackupService {
  final AppDatabase db;
  final UserDao userDao;
  final BankDao bankDao;
  final TransactionDao transactionDao;
  final BudgetDao budgetDao;
  final LoanDao loanDao;
  final LimitDao limitDao;
  final SharedPrefsService prefs;

  BackupService({
    required this.db,
    required this.userDao,
    required this.bankDao,
    required this.transactionDao,
    required this.budgetDao,
    required this.loanDao,
    required this.limitDao,
    required this.prefs,
  });

  Future<File> exportToFile() async {
    final payload = await _buildExportPayload();
    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(
        dir.path,
        'birren_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      ),
    );
    await file.writeAsString(jsonEncode(payload));
    return file;
  }

  Future<void> shareBackup() async {
    final file = await exportToFile();
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Birren data backup',
    );
  }

  Future<void> importFromFile(String path) async {
    final content = await File(path).readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;
    await _importPayload(data);
  }

  Future<Map<String, dynamic>> _buildExportPayload() async {
    final users = await userDao.getUsers();
    final banks = await bankDao.getBanks();
    final transactions = await transactionDao.getAllTransactions();
    final budgets = await budgetDao.getAllBudgets();
    final loans = await loanDao.getAllLoans();
    final limits = await limitDao.getAllLimits();
    final syncCheckpoints = await prefs.exportSyncCheckpoints();

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'users': users
          .map(
            (u) => {
              'id': u.id,
              'name': u.name,
              'email': u.email,
              'googleId': u.googleId,
              'createdAt': u.createdAt.toIso8601String(),
              'updatedAt': u.updatedAt.toIso8601String(),
            },
          )
          .toList(),
      'banks': banks.map((b) => b.toMap()).toList(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'loans': loans.map((l) => l.toMap()).toList(),
      'budgets': budgets
          .map(
            (b) => {
              'id': b.id,
              'userId': b.userId,
              'name': b.name,
              'startDate': b.startDate.toIso8601String(),
              'endDate': b.endDate.toIso8601String(),
              'status': b.status,
              'createdAt': b.createdAt.toIso8601String(),
              'updatedAt': b.updatedAt.toIso8601String(),
              'lineItems': b.lineItems
                  .map(
                    (item) => {
                      'id': item.id,
                      'budgetId': item.budgetId,
                      'name': item.name,
                      'allocatedAmount': item.allocatedAmount,
                      'categoryIndex': item.categoryIndex,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
      'limits': limits
          .map(
            (l) => {
              'id': l.id,
              'userId': l.userId,
              'type': l.type,
              'amount': l.amount,
              'monthStartDay': l.monthStartDay,
              'monthStartType': l.monthStartType,
              'createdAt': l.createdAt.toIso8601String(),
              'updatedAt': l.updatedAt.toIso8601String(),
            },
          )
          .toList(),
      'syncCheckpoints': syncCheckpoints,
    };
  }

  Future<void> _importPayload(Map<String, dynamic> data) async {
    if (data['version'] != 1) {
      throw FormatException('Unsupported backup version');
    }

    await db.transaction(() async {
      await db.delete(db.transactions).go();
      await db.delete(db.loans).go();
      await db.delete(db.budgetLineItems).go();
      await db.delete(db.budgets).go();
      await db.delete(db.limits).go();
      await db.delete(db.banks).go();
      await db.delete(db.users).go();

      for (final raw in data['users'] as List<dynamic>) {
        final map = raw as Map<String, dynamic>;
        await db.into(db.users).insert(
              UsersCompanion(
                id: Value(map['id'] as int),
                name: Value(map['name'] as String),
                email: Value(map['email'] as String?),
                googleId: Value(map['googleId'] as String?),
                createdAt: Value(DateTime.parse(map['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(map['updatedAt'] as String)),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }

      for (final raw in data['banks'] as List<dynamic>) {
        final map = raw as Map<String, dynamic>;
        await db.into(db.banks).insert(
              BanksCompanion(
                id: Value(map['id'] as int),
                userId: Value(map['userId'] as int),
                bankName: Value(map['bankName'] as String),
                displayName: Value(map['displayName'] as String?),
                balance: Value((map['balance'] as num).toDouble()),
                createdAt: Value(DateTime.parse(map['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(map['updatedAt'] as String)),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }

      for (final raw in data['budgets'] as List<dynamic>) {
        final map = raw as Map<String, dynamic>;
        await db.into(db.budgets).insert(
              BudgetsCompanion(
                id: Value(map['id'] as int),
                userId: Value(map['userId'] as int),
                name: Value(map['name'] as String),
                startDate: Value(DateTime.parse(map['startDate'] as String)),
                endDate: Value(DateTime.parse(map['endDate'] as String)),
                status: Value(map['status'] as String),
                createdAt: Value(DateTime.parse(map['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(map['updatedAt'] as String)),
              ),
              mode: InsertMode.insertOrReplace,
            );

        for (final itemRaw in map['lineItems'] as List<dynamic>? ?? []) {
          final item = itemRaw as Map<String, dynamic>;
          await db.into(db.budgetLineItems).insert(
                BudgetLineItemsCompanion(
                  id: Value(item['id'] as int),
                  budgetId: Value(item['budgetId'] as int),
                  name: Value(item['name'] as String),
                  allocatedAmount:
                      Value((item['allocatedAmount'] as num).toDouble()),
                  categoryIndex: Value(item['categoryIndex'] as String?),
                ),
                mode: InsertMode.insertOrReplace,
              );
        }
      }

      for (final raw in data['transactions'] as List<dynamic>) {
        final map = raw as Map<String, dynamic>;
        await db.into(db.transactions).insert(
              TransactionsCompanion(
                id: Value(map['id'] as int),
                bankId: Value(map['bankId'] as int),
                category: Value(map['category'] as String),
                type: Value(map['type'] as String),
                amount: Value((map['amount'] as num).toDouble()),
                transferId: Value(map['transferId'] as int?),
                budgetLineItemId: Value(map['budgetLineItemId'] as int?),
                loanId: Value(map['loanId'] as int?),
                dateOf: Value(DateTime.parse(map['dateOf'] as String)),
                createdAt: Value(DateTime.parse(map['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(map['updatedAt'] as String)),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }

      for (final raw in data['loans'] as List<dynamic>? ?? []) {
        final map = raw as Map<String, dynamic>;
        await db.into(db.loans).insert(
              LoansCompanion(
                id: Value(map['id'] as int),
                userId: Value(map['userId'] as int),
                counterpartyName: Value(map['counterpartyName'] as String?),
                principalAmount:
                    Value((map['principalAmount'] as num).toDouble()),
                disbursementTransactionId:
                    Value(map['disbursementTransactionId'] as int),
                status: Value(map['status'] as String),
                closeTransactionId: Value(map['closeTransactionId'] as int?),
                createdAt: Value(DateTime.parse(map['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(map['updatedAt'] as String)),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }

      for (final raw in data['limits'] as List<dynamic>? ?? []) {
        final map = raw as Map<String, dynamic>;
        await db.into(db.limits).insert(
              LimitsCompanion(
                id: Value(map['id'] as int),
                userId: Value(map['userId'] as int),
                type: Value(map['type'] as String),
                amount: Value((map['amount'] as num).toDouble()),
                monthStartDay: Value(map['monthStartDay'] as int),
                monthStartType: Value(map['monthStartType'] as String),
                createdAt: Value(DateTime.parse(map['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(map['updatedAt'] as String)),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });

    final checkpoints = data['syncCheckpoints'] as Map<String, dynamic>?;
    await prefs.importSyncCheckpoints(checkpoints);
  }

  Future<void> clearAllLocalData() async {
    await db.transaction(() async {
      await db.delete(db.transactions).go();
      await db.delete(db.loans).go();
      await db.delete(db.budgetLineItems).go();
      await db.delete(db.budgets).go();
      await db.delete(db.limits).go();
      await db.delete(db.banks).go();
      await db.delete(db.users).go();
    });
    await prefs.clearAll();
  }
}
