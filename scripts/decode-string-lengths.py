#!/usr/bin/env python3
"""Decode the byte lengths stored at the ABI offsets for constructor strings."""

import json
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parent.parent
WORDS_FILE = PROJECT_DIR / "results/deployment-verification/constructor-arguments-words.json"
OFFSETS_FILE = PROJECT_DIR / "results/deployment-verification/constructor-string-offsets.json"
OUTPUT_FILE = PROJECT_DIR / "results/deployment-verification/constructor-string-lengths.json"


def main():
    # ABI word一覧を読み込む。各wordには、引数領域の先頭からのbyteOffsetとhex値がある。
    words = json.loads(WORDS_FILE.read_text())["words"]

    # 文字列引数ごとの位置を読み込む。例: _nameはoffsetBytes=128。
    string_offsets = json.loads(OFFSETS_FILE.read_text())["stringOffsets"]
    string_lengths = []

    for string_offset in string_offsets:
        # この文字列の長さwordが置かれている、引数領域先頭からの位置を取得する。
        offset_bytes = string_offset["offsetBytes"]

        # その位置とbyteOffsetが一致するwordを探す。
        # 例: 128ならword[4]、192ならword[6]が見つかる。
        length_word = next(word for word in words if word["byteOffset"] == offset_bytes)

        # 見つけたwordのhex値（例: 0x...000a）を整数にし、文字列長の10バイトにする。
        length_bytes = int(length_word["hex"], 16)

        # 引数名、長さが書かれていたword番号、デコードした長さを結果に追加する。
        string_lengths.append(
            {
                "name": string_offset["name"],
                "offsetBytes": offset_bytes,
                "lengthWordIndex": length_word["index"],
                "lengthBytes": length_bytes,
            }
        )

    # 2つの文字列について集めた長さをJSONファイルに保存する。
    OUTPUT_FILE.write_text(json.dumps({"stringLengths": string_lengths}, indent=2) + "\n")
    print(f"Saved: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
