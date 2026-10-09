import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'db.dart';

const _uuid = Uuid();

/// Depot simple, zero duplication, offline-first.
class JournalRepo {
  JournalRepo(this.db);
  final AppDb db;

  Stream<List<Journal>> watchJournals() =>
      (db.select(db.journals)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).watch();

  Future<String> createJournal() async {
    final count = await (db.selectOnly(db.journals)..addColumns([db.journals.id.count()])).getSingle();
    final n = (count.read(db.journals.id.count()) ?? 0) + 1;
    final id = _uuid.v4();
    await db.into(db.journals).insert(JournalsCompanion(id: Value(id), name: Value('Journal $n')));
    return id;
  }

  Future<void> deleteJournal(String id) =>
      (db.delete(db.journals)..where((t) => t.id.equals(id))).go();

  Stream<List<Property>> watchProps(String journalId) =>
      (db.select(db.properties)
            ..where((t) => t.journalId.equals(journalId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<void> addProperty(String journalId, String name, String kind, {List<String> options = const []}) async {
    final existing = await (db.select(db.properties)..where((t) => t.journalId.equals(journalId))).get();
    await db.into(db.properties).insert(PropertiesCompanion(
      id: Value(_uuid.v4()),
      journalId: Value(journalId),
      name: Value(name.trim()),
      kind: Value(kind),
      optionsJson: Value(jsonEncode(options)),
      sortOrder: Value(existing.length),
    ));
  }

  Stream<List<EntryRow>> watchRows(String journalId) =>
      (db.select(db.entryRows)
            ..where((t) => t.journalId.equals(journalId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .watch();

  Future<void> addRow(String journalId, Map<String, dynamic> values) async {
    await db.into(db.entryRows).insert(EntryRowsCompanion(
      id: Value(_uuid.v4()),
      journalId: Value(journalId),
      valuesJson: Value(jsonEncode(values)),
    ));
  }

  Future<void> updateCell(String rowId, String propId, dynamic value) async {
    final row = await (db.select(db.entryRows)..where((t) => t.id.equals(rowId))).getSingle();
    final map = Map<String, dynamic>.from(jsonDecode(row.valuesJson) as Map);
    map[propId] = value;
    await (db.update(db.entryRows)..where((t) => t.id.equals(rowId)))
        .write(EntryRowsCompanion(valuesJson: Value(jsonEncode(map))));
  }

  Future<void> deleteRow(String rowId) =>
      (db.delete(db.entryRows)..where((t) => t.id.equals(rowId))).go();
}

Map<String, dynamic> decodeValues(String json) =>
    Map<String, dynamic>.from(jsonDecode(json) as Map);
