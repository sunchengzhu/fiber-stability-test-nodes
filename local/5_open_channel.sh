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

response2=$(curl -s -X POST http://127.0.0.1:8232 \
  -H "Content-Type: application/json" \
  -d '{
        "id": 1,
        "jsonrpc": "2.0",
        "method": "node_info",
        "params": []
      }')

if [ $? -eq 0 ]; then
  peer_id2=$(echo "$response2" | jq -r '.result.addresses[0]' | awk -F '/' '{print $NF}' | sed 's/0.0.0.0/127.0.0.1/')
  echo "Peer ID: $peer_id2"
else
  echo "Query to port 8232 failed."
fi

response3=$(curl -s -X POST http://127.0.0.1:8233 \
  -H "Content-Type: application/json" \
  -d '{
        "id": 1,
        "jsonrpc": "2.0",
        "method": "node_info",
        "params": []
      }')

if [ $? -eq 0 ]; then
  peer_id3=$(echo "$response3" | jq -r '.result.addresses[0]' | awk -F '/' '{print $NF}' | sed 's/0.0.0.0/127.0.0.1/')
  echo "Peer ID: $peer_id3"
else
  echo "Query to port 8233 failed."
fi

port1=8231
port2=8232
port3=8233

json_data12=$(
  cat <<EOF
{
  "id": "$port1",
  "jsonrpc": "2.0",
  "method": "open_channel",
  "params": [
    {
      "peer_id": "$peer_id2",
      "funding_amount": "0x4ae0da900",
      "public": true
    }
  ]
}
EOF
)

json_data23=$(
  cat <<EOF
{
  "id": "$port2",
  "jsonrpc": "2.0",
  "method": "open_channel",
  "params": [
    {
      "peer_id": "$peer_id3",
      "funding_amount": "0x4b4038a00",
      "public": true
    }
  ]
}
EOF
)

json_data32=$(
  cat <<EOF
{
  "id": "$port3",
  "jsonrpc": "2.0",
  "method": "open_channel",
  "params": [
    {
      "peer_id": "$peer_id2",
      "funding_amount": "0x4b9f96b00",
      "public": true
    }
  ]
}
EOF
)

curl --location "http://127.0.0.1:$port1" --header "Content-Type: application/json" --data "$json_data12"
echo ""
check_channels_ready "$port1" "$peer_id2"
sleep 30

curl --location "http://127.0.0.1:$port2" --header "Content-Type: application/json" --data "$json_data23"
echo ""
check_channels_ready "$port2" "$peer_id3"
sleep 30

if [ "$1" == "find" ]; then
  curl --location "http://127.0.0.1:$port3" --header "Content-Type: application/json" --data "$json_data32"
  echo ""
  check_channels_ready "$port3" "$peer_id2"
fi
