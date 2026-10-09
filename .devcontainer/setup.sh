#!/bin/bash
set -e
# Installe Flutter stable dans ~/flutter si absent
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter
fi
export PATH="$PATH:$HOME/flutter/bin"
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> "$HOME/.bashrc"
flutter --disable-analytics
flutter precache --android
flutter config --enable-web
yes | flutter doctor --android-licenses
flutter doctor -v
if [ -f pubspec.yaml ]; then
  flutter pub get
  # android/ web/ crees a la main si besoin: flutter create --platforms=android,web .
  dart run build_runner build --delete-conflicting-outputs
fi
echo "Codespace pret. Lance: flutter run -d chrome / flutter run"
