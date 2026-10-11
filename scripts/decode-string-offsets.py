#!/usr/bin/env python3
"""Decode the ABI offsets for the dynamic string constructor arguments."""

import json
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parent.parent
INPUT_FILE = PROJECT_DIR / "results/deployment-verification/constructor-arguments-words.json"
OUTPUT_FILE = PROJECT_DIR / "results/deployment-verification/constructor-string-offsets.json"
STRING_ARGUMENTS = [
    {"wordIndex": 1, "name": "_name"},
    {"wordIndex": 2, "name": "_symbol"},
]


def main():
    words = json.loads(INPUT_FILE.read_text())["words"]
    offsets = []
    for argument in STRING_ARGUMENTS:
        word_hex = words[argument["wordIndex"]]["hex"]
        # ABIの相対オフセットを32バイト語の16進数から整数に変換する
        offsets.append(
            {
                "wordIndex": argument["wordIndex"],
                "name": argument["name"],
                "offsetBytes": int(word_hex, 16),
            }
        )

    OUTPUT_FILE.write_text(json.dumps({"stringOffsets": offsets}, indent=2) + "\n")
    print(f"Saved: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
