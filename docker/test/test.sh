#!/bin/sh
set -e

# ==== 配置 ====
API1_URL="http://fiber-node1:8231"
API2_URL="http://fiber-node2:8232"
API3_URL="http://fiber-node3:8233"
TOKEN="EpECCqYBCgVwZWVycwoIcGF5bWVudHMKCGNoYW5uZWxzCghpbnZvaWNlcxgDIgkKBwgAEgMYgAgiCQoHCAESAxiACCIJCgcIARIDGIEIIgkKBwgAEgMYgQgiCQoHCAESAxiCCCIJCgcIABIDGIIIIggKBggAEgIYGCIJCgcIARIDGIMIMiYKJAoCCBsSBggFEgIIBRoWCgQKAggFCggKBiCAwODoBgoEGgIIAhIkCAASIC3KNA3sQcH7HueRbBDT-Kg9Lmu5LwcEy-OMKcCvtVqRGkCg8T6TWf9HIT5nOfBjB0gelDJMwpIjM9utyJQ9JI3m3L5Sll2AJIPNajGsBy0Ywmkx0Z5VFT3n1SlHuWMM_wMFIiIKIMnzUSJrPnRIaFZYVjxVJu64vI-Oi81uftHSZWcuCZUQ"
PLACEHOLDER_PEER_ID="QmWECEVkMvn4j9gkMpWLFZw3aqNVVXzzgQ742JpfBDz8KW"
PLACEHOLDER_PEER_ID_NODE3="QmZPivdNrYkLowXCSTZtbba1kgqfgUWBsHo4AX3PoqJmnL"

MAX_WAIT_SECONDS=180
SLEEP=1

# 与脚本同目录的 open_channel.sh
SCRIPT_DIR=$(dirname "$0")
OPEN_CHANNEL_PATH="$SCRIPT_DIR/open_channel.sh"
OPEN_CHANNEL_PATH_13="$SCRIPT_DIR/13_open_channel.sh"
LIST_CHANNELS_PATH="$SCRIPT_DIR/list_channels.sh"
LIST_CHANNELS_CURRENT="/app/list_channels_current.sh"
SHUTDOWN_CHANNEL_PATH="$SCRIPT_DIR/shutdown_channel.sh"

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

echo "probing fiber-node2..."
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

echo "probing fiber-node3..."
elapsed=0
while true
do
  if curl -s --connect-timeout 1 -o /dev/null "$API3_URL"; then
    break
  fi
  sleep "$SLEEP"
  elapsed=$((elapsed + SLEEP))
  [ "$elapsed" -ge "$MAX_WAIT_SECONDS" ] && { echo "timeout waiting $API3_URL"; exit 1; }
done
echo "fiber-node3 API is up."

# ==== 从 fiber-node2 拿 peer_id（保持你的逻辑）====
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

  [ -n "$addr" ] && { echo "$addr"; break; }

  sleep "$SLEEP"
  elapsed=$((elapsed + SLEEP))
  [ "$elapsed" -ge "$MAX_WAIT_SECONDS" ] && { echo "timeout waiting addresses"; exit 1; }
done

peer_id_node2=$(printf "%s\n" "$addr" | sed -n 's#.*/p2p/\(.*\)$#\1#p')
[ -n "$peer_id_node2" ] || { echo "failed to extract peer_id from: $addr"; exit 1; }
echo "$peer_id_node2"

# ==== 从 fiber-node3 再拿一个 peer_id（用于第二个占位符）====
echo "fetching node_info from fiber-node3..."
addr3=""
elapsed=0
while true
do
  resp3=$(curl -sS "$API3_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"id":1,"jsonrpc":"2.0","method":"node_info","params":[]}' 2>/dev/null || true)

  addr3=$(printf "%s\n" "$resp3" | jq -r '.result.addresses // [] | .[]' 2>/dev/null | grep -v "/ws/" | head -n1 || true)

  [ -n "$addr3" ] && { echo "$addr3"; break; }

  sleep "$SLEEP"
  elapsed=$((elapsed + SLEEP))
  [ "$elapsed" -ge "$MAX_WAIT_SECONDS" ] && { echo "timeout waiting addresses (node3)"; exit 1; }
done

peer_id_node3=$(printf "%s\n" "$addr3" | sed -n 's#.*/p2p/\(.*\)$#\1#p')
[ -n "$peer_id_node3" ] || { echo "failed to extract peer_id from: $addr3"; exit 1; }
echo "$peer_id_node3"

# ==== 修改 shutdown_channel.sh 内的两个占位符（就地替换，不执行）====
sed -i \
  -e "s|$PLACEHOLDER_PEER_ID|$peer_id_node2|g" \
  -e "s|$PLACEHOLDER_PEER_ID_NODE3|$peer_id_node3|g" \
  "$SHUTDOWN_CHANNEL_PATH"

# ==== 修改 13_open_channel.sh 的 peer_id（不执行）====
sed -i "s|$PLACEHOLDER_PEER_ID_NODE3|$peer_id_node3|g" "$OPEN_CHANNEL_PATH_13"

# ==== open_channel：替换占位符后执行 ====
[ -r "$OPEN_CHANNEL_PATH" ] || { echo "cannot read $OPEN_CHANNEL_PATH"; exit 1; }
sed "s|$PLACEHOLDER_PEER_ID|$peer_id_node2|g" "$OPEN_CHANNEL_PATH" | sh
rc=$?
[ "$rc" -ne 0 ] && { echo "open_channel.sh failed with code $rc"; exit "$rc"; }

# ==== 先跑一次 list_channels ====
curl -sS 'http://172.30.0.1:8231' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d "$(printf '{"id":12,"jsonrpc":"2.0","method":"list_channels","params":[{"peer_id":"%s"}]}' "$peer_id_node2")" \
  | jq .result
echo

# ==== list_channels 死循环：两个占位符都替换 ====
while true; do
  current_time=$(TZ='Asia/Shanghai' date "+%Y-%m-%d %H:%M:%S")

  if [ -z "${LIST_CHANNELS_PATH:-}" ]; then
    echo "$current_time LIST_CHANNELS_PATH is empty"
  else
    sed -e "s|$PLACEHOLDER_PEER_ID|$peer_id_node2|g" \
        -e "s|$PLACEHOLDER_PEER_ID_NODE3|$peer_id_node3|g" \
        "$LIST_CHANNELS_PATH" > "$LIST_CHANNELS_CURRENT"

    chmod +x "$LIST_CHANNELS_CURRENT"

    output=$(sh "$LIST_CHANNELS_CURRENT")

    if [ -z "$output" ]; then
      echo "$current_time list_channels output is empty"
    else
      # 逐行对齐打印：第一行带时间戳，后续行用等宽空白占位
      width=19  # "%Y-%m-%d %H:%M:%S" 刚好 19 个字符
      first=1
      printf '%s\n' "$output" | while IFS= read -r line; do
        [ -z "$line" ] && continue
        if [ $first -eq 1 ]; then
          printf '%-*s %s\n' "$width" "$current_time" "$line"
          first=0
        else
          printf '%-*s %s\n' "$width" "" "$line"
        fi
      done
    fi
  fi

  sleep 10
done
