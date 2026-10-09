import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

/// Bouton login/sign compact pour la top bar + gate email/mdp avec cache offline.
class AuthButton extends StatelessWidget {
  const AuthButton({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!hasSupabase) return const Chip(label: Text('Local'));
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (_, snap) {
        final user = snap.data?.session?.user;
        if (user == null) {
          return TextButton(
            child: Text(compact ? 'Login' : 'Login / Sign up'),
            onPressed: () => showDialog(context: context, builder: (_) => const _AuthDialog()),
          );
        }
        return TextButton(
          child: Text(user.email ?? 'Compte'),
          onPressed: () => Supabase.instance.client.auth.signOut(),
        );
      },
    );
  }
}

class _AuthDialog extends StatefulWidget {
  const _AuthDialog();
  @override
  State<_AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<_AuthDialog> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool login = true;
  String? err;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(login ? 'Login' : 'Sign up'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
        TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe')),
        if (err != null) Text(err!, style: const TextStyle(color: Colors.red)),
      ]),
      actions: [
        TextButton(
          onPressed: () => setState(() => login = !login),
          child: Text(login ? 'Creer compte' : 'Jai deja un compte'),
        ),
        FilledButton(
          onPressed: () async {
            try {
              if (login) {
                await Supabase.instance.client.auth.signInWithPassword(email: email.text.trim(), password: pass.text);
              } else {
                await Supabase.instance.client.auth.signUp(email: email.text.trim(), password: pass.text);
              }
              if (context.mounted) Navigator.pop(context);
            } on AuthException catch (e) {
              setState(() => err = e.message);
            }
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
