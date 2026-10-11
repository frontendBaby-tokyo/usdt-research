#!/usr/bin/env python3
"""Decode constructor string values using their ABI offsets and byte lengths."""

import json
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parent.parent
WORDS_FILE = PROJECT_DIR / "results/deployment-verification/constructor-arguments-words.json"
LENGTHS_FILE = PROJECT_DIR / "results/deployment-verification/constructor-string-lengths.json"
OUTPUT_FILE = PROJECT_DIR / "results/deployment-verification/constructor-strings.json"


def main():
    # 各wordのhexをバイト列に戻し、constructor arguments全体を元の並びで作る。
    words = json.loads(WORDS_FILE.read_text())["words"]
    arguments_data = b"".join(bytes.fromhex(word["hex"][2:]) for word in words)

    # 名前・オフセット・文字列長を使い、該当する文字列の範囲を決める。
    string_lengths = json.loads(LENGTHS_FILE.read_text())["stringLengths"]
    decoded_strings = []
    for string_length in string_lengths:
        # ABIではoffset位置の32バイトが長さ。その直後から実際の文字列が始まる。
        data_start = string_length["offsetBytes"] + 32
        data_end = data_start + string_length["lengthBytes"]

        # 指定された長さ分だけバイト列を取り出し、UTF-8文字列に変換する。
        value = arguments_data[data_start:data_end].decode("utf-8")
        decoded_strings.append(
            {
                "name": string_length["name"],
                "offsetBytes": string_length["offsetBytes"],
                "lengthBytes": string_length["lengthBytes"],
                "value": value,
            }
        )

    # デコードした文字列と参照した位置・長さをJSONに保存する。
    OUTPUT_FILE.write_text(json.dumps({"strings": decoded_strings}, indent=2) + "\n")
    print(f"Saved: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
