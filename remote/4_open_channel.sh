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
  local expected_count=$4   # 新增参数：期望通道数
  local start_time=$(date +%s)
  local timeout=240

  while true; do
    local response=$(
      curl -sS --location "http://$local_ip:$port" \
        --header "Content-Type: application/json" \
        -d "{
          \"id\": \"1\",
          \"jsonrpc\": \"2.0\",
          \"method\": \"list_channels\",
          \"params\": [{
            \"peer_id\": \"$peer_id\"
          }]
        }"
    )

    local states=$(echo "$response" | jq -r '.result.channels[].state.state_name')
    local count=$(echo "$response" | jq '.result.channels | length')

    if [[ -z "$states" || "$count" -eq 0 ]]; then
      echo "Port $port states is empty, retrying..."
    else
      echo "Port $port channel count: $count, states: $states"

      # 数量不够，继续等
      if (( count < expected_count )); then
        echo "Port $port 当前只有 $count/$expected_count 个通道，继续等待..."
      else
        local all_ready=true
        for state in $states; do
          if [[ "$state" != "CHANNEL_READY" ]]; then
            all_ready=false
            break
          fi
        done

        if [[ "$all_ready" == "true" ]]; then
          local current_time=$(date +%s)
          local elapsed_time=$((current_time - start_time))
          echo "所有 $count 个通道都已准备就绪，总耗时：${elapsed_time}秒。"
          return
        fi
      fi
    fi

    local current_time=$(date +%s)
    local elapsed_time=$((current_time - start_time))

    if [[ "$elapsed_time" -ge "$timeout" ]]; then
      echo "超时：240秒内未完成 $expected_count 个通道的准备。"
      exit 1
    fi

    sleep 5
  done
}

PORTS=($(seq 8231 8238))
peer_ids=()

for idx in "${!PORTS[@]}"; do
  PORT=${PORTS[idx]}
  if [ "$idx" -lt 5 ]; then
    ip="18.167.71.41"
  elif [ "$idx" -eq 5 ]; then
    ip="43.198.254.225"
  elif [ "$idx" -ge 6 ]; then
    ip="43.199.108.57"
  fi


  # 临时跳过特定端口，但要在 peer_ids 填充占位
  if [[ "$PORT" == "8232" || "$PORT" == "8233" || "$PORT" == "8234" || "$PORT" == "8235" || "$PORT" == "8238" ]]; then
#    echo "Skipping port $PORT (temporarily disabled)"
    peer_ids+=("skip")
    continue
  fi

  response=$(curl -s -X POST http://"$ip":"$PORT" \
    -H "Content-Type: application/json" \
    -d "$(printf '{
                 "id": %d,
                 "jsonrpc": "2.0",
                 "method": "node_info",
                 "params": []
             }' "$id")")
  if [ $? -eq 0 ]; then
    peer_id=$(echo "$response" | jq -r '.result.addresses[0]' | awk -F '/' '{print $NF}' | sed "s/0.0.0.0/$ip/")
    peer_ids+=("$peer_id")
  else
    echo "Query to port $PORT failed."
  fi
done

f_peer_id="${peer_ids[5]}"
g_peer_id="${peer_ids[6]}"

open_channel_f_json_data=$(
  cat <<EOF
{
  "id": "%s",
  "jsonrpc": "2.0",
  "method": "open_channel",
  "params": [
    {
      "peer_id": "$f_peer_id",
      "funding_amount": "0x174876e800",
      "public": true,
      "funding_fee_rate": "0x186a0"
    }
  ]
}
EOF
)

open_channel_g_json_data=$(
  cat <<EOF
{
  "id": "%s",
  "jsonrpc": "2.0",
  "method": "open_channel",
  "params": [
    {
      "peer_id": "$g_peer_id",
      "funding_amount": "0x1bf08eb000",
      "public": true,
      "funding_fee_rate": "0x186a0"
    }
  ]
}
EOF
)

TZ=Asia/Shanghai date "+%Y-%m-%d %H:%M:%S"

current_ip=$(curl -s ifconfig.me)

if [ "$current_ip" == "18.167.71.41" ]; then
  # for i in {0..4}; do
  for i in 0; do
    port="${PORTS[i]}"

    # 先记录当前已有的通道数
    local_ip="172.31.23.160"
    before_count=$(curl -sS --location "http://$local_ip:$port" \
      --header "Content-Type: application/json" \
      -d "{
        \"id\": \"1\",
        \"jsonrpc\": \"2.0\",
        \"method\": \"list_channels\",
        \"params\": [{
          \"peer_id\": \"$f_peer_id\"
        }]
      }" | jq '.result.channels | length')

    # 默认执行 1 次，只有 i 为 0 时执行 OPEN_CHANNEL_COUNT 次
    repeat_count=1
    if [ "$i" -eq 0 ]; then
      repeat_count=$OPEN_CHANNEL_COUNT
    fi

    json_data=$(printf "$open_channel_f_json_data" "$port")

    echo "准备在 port $port 上打开 $repeat_count 个通道（当前已有 $before_count 个）"

    # 先把所有 open_channel 请求发出去
    for ((j = 1; j <= repeat_count; j++)); do
      curl -sS --location "http://$local_ip:$port" \
        --header "Content-Type: application/json" \
        --data "$json_data"
      echo ""
    done

    # 然后等通道数达到 before_count + repeat_count 且全部 READY
    expected_total=$((before_count + repeat_count))
    check_channels_ready "$port" "$f_peer_id" "$local_ip" "$expected_total"
  done
  # for i in {0..4}; do
  #   port="${PORTS[i]}"
  #   check_channels_ready "$port" "$f_peer_id"
  # done
elif [ "$current_ip" == "43.198.254.225" ]; then
  port="${PORTS[5]}"
  json_data=$(printf "$open_channel_g_json_data" "$port")
  for ((j = 1; j <= OPEN_CHANNEL_COUNT; j++)); do
    curl -sS --location "http://172.31.28.209:$port" --header "Content-Type: application/json" --data "$json_data"
    echo ""
    check_channels_ready "$port" "$g_peer_id" "172.31.28.209"
  done
#elif [ "$current_ip" == "43.199.108.57" ]; then
#  port1="${PORTS[6]}"
#  json_data1=$(printf "$open_channel_f_json_data" "$port1")
#  curl -sS --location "http://172.31.16.223:$port1" --header "Content-Type: application/json" --data "$json_data1"
#  echo ""
#  check_channels_ready "$port1" "$f_peer_id"

#  port2="${PORTS[7]}"
#  json_data2=$(printf "$open_channel_g_json_data" "$port2")
#  curl -sS --location "http://172.31.16.223:$port2" --header "Content-Type: application/json" --data "$json_data2"
#  check_channels_ready "$port2" "$g_peer_id"
fi
