import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import 'auth_gate.dart';

/// Shell style VS Code : top bar + burger lateral.
class Shell extends ConsumerStatefulWidget {
  const Shell({super.key, required this.journalPage, required this.settingsPage});
  final Widget journalPage;
  final Widget settingsPage;

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  int index = 0;
  bool journalsOpen = true;

  @override
  Widget build(BuildContext context) {
    final journalsAsync = ref.watch(journalsProvider);
    final selected = ref.watch(selectedJournalProvider);
    final selectedName = journalsAsync.when(
      data: (list) => list.firstWhere((j) => j.id == selected, orElse: () => list.firstOrNull)?.name,
      loading: () => null,
      error: (_, _) => null,
    );
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (c) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(c).openDrawer()),
        ),
        title: Text(index == 0 ? 'Journal${selectedName != null ? ' — $selectedName' : ''}' : 'Parametres'),
        actions: [
          AuthButton(compact: true),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('myapp', style: TextStyle(fontSize: 20))),
            ExpansionTile(
              initiallyExpanded: journalsOpen,
              onExpansionChanged: (v) => setState(() => journalsOpen = v),
              leading: const Icon(Icons.book),
              title: const Text('Journal'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () async {
                    final id = await ref.read(repoProvider).createJournal();
                    ref.read(selectedJournalProvider.notifier).state = id;
                    setState(() => index = 0);
                  },
                ),
              ]),
              children: [
                ...?journalsAsync.valueOrNull?.map((j) => ListTile(
                      dense: true,
                      selected: selected == j.id,
                      title: Text(j.name),
                      onTap: () {
                        ref.read(selectedJournalProvider.notifier).state = j.id;
                        setState(() => index = 0);
                        Navigator.pop(context);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _confirmDelete(context, ref, j.id, j.name),
                      ),
                    )),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Parametres'),
              selected: index == 1,
              onTap: () {
                setState(() => index = 1);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: index == 0 ? widget.journalPage : widget.settingsPage,
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer $name ?'),
        content: const Text('Suppression definitive, avec lignes et proprietes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              await ref.read(repoProvider).deleteJournal(id);
              if (ref.read(selectedJournalProvider) == id) {
                ref.read(selectedJournalProvider.notifier).state = null;
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
