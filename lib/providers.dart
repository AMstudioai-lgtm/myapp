import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/db.dart';
import 'data/journal_repo.dart';

final dbProvider = Provider<AppDb>((_) => throw UnimplementedError('override in main'));
final repoProvider = Provider<JournalRepo>((ref) => JournalRepo(ref.watch(dbProvider)));
final journalsProvider = StreamProvider((ref) => ref.watch(repoProvider).watchJournals());
final selectedJournalProvider = StateProvider<String?>((_) => null);
