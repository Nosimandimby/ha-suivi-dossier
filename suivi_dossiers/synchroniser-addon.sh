#!/usr/bin/env bash
# Recopie le code de l'application dans hass-addon/suivi_dossiers/app/.
#
# Home Assistant ne transmet au moteur de construction Docker que le dossier de
# l'add-on : les fichiers de l'application doivent donc y être présents. Lancez
# ce script depuis la racine du projet après toute modification du code,
# avant de publier / installer l'add-on.
set -euo pipefail

# Ce script doit être exécuté depuis la racine du projet (là où se trouvent
# main.py, database.py, etc.)
DEST="hass-addon/suivi_dossiers/app"

rm -rf "$DEST"
mkdir -p "$DEST"
cp main.py database.py seed.py chemins.py requirements.txt "$DEST"/
cp -r static "$DEST"/
find "$DEST" -name '__pycache__' -type d -prune -exec rm -rf {} +

echo "Add-on synchronisé : $DEST"