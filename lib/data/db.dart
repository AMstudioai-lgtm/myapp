import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'db.g.dart';

// Types de propriete MVP : texte, nombre, date, selection.
class Journals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

class Properties extends Table {
  TextColumn get id => text()();
  TextColumn get journalId => text().references(Journals, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  // kind: text | number | date | select
  TextColumn get kind => text()();
  // options JSON pour select : ["A","B"]
  TextColumn get optionsJson => text().withDefault(const Constant('[]'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

class EntryRows extends Table {
  TextColumn get id => text()();
  TextColumn get journalId => text().references(Journals, #id, onDelete: KeyAction.cascade)();
  // values JSON : {propertyId: value}
  TextColumn get valuesJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Journals, Properties, EntryRows])
class AppDb extends _$AppDb {
  AppDb() : super(_open());

  AppDb.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );

  static QueryExecutor _open() {
    return driftDatabase(
      name: 'myapp',
      native: const DriftNativeOptions(
        databaseDirectory: _dir,
      ),
    );
  }

  static Future<Directory> _dir() async {
    final d = await getApplicationDocumentsDirectory();
    return Directory(p.join(d.path, 'myapp'));
  }
}
