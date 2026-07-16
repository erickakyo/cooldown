#!/bin/bash
# Gera o DMG e publica uma release no GitHub.
# Uso: scripts/release.sh            (usa a versão do Support/Info.plist)
#
# Pré-requisitos: build ok (scripts/build.sh) e gh autenticado.
# NOTA: enquanto o app for assinado ad-hoc (sem conta Apple Developer),
# o Gatekeeper vai alertar em outras máquinas. Para release "de verdade":
# assinar com Developer ID + notarizar antes do hdiutil.
set -euo pipefail

cd "$(dirname "$0")/.."
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Support/Info.plist)
DMG="dist/Cooldown-$VERSION.dmg"

./scripts/build.sh

echo "▸ Gerando $DMG…"
STAGE=$(mktemp -d)
cp -R dist/Cooldown.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -volname "Cooldown" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

echo "▸ Publicando release v$VERSION…"
gh release create "v$VERSION" "$DMG" \
  --title "Cooldown v$VERSION" \
  --notes "⏳ Cooldown v$VERSION — menu bar app that alerts you when your AI usage limit resets.

**Install:** download the DMG, drag Cooldown to Applications, allow notifications on first launch.
**Instalação:** baixe o DMG, arraste o Cooldown para Aplicativos e permita as notificações na primeira abertura.

> ⚠️ This build is not notarized yet — macOS may warn on first open (right-click → Open)."

echo "✅ Release v$VERSION publicada"
