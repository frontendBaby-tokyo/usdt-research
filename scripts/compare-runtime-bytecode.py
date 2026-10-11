from pathlib import Path

onchain = Path("results/usdt-onchain.hex").read_text().strip()
compiled = Path("results/usdt-compiled.hex").read_text().strip()

# 末尾43バイト分のメタデータを除外
onchain_code = onchain[:-86]
compiled_code = compiled[:-86]

print("Runtime Bytecode (excluding metadata)")
print("MATCH:", onchain_code == compiled_code)