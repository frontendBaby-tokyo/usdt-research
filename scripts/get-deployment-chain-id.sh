#!/usr/bin/env bash
set -euo pipefail

RPC_URL="${ETH_RPC_URL:-https://cloudflare-eth.com}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../results/deployment-verification"
OUTPUT_FILE="$OUTPUT_DIR/chain-id-response.json"

mkdir -p "$OUTPUT_DIR"

response="$(curl -fsS "$RPC_URL" \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}')"

if ! jq -e '.id == 1 and (.result | type == "string" and test("^0x[0-9a-fA-F]+$"))' \
  >/dev/null <<< "$response"; then
  echo "ERROR: Invalid JSON-RPC response for eth_chainId." >&2
  exit 1
fi

printf '%s\n' "$response" > "$OUTPUT_FILE"
echo "Saved: $OUTPUT_FILE"
