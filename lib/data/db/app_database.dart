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
  DateTimeColumn get dateOf => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Limits table
class Limits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().customConstraint('REFERENCES users(id)')();
  TextColumn get type => text()(); // e.g., "daily", "weekly", "monthly"
  RealColumn get amount => real()();
  IntColumn get monthStartDay => integer()(); // e.g., 1st, 15th
  TextColumn get monthStartType => text()(); // e.g., "day" or "week"
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Database
@DriftDatabase(tables: [Users, Banks, Transactions, Limits])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

// You can add DAOs here later
}

// Lazy connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
