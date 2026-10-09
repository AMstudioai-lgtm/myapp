import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/db.dart';
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
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF007ACC),
          foregroundColor: Colors.white,
        ),
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
    final props = ref.watch(propsProvider(journalId));
    final rows = ref.watch(rowsProvider(journalId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            border: Border(bottom: BorderSide(color: Color(0xFF2D2D2D), width: 1)),
          ),
          child: Text(
            journalName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
        Expanded(
          child: props.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (cols) {
              if (cols.isEmpty) return _noProps(context, ref);
              return rows.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
                data: (lines) => _grid(context, ref, cols, lines),
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
        const Text('Table vide. Ajoute ta premiere propriete.', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF007ACC),
            foregroundColor: Colors.white,
          ),
          onPressed: () => showAddProp(context, ref, journalId),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter propriete'),
        ),
      ]),
    );
  }

  Widget _grid(BuildContext context, WidgetRef ref, List<Property> cols, List<EntryRow> lines) {
    final sums = _sums(cols, lines);
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF252526)),
              dataRowColor: WidgetStateProperty.all(const Color(0xFF1E1E1E)),
              columns: [
                for (final c in cols)
                  DataColumn(
                    label: Text(
                      '${c.name} (${c.kind})',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                const DataColumn(label: Text('')),
              ],
              rows: [
                for (final r in lines)
                  DataRow(cells: [
                    for (final c in cols)
                      DataCell(_cell(context, ref, r, c)),
                    DataCell(IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: Colors.white54,
                      tooltip: 'Supprimer la ligne',
                      onPressed: () => ref.read(repoProvider).deleteRow(r.id),
                    )),
                  ]),
                // Ligne footer calcul
                DataRow(
                  color: WidgetStateProperty.all(const Color(0xFF252526)),
                  cells: [
                    for (final c in cols)
                      DataCell(Text(
                        c.kind == 'number' ? 'Σ ${sums['${c.id}_sum'] ?? 0}  |  moy ${sums['${c.id}_avg'] ?? 0}' : '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF007ACC),
                        ),
                      )),
                    const DataCell(Text('')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFF252526),
          border: Border(top: BorderSide(color: Color(0xFF2D2D2D), width: 1)),
        ),
        child: Row(children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Color(0xFF3C3C3C)),
            ),
            onPressed: () => showAddProp(context, ref, journalId),
            icon: const Icon(Icons.view_column, size: 18),
            label: const Text('Propriete'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF007ACC),
              foregroundColor: Colors.white,
            ),
            onPressed: () => ref.read(repoProvider).addRow(journalId, {}),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ligne'),
          ),
        ]),
      ),
    ]);
  }

  Map<String, num> _sums(List<Property> cols, List<EntryRow> lines) {
    final out = <String, num>{};
    for (final c in cols) {
      if (c.kind != 'number') continue;
      num sum = 0, n = 0;
      for (final r in lines) {
        final map = decodeValues(r.valuesJson);
        final raw = map[c.id];
        final num? v = raw is num
            ? raw
            : (raw != null ? num.tryParse('$raw'.trim().replaceAll(',', '.')) : null);
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

  Widget _cell(BuildContext context, WidgetRef ref, EntryRow row, Property col) {
    final map = decodeValues(row.valuesJson);
    final v = map[col.id];
    final kind = col.kind;
    if (kind == 'select') {
      List<String> opts = const [];
      try {
        final decoded = jsonDecode(col.optionsJson);
        if (decoded is List) {
          opts = decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toSet().toList();
        }
      } catch (_) {
        opts = const [];
      }
      return DropdownButton<String>(
        value: v is String && opts.contains(v) ? v : null,
        hint: const Text('—', style: TextStyle(color: Colors.white38)),
        dropdownColor: const Color(0xFF252526),
        underline: const SizedBox(),
        isDense: true,
        items: [for (final o in opts) DropdownMenuItem(value: o, child: Text(o))],
        onChanged: (nv) => ref.read(repoProvider).updateCell(row.id, col.id, nv),
      );
    }
    if (kind == 'date') {
      final dateStr = v is String && v.isNotEmpty ? v : null;
      return TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          alignment: Alignment.centerLeft,
          foregroundColor: dateStr != null ? Colors.white : Colors.white38,
        ),
        child: Text(dateStr ?? 'Choisir'),
        onPressed: () async {
          DateTime initial = DateTime.now();
          if (dateStr != null) {
            final parsed = DateTime.tryParse(dateStr);
            if (parsed != null) initial = parsed;
          }
          final d = await showDatePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            initialDate: initial,
          );
          if (d != null) {
            await ref.read(repoProvider).updateCell(row.id, col.id, DateFormat('yyyy-MM-dd').format(d));
          }
        },
      );
    }
    return SizedBox(
      width: kind == 'number' ? 90 : 140,
      child: TextFormField(
        key: ValueKey('${row.id}_${col.id}_$v'),
        initialValue: '${v ?? ''}',
        keyboardType: kind == 'number'
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : TextInputType.text,
        decoration: const InputDecoration(isDense: true),
        onFieldSubmitted: (nv) {
          final trimmed = nv.trim();
          if (kind == 'number') {
            final parsed = num.tryParse(trimmed.replaceAll(',', '.'));
            ref.read(repoProvider).updateCell(row.id, col.id, parsed ?? (trimmed.isEmpty ? null : trimmed));
          } else {
            ref.read(repoProvider).updateCell(row.id, col.id, trimmed);
          }
        },
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
          backgroundColor: const Color(0xFF252526),
          title: const Text('Nouvelle propriete', style: TextStyle(color: Colors.white)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom')),
            const SizedBox(height: 12),
            DropdownButton<String>(
              isExpanded: true,
              dropdownColor: const Color(0xFF252526),
              value: kind,
              items: const [
                DropdownMenuItem(value: 'text', child: Text('Texte')),
                DropdownMenuItem(value: 'number', child: Text('Nombre')),
                DropdownMenuItem(value: 'date', child: Text('Date')),
                DropdownMenuItem(value: 'select', child: Text('Selection')),
              ],
              onChanged: (v) => setS(() => kind = v!),
            ),
            if (kind == 'select') ...[
              const SizedBox(height: 12),
              TextField(controller: opts, decoration: const InputDecoration(labelText: 'Options separees par ,')),
            ],
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF007ACC)),
              onPressed: () async {
                final propName = name.text.trim();
                if (propName.isEmpty) return;
                final options =
                    opts.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                if (kind == 'select' && options.isEmpty) return;
                await ref.read(repoProvider).addProperty(journalId, propName, kind, options: options);
                if (c.mounted) Navigator.pop(c);
              },
              child: const Text('Ajouter'),
            ),
          ],
        )),
  );
}
