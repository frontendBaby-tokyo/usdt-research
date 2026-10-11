#!/usr/bin/env bash
set -euo pipefail

RPC_URL="${ETH_RPC_URL:-https://cloudflare-eth.com}"
TRANSACTION_HASH="0x2f1c5c2b44f771e942a8506148e256f94f1a464babc938ae0690c6e34cd79190"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../results/deployment-verification"
OUTPUT_FILE="$OUTPUT_DIR/transaction-response.json"

mkdir -p "$OUTPUT_DIR"

response="$(curl -fsS "$RPC_URL" \
  -H "Content-Type: application/json" \
  --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionByHash\",\"params\":[\"$TRANSACTION_HASH\"],\"id\":1}")"

if ! jq -e --arg hash "$TRANSACTION_HASH" \
  '.id == 1 and (.result | type == "object" and (.hash | ascii_downcase) == ($hash | ascii_downcase))' \
  >/dev/null <<< "$response"; then
  echo "ERROR: Invalid or missing transaction in JSON-RPC response." >&2
  exit 1
fi

printf '%s\n' "$response" > "$OUTPUT_FILE"
echo "Saved: $OUTPUT_FILE"
