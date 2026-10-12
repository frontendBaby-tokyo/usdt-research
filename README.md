# USDTコントラクト調査

Ethereum Mainnet上のUSDTコントラクトを対象に、公開Solidityソースの構造、デプロイ時の引数、Runtime Bytecodeを調べた個人研究の記録です。エクスプローラの「Verified」表示だけに依存せず、JSON-RPCから取得したデータと手元で再生成したデータを比較しています。

対象アドレスは `0xdAC17F958D2ee523a2206206994597C13D831ec7`、比較に使ったコンパイラは Solidity `0.4.18`（optimizer無効）です。

## 調査の概要

- **ソースの構造**：ERC-20の基本機能に加え、送金手数料、停止、ブラックリスト、発行・償還、移行の実装と管理者権限を整理しました。
- **デプロイ時の引数**：作成トランザクションの `input` をJSON-RPCから取得してデコードし、初期供給量・名前・シンボル・小数桁数を確認しました。
- **公開ソースとチェーン上のコードの対応**：GitHubのソースを読む前に、オンチェーンのRuntime Bytecodeとソースをコンパイルした結果を比較しました。全体は一致せず、末尾のメタデータ43バイトを除いた実行コードが一致したため、このソースを以後の調査に使います。

## 調査ドキュメント

1. [コントラクトの構造と機能](docs/01-architecture.md)
2. [デプロイトランザクションとconstructor arguments](docs/02-deployment-arguments.md)
3. [GitHubのUSDTソースはチェーン上のコードと対応するか](docs/03-runtime-bytecode.md)

## USDTコントラクトのソースコードを読む

[`annotated/TetherToken.sol`](annotated/TetherToken.sol) には、ソースを読みながら調べたことを解説コメントとして残しています。[比較に使った原本](source/TetherToken.sol) に対し、コメント以外のコードは変更していません。チェーン上のコードとの比較には原本を使用しています。

## フォルダ構成

```text
usdt-research/
├── README.md
├── docs/
│   ├── 01-architecture.md            # ソースの構造と機能
│   ├── 02-deployment-arguments.md    # デプロイ時の引数
│   └── 03-runtime-bytecode.md        # 公開ソースとチェーン上のコードの比較
├── source/
│   └── TetherToken.sol               # 比較に使う原本
├── annotated/
│   └── TetherToken.sol               # 読みながら付けた解説コメント
├── scripts/                           # 取得・コンパイル・比較・デコード
└── results/
    ├── usdt-onchain.hex              # オンチェーンのRuntime Bytecode
    ├── compilation-output.txt        # コンパイル出力
    ├── usdt-compiled.hex             # ローカルのRuntime Bytecode
    └── deployment-verification/      # RPC応答と引数のデコード結果
```

手順と結果の詳細は各ドキュメントを参照してください。検証に使ったコマンドは [`scripts/`](scripts/) に、中間結果は [`results/`](results/) に保存しています。
