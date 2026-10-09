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
      data: (list) =>
          list.where((j) => j.id == selected).firstOrNull?.name ?? list.firstOrNull?.name,
      loading: () => null,
      error: (err, stack) => null,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252526),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: Builder(
          builder: (c) => IconButton(
            icon: const Icon(Icons.menu, size: 20),
            onPressed: () => Scaffold.of(c).openDrawer(),
          ),
        ),
        title: Text(
          index == 0 ? 'Journal${selectedName != null ? ' — $selectedName' : ''}' : 'Parametres',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFF2D2D2D)),
        ),
        actions: const [
          AuthButton(compact: true),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF252526),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 44, 16, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF2D2D2D), width: 1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.terminal, color: Color(0xFF007ACC), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'myapp',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ExpansionTile(
                    initiallyExpanded: journalsOpen,
                    onExpansionChanged: (v) => setState(() => journalsOpen = v),
                    leading: const Icon(Icons.book_outlined, size: 18),
                    title: const Text('Journal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    textColor: Colors.white,
                    collapsedTextColor: Colors.white70,
                    iconColor: const Color(0xFF007ACC),
                    collapsedIconColor: Colors.white54,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          color: const Color(0xFF007ACC),
                          tooltip: 'Nouveau journal',
                          onPressed: () async {
                            final id = await ref.read(repoProvider).createJournal();
                            ref.read(selectedJournalProvider.notifier).state = id;
                            setState(() => index = 0);
                          },
                        ),
                      ],
                    ),
                    children: [
                      ...?journalsAsync.valueOrNull?.map((j) => ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(left: 32, right: 8),
                            selected: selected == j.id && index == 0,
                            selectedTileColor: const Color(0xFF094771),
                            selectedColor: Colors.white,
                            leading: const Icon(Icons.description_outlined, size: 16),
                            title: Text(j.name, style: const TextStyle(fontSize: 13)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16),
                              color: Colors.white54,
                              hoverColor: const Color(0x33FF0000),
                              onPressed: () => _confirmDelete(context, ref, j.id, j.name),
                            ),
                            onTap: () {
                              ref.read(selectedJournalProvider.notifier).state = j.id;
                              setState(() => index = 0);
                              Navigator.pop(context);
                            },
                          )),
                    ],
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFF2D2D2D)),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.settings_outlined, size: 18),
                    title: const Text('Parametres', style: TextStyle(fontSize: 13)),
                    selected: index == 1,
                    selectedTileColor: const Color(0xFF094771),
                    selectedColor: Colors.white,
                    onTap: () {
                      setState(() => index = 1);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
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
        backgroundColor: const Color(0xFF252526),
        title: Text('Supprimer $name ?', style: const TextStyle(color: Colors.white)),
        content: const Text(
          'Suppression definitive, avec lignes et proprietes.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF007ACC)),
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
