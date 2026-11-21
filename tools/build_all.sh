#!/usr/bin/env bash
# Lance TOUS les tests puis fabrique la version Web (docs/) et l'APK Android (dist/).
# Usage : bash tools/build_all.sh
set -euo pipefail
cd "$(dirname "$0")/.."

echo "━━ 1/4  Import du projet"
godot --headless --path . --import >/dev/null 2>&1 || true

echo "━━ 2/4  Tests de la logique du jeu"
godot --headless --path . --script res://tests/run_tests.gd 2>&1 | grep -E "✅|❌|   - |échec"

echo "━━ 3/4  Test d'interface (robot qui joue)"
MONKEY_GAMES="${MONKEY_GAMES:-40}" godot --headless --path . res://tests/ui_flow_test.tscn 2>&1 | grep -E "✅|❌|ERROR|✗"

echo "━━ 4/4  Exports"
rm -f docs/index.* dist/La-Caisse.apk dist/La-Caisse-web.zip dist/*.idsig
godot --headless --path . --export-release "Web" docs/index.html 2>&1 | grep -E "ERROR" || true
godot --headless --path . --export-release "Android" dist/La-Caisse.apk 2>&1 | grep -E "ERROR|Signed" || true
rm -f dist/*.idsig
# Archive du site Web (pour itch.io, Netlify Drop…)
python3 - <<'PY'
import os, zipfile
with zipfile.ZipFile("dist/La-Caisse-web.zip", "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for f in sorted(os.listdir("docs")):
        if f not in (".nojekyll", ".gdignore"):
            z.write(os.path.join("docs", f), f)
PY
ls -la docs/index.html docs/index.wasm docs/index.pck dist/La-Caisse.apk
echo "✅ Terminé."
