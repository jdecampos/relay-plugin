#!/usr/bin/env bash
#
# tikett-callback.sh — notifie Tikett qu'un PRD a été traité.
# Usage : tikett-callback.sh <prdId> <commit> [status]
#   status : done (défaut) | failed
#
# Lit tikettUrl + projectId depuis .ticket/config.json (committé) et la clé
# secrète depuis $TIKETT_DELIVERY_KEY (ou la ligne TIKETT_DELIVERY_KEY de
# .env.local, jamais committée). À lancer depuis la racine du repo.
set -euo pipefail

PRD_ID="${1:?usage: tikett-callback.sh <prdId> <commit> [status]}"
COMMIT="${2:?commit requis}"
STATUS="${3:-done}"
CONFIG=".ticket/config.json"

[ -f "$CONFIG" ] || { echo "tikett-callback: $CONFIG introuvable — lance depuis la racine du repo." >&2; exit 1; }

# Clé : env d'abord, sinon repli sur .env.local.
KEY="${TIKETT_DELIVERY_KEY:-}"
if [ -z "$KEY" ] && [ -f .env.local ]; then
  KEY=$(grep -E '^TIKETT_DELIVERY_KEY=' .env.local | tail -1 | cut -d= -f2-)
  KEY="${KEY%\"}"; KEY="${KEY#\"}"; KEY="${KEY%\'}"; KEY="${KEY#\'}"
fi
[ -n "$KEY" ] || { echo "tikett-callback: TIKETT_DELIVERY_KEY manquant — ajoute-le à .env.local." >&2; exit 1; }

TIKETT_URL=$(node -e "process.stdout.write((require('./$CONFIG').tikettUrl||'').replace(/\/+$/,''))")
PROJECT_ID=$(node -e "process.stdout.write(require('./$CONFIG').projectId||'')")
[ -n "$TIKETT_URL" ] || { echo "tikett-callback: tikettUrl absent de $CONFIG." >&2; exit 1; }

curl -fsS -X POST "$TIKETT_URL/api/delivery/callback" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d "{\"projectId\":\"$PROJECT_ID\",\"prdId\":\"$PRD_ID\",\"commit\":\"$COMMIT\",\"status\":\"$STATUS\"}" \
  && echo "tikett-callback: $PRD_ID → $STATUS ($COMMIT) envoyé à $TIKETT_URL"
