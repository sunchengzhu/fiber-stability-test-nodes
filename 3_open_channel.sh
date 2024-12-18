#!/bin/bash

check_channels_ready() {
  local port=$1
  local peer_id=$2
  local start_time=$(date +%s)
  local timeout=180

  while true; do
    # 直接在 curl 请求中构造 JSON 数据
    local states=$(curl -sS --location "http://127.0.0.1:$port" \
      --header "Content-Type: application/json" \
      -d "{
        \"id\": \"1\",
        \"jsonrpc\": \"2.0\",
        \"method\": \"list_channels\",
        \"params\": [{
          \"peer_id\": \"$peer_id\"
        }]
      }" | jq -r '.result.channels[].state.state_name')

    # 如果 states 为空，则继续等待
    if [[ -z "$states" ]]; then
      echo "Port $port states is empty, retrying..."
    else
      echo "Port $port states: $states"

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
      echo "超时：180秒内未所有通道都准备就绪。"
      return
    fi

    # 等待5秒再次检查
    sleep 5
  done
}

PORTS=(8227 8230 8232 8234 8236 8238 8240 8242)
id=1
addresses=()
peer_ids=()

for PORT in "${PORTS[@]}"; do
  response=$(curl -s -X POST http://127.0.0.1:"$PORT" \
    -H "Content-Type: application/json" \
    -d "$(printf '{
                 "id": %d,
                 "jsonrpc": "2.0",
                 "method": "node_info",
                 "params": []
             }' "$id")")
  if [ $? -eq 0 ]; then
    address=$(echo "$response" | jq -r '.result.addresses[]')
    addresses+=("$address")
    peer_id=$(echo "$response" | jq -r '.result.peer_id')
    peer_ids+=("$peer_id")
  else
    echo "Query to port $PORT failed."
  fi

  ((id++))
done

for addr in "${addresses[@]}"; do
  echo "$addr"
done

f_peer_id="${peer_ids[5]}"
g_peer_id="${peer_ids[6]}"

for i in 0 1 2 3 4 6; do
  port="${PORTS[i]}"

  json_data=$(
    cat <<EOF
{
  "id": "$port",
  "jsonrpc": "2.0",
  "method": "open_channel",
  "params": [
    {
      "peer_id": "$f_peer_id",
      "funding_amount": "0x174876e800",
      "public": true
    }
  ]
}
EOF
  )

  curl --location "http://127.0.0.1:$port" --header "Content-Type: application/json" --data "$json_data"
  echo ""
  check_channels_ready "$port" "$f_peer_id"
done

for i in 5 7; do
  port="${PORTS[i]}"

  json_data=$(
    cat <<EOF
{
  "id": "$port",
  "jsonrpc": "2.0",
  "method": "open_channel",
  "params": [
    {
      "peer_id": "$g_peer_id",
      "funding_amount": "0x1bf08eb000",
      "public": true
    }
  ]
}
EOF
  )

  curl --location "http://127.0.0.1:$port" --header "Content-Type: application/json" --data "$json_data"
  echo ""
  check_channels_ready "$port" "$g_peer_id"
done
