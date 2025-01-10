#!/bin/bash

PEER_ID="QmXen3eUHhywmutEzydCsW4hXBoeVmdET2FJvMX69XJ1Eo"
IP="127.0.0.1"
PORT="8231"
NUM=5

check_channels_ready() {
  local start_time=$(date +%s)
  local timeout=240

  while true; do
    # 等待5秒再次检查
    sleep 5

    # 直接在 curl 请求中构造 JSON 数据
    local states=$(curl -sS --location "http://$IP:$PORT" \
      --header "Content-Type: application/json" \
      -d "{
        \"id\": \"1\",
        \"jsonrpc\": \"2.0\",
        \"method\": \"list_channels\",
        \"params\": [{
          \"peer_id\": \"$PEER_ID\"
        }]
      }" | jq -r '.result.channels[].state.state_name')

    # 如果 states 为空，则继续等待
    if [[ -z "$states" ]]; then
      echo "Port $PORT states is empty, retrying..."
    else
      echo "Port $PORT states: $states"

      # 检查是否所有状态都为 CHANNEL_READY
      local all_ready=true
      for state in $states; do
        if [[ "$state" != "CHANNEL_READY" ]]; then
          all_ready=false
          break
        fi
      done

      # 如果所有状态都为 CHANNEL_READY，则退出
      if [[ "$all_ready" == "true" ]]; then
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
      exit 1
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
  curl --location "http://$IP:$PORT" --header "Content-Type: application/json" --data "$json_data"
  echo ""
  check_channels_ready
  wait_time=30
done
