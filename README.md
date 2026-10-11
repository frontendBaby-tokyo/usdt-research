# USDT Runtime Bytecode Verification

Ethereumメインネット上のUSDTコントラクトのRuntime Bytecodeと、公開Solidityソースコードをローカルでコンパイルした結果を比較する個人研究プロジェクトです。

## 目的

EthereumのJSON-RPCから取得したオンチェーンコードと、公開ソースから再生成したコードを独立して比較し、**どの範囲が一致しているか**を再現可能な手順で確認します。Etherscanなどのエクスプローラに表示される「Verified」という判定だけには依存しません。

この検証は、GitHubリポジトリの管理者がTether社であること、デプロイ時のコンストラクタ引数・初期状態、またはコントラクトの現在の全動作を証明するものではありません。

## 調査ドキュメント

- [01: `TetherToken.sol` アーキテクチャ](docs/01-architecture.md)
- [02: USDTデプロイトランザクションとconstructor argumentsの検証](docs/02-deployment-arguments.md)

## 対象

- ネットワーク：Ethereum Mainnet（chain ID: `1`）
- USDTコントラクト：`0xdAC17F958D2ee523a2206206994597C13D831ec7`
- ソース候補：<https://github.com/tethercoin/USDT/blob/main/TetherToken.sol>
- 対象コントラクト名：`TetherToken`
- 検証用コンパイラ：Solidity `0.4.18`（optimizer無効）

> **注意**：`pragma solidity ^0.4.17` はコンパイラの正確なバージョンを固定しません。上記の `0.4.18` は今回の検証で採用した設定です。ソース取得時のコミットSHA、コンパイラのビルド情報、取得ブロック番号を追記すると、さらに再現性が上がります。

## ディレクトリ構成

```text
usdt-research/
├── README.md
├── scripts/
│   ├── fetch-usdt.sh              # RPC経由でデプロイ済みコードを取得
│   ├── compile-usdt.sh            # solcによるコンパイル
│   ├── extract-bytecode.sh        # TetherTokenのRuntime Bytecodeを抽出
│   ├── compare-runtime-bytecode.py # オンチェーンとローカルのコードを比較
│   ├── get-deployment-chain-id.sh # RPCからchain IDの応答を保存
│   ├── get-deployment-transaction.sh # デプロイトランザクションの応答を保存
│   ├── get-deployment-receipt.sh  # デプロイトランザクションのreceiptを保存
│   ├── extract-deployment-input.sh # 保存済み応答からinputを抽出
│   ├── split-constructor-arguments.py # input末尾の8つの32バイト語を分割
│   ├── decode-static-constructor-arguments.py # uint256引数を10進数に変換
│   ├── decode-string-offsets.py # 文字列引数のABIオフセットを変換
│   ├── decode-string-lengths.py # 文字列のバイト長を取得
│   └── decode-constructor-strings.py # 文字列引数をUTF-8としてデコード
├── source/
│   └── TetherToken.sol
└── results/
    ├── usdt-onchain.hex
    ├── compilation-output.txt
    ├── usdt-compiled.hex
    └── deployment-verification/
        ├── chain-id-response.json
        ├── transaction-response.json
        ├── receipt-response.json
        ├── transaction-input.hex
        ├── constructor-arguments-words.json
        ├── constructor-arguments-static.json
        ├── constructor-string-offsets.json
        ├── constructor-string-lengths.json
        └── constructor-strings.json
```

## 必要な環境

- macOSのターミナル（bash）
- `curl`、`jq`、`awk`、`grep`
- Docker（Solidity 0.4.18のイメージを実行するため）
- Python 3
- Ethereumメインネットへ接続できるJSON-RPCエンドポイント

## 実行手順

プロジェクトのルートディレクトリから、各ステップを**個別に**実行します。中間生成物は削除せずに保存します。

### STEP 1：オンチェーンのRuntime Bytecodeを取得

```bash
bash scripts/fetch-usdt.sh
```

生成物：`results/usdt-onchain.hex`

`eth_getCode` を使用して、指定アドレスのデプロイ済みコードを取得します。スクリプトが `latest` を指定している場合、取得した時点のブロック番号も別途記録することを推奨します。公開RPCの結果にはRPC提供者への信頼が伴うため、可能であれば別のRPCとも比較します。

### STEP 2：ソースコードをコンパイル

```bash
bash scripts/compile-usdt.sh
```

生成物：`results/compilation-output.txt`

Docker上の `solc 0.4.18` により `source/TetherToken.sol` を `--bin-runtime` でコンパイルします。Optimizerは無効です。この段階ではコンパイラのテキスト出力全体を残します。

### STEP 3：対象コントラクトのRuntime Bytecodeを抽出

```bash
bash scripts/extract-bytecode.sh
```

入力：`results/compilation-output.txt`  
生成物：`results/usdt-compiled.hex`

コンパイル結果に含まれる複数コントラクトから `TetherToken` のRuntime Bytecodeのみを取り出します。

### STEP 4：比較

```bash
python3 scripts/compare-runtime-bytecode.py
```

このスクリプトには、これまで手元で確認した**メタデータを除外した比較処理**を保存します。ファイルを作成しただけでは実行できないので、実装が必要です。

ファイル全体のサイズ・ハッシュ・最初の不一致位置は、次のコマンドでも確認できます。

