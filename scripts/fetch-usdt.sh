
#!/usr/bin/env bash
set -euo pipefail

# Ethereum Mainnet RPC
RPC_URL="https://ethereum-rpc.publicnode.com"

# USDT contract address (Ethereum Mainnet)
CONTRACT_ADDRESS="0xdAC17F958D2ee523a2206206994597C13D831ec7"

# 出力先（スクリプトの場所を基準にする）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../results"

# オンチェーンのRuntime Bytecodeを取得
curl -fsS "$RPC_URL" \
  -H "Content-Type: application/json" \
  --data "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"eth_getCode\",
    \"params\": [
      \"$CONTRACT_ADDRESS\",
      \"latest\"
    ],
    \"id\": 1
  }" | jq -er '.result | select(startswith("0x") and length > 2)' \
  > "$OUTPUT_DIR/usdt-onchain.hex"

echo "Saved: $OUTPUT_DIR/usdt-onchain.hex"
