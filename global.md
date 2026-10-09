# global.md — myapp journal trading offline-first

## Description
- App Android Flutter, perso, style VS Code sombre.
- Page = titre + tableau seul. Table vide au depart, proprietes creees par user.
- Burger lateral : sections Journal (depliable en Journal 1...), Parametres.
- Top bar : burger + titre + login/sign.
- Page vide + bouton `+` centre pour creer journal. `+` aussi dans sous-section Journal.
- Corbeille a cote de chaque journal pour suppression.

## Technologies retenues
- Flutter stable, Material 3 dark custom VS Code (#1e1e1e, #252526, #007acc).
- Drift + sqlite3_flutter_libs : stockage local offline-first.
  - Tables : journals(id, name, created_at) / properties(id, journal_id, name, kind, options_json, order) / rows(id, journal_id, values_json, created_at).
  - kind : texte, nombre, date, selection.
- Supabase Auth email/mdp : session persistee (cache offline). Pas de sync V1.
- Riverpod pour state. GoRouter ou navigation simple par index (MVP simple).
- Avantages : Drift type, offline natif. Supabase simple. Inconvenients : Drift verbeux, Supabase Google Sign-In moins natif que Firebase.

## Module en cours
- M0 : repo + codespace — termine.
- M1 : shell VS Code (top bar, burger, navigation) — termine.
- M2 : CRUD journal + arborescence + suppression — termine.
- M3 : table dynamique + proprietes user — termine.
- M4 : footer somme/moyenne — termine.
- M5 : auth + parametres — termine.

## Backlog / V2
- Sync cloud Supabase DB, formules custom, stats trading, recherche, onglets, export CSV, multi-tableaux.
- Hors-version : toute demande hors MVP s'inscrit ici, on arrete et on discute.

## Contraintes
- Android only MVP. Offline-first. Pas de propriete preset. Code propre, zero duplication.
- Commandes codespace : `flutter pub get`, `flutter run`, `flutter analyze`, `dart run build_runner build`.
