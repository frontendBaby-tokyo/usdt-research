#!/usr/bin/env python3
"""Write the final eight ABI words from the saved deployment input."""

import json
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parent.parent
INPUT_FILE = PROJECT_DIR / "results/deployment-verification/transaction-input.hex"
OUTPUT_FILE = PROJECT_DIR / "results/deployment-verification/constructor-arguments-words.json"
WORD_HEX_LENGTH = 64
WORD_COUNT = 8


def main():
    input_hex = INPUT_FILE.read_text().strip()
    input_data = input_hex[2:]  # 先頭の "0x" を除き、16進データ部分だけにする
    candidate_length = WORD_HEX_LENGTH * WORD_COUNT
    candidate = input_data[-candidate_length:]
    words = []
    for index in range(WORD_COUNT):
        start = index * WORD_HEX_LENGTH
        word_hex = candidate[start : start + WORD_HEX_LENGTH]
        words.append(
            {
                "index": index,
                "byteOffset": index * 32,
                "hex": f"0x{word_hex}",
            }
        )

    OUTPUT_FILE.write_text(json.dumps({"words": words}, indent=2) + "\n")
    print(f"Saved: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
