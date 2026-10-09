import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config.dart';
import 'data/db.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (hasSupabase) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  }
  final db = AppDb();
  runApp(
    ProviderScope(
      overrides: [dbProvider.overrideWithValue(db)],
      child: const MyApp(),
    ),
  );
}
