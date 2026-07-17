#!/bin/bash
# Números de uso do Cooldown SEM telemetria no app (promessa do README):
# downloads por release + tráfego do repositório. Cliques vindos do app
# aparecem no GA4 do site (utm_source=cooldown).
# Uso: scripts/stats.sh   (requer gh autenticado)
set -euo pipefail

REPO="erickakyo/cooldown"

echo "▸ Downloads por release:"
gh api "repos/$REPO/releases" \
  --jq '.[] | "  \(.tag_name)\t\(.assets[0].download_count // 0) downloads"'

echo ""
echo "▸ Tráfego do repositório (últimos 14 dias):"
gh api "repos/$REPO/traffic/views" \
  --jq '"  views:  \(.count) (\(.uniques) visitantes únicos)"' 2>/dev/null \
  || echo "  (requer acesso de push ao repositório)"
gh api "repos/$REPO/traffic/clones" \
  --jq '"  clones: \(.count) (\(.uniques) únicos)"' 2>/dev/null || true
