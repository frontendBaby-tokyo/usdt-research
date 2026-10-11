
#!/usr/bin/env bash
set -euo pipefail

# コンパイラのバージョン
SOLC_VERSION="0.4.18"

# プロジェクトのルートディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 出力先ディレクトリ
OUTPUT_DIR="$PROJECT_DIR/results"

# Dockerでコンパイル
docker run --rm \
  -v "$PROJECT_DIR:/src" \
  -w /src \
  "ethereum/solc:$SOLC_VERSION" \
  --bin-runtime source/TetherToken.sol \
  > "$OUTPUT_DIR/compilation-output.txt"

echo "Compilation completed."
