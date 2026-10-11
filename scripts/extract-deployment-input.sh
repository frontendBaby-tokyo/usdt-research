#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INPUT_FILE="$PROJECT_DIR/results/deployment-verification/transaction-response.json"
OUTPUT_FILE="$PROJECT_DIR/results/deployment-verification/transaction-input.hex"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "ERROR: Run scripts/get-deployment-transaction.sh first." >&2
  exit 1
fi

input="$(jq -er '
  .result.input
  | select(type == "string" and startswith("0x") and (length > 2) and (length % 2 == 0))
' "$INPUT_FILE")"

printf '%s\n' "$input" > "$OUTPUT_FILE"
echo "Saved: $OUTPUT_FILE"
