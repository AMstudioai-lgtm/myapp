import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/shell.dart';
import 'features/journal_page.dart';
import 'features/settings_page.dart';
import 'theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'myapp',
        theme: buildTheme(),
        home: const Shell(journalPage: JournalPage(), settingsPage: SettingsPage()),
      ),
    );
  }
}
