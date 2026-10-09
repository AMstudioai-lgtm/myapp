import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/journal_repo.dart';
import '../providers.dart';

/// Page journal : etat vide + bouton +, sinon titre + tableau + footer calcul.
class JournalPage extends ConsumerWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journals = ref.watch(journalsProvider);
    final selected = ref.watch(selectedJournalProvider);
    return journals.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (list) {
        if (list.isEmpty) return _empty(context, ref);
        final current = selected != null && list.any((j) => j.id == selected)
            ? list.firstWhere((j) => j.id == selected)
            : list.first;
        return _TableView(journalId: current.id, journalName: current.name);
      },
    );
  }

  Widget _empty(BuildContext context, WidgetRef ref) {
    return Center(
      child: FilledButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Creer une base de donnees'),
        onPressed: () async {
          final id = await ref.read(repoProvider).createJournal();
          ref.read(selectedJournalProvider.notifier).state = id;
        },
      ),
    );
  }
}

class _TableView extends ConsumerWidget {
  const _TableView({required this.journalId, required this.journalName});
  final String journalId;
  final String journalName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repoProvider);
    final props = ref.watch(StreamProvider.autoDispose(
      (r) => r.watch(repoProvider).watchProps(journalId),
    ));
    final rows = ref.watch(StreamProvider.autoDispose(
      (r) => r.watch(repoProvider).watchRows(journalId),
    ));
    return Column(
      children: [
        ListTile(title: Text(journalName, style: Theme.of(context).textTheme.titleLarge)),
        Expanded(
          child: props.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (cols) {
              if (cols.isEmpty) return _noProps(context, ref);
              return rows.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
                data: (lines) => _grid(context, ref, repo, cols, lines),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _noProps(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Table vide. Ajoute ta premiere propriete.'),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => showAddProp(context, ref, journalId),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter propriete'),
        ),
      ]),
    );
  }

  Widget _grid(BuildContext context, WidgetRef ref, JournalRepo repo, List cols, List lines) {
    final sums = _sums(cols, lines);
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              for (final c in cols) DataColumn(label: Text('${c.name} (${c.kind})')),
              const DataColumn(label: Text('')),
            ],
            rows: [
              for (final r in lines)
                DataRow(cells: [
                  for (final c in cols)
                    DataCell(_cell(context, ref, repo, r, c)),
                  DataCell(IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => repo.deleteRow(r.id as String),
                  )),
                ]),
              // Ligne footer calcul
              DataRow(cells: [
                for (final c in cols)
                  DataCell(Text(
                    c.kind == 'number' ? 'Σ ${sums['${c.id}_sum'] ?? 0}  |  moy ${sums['${c.id}_avg'] ?? 0}' : '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  )),
                const DataCell(Text('')),
              ]),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          OutlinedButton.icon(
            onPressed: () => showAddProp(context, ref, journalId),
            icon: const Icon(Icons.view_column),
            label: const Text('Propriete'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => repo.addRow(journalId, {}),
            icon: const Icon(Icons.add),
            label: const Text('Ligne'),
          ),
        ]),
      ),
    ]);
  }

  Map<String, num> _sums(List cols, List lines) {
    final out = <String, num>{};
    for (final c in cols) {
      if (c.kind != 'number') continue;
      num sum = 0, n = 0;
      for (final r in lines) {
        final map = decodeValues(r.valuesJson as String);
        final v = num.tryParse('${map[c.id] ?? ''}');
        if (v != null) {
          sum += v;
          n++;
        }
      }
      out['${c.id}_sum'] = sum;
      out['${c.id}_avg'] = n == 0 ? 0 : num.parse((sum / n).toStringAsFixed(2));
    }
    return out;
  }

  Widget _cell(BuildContext context, WidgetRef ref, JournalRepo repo, dynamic row, dynamic col) {
    final map = decodeValues(row.valuesJson as String);
    final v = map[col.id];
    final kind = col.kind as String;
    if (kind == 'select') {
      final opts = List<String>.from(jsonDecode(col.optionsJson as String) as List);
      return DropdownButton<String>(
        value: v is String && opts.contains(v) ? v : null,
        hint: const Text('—'),
        items: [for (final o in opts) DropdownMenuItem(value: o, child: Text(o))],
        onChanged: (nv) => repo.updateCell(row.id as String, col.id as String, nv),
      );
    }
    if (kind == 'date') {
      return TextButton(
        child: Text(v is String && v.isNotEmpty ? v : 'Choisir'),
        onPressed: () async {
          final d = await showDatePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            initialDate: DateTime.now(),
          );
          if (d != null) {
            await repo.updateCell(row.id as String, col.id as String, DateFormat('yyyy-MM-dd').format(d));
          }
        },
      );
    }
    return SizedBox(
      width: kind == 'number' ? 90 : 140,
      child: TextFormField(
        initialValue: '${v ?? ''}',
        keyboardType: kind == 'number' ? TextInputType.number : TextInputType.text,
        decoration: const InputDecoration(isDense: true),
        onFieldSubmitted: (nv) => repo.updateCell(row.id as String, col.id as String, nv),
      ),
    );
  }
}

/// Dialogue ajout propriete : nom + type + options si select.
Future<void> showAddProp(BuildContext context, WidgetRef ref, String journalId) async {
  final name = TextEditingController();
  String kind = 'text';
  final opts = TextEditingController();
  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(builder: (c, setS) => AlertDialog(
          title: const Text('Nouvelle propriete'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom')),
            DropdownButton<String>(
              value: kind,
              items: const [
                DropdownMenuItem(value: 'text', child: Text('Texte')),
                DropdownMenuItem(value: 'number', child: Text('Nombre')),
                DropdownMenuItem(value: 'date', child: Text('Date')),
                DropdownMenuItem(value: 'select', child: Text('Selection')),
              ],
              onChanged: (v) => setS(() => kind = v!),
            ),
            if (kind == 'select')
              TextField(controller: opts, decoration: const InputDecoration(labelText: 'Options separees par ,')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                final options =
                    opts.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                await ref.read(repoProvider).addProperty(journalId, name.text, kind, options: options);
                if (c.mounted) Navigator.pop(c);
              },
              child: const Text('Ajouter'),
            ),
          ],
        )),
  );
}
