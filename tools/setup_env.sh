#!/usr/bin/env bash
# Prépare une machine Linux vierge (ex. une session Claude Code dans le cloud) pour
# tester et exporter « La Caisse » : Godot 4.4.1, modèles d'export, et un mini « SDK Android »
# suffisant pour signer l'APK. À lancer une seule fois : bash tools/setup_env.sh
set -euo pipefail

GODOT_VERSION="4.4.1-stable"
GODOT_DIR="/opt/godot-dl"
TEMPLATES_DIR="$HOME/.local/share/godot/export_templates/4.4.1.stable"
SDK_DIR="/opt/android-sdk"
BASE="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}"

mkdir -p "$GODOT_DIR"
if ! command -v godot >/dev/null; then
  echo "→ Téléchargement de Godot…"
  curl -sL -o "$GODOT_DIR/godot.zip" "$BASE/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
  unzip -o -q "$GODOT_DIR/godot.zip" -d "$GODOT_DIR"
  chmod +x "$GODOT_DIR/Godot_v${GODOT_VERSION}_linux.x86_64"
  ln -sf "$GODOT_DIR/Godot_v${GODOT_VERSION}_linux.x86_64" /usr/local/bin/godot
fi

if [ ! -f "$TEMPLATES_DIR/web_release.zip" ]; then
  echo "→ Téléchargement des modèles d'export (~1,2 Go)…"
  curl -sL -o "$GODOT_DIR/templates.tpz" "$BASE/Godot_v${GODOT_VERSION}_export_templates.tpz"
  mkdir -p "$TEMPLATES_DIR" "$GODOT_DIR/tpl"
  unzip -o -q "$GODOT_DIR/templates.tpz" -d "$GODOT_DIR/tpl"
  cp -r "$GODOT_DIR"/tpl/templates/* "$TEMPLATES_DIR/"
  rm -rf "$GODOT_DIR/templates.tpz" "$GODOT_DIR/tpl"
fi

echo "→ Outils de signature Android (apksigner, zipalign, adb)…"
apt-get update -qq && apt-get install -y -qq openjdk-21-jdk-headless apksigner zipalign adb unzip >/dev/null

# Godot veut un dossier qui ressemble à un SDK Android : on lui en fabrique un minimal.
mkdir -p "$SDK_DIR/platform-tools" "$SDK_DIR/build-tools/35.0.1" "$SDK_DIR/cmdline-tools/latest/bin"
ln -sf /usr/bin/adb "$SDK_DIR/platform-tools/adb"
ln -sf /usr/bin/apksigner "$SDK_DIR/build-tools/35.0.1/apksigner"
ln -sf /usr/bin/zipalign "$SDK_DIR/build-tools/35.0.1/zipalign"
printf '#!/bin/sh\nexit 0\n' > "$SDK_DIR/cmdline-tools/latest/bin/sdkmanager"
chmod +x "$SDK_DIR/cmdline-tools/latest/bin/sdkmanager"

# Premier lancement de Godot pour créer ses réglages, puis on y inscrit les chemins Android.
cd "$(dirname "$0")/.."
godot --headless --path . --import >/dev/null 2>&1 || true
SETTINGS="$HOME/.config/godot/editor_settings-4.4.tres"
if [ -f "$SETTINGS" ]; then
  sed -i "s#export/android/android_sdk_path = \".*\"#export/android/android_sdk_path = \"$SDK_DIR\"#" "$SETTINGS"
  JAVA_HOME_GUESS="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"
  sed -i "s#export/android/java_sdk_path = \".*\"#export/android/java_sdk_path = \"$JAVA_HOME_GUESS\"#" "$SETTINGS"
fi
echo "✅ Environnement prêt."
