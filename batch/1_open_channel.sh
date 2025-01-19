#!/bin/bash

PEER_ID="QmXen3eUHhywmutEzydCsW4hXBoeVmdET2FJvMX69XJ1Eo"
IP="127.0.0.1"
PORT="8231"
NUM=5

check_channels_ready() {
  local expected_count=$1
  local start_time=$(date +%s)
  local timeout=240

  while true; do
    # 等待5秒再次检查
    sleep 5

    local response=$(curl -sS --location "http://$IP:$PORT" \
      --header "Content-Type: application/json" \
      -d "{
        \"id\": \"1\",
        \"jsonrpc\": \"2.0\",
        \"method\": \"list_channels\",
        \"params\": [{
          \"peer_id\": \"$PEER_ID\"
        }]
      }")

    local state=$(echo "$response" | jq -r '.result.channels[0].state.state_name')
    local count=$(echo "$response" | jq '.result.channels | length')

    if [[ "$count" -ne "$expected_count" ]]; then
      echo "Expected $expected_count channels on port $PORT, but found $count. Retrying..."
    else
      echo "Port $PORT state: $state"
      if [[ "$state" == "CHANNEL_READY" ]]; then
        local current_time=$(date +%s)
        local elapsed_time=$((current_time - start_time))
        echo "所有通道都已准备就绪，总耗时：${elapsed_time}秒。"
        return
      fi
    fi

    # 计算已经过的时间
    local current_time=$(date +%s)
    local elapsed_time=$((current_time - start_time))

    # 超过时间限制则退出
    if [[ "$elapsed_time" -ge "$timeout" ]]; then
      echo "超时：240秒内未所有通道都准备就绪。"
      return
    fi
  done

}

json_data=$(
  cat <<EOF
{
  "id": "1",
  "jsonrpc": "2.0",
  "method": "open_channel",
  "params": [
    {
      "peer_id": "$PEER_ID",
      "funding_amount": "0xba43b7400",
      "public": true
    }
  ]
}
EOF
)

for ((i = 0; i < NUM; i++)); do
  channels_count=$(curl -sS --location "http://$IP:$PORT" \
    --header "Content-Type: application/json" \
    -d "{
          \"id\": \"1\",
          \"jsonrpc\": \"2.0\",
          \"method\": \"list_channels\",
          \"params\": [{
            \"peer_id\": \"$PEER_ID\"
          }]
        }" | jq '.result.channels | length')
  channel_number=$((channels_count + 1))
  echo "channel-$channel_number"
  curl --location "http://$IP:$PORT" --header "Content-Type: application/json" --data "$json_data"
  echo ""
  check_channels_ready "$channel_number"
done
