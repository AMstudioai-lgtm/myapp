import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/data/db.dart';
import 'package:myapp/data/journal_repo.dart';

void main() {
  late AppDb db;
  late JournalRepo repo;

  setUp(() {
    db = AppDb.forTesting(NativeDatabase.memory());
    repo = JournalRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('JournalRepo Tests', () {
    test('createJournal crée un journal avec un nom incrémenté', () async {
      final id1 = await repo.createJournal();
      final id2 = await repo.createJournal();

      final journals = await repo.watchJournals().first;
      expect(journals.length, 2);
      expect(journals[0].id, id1);
      expect(journals[0].name, 'Journal 1');
      expect(journals[1].id, id2);
      expect(journals[1].name, 'Journal 2');
    });

    test('addProperty ajoute des colonnes de types variés (text, number, date, select)', () async {
      final journalId = await repo.createJournal();

      await repo.addProperty(journalId, 'Asset', 'text');
      await repo.addProperty(journalId, 'P&L', 'number');
      await repo.addProperty(journalId, 'Date Trade', 'date');
      await repo.addProperty(journalId, 'Direction', 'select', options: ['Long', 'Short']);

      final props = await repo.watchProps(journalId).first;
      expect(props.length, 4);
      expect(props[0].name, 'Asset');
      expect(props[0].kind, 'text');
      expect(props[1].name, 'P&L');
      expect(props[1].kind, 'number');
      expect(props[2].name, 'Date Trade');
      expect(props[2].kind, 'date');
      expect(props[3].name, 'Direction');
      expect(props[3].kind, 'select');
      expect(jsonDecode(props[3].optionsJson), ['Long', 'Short']);
    });

    test('addProperty lève une exception sur nom vide ou select sans options', () async {
      final journalId = await repo.createJournal();

      expect(() => repo.addProperty(journalId, '  ', 'text'), throwsArgumentError);
      expect(() => repo.addProperty(journalId, 'Direction', 'select', options: []), throwsArgumentError);
      expect(() => repo.addProperty(journalId, 'Test', 'invalid_kind'), throwsArgumentError);
    });

    test('addRow et updateCell gèrent les valeurs dynamiques en JSON', () async {
      final journalId = await repo.createJournal();
      await repo.addProperty(journalId, 'P&L', 'number');
      final props = await repo.watchProps(journalId).first;
      final propId = props.first.id;

      await repo.addRow(journalId, {propId: 150.5});
      var rows = await repo.watchRows(journalId).first;
      expect(rows.length, 1);
      expect(decodeValues(rows.first.valuesJson)[propId], 150.5);

      await repo.updateCell(rows.first.id, propId, 300.0);
      rows = await repo.watchRows(journalId).first;
      expect(decodeValues(rows.first.valuesJson)[propId], 300.0);

      await repo.deleteRow(rows.first.id);
      rows = await repo.watchRows(journalId).first;
      expect(rows.isEmpty, true);
    });

    test('deleteJournal supprime en cascade les propriétés et les lignes', () async {
      final journalId = await repo.createJournal();
      await repo.addProperty(journalId, 'Ticker', 'text');
      await repo.addRow(journalId, {'custom': 'BTC/USDT'});

      var journals = await repo.watchJournals().first;
      expect(journals.length, 1);

      await repo.deleteJournal(journalId);

      journals = await repo.watchJournals().first;
      expect(journals.isEmpty, true);

      final props = await repo.watchProps(journalId).first;
      expect(props.isEmpty, true);

      final rows = await repo.watchRows(journalId).first;
      expect(rows.isEmpty, true);
    });
  });
}
