# myapp — journal trading offline-first

Clone Notion minimal pour trader, souvent sans internet.

## Ouvrir dans Codespace
1. Ouvre ce repo sur GitHub.
2. `Code > Codespaces > Create codespace on main`.
3. Attends `setup.sh` : installe Flutter + Android SDK.
4. Dans le terminal codespace :
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome
# Android : flutter run (avec device) / flutter build apk
```

## Config Supabase (optionnel)
Sans cles, l app tourne en mode local.
```bash
flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co --dart-define=SUPABASE_KEY=eyJ...
```

## MVP
- Page vide + bouton `+` centre, `+` dans sous-section Journal.
- Journal depliable, suppression corbeille avec confirmation.
- Table vide, proprietes user : texte, nombre, date, selection.
- Footer somme / moyenne sur colonnes nombre.
- Parametres avec email connecte, cache offline.
