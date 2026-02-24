#!/bin/bash
set -e

echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable /tmp/flutter
export PATH="$PATH:/tmp/flutter/bin"

echo "Enabling web..."
flutter config --enable-web
flutter pub get

echo "Building..."
flutter build web --release
