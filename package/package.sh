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

echo "[package] params: version=$version branch=${fiber_branch:-<none>} commit=${commit_sha:-<none>}"

# 1) 进入源码目录
if [ "$version" = "debug" ]; then
  cd "$DEBUG_DIR"
else
  cd "$DIR"
fi
echo "[package] repo: $(pwd)"

# 2) 选择提交/分支（严格无 git pull）
git fetch --all --prune

if [ -n "$commit_sha" ] && [ -n "$fiber_branch" ]; then
  echo "[package] branch+commit 模式: branch=$fiber_branch, commit=$commit_sha"

  # 确认远端分支存在
  git show-ref --verify --quiet "refs/remotes/origin/$fiber_branch" || {
    echo "[ERROR] origin/$fiber_branch 不存在"; exit 1;
  }
  # 确认 commit 存在
  git cat-file -e "${commit_sha}^{commit}" 2>/dev/null || {
    echo "[ERROR] commit 不存在: $commit_sha"; exit 1;
  }
  # 确认 commit 属于该分支
  if git merge-base --is-ancestor "$commit_sha" "origin/$fiber_branch"; then
    echo "[package] $commit_sha ∈ origin/$fiber_branch"
  else
    echo "[ERROR] $commit_sha 不在 origin/$fiber_branch 的历史上"; exit 1
  fi
  git checkout --detach -f "$commit_sha"

elif [ -n "$commit_sha" ]; then
  echo "[package] 仅指定 commit: $commit_sha"
  git cat-file -e "${commit_sha}^{commit}" 2>/dev/null || {
    echo "[ERROR] commit 不存在: $commit_sha"; exit 1;
  }
  git checkout --detach -f "$commit_sha"

elif [ -n "$fiber_branch" ]; then
  echo "[package] 仅指定分支: origin/${fiber_branch}"

  # 强制刷新远端追踪分支，保证本地拿到的是远端最新（即便远端 rebase/force-push）
  if git rev-parse --is-shallow-repository >/dev/null 2>&1 && \
     [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
    git fetch --prune --depth=1 origin \
      "+refs/heads/${fiber_branch}:refs/remotes/origin/${fiber_branch}"
  else
    git fetch --prune origin \
      "+refs/heads/${fiber_branch}:refs/remotes/origin/${fiber_branch}"
  fi

  git reset --hard "origin/${fiber_branch}"

else
  echo "[package] 未指定 commit/branch，默认对齐 origin/develop"

  if git rev-parse --is-shallow-repository >/dev/null 2>&1 && \
     [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
    git fetch --prune --depth=1 origin \
      "+refs/heads/develop:refs/remotes/origin/develop"
  else
    git fetch --prune origin \
      "+refs/heads/develop:refs/remotes/origin/develop"
  fi

  git reset --hard origin/develop
fi

# 3) 打印并校验当前提交
current_full="$(git rev-parse HEAD)"
current_short="$(git rev-parse --short HEAD)"
echo "[package] current HEAD: $current_full ($current_short)"

if [ -n "$commit_sha" ]; then
  # 允许传入完整或前缀，只要前缀匹配即可
  case "$current_full" in
    "$commit_sha"*) : ;;  # ok
    *) echo "[ERROR] 当前 HEAD($current_full) 与传入 commit($commit_sha) 不一致"; exit 1 ;;
  esac
fi

# 4) 构建
cargo build --release

# 5) 准备打包
mkdir -p "$TMP_DIR"
cp ./target/release/fnn "$TMP_DIR/fnn"
[ -x ./target/release/fnn-migrate ] && cp ./target/release/fnn-migrate "$TMP_DIR/fnn-migrate"
[ -d ./config ] && rsync -a --delete ./config/ "$TMP_DIR/config/"

# 6) 从 fnn --version 取信息生成包名
cd "$TMP_DIR"
ver_out="$(./fnn --version)"   # e.g. fnn Fiber v0.6.0-rc5 (de94624 2025-09-18)
commit_short="$(echo "$ver_out" | sed -n 's/.*(\([0-9a-f]\{7,\}\) .*/\1/p')"
date_iso="$(echo "$ver_out"   | sed -n 's/.*(.* \([0-9-]\{10\}\)).*/\1/p')"
date_compact="${date_iso//-/}"

echo "[package] fnn --version: $ver_out"
echo "[package] parsed: date=$date_compact commit_short=$commit_short"

pkg="fnn_${version}_${date_compact}_${commit_short}-x86_64-linux-portable.tar.gz"

files=( "fnn" )
[ -x "$TMP_DIR/fnn-migrate" ] && files+=( "fnn-migrate" )
[ -d "$TMP_DIR/config" ]      && files+=( "config" )
echo "[package] tar -> $pkg  files: ${files[*]}"
tar czvf "$pkg" "${files[@]}"

# 7) 上传 tar 包
python3 "$TMP_DIR/upload.py" "$TMP_DIR/$pkg"

# 8) 更新并上传 fnn.conf（强制写到 package 目录）
CONF="$PKG_DIR/fnn.conf" bash "$PKG_DIR/fnn.sh" set "$version" "$commit_short" "$date_compact"
python3 "$TMP_DIR/upload.py" "$PKG_DIR/fnn.conf"

echo "[package] Done: $pkg"
