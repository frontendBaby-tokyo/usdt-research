# GitHubのUSDTソースはチェーン上のコードと対応するか

## この検証の目的

GitHubで公開されている [`TetherToken.sol`](https://github.com/tethercoin/USDT/blob/main/TetherToken.sol) を読み進める前に、そのソースがEthereum Mainnet上のUSDTコントラクト `0xdAC17F958D2ee523a2206206994597C13D831ec7` と対応しているかを確かめた。リポジトリ内の比較対象は、取得済みの [`source/TetherToken.sol`](../source/TetherToken.sol) である。

Solidityのソースをそのままチェーン上のデータと比較することはできない。そこで、ソースをコンパイルして得た**Runtime Bytecode**（デプロイ後にコントラクトアドレスに置かれ、呼び出し時に実行されるコード）を、JSON-RPCで取得したチェーン上のRuntime Bytecodeと比較した。

## 比較条件と結果

ソースには `pragma solidity ^0.4.17` とあり、これだけではコンパイラの正確なバージョンは決まらない。[Etherscanの対象コントラクトの表示](https://etherscan.io/address/0xdAC17F958D2ee523a2206206994597C13D831ec7#code) に `v0.4.18+commit.9cf6e910`、optimizer無効と記載されているため、今回はDockerの `solc 0.4.18` をoptimizerを有効にせず使用した。この表示は設定を選ぶ参考情報であり、比較結果そのものの根拠ではない。

| 比較対象 | 結果 |
| --- | --- |
| Runtime Bytecode全体 | 不一致 |
| 両方の末尾43バイトを除いた範囲 | 一致 |

保存済みの2ファイルは各11,075バイトのコードを表し、先頭から11,032バイトが一致した。最初の不一致は、`0x` を含むHex文字列の22,086文字目（1始まり）で、末尾のメタデータ領域内にある。したがって、**今回調べた範囲では公開ソースからチェーン上の実行コードを再現できた**として、このソースを以後のコード調査に使う。ただし、Runtime Bytecode全体が完全一致したという意味ではない。

## 各スクリプトがすること

リポジトリのルートから、次の順番で実行する。`curl`、`jq`、`awk`、`grep`、Docker、Python 3 とEthereum MainnetへのJSON-RPC接続を使う。

| 順番 | スクリプト | 入力と処理 | 出力 |
| --- | --- | --- | --- |
| 1 | [`fetch-usdt.sh`](../scripts/fetch-usdt.sh) | 対象アドレスを指定してRPCの `eth_getCode` を呼ぶ | [`results/usdt-onchain.hex`](../results/usdt-onchain.hex)：チェーン上のRuntime Bytecode |
| 2 | [`compile-usdt.sh`](../scripts/compile-usdt.sh) | `source/TetherToken.sol` をDocker上の `solc 0.4.18` でコンパイルする | [`results/compilation-output.txt`](../results/compilation-output.txt)：各コントラクトを含むコンパイル出力 |
| 3 | [`extract-bytecode.sh`](../scripts/extract-bytecode.sh) | コンパイル出力から `TetherToken` のRuntime Bytecodeだけを取り出す | [`results/usdt-compiled.hex`](../results/usdt-compiled.hex)：比較するコンパイル済みコード |
| 4 | [`compare-runtime-bytecode.py`](../scripts/compare-runtime-bytecode.py) | 2つのHexファイルから、それぞれ末尾43バイトに相当する86桁を除いて比較する | 標準出力の `MATCH: True` または `False` |

```bash
bash scripts/fetch-usdt.sh
bash scripts/compile-usdt.sh
bash scripts/extract-bytecode.sh
python3 scripts/compare-runtime-bytecode.py
```

全体が一致するかは、別途次のコマンドで確認できる。

```bash
cmp results/usdt-onchain.hex results/usdt-compiled.hex
```

## なぜ末尾を除いたか

両コードの末尾43バイトには `a1 65 62 7a 7a 72 30 58 20 [32-byte Swarm hash] 00 29` という形式のメタデータ領域がある。末尾の `0029` はCBOR本体の長さ41バイトを示し、長さを示す2バイトを合わせると43バイトになる。今回の不一致はこの領域に収まる。

比較スクリプトはメタデータを解析して境界を見つけるものではなく、末尾86桁を固定で除外する。メタデータもオンチェーンコードの一部なので、この結果は「メタデータを除いた実行コードの一致」に限る。メタデータのハッシュが異なる理由は未確認である。
