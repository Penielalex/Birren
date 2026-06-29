import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
part 'app_database.g.dart';

// Users table
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text().withLength(min: 1, max: 255).nullable()();
  TextColumn get googleId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Banks table
class Banks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('REFERENCES users(id)')();
  TextColumn get bankName => text()();
  TextColumn get displayName => text().nullable()();
  RealColumn get balance => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>>? get uniqueKeys => [
    {userId, bankName} // composite unique per user
  ];
}

// Transactions table
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bankId => integer().customConstraint('REFERENCES banks(id)')();
  TextColumn get category => text()();
  TextColumn get type => text()(); // income/expense
  RealColumn get amount => real()();
  IntColumn get transferId =>
      integer().nullable().customConstraint('NULL REFERENCES transactions(id)')();
  IntColumn get budgetLineItemId => integer().nullable()();
  IntColumn get loanId =>
      integer().nullable().customConstraint('NULL REFERENCES loans(id)')();
  DateTimeColumn get dateOf => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Limits table (legacy — replaced by Budgets)
class Limits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('REFERENCES users(id)')();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  IntColumn get monthStartDay => integer()();
  TextColumn get monthStartType => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('REFERENCES users(id)')();
  TextColumn get name => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class BudgetLineItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get budgetId =>
      integer().customConstraint('REFERENCES budgets(id)')();
  TextColumn get name => text()();
  RealColumn get allocatedAmount => real()();
  TextColumn get categoryIndex => text().nullable()();
}

class Loans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('REFERENCES users(id)')();
  TextColumn get counterpartyName => text().nullable()();
  RealColumn get principalAmount => real()();
  IntColumn get disbursementTransactionId =>
      integer().customConstraint('REFERENCES transactions(id)')();
  TextColumn get status => text()();
  IntColumn get closeTransactionId =>
      integer().nullable().customConstraint('NULL REFERENCES transactions(id)')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Database
@DriftDatabase(
  tables: [Users, Banks, Transactions, Limits, Budgets, BudgetLineItems, Loans],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(transactions, transactions.transferId);
      }
      if (from < 3) {
        await migrator.createTable(budgets);
        await migrator.createTable(budgetLineItems);
      }
      if (from < 4) {
        await migrator.addColumn(transactions, transactions.budgetLineItemId);
      }
      if (from < 5) {
        await migrator.createTable(loans);
        await migrator.addColumn(transactions, transactions.loanId);
      }
    },
  );
}

// Lazy connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
