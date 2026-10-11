
#!/usr/bin/env bash
set -euo pipefail

# ディレクトリ設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

INPUT_FILE="$PROJECT_DIR/results/compilation-output.txt"
OUTPUT_FILE="$PROJECT_DIR/results/usdt-compiled.hex"

# コンパイル結果からTetherTokenを抽出
awk '
  /^======= .*:TetherToken =======$/ {
    found=1
    next
  }
  found && /^Binary of the runtime part:/ {
    if (getline <= 0) exit 1
    print "0x" $0
    exit
  }
' "$INPUT_FILE" > "$OUTPUT_FILE"

# 抽出結果の確認
if ! grep -Eq '^0x([0-9a-fA-F]{2})+$' "$OUTPUT_FILE"; then
  echo "ERROR: Invalid bytecode." >&2
  exit 1
fi

echo "Extraction completed."
echo "Saved: $OUTPUT_FILE"