```bash
wc -c results/usdt-onchain.hex results/usdt-compiled.hex
shasum -a 256 results/usdt-onchain.hex results/usdt-compiled.hex
cmp results/usdt-onchain.hex results/usdt-compiled.hex
```

### デプロイトランザクションの情報を段階的に取得

```bash
bash scripts/get-deployment-chain-id.sh
bash scripts/get-deployment-transaction.sh
bash scripts/get-deployment-receipt.sh
bash scripts/extract-deployment-input.sh
python3 scripts/split-constructor-arguments.py
python3 scripts/decode-static-constructor-arguments.py
python3 scripts/decode-string-offsets.py
python3 scripts/decode-string-lengths.py
python3 scripts/decode-constructor-strings.py
```

各スクリプトは一つの処理を行い、結果を`results/deployment-verification/`に保存します。最初の3つはJSON-RPCの応答全体を保存し、続くスクリプトで`input`を抽出し、末尾の8語を分割します。その後、固定長整数、文字列のオフセット、オフセットが指す文字列長、文字列本体を順にデコードします。順番に一つずつ実行し、生成ファイルの内容を確認しながら進めます。

既定ではCloudflare RPCを使用します。別のRPCを使う場合は各コマンドの前に`ETH_RPC_URL`を指定します。

```bash
ETH_RPC_URL="https://別のEthereum Mainnet RPC" bash scripts/get-deployment-transaction.sh
```

`split-constructor-arguments.py`は`input`末尾の8つの32バイト語をJSON配列に保存します。`decode-static-constructor-arguments.py`は固定長の`uint256`引数である`_initialSupply`と`_decimals`を10進数に変換し、`decode-string-offsets.py`は文字列引数の位置を示すABIオフセットをバイト数に変換します。`decode-string-lengths.py`はオフセット位置にあるwordから文字列の長さを読み取り、`decode-constructor-strings.py`はその直後から指定バイト数を取り出してUTF-8文字列に変換します。

```text
results/deployment-verification/constructor-arguments-words.json
results/deployment-verification/constructor-arguments-static.json
results/deployment-verification/constructor-string-offsets.json
results/deployment-verification/constructor-string-lengths.json
results/deployment-verification/constructor-strings.json
```

これらの処理にはPythonの標準機能を使い、外部ライブラリは追加していません。

## 今回の検証結果

以下はローカルでの実行結果として記録したものです。別の環境・別の取得時点では値が変わる可能性があります。

| 項目 | 結果 |
| --- | --- |
| オンチェーンのHexテキストサイズ | 22,153 bytes |
| ローカルコンパイルのHexテキストサイズ | 22,153 bytes |
| オンチェーンのファイルSHA-256 | `b00d39dc2106f6a78d26c8f5c3c225cc40717bb5b24250b638b41da97fafbfcb` |
| ローカルのファイルSHA-256（再編集前の実行） | `4921274fbcc17003a841fc9f444f4d00a5af91d012a8a29be3abeb6574dab70f` |
| ファイル全体の一致 | **不一致** |
| オリジナルソースに戻した後の最初の不一致位置 | 22,085文字目（1始まり） |
| 末尾のCBORメタデータ領域を除く比較 | **一致（`True`）** |

> **記録上の注意**：SHA-256の値はソースを編集していた時点の比較結果を含みます。ソースを元に戻した後の完全なSHA-256一式は未記録なので、再実行して追記してください。

### メタデータについて

今回の両バイトコード末尾には、次の形式の領域が確認されました。

```text
a1 65 62 7a 7a 72 30 58 20 [32-byte Swarm hash] 00 29
```

末尾の `0029` は16進数で41を表します。この形式ではCBOR本体が41バイトであり、長さを表す2バイトと合わせて**43バイト＝86桁のHex文字列**です。実際の比較では、先頭の `0x` と末尾改行を正規化した後、この領域を除いて比較し、`True` が得られました。

これは「実行ロジックに対応する主要なバイトコード領域が一致した」という強い証拠ですが、**Runtime Bytecode全体の完全再現とは異なります**。また、メタデータ領域もオンチェーンのコードの一部であり、厳密には観測可能です。

## 残っている検証課題

- [ ] SolidityメタデータをCBORとしてデコードし、除外位置を機械的に検証する
- [ ] ソースのコミットSHA、完全なコンパイラバージョン、使用したビルド設定を記録する
- [ ] 取得ブロック番号と別のRPCからの結果を記録する
- [ ] メタデータハッシュ不一致の原因（ソース内容・ファイル名・コンパイル方法等）を調べる
- [x] デプロイトランザクションとコンストラクタ引数を調査する
- [ ] `deprecated` / `upgradedAddress` のオンチェーン状態を確認し、委譲先がある場合は別途検証する
- [ ] JPYCの対象チェーン・コントラクトを特定し、同じ手順で比較する

## 参考資料

- [TetherToken.sol](https://github.com/tethercoin/USDT/blob/main/TetherToken.sol)
- [Solidity 0.4系のメタデータ仕様](https://docs.soliditylang.org/en/v0.4.17/metadata.html)
- [Ethereum JSON-RPC: eth_getCode](https://ethereum.org/en/developers/docs/apis/json-rpc/#eth_getcode)

## 免責

このプロジェクトは学習・検証を目的としています。監査報告書やTether社による正式な認証ではありません。
