# USDTデプロイトランザクションとconstructor argumentsの検証

対象: Ethereum Mainnet上のUSDTコントラクト `0xdAC17F958D2ee523a2206206994597C13D831ec7`。Etherscanに表示された作成トランザクションとconstructor argumentsを、JSON-RPCから取得したトランザクションデータと照合する。

## 1. 結論

Etherscanで確認した作成トランザクションをJSON-RPCから取得し、その`input`末尾のconstructor argumentsをABIの規則に沿って分割・デコードした。CloudflareとdRPCの2つのRPCプロバイダーで確認した結果、トランザクションの作成先とconstructor argumentsはEtherscanの表示値に一致した。

| Constructor argument | RPCの`input`からデコードした値 | Etherscan表示値 |
| --- | --- | --- |
| `_initialSupply` (`uint256`) | `100000000000` | `100000000000` |
| `_name` (`string`) | `Tether USD` | `Tether USD` |
| `_symbol` (`string`) | `USDT` | `USDT` |
| `_decimals` (`uint256`) | `6` | `6` |

`_initialSupply`はトークンの最小単位での値である。`_decimals`が6なので、初期供給量は表示上`100000000000 / 10^6 = 100000 USDT`に相当する。

この結果は、指定した作成トランザクションに実際に含まれるconstructor argumentsがEtherscanの表示値と一致することを示す。

## 2. 対象と確認した情報

| 項目 | 確認値 |
| --- | --- |
| ネットワーク | Ethereum Mainnet（chain ID `1`） |
| コントラクト | `0xdAC17F958D2ee523a2206206994597C13D831ec7` |
| 作成トランザクション | `0x2f1c5c2b44f771e942a8506148e256f94f1a464babc938ae0690c6e34cd79190` |
| ブロック番号 | `0x46b87c` |
| 作成者 | `0x36928500bc1dcd7af6a2b4008875cc336b927d57` |
| Receipt status | `0x1`（成功） |
| Receiptの作成先 | `0xdac17f958d2ee523a2206206994597c13d831ec7` |
| RPCプロバイダー | Cloudflare (`cloudflare-eth.com`)、dRPC (`eth.drpc.org`) |

### Transactionとreceiptの役割

`eth_getTransactionByHash`はトランザクションの内容を返す。作成トランザクションの場合、`input`にはコントラクト作成用bytecodeとconstructor argumentsが含まれるため、デプロイ時に渡された引数を調べるときに使う。

`eth_getTransactionReceipt`はトランザクション実行後の結果を返す。今回の調査では、`status`で作成が成功したこと、`contractAddress`で作成先アドレスを確認するために使った。constructor argumentsやデプロイ時の`input`を調べるものではない。

## 3. Constructor argumentsのABI表現

対象constructorの引数は次の4つである。

```solidity
TetherToken(uint _initialSupply, string _name, string _symbol, uint _decimals)
```

`uint256`は32バイトのwordに値が入る。`string`は長さが固定ではないため、先頭の固定領域には文字列そのものではなく、文字列データの位置（オフセット）を置き、長さと文字列本体は後ろの動的データ領域に置く。

今回のconstructor argumentsは末尾にある8個の32バイトword、合計256バイトで構成される。これは8個のconstructor引数という意味ではなく、4つの引数のうち2つが動的型の文字列であり、位置情報と後ろの文字列データを使って表現されているためである。

| Word | Encoded value | ABI上の内容 | このデータでの意味 |
| --- | --- | --- | --- |
| `word[0]` | `000000000000000000000000000000000000000000000000000000174876e800` | `_initialSupply` | `100000000000` |
| `word[1]` | `0000000000000000000000000000000000000000000000000000000000000080` | `_name`のオフセット | 引数領域の先頭から128バイト |
| `word[2]` | `00000000000000000000000000000000000000000000000000000000000000c0` | `_symbol`のオフセット | 引数領域の先頭から192バイト |
| `word[3]` | `0000000000000000000000000000000000000000000000000000000000000006` | `_decimals` | `6` |
| `word[4]` | `000000000000000000000000000000000000000000000000000000000000000a` | `_name`の長さ | 10バイト |
| `word[5]` | `5465746865722055534400000000000000000000000000000000000000000000` | `_name`のデータ | `Tether USD`の10バイトとpadding |
| `word[6]` | `0000000000000000000000000000000000000000000000000000000000000004` | `_symbol`の長さ | 4バイト |
| `word[7]` | `5553445400000000000000000000000000000000000000000000000000000000` | `_symbol`のデータ | `USDT`の4バイトとpadding |

