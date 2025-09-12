#!/bin/sh
set -e

# ==== 配置 ====
API2_URL="http://fiber-node2:8232"   # node2 的 JSON-RPC
API1_URL="http://fiber-node1:8231"   # node1 的 JSON-RPC（open_channel 用）
TOKEN="EpECCqYBCgVwZWVycwoIcGF5bWVudHMKCGNoYW5uZWxzCghpbnZvaWNlcxgDIgkKBwgAEgMYgAgiCQoHCAESAxiACCIJCgcIARIDGIEIIgkKBwgAEgMYgQgiCQoHCAESAxiCCCIJCgcIABIDGIIIIggKBggAEgIYGCIJCgcIARIDGIMIMiYKJAoCCBsSBggFEgIIBRoWCgQKAggFCggKBiCAwODoBgoEGgIIAhIkCAASIC3KNA3sQcH7HueRbBDT-Kg9Lmu5LwcEy-OMKcCvtVqRGkCg8T6TWf9HIT5nOfBjB0gelDJMwpIjM9utyJQ9JI3m3L5Sll2AJIPNajGsBy0Ywmkx0Z5VFT3n1SlHuWMM_wMFIiIKIMnzUSJrPnRIaFZYVjxVJu64vI-Oi81uftHSZWcuCZUQ"
PLACEHOLDER_PEER_ID="QmWECEVkMvn4j9gkMpWLFZw3aqNVVXzzgQ742JpfBDz8KW"

MAX_WAIT_SECONDS=180
SLEEP=1

# 与脚本同目录的 open_channel.sh
SCRIPT_DIR=$(dirname "$0")
OPEN_CHANNEL_PATH="$SCRIPT_DIR/open_channel.sh"
LIST_CHANNELS_PATH="$SCRIPT_DIR/list_channels.sh"
SHUTDOWN_CHANNEL_PATH="$SCRIPT_DIR/shutdown_channel.sh"

elapsed=0
while true
do
  if curl -s --connect-timeout 1 -o /dev/null "$API2_URL"; then
    break
  fi
  sleep "$SLEEP"
  elapsed=$((elapsed + SLEEP))
  [ "$elapsed" -ge "$MAX_WAIT_SECONDS" ] && { echo "timeout waiting $API2_URL"; exit 1; }
done
echo "fiber-node2 API is up."

echo "probing fiber-node1..."
elapsed=0
while true
do
  if curl -s --connect-timeout 1 -o /dev/null "$API1_URL"; then
    break
  fi
  sleep "$SLEEP"
  elapsed=$((elapsed + SLEEP))
  [ "$elapsed" -ge "$MAX_WAIT_SECONDS" ] && { echo "timeout waiting $API1_URL"; exit 1; }
done
echo "fiber-node1 API is up."

# ==== 拉取 node_info，拿第一条地址 ====
echo "fetching node_info from fiber-node2..."
addr=""
elapsed=0
while true
do
  resp=$(curl -sS "$API2_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"id":1,"jsonrpc":"2.0","method":"node_info","params":[]}' 2>/dev/null || true)

  addr=$(printf "%s\n" "$resp" | jq -r '.result.addresses // [] | .[]' 2>/dev/null | grep -v "/ws/" | head -n1 || true)

  if [ -n "$addr" ]; then
    echo "$addr"
    break
  fi

  sleep "$SLEEP"
  elapsed=$((elapsed + SLEEP))
  [ "$elapsed" -ge "$MAX_WAIT_SECONDS" ] && { echo "timeout waiting addresses"; exit 1; }
done

# ==== 提取 peer_id ====
peer_id=$(printf "%s\n" "$addr" | sed -n 's#.*/p2p/\(.*\)$#\1#p')
[ -n "$peer_id" ] || { echo "failed to extract peer_id from: $addr"; exit 1; }
echo "$peer_id"

# ==== 修改shutdown_channel.sh的peer_id ====
sed -i "s|$PLACEHOLDER_PEER_ID|$peer_id|g" "$SHUTDOWN_CHANNEL_PATH"

# ==== open_channel ====
[ -r "$OPEN_CHANNEL_PATH" ] || { echo "cannot read $OPEN_CHANNEL_PATH"; exit 1; }

# 直接替换后通过管道执行
sed "s|$PLACEHOLDER_PEER_ID|$peer_id|g" "$OPEN_CHANNEL_PATH" | sh
rc=$?

[ "$rc" -ne 0 ] && { echo "open_channel.sh failed with code $rc"; exit "$rc"; }

# ==== 先跑一次 list_channels ====
curl -sS 'http://172.30.0.1:8231' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d "$(printf '{"id":1,"jsonrpc":"2.0","method":"list_channels","params":[{"peer_id":"%s"}]}' "$peer_id")" \
  | jq .result
echo

# ==== list_channels 死循环 ====
while true; do
  current_time=$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")

  if [ -z "${LIST_CHANNELS_PATH:-}" ]; then
    echo "$current_time LIST_CHANNELS_PATH is empty"
  else
    output=$(sed "s|$PLACEHOLDER_PEER_ID|$peer_id|g" "$LIST_CHANNELS_PATH" | sh)
    if [ -z "$output" ]; then
      echo "$current_time list_channels output is empty"
    else
      echo "$current_time $output"
    fi
  fi
  sleep 10
done
