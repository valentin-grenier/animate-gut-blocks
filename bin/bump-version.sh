#!/bin/bash
#
# Bumpe la version du plugin dans TOUS les fichiers concernés et, en option,
# insère une entrée dans la section « == Changelog == » de readme.txt.
#
# Usage :
#   bin/bump-version.sh <patch|minor|major|X.Y.Z> ["puce 1 | puce 2 | ..."]
#
# Source de vérité : le header « Version: » de simple-block-animations.php.
# Tous les messages d'info vont sur stderr ; SEULE la nouvelle version est
# écrite sur stdout (pour être capturée par la CI).

set -eu

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAIN_FILE="$PLUGIN_DIR/simple-block-animations.php"
README_FILE="$PLUGIN_DIR/readme.txt"
PACKAGE_FILE="$PLUGIN_DIR/package.json"

log() { echo "$@" >&2; }

if [ $# -lt 1 ]; then
    log "Usage: $0 <patch|minor|major|X.Y.Z> [changelog]"
    exit 1
fi

BUMP="$1"
CHANGELOG="${2:-}"

# --- Version actuelle (depuis le header du fichier principal) ---------------
CURRENT_VERSION="$(grep -iE '^[[:space:]]*\*[[:space:]]*Version:' "$MAIN_FILE" \
    | head -1 | sed -E 's/.*Version:[[:space:]]*//' | tr -d '[:space:]')"

if ! printf '%s' "$CURRENT_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    log "❌ Version actuelle introuvable ou invalide (lu: '$CURRENT_VERSION')"
    exit 1
fi
log "📌 Version actuelle : $CURRENT_VERSION"

# --- Calcul de la nouvelle version ------------------------------------------
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
case "$BUMP" in
    patch) NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))" ;;
    minor) NEW_VERSION="$MAJOR.$((MINOR + 1)).0" ;;
    major) NEW_VERSION="$((MAJOR + 1)).0.0" ;;
    *)
        if printf '%s' "$BUMP" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
            NEW_VERSION="$BUMP"
        else
            log "❌ Argument invalide : '$BUMP' (attendu patch|minor|major|X.Y.Z)"
            exit 1
        fi
        ;;
esac
log "🚀 Nouvelle version : $NEW_VERSION"

# --- Mise à jour des fichiers -----------------------------------------------
# Header « Version: » du fichier principal
sed -i -E "s/^([[:space:]]*\*[[:space:]]*Version:[[:space:]]*).*/\1$NEW_VERSION/" "$MAIN_FILE"

# Constante SIMPBLAN_VERSION
sed -i -E "s/(define\([[:space:]]*'SIMPBLAN_VERSION',[[:space:]]*')[^']*('[[:space:]]*\);)/\1$NEW_VERSION\2/" "$MAIN_FILE"

# « Stable tag: » de readme.txt
sed -i -E "s/^(Stable tag:[[:space:]]*).*/\1$NEW_VERSION/" "$README_FILE"

# Champ "version" de package.json (via Node pour garder un JSON valide)
node -e '
  const fs = require("fs");
  const f = process.argv[1];
  const p = JSON.parse(fs.readFileSync(f, "utf8"));
  p.version = process.argv[2];
  fs.writeFileSync(f, JSON.stringify(p, null, "\t") + "\n");
' "$PACKAGE_FILE" "$NEW_VERSION"

log "✅ Versions mises à jour (php header, SIMPBLAN_VERSION, readme.txt, package.json)"

# --- Changelog (optionnel) --------------------------------------------------
if [ -n "$CHANGELOG" ]; then
    ENTRY="= $NEW_VERSION ="$'\n'
    IFS='|' read -ra ITEMS <<< "$CHANGELOG"
    for item in "${ITEMS[@]}"; do
        item="$(printf '%s' "$item" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
        [ -z "$item" ] && continue
        if printf '%s' "$item" | grep -qE '^[*-]'; then
            ENTRY+="$item"$'\n'
        else
            ENTRY+="* $item"$'\n'
        fi
    done

    if grep -q '^== Changelog ==' "$README_FILE"; then
        awk -v entry="$ENTRY" '
            /^== Changelog ==/ {
                print $0
                print ""
                printf "%s", entry
                next
            }
            { print }
        ' "$README_FILE" > "$README_FILE.tmp" && mv "$README_FILE.tmp" "$README_FILE"
        log "✅ Entrée de changelog insérée dans readme.txt"
    else
        log "⚠️  Section « == Changelog == » introuvable, changelog ignoré"
    fi
fi

# --- Sortie : la nouvelle version (et rien d'autre) sur stdout --------------
printf '%s\n' "$NEW_VERSION"
