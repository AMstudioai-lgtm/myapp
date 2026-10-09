import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

/// Page Parametres : profil avec email connecte + infos stockage.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = hasSupabase ? Supabase.instance.client.auth.currentUser : null;
    return ListView(children: [
      const ListTile(title: Text('Profil', style: TextStyle(fontWeight: FontWeight.bold))),
      ListTile(
        leading: const Icon(Icons.person),
        title: Text(user?.email ?? 'Mode local (sans compte)'),
        subtitle: Text(user != null ? 'Connecte — session en cache offline' : 'Ajoute SUPABASE_URL/KEY pour activer login'),
      ),
      const Divider(),
      const ListTile(
        leading: Icon(Icons.storage),
        title: Text('Stockage local SQLite (Drift)'),
        subtitle: Text('Fonctionne sans internet. Sync cloud en V2.'),
      ),
    ]);
  }
}
