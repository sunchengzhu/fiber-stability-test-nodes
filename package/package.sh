#!/bin/bash

DEBUG_DIR="/home/ckb/scz/yukang/fiber"
DIR="/home/ckb/scz/fiber"
TMP_DIR="/home/ckb/scz/tmp"
PKG_DIR="$(cd "$(dirname "$0")" && pwd)"   # 当前脚本所在目录 (package)

channel="${1:?usage: $0 <channel> [remote-branch] }"

if [ "$channel" = "debug" ]; then
  cd "$DEBUG_DIR" || exit 1
else
  cd "$DIR" || exit 1
fi

if [ -n "${2:-}" ]; then
  git reset --hard "origin/$2"
fi

git pull
cargo build --release

mkdir -p "$TMP_DIR"
cp ./target/release/fnn "$TMP_DIR/fnn"
cd "$TMP_DIR" || exit 1
./fnn --version

ver_out="$(./fnn --version)"   # 例：fnn Fiber v0.6.0-rc5 (de94624 2025-09-18)

commit="$(echo "$ver_out" | sed -n 's/.*(\([0-9a-f]\{7,\}\) .*/\1/p')"
date_iso="$(echo "$ver_out" | sed -n 's/.*(.* \([0-9-]\{10\}\)).*/\1/p')"
date_compact="${date_iso//-/}"

pkg="fnn_${channel}_${date_compact}_${commit}-x86_64-linux-portable.tar.gz"

tar czvf "$pkg" fnn fnn-migrate config
python3 upload.py "$pkg"

bash "$PKG_DIR/fnn.sh" set "$channel" "$commit" "$date_compact"
python3 "$TMP_DIR/upload.py" "$PKG_DIR/fnn.conf"

echo "Done: $pkg"
