# Runtime Bytecodeの比較

Ethereum MainnetのUSDTコントラクト `0xdAC17F958D2ee523a2206206994597C13D831ec7` から取得したRuntime Bytecodeと、[`source/TetherToken.sol`](../source/TetherToken.sol) の `TetherToken` をSolidity `0.4.18`（optimizer無効）でコンパイルした結果を比較する。`pragma solidity ^0.4.17` は正確なコンパイラバージョンを固定しないため、このバージョンは今回採用した検証設定である。

## 結果

| 項目 | 記録した結果 |
| --- | --- |
| 両Hexテキストのサイズ | 各22,153 bytes |
| ファイル全体 | 不一致 |
| ソースを元に戻した後の最初の不一致 | 22,085文字目（1始まり） |
| 末尾のメタデータ43バイトを除いた比較 | 一致 |

オンチェーンのファイルSHA-256は `b00d39dc2106f6a78d26c8f5c3c225cc40717bb5b24250b638b41da97fafbfcb`。過去に記録したローカルファイルのSHA-256 `4921274fbcc17003a841fc9f444f4d00a5af91d012a8a29be3abeb6574dab70f` はソース編集時の結果を含むため、現行ファイルの対になる値として扱わない。

両バイトコード末尾には `a1 65 62 7a 7a 72 30 58 20 [32-byte Swarm hash] 00 29` という形式の領域がある。末尾の `0029` はCBOR本体の長さ41バイトを示し、長さの2バイトと合わせて43バイトとなる。[`compare-runtime-bytecode.py`](../scripts/compare-runtime-bytecode.py) は両Hex文字列の末尾86桁を除いて比較する。これはメタデータの構造を検証して自動的に切り分ける実装ではない。

この一致は主要な実行コードの再現を示すが、Runtime Bytecode全体の完全一致を示すものではない。メタデータもオンチェーンコードの一部である。

## 再現手順

macOSのターミナルで `curl`、`jq`、`awk`、`grep`、Docker、Python 3 とEthereum MainnetのJSON-RPCエンドポイントを用意する。リポジトリのルートから順に実行する。

```bash
bash scripts/fetch-usdt.sh
bash scripts/compile-usdt.sh
bash scripts/extract-bytecode.sh
python3 scripts/compare-runtime-bytecode.py
```

最初の3つのスクリプトは、RPCの `eth_getCode` で取得したコードを [`results/usdt-onchain.hex`](../results/usdt-onchain.hex) に、Docker上の `solc 0.4.18` によるコンパイル出力を [`results/compilation-output.txt`](../results/compilation-output.txt) に、抽出した `TetherToken` のRuntime Bytecodeを [`results/usdt-compiled.hex`](../results/usdt-compiled.hex) に保存する。

ファイル全体の比較には次のコマンドを使える。

```bash
wc -c results/usdt-onchain.hex results/usdt-compiled.hex
shasum -a 256 results/usdt-onchain.hex results/usdt-compiled.hex
cmp results/usdt-onchain.hex results/usdt-compiled.hex
```

## 今後の確認事項

- メタデータをCBORとしてデコードし、除外位置を機械的に確認する。
- ソースのコミットSHA、コンパイラの完全なビルド情報、取得ブロック番号を記録する。
- 別のRPCで取得したコードと比較し、メタデータハッシュ不一致の原因を調べる。
- `deprecated` と `upgradedAddress` の現在の状態を確認し、必要なら移行先を別途調べる。

この検証は公開ソースと取得したコードの比較であり、GitHubリポジトリの管理者の身元、現在のコントラクトの全動作、またはTether社による正式な認証を示すものではない。
