#!/usr/bin/env sh
set -e

echo "🗑️  Limpiando JSON antiguos…"
rm -f /files/workflows/*.json         

echo "🔄  Exportando todos los workflows…"
n8n export:workflow \
  --all \
  --separate \
  --output /files/workflows \
  --pretty

echo "✅  Workflows actualizados en /files/workflows."