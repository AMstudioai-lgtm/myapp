#!/bin/bash
set -e
# Installe Flutter stable dans ~/flutter si absent
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter
fi
export PATH="$PATH:$HOME/flutter/bin"
flutter --disable-analytics || true
flutter precache --android || true
flutter config --enable-web || true
yes | flutter doctor --android-licenses || true
flutter doctor -v || true
if [ -f pubspec.yaml ]; then
  flutter pub get || true
  if [ ! -d android ]; then
    flutter create --platforms=android,web --project-name myapp . || true
    flutter pub get || true
  fi
  dart run build_runner build --delete-conflicting-outputs || true
fi
echo "Codespace pret. Lance: flutter run -d chrome / flutter run"
