#!/bin/bash

# 判断是否传入参数，否则默认次数为1
if [ -z "$1" ]; then
  OPEN_CHANNEL_COUNT=1
else
  OPEN_CHANNEL_COUNT=$1
fi

# 参数校验：必须为正整数
if ! [[ "$OPEN_CHANNEL_COUNT" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: open_channel_count 必须为正整数。"
  usage
fi

check_channels_ready() {
  local port=$1
  local peer_id=$2
  local local_ip=$3
  local start_time=$(date +%s)
  local timeout=180

  while true; do
    # 直接在 curl 请求中构造 JSON 数据
    local states=$(curl -sS --location "http://$local_ip:$port" \
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
      exit 1
    fi

    # 等待5秒再次检查
    sleep 5
  done
}

PORTS=($(seq 8231 8238))

edge_0_peer_id="QmUf2ZSuGGBgFQEupTAAjGQbrhcRNoUXKwbHTdVMTGdEg3"
edge_39_peer_id="QmZEGQRyDfzAMUdV7QnncgdDZqkaiTy3fKvrvNd7hCBgEm"

open_channel_0_json_data=$(
  cat <<EOF
{
  "id": "%s",
  "jsonrpc": "2.0",
  "method": "open_channel",
  "params": [
    {
      "peer_id": "$edge_0_peer_id",
      "funding_amount": "0x174876e800",
      "public": true
    }
  ]
}
EOF
)

open_channel_39_json_data=$(
  cat <<EOF
{
  "id": "%s",
  "jsonrpc": "2.0",
  "method": "open_channel",
  "params": [
    {
      "peer_id": "$edge_39_peer_id",
      "funding_amount": "0x1bf08eb000",
      "public": true
    }
  ]
}
EOF
)

TZ=Asia/Shanghai date "+%Y-%m-%d %H:%M:%S"

current_ip=$(curl -s ifconfig.me)

if [ "$current_ip" == "18.167.71.41" ]; then
  port="${PORTS[0]}"
  json_data=$(printf "$open_channel_0_json_data" "$port")
  for ((j = 1; j <= OPEN_CHANNEL_COUNT; j++)); do
    curl -sS --location "http://172.31.23.160:$port" --header "Content-Type: application/json" --data "$json_data"
    echo ""
    check_channels_ready "$port" "$edge_0_peer_id" "172.31.23.160"
  done
elif [ "$current_ip" == "43.199.108.57" ]; then
  port="${PORTS[6]}"
  json_data=$(printf "$open_channel_39_json_data" "$port")
  for ((j = 1; j <= OPEN_CHANNEL_COUNT; j++)); do
    curl -sS --location "http://172.31.28.209:$port" --header "Content-Type: application/json" --data "$json_data"
    echo ""
    check_channels_ready "$port" "$edge_39_peer_id" "172.31.16.223"
  done
fi
