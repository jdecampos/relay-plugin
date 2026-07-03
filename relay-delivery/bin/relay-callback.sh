#!/usr/bin/env bash
#
# relay-callback.sh — notifie Relay qu'un PRD a été traité.
# Usage : relay-callback.sh <prdId> <commit> [status]
#   status : done (défaut) | failed
#
# Lit relayUrl + projectId depuis .ticket/config.json (committé) et la clé
# secrète depuis $RELAY_DELIVERY_KEY (ou la ligne RELAY_DELIVERY_KEY de
# .env.local, jamais committée). À lancer depuis la racine du repo.
set -euo pipefail

PRD_ID="${1:?usage: relay-callback.sh <prdId> <commit> [status]}"
COMMIT="${2:?commit requis}"
STATUS="${3:-done}"
CONFIG=".ticket/config.json"

[ -f "$CONFIG" ] || { echo "relay-callback: $CONFIG introuvable — lance depuis la racine du repo." >&2; exit 1; }

# Clé : env d'abord, sinon repli sur .env.local.
KEY="${RELAY_DELIVERY_KEY:-}"
if [ -z "$KEY" ] && [ -f .env.local ]; then
  KEY=$(grep -E '^RELAY_DELIVERY_KEY=' .env.local | tail -1 | cut -d= -f2-)
  KEY="${KEY%\"}"; KEY="${KEY#\"}"; KEY="${KEY%\'}"; KEY="${KEY#\'}"
fi
[ -n "$KEY" ] || { echo "relay-callback: RELAY_DELIVERY_KEY manquant — ajoute-le à .env.local." >&2; exit 1; }

RELAY_URL=$(node -e "process.stdout.write((require('./$CONFIG').relayUrl||'').replace(/\/+$/,''))")
PROJECT_ID=$(node -e "process.stdout.write(require('./$CONFIG').projectId||'')")
[ -n "$RELAY_URL" ] || { echo "relay-callback: relayUrl absent de $CONFIG." >&2; exit 1; }

curl -fsS -X POST "$RELAY_URL/api/delivery/callback" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d "{\"projectId\":\"$PROJECT_ID\",\"prdId\":\"$PRD_ID\",\"commit\":\"$COMMIT\",\"status\":\"$STATUS\"}" \
  && echo "relay-callback: $PRD_ID → $STATUS ($COMMIT) envoyé à $RELAY_URL"
