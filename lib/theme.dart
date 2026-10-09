import 'package:flutter/material.dart';

ThemeData buildTheme() {
  const bg = Color(0xFF1E1E1E);
  const panel = Color(0xFF252526);
  const accent = Color(0xFF007ACC);
  final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark).copyWith(
    surface: bg,
    primary: accent,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    appBarTheme: const AppBarTheme(backgroundColor: panel, foregroundColor: Colors.white70),
    drawerTheme: const DrawerThemeData(backgroundColor: panel),
    cardColor: panel,
  );
}
