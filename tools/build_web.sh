#!/usr/bin/env bash
# Exporte la version Web du jeu dans le dossier docs/ (à publier sur GitHub Pages).
# Usage : bash tools/build_web.sh
set -euo pipefail
cd "$(dirname "$0")/.."
godot --headless --path . --import >/dev/null 2>&1 || true
rm -f docs/index.*
godot --headless --path . --export-release "Web" docs/index.html 2>&1 | grep -E "ERROR|error:" || true
ls -la docs/index.html docs/index.wasm docs/index.pck
