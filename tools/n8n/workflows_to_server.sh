#!/usr/bin/env sh
set -e

echo "📥  Importando workflows desde /files/workflows …"
n8n import:workflow \
  --input /files/workflows \
  --separate

echo "✅  Base de datos n8n actualizada."