オフセットはconstructor arguments領域の先頭、すなわち`word[0]`の先頭から数える相対位置であり、長さwordの位置を指す。したがって、`_name`はオフセット128のwordに長さ10があり、その直後の位置160から10バイトを読む。`_symbol`はオフセット192のwordに長さ4があり、その直後の位置224から4バイトを読む。32バイトword末尾のpaddingは文字列長に含めない。

## 4. 確認手順と保存結果

確認は一つの処理を一つのスクリプトに分け、JSON-RPC応答と中間結果を`results/deployment-verification/`に保存した。プロジェクトルートから次の順に実行できる。

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

既定のRPCはCloudflare。別のEthereum Mainnet RPCを使う場合は、RPCを呼び出す各シェルスクリプトに`ETH_RPC_URL`を指定する。

| 出力ファイル | 内容 |
| --- | --- |
| [`chain-id-response.json`](../results/deployment-verification/chain-id-response.json) | `eth_chainId`のJSON-RPC応答 |
| [`transaction-response.json`](../results/deployment-verification/transaction-response.json) | `eth_getTransactionByHash`の応答全体 |
| [`receipt-response.json`](../results/deployment-verification/receipt-response.json) | `eth_getTransactionReceipt`の応答全体 |
| [`transaction-input.hex`](../results/deployment-verification/transaction-input.hex) | Transaction応答から抽出した`input` |
| [`constructor-arguments-words.json`](../results/deployment-verification/constructor-arguments-words.json) | `input`末尾から分割した8つのword |
| [`constructor-arguments-static.json`](../results/deployment-verification/constructor-arguments-static.json) | `_initialSupply`と`_decimals`のデコード結果 |
| [`constructor-string-offsets.json`](../results/deployment-verification/constructor-string-offsets.json) | `_name`と`_symbol`のオフセット |
| [`constructor-string-lengths.json`](../results/deployment-verification/constructor-string-lengths.json) | それぞれの文字列のバイト長 |
| [`constructor-strings.json`](../results/deployment-verification/constructor-strings.json) | UTF-8としてデコードした文字列 |

## 5. RPCで確認したTransaction情報

`eth_getTransactionByHash`と`eth_getTransactionReceipt`から、以下を確認した。

| 項目 | 値 |
| --- | --- |
| Mainnet chain ID | `1` |
| Transaction hash | `0x2f1c5c2b44f771e942a8506148e256f94f1a464babc938ae0690c6e34cd79190` |
| `to` | `null`（コントラクト作成Transaction） |
| Receipt status | `0x1` |
| Receipt `contractAddress` | `0xdac17f958d2ee523a2206206994597c13d831ec7` |
| `input`全体 | 11,900 bytes |
| 作成用bytecode部分 | 11,644 bytes |
| `input`のSHA-256 | `7e1bc86ef4e1d833671905d35f4a11d1f67e1c7ba29814acc0d8fc0217827ded` |

残り256バイトが8つのconstructor argument wordにあたる。ABIに従って再構成した引数データはTransaction `input`末尾と一致した。CloudflareとdRPCでTransaction hash、ブロック番号、作成Transactionであることを照合した。

## 6. 参考資料

- [Etherscan: USDT contract](https://etherscan.io/address/0xdAC17F958D2ee523a2206206994597C13D831ec7)
- [Etherscan: creation transaction](https://etherscan.io/tx/0x2f1c5c2b44f771e942a8506148e256f94f1a464babc938ae0690c6e34cd79190)
- [Ethereum JSON-RPC: `eth_getTransactionByHash`](https://ethereum.org/en/developers/docs/apis/json-rpc/#eth_gettransactionbyhash)
- [Ethereum JSON-RPC: `eth_getTransactionReceipt`](https://ethereum.org/en/developers/docs/apis/json-rpc/#eth_gettransactionreceipt)
- [Solidity ABI specification](https://docs.soliditylang.org/en/latest/abi-spec.html)
