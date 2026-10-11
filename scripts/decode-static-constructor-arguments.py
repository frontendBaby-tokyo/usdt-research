#!/usr/bin/env python3
"""Decode the uint256 constructor arguments from the saved ABI words."""

import json
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parent.parent
INPUT_FILE = PROJECT_DIR / "results/deployment-verification/constructor-arguments-words.json"
OUTPUT_FILE = PROJECT_DIR / "results/deployment-verification/constructor-arguments-static.json"
STATIC_ARGUMENTS = [
    {"wordIndex": 0, "name": "_initialSupply", "type": "uint256"},
    {"wordIndex": 3, "name": "_decimals", "type": "uint256"},
]


def main():
    words = json.loads(INPUT_FILE.read_text())["words"]
    decoded_arguments = []
    for argument in STATIC_ARGUMENTS:
        word_hex = words[argument["wordIndex"]]["hex"]
        # 32バイト語の16進数を整数として読み取り、uint256の10進数値にする
        decoded_arguments.append(
            {
                "wordIndex": argument["wordIndex"],
                "name": argument["name"],
                "type": argument["type"],
                "value": str(int(word_hex, 16)), # デコード
            }
        )

    OUTPUT_FILE.write_text(
        json.dumps({"decodedArguments": decoded_arguments}, indent=2) + "\n"
    )
    print(f"Saved: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
