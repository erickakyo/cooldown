#!/bin/bash
# Compila o Cooldown e monta o bundle Cooldown.app (funciona só com
# Command Line Tools — não requer Xcode).
#
# Uso:
#   scripts/build.sh            # build release + monta dist/Cooldown.app
#   scripts/build.sh --run      # build + abre o app (desenvolvimento)
#   scripts/build.sh --install  # build + instala em /Applications e abre
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
APP="$ROOT/dist/Cooldown.app"

echo "▸ swift build (release)…"
swift build -c release

BIN="$(swift build -c release --show-bin-path)/Cooldown"

# ${VAR} com chaves: o bash 3.2 do macOS, em locale não-UTF-8, engole o
# primeiro byte de um caractere multibyte (…) colado no nome da variável.
echo "▸ Montando ${APP}…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Cooldown"
cp "$ROOT/Support/Info.plist" "$APP/Contents/Info.plist"

# Ícone (gera uma vez; delete dist/AppIcon.icns para regenerar)
if [ ! -f "$ROOT/dist/AppIcon.icns" ]; then
  echo "▸ Gerando ícone…"
  swift "$ROOT/scripts/make_icon.swift" "$ROOT/dist/AppIcon.icns"
fi
cp "$ROOT/dist/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

echo "▸ Assinando (ad-hoc)…"
codesign --force --deep --sign - "$APP"

echo "✅ Pronto: $APP"

if [ "${1:-}" = "--run" ]; then
  # Relança o app do zero (rodando direto de dist/ — fluxo de desenvolvimento)
  pkill -x Cooldown 2>/dev/null || true
  sleep 0.5
  open "$APP"
  echo "▸ Cooldown aberto — confira a barra de menus (ícone de floco de neve)."
fi

if [ "${1:-}" = "--install" ]; then
  DEST="/Applications/Cooldown.app"
  echo "▸ Instalando em ${DEST}…"
  pkill -x Cooldown 2>/dev/null || true
  sleep 0.5
  rm -rf "$DEST"
  cp -R "$APP" "$DEST"
  open "$DEST"
  echo "✅ Cooldown instalado em /Applications e aberto."
  echo "  Se 'Iniciar com o sistema' já estava ativo, desative e reative nas"
  echo "  configurações do app para o login item apontar pro novo caminho."
fi
