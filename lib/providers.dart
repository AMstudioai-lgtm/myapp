import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/db.dart';
import 'data/journal_repo.dart';

final dbProvider = Provider<AppDb>((_) => throw UnimplementedError('override in main'));
final repoProvider = Provider<JournalRepo>((ref) => JournalRepo(ref.watch(dbProvider)));
final journalsProvider = StreamProvider((ref) => ref.watch(repoProvider).watchJournals());
final selectedJournalProvider = StateProvider<String?>((_) => null);
final propsProvider =
    StreamProvider.family<List<Property>, String>((ref, journalId) => ref.watch(repoProvider).watchProps(journalId));
final rowsProvider =
    StreamProvider.family<List<EntryRow>, String>((ref, journalId) => ref.watch(repoProvider).watchRows(journalId));
