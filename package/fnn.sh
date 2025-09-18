#!/usr/bin/env bash
set -euo pipefail

# 单文件工具：读/写 fnn.conf + 下载&解压
# 环境变量：
#   CONF             配置文件路径（默认 ./fnn.conf）
#   FNN_BASE_URL     默认基础地址（首次初始化时写入）
#   FNN_ARCH         默认架构（首次初始化时写入）
#   FNN_OS           默认 OS（首次初始化时写入）

CONF="${CONF:-./fnn.conf}"
DEFAULT_BASE_URL="${FNN_BASE_URL:-http://github-test-logs.ckbapp.dev/fiber/}"
DEFAULT_ARCH="${FNN_ARCH:-x86_64}"
DEFAULT_OS="${FNN_OS:-linux}"

usage() {
  cat <<'EOF'
Usage:
  fnn.sh set <channel> <commit> [YYYYMMDD]   # 写入/更新 TARBALL_<channel>
  fnn.sh get <channel>                       # 读取包名
  fnn.sh url <channel>                       # 输出下载URL
  fnn.sh download <channel>                  # 下载并解压
  fnn.sh list                                # 列出所有渠道与包名

Notes:
  - 包名模板：fnn_<channel>_<YYYYMMDD>_<commit>-<arch>-<os>-portable.tar.gz
  - 配置文件为 KEY=VALUE 的 .env 风格，可被 source
  - 可通过环境变量覆盖配置路径：CONF=/path/to/fnn.conf fnn.sh ...
EOF
}

# 初始化配置文件（若不存在）
ensure_conf() {
  if [[ ! -f "$CONF" ]]; then
    {
      echo "FNN_BASE_URL=\"$DEFAULT_BASE_URL\""
      echo "FNN_ARCH=\"$DEFAULT_ARCH\""
      echo "FNN_OS=\"$DEFAULT_OS\""
      echo
      # 预留注释行，方便人工维护
      echo "# TARBALL_<channel>=\"fnn_<channel>_<YYYYMMDD>_<commit>-<arch>-<os>-portable.tar.gz\""
    } > "$CONF"
  fi
}

# 读取配置
load_conf() {
  # shellcheck disable=SC1090
  source "$CONF"
  FNN_BASE_URL="${FNN_BASE_URL:-$DEFAULT_BASE_URL}"
  FNN_ARCH="${FNN_ARCH:-$DEFAULT_ARCH}"
  FNN_OS="${FNN_OS:-$DEFAULT_OS}"
}

# 写入/更新某个键（整行替换或追加），跨 macOS/BSD 与 GNU 通用
set_kv() {
  local key="$1" val="$2"
  if grep -qE "^${key}=" "$CONF" 2>/dev/null; then
    awk -v k="$key" -v v="$val" '
      BEGIN{FS=OFS="="}
      $1==k {$0=k"=\""v"\""}
      {print}
    ' "$CONF" > "${CONF}.tmp" && mv "${CONF}.tmp" "$CONF"
  else
    echo "${key}=\"${val}\"" >> "$CONF"
  fi
}

# 间接取值：取变量 TARBALL_<channel>
get_tarball_from_conf() {
  local channel="$1"
  local key="TARBALL_${channel}"
  local varname="$key"
  local val="${!varname-}"
  echo "$key" "$val"
}

# 拼 URL（清理多余斜杠）
join_url() {
  local base="$1" path="$2"
  base="${base%/}/"
  echo "${base}${path}"
}

cmd="${1:-}"
case "$cmd" in
  set)
    # fnn.sh set <channel> <commit> [YYYYMMDD]
    channel="${2:-}"; commit="${3:-}"; date="${4:-}"
    [[ -n "$channel" && -n "$commit" ]] || { usage; exit 1; }
    date="${date:-$(date +%Y%m%d)}"

    ensure_conf
    load_conf

    # 生成包名
    tarball="fnn_${channel}_${date}_${commit}-${FNN_ARCH}-${FNN_OS}-portable.tar.gz"
    key="TARBALL_${channel}"

    echo "Setting ${key}=${tarball} in ${CONF}"
    set_kv "$key" "$tarball"
    echo "OK"
    ;;

  get)
    # fnn.sh get <channel>
    channel="${2:-}"
    [[ -n "$channel" ]] || { usage; exit 1; }
    [[ -f "$CONF" ]] || { echo "ERROR: config not found: $CONF" >&2; exit 1; }
    load_conf

    read -r key val < <(get_tarball_from_conf "$channel")
    [[ -n "${val:-}" ]] || { echo "ERROR: ${key} is empty or not set in $CONF" >&2; exit 1; }
    echo "$val"
    ;;

  url)
    # fnn.sh url <channel>
    channel="${2:-}"
    [[ -n "$channel" ]] || { usage; exit 1; }
    [[ -f "$CONF" ]] || { echo "ERROR: config not found: $CONF" >&2; exit 1; }
    load_conf

    read -r key val < <(get_tarball_from_conf "$channel")
    [[ -n "${val:-}" ]] || { echo "ERROR: ${key} is empty or not set in $CONF" >&2; exit 1; }
    join_url "$FNN_BASE_URL" "$val"
    ;;

  download)
    # fnn.sh download <channel>
    channel="${2:-}"
    [[ -n "$channel" ]] || { usage; exit 1; }
    [[ -f "$CONF" ]] || { echo "ERROR: config not found: $CONF" >&2; exit 1; }
    load_conf

    read -r key tarball < <(get_tarball_from_conf "$channel")
    [[ -n "${tarball:-}" ]] || { echo "ERROR: ${key} is empty or not set in $CONF" >&2; exit 1; }
    url="$(join_url "$FNN_BASE_URL" "$tarball")"

    echo "Downloading: $url"
    wget -q -O "$tarball" "$url" || { echo "ERROR: download failed"; exit 1; }

    echo "Extracting: $tarball"
    tar xzf "$tarball"
    echo "Done."
    ;;

  list)
    [[ -f "$CONF" ]] || { echo "ERROR: config not found: $CONF" >&2; exit 1; }
    awk -F= '/^TARBALL_[A-Za-z0-9_-]+=/{
      split($1,a,"_"); ch=a[2];
      gsub(/^"+|"+$/,"",$2); print ch " -> " $2
    }' "$CONF" | sort
    ;;

  ""|-h|--help|help)
    usage
    ;;

  *)
    echo "ERROR: unknown command: $cmd" >&2
    usage
    exit 1
    ;;
esac
