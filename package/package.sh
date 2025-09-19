#!/bin/bash
set -euo pipefail

DEBUG_DIR="/home/ckb/scz/yukang/fiber"
DIR="/home/ckb/scz/fiber"
TMP_DIR="/home/ckb/scz/tmp"
PKG_DIR="$(cd "$(dirname "$0")" && pwd)"   # 当前脚本所在目录 (package)

# 用法: package.sh <channel> [fiber-branch] [commit-sha]
version="${1:?usage: $0 <channel> [fiber-branch] [commit-sha] }"
fiber_branch="${2:-}"
commit_sha="${3:-}"

# 1) 进入源码目录：debug 用 DEBUG_DIR，其它用 DIR
if [ "$version" = "debug" ]; then
  cd "$DEBUG_DIR"
else
  cd "$DIR"
fi

# 2) 选择提交/分支
git fetch --all --prune

if [ -n "$commit_sha" ] && [ -n "$fiber_branch" ]; then
  echo "[package] branch+commit 模式: branch=$fiber_branch, commit=$commit_sha"

  # 远端分支存在?
  if ! git show-ref --verify --quiet "refs/remotes/origin/$fiber_branch"; then
    echo "[package][ERROR] origin/$fiber_branch 不存在"; exit 1
  fi

  # 提交存在?
  if ! git cat-file -e "${commit_sha}^{commit}" 2>/dev/null; then
    echo "[package][ERROR] commit 不存在: $commit_sha"; exit 1
  fi

  # commit 是否属于该分支
  if git merge-base --is-ancestor "$commit_sha" "origin/$fiber_branch"; then
    echo "[package] 校验通过: $commit_sha ∈ origin/$fiber_branch"
  else
    echo "[package][ERROR] $commit_sha 不在 origin/$fiber_branch 的历史上"; exit 1
  fi

  git checkout --detach -f "$commit_sha"

elif [ -n "$commit_sha" ]; then
  echo "[package] 仅指定 commit: $commit_sha"
  if ! git cat-file -e "${commit_sha}^{commit}" 2>/dev/null; then
    echo "[package][ERROR] commit 不存在: $commit_sha"; exit 1
  fi
  git checkout --detach -f "$commit_sha"

elif [ -n "$fiber_branch" ]; then
  echo "[package] 仅指定分支: origin/$fiber_branch"
  git fetch origin "$fiber_branch" || true
  git reset --hard "origin/$fiber_branch"

else
  echo "[package] 未指定 commit/branch，默认对齐 origin/develop"
  git fetch origin develop || true
  git reset --hard origin/develop
fi

echo "[package] 当前提交: $(git rev-parse --short HEAD)"

# 3) 构建
cargo build --release

# 4) 准备打包
mkdir -p "$TMP_DIR"
cp ./target/release/fnn "$TMP_DIR/fnn"
# 可选：打包 fnn-migrate / config（存在才打）
[ -x ./target/release/fnn-migrate ] && cp ./target/release/fnn-migrate "$TMP_DIR/fnn-migrate"
[ -d ./config ] && rsync -a --delete ./config/ "$TMP_DIR/config/"

# 5) 从 fnn --version 提取信息生成包名
cd "$TMP_DIR"
ver_out="$(./fnn --version)"   # 例：fnn Fiber v0.6.0-rc5 (de94624 2025-09-18)
commit_short="$(echo "$ver_out" | sed -n 's/.*(\([0-9a-f]\{7,\}\) .*/\1/p')"
date_iso="$(echo "$ver_out"   | sed -n 's/.*(.* \([0-9-]\{10\}\)).*/\1/p')"
date_compact="${date_iso//-/}"

pkg="fnn_${version}_${date_compact}_${commit_short}-x86_64-linux-portable.tar.gz"

# 6) 打包（有啥打啥）
files=( "fnn" )
[ -x "$TMP_DIR/fnn-migrate" ] && files+=( "fnn-migrate" )
[ -d "$TMP_DIR/config" ]      && files+=( "config" )
tar czvf "$pkg" "${files[@]}"

# 7) 上传 tar 包（upload.py 在 TMP_DIR 中）
python3 "$TMP_DIR/upload.py" "$TMP_DIR/$pkg"

# 8) 更新并上传 fnn.conf（写入 package 目录）
CONF="$PKG_DIR/fnn.conf" bash "$PKG_DIR/fnn.sh" set "$version" "$commit_short" "$date_compact"
python3 "$TMP_DIR/upload.py" "$PKG_DIR/fnn.conf"

echo "Done: $pkg"
