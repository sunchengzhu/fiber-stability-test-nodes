#!/bin/bash

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
    peer_ids+=("skip")
    continue
  fi

  response=$(curl -s -X POST "http://$ip:$PORT" \
    -H "Content-Type: application/json" \
    -d '{
          "id": 1,
          "jsonrpc": "2.0",
          "method": "node_info",
          "params": []
        }')
  if [ $? -eq 0 ]; then
    peer_id=$(echo "$response" | jq -r '.result.addresses[0]' | awk -F '/' '{print $NF}' | sed "s/0.0.0.0/$ip/")
    peer_ids+=("$peer_id")
  else
    echo "Query to port $PORT failed."
  fi
done

f_peer_id="${peer_ids[5]}"
g_peer_id="${peer_ids[6]}"

current_ip=$(curl -s ifconfig.me)

list_channels_f_json_data=$(
  cat <<EOF
{
  "id": "%s",
  "jsonrpc": "2.0",
  "method": "list_channels",
  "params": [
    {
      "peer_id": "$f_peer_id"
    }
  ]
}
EOF
)

list_channels_g_json_data=$(
  cat <<EOF
{
  "id": "%s",
  "jsonrpc": "2.0",
  "method": "list_channels",
  "params": [
    {
      "peer_id": "$g_peer_id"
    }
  ]
}
EOF
)

shutdown_channel_json_template='{
  "id": "%s",
  "jsonrpc": "2.0",
  "method": "shutdown_channel",
  "params": [
    {
      "channel_id": "%s",
      "close_script": {
        "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
        "hash_type": "type",
        "args": "%s"
      },
      "fee_rate": "0x3FC"
    }
  ]
}'

if [ "$current_ip" == "18.167.71.41" ]; then
  #  for i in 0 1 2 3 4; do
  for i in 0; do
    port="${PORTS[i]}"
    json_data=$(printf "$list_channels_f_json_data" "$port")

    channel_ids=$(curl -sS --location "http://$current_ip:$port" \
      --header "Content-Type: application/json" \
      --data "$json_data" | jq -r '.result.channels[].channel_id')

    if [[ -n "$channel_ids" ]]; then
      args=$(sed -n "$((5 + 1))p" ../args.txt)

      for channel_id in $channel_ids; do
        if [[ "$channel_id" != "null" && -n "$channel_id" ]]; then
          echo "$channel_id"
          shutdown_channel_json_data=$(printf "$shutdown_channel_json_template" "$port" "$channel_id" "$args")
          curl -sS --location "http://$current_ip:$port" \
            --header "Content-Type: application/json" \
            --data "$shutdown_channel_json_data"
        fi
        echo ""
      done
    else
      echo "No channels found to shutdown."
    fi
  done
elif [ "$current_ip" == "43.198.254.225" ]; then
  port="${PORTS[5]}"
  json_data=$(printf "$list_channels_g_json_data" "$port")
  # 获取所有channel IDs
  channel_ids=$(curl -sS --location "http://$current_ip:$port" \
    --header "Content-Type: application/json" \
    --data "$json_data" | jq -r '.result.channels[].channel_id')

  # 检查是否有有效的channel IDs
  if [[ -n "$channel_ids" ]]; then
    # 读取额外的参数
    args=$(sed -n "$((5 + 1))p" ../args.txt)

    # 为每个channel ID执行关闭操作
    for channel_id in $channel_ids; do
      if [[ "$channel_id" != "null" && -n "$channel_id" ]]; then
        echo "$channel_id"
        shutdown_channel_json_data=$(printf "$shutdown_channel_json_template" "$port" "$channel_id" "$args")
        curl -sS --location "http://$current_ip:$port" \
          --header "Content-Type: application/json" \
          --data "$shutdown_channel_json_data"
      fi
      echo ""
    done
  else
    echo "No channels found to shutdown."
  fi

# elif [ "$current_ip" == "43.199.108.57" ]; then
#   port="${PORTS[6]}"
#   json_data=$(printf "$list_channels_f_json_data" "$port")
#   channel_id=$(curl -sS --location "http://$current_ip:$port" --header "Content-Type: application/json" --data "$json_data" | jq -r '.result.channels[0].channel_id')
#   echo "$channel_id"
#   echo ""
#   args=$(sed -n "$((6 + 1))p" ../args.txt)
#   shutdown_channel_json_data=$(printf "$shutdown_channel_json_template" "$port" "$channel_id" "$args")
#   if [[ "$channel_id" != "null" && -n "$channel_id" ]]; then
#     curl -sS --location "http://$current_ip:$port" --header "Content-Type: application/json" --data "$shutdown_channel_json_data"
#   fi
#   echo ""

#  port="${PORTS[7]}"
#  json_data=$(printf "$list_channels_g_json_data" "$port")
#  channel_id=$(curl -sS --location "http://$current_ip:$port" --header "Content-Type: application/json" --data "$json_data" | jq -r '.result.channels[0].channel_id')
#  echo "$channel_id"
#  echo ""
#  args=$(sed -n "$((7 + 1))p" ../args.txt)
#  shutdown_channel_json_data=$(printf "$shutdown_channel_json_template" "$port" "$channel_id" "$args")
#  if [[ "$channel_id" != "null" && -n "$channel_id" ]]; then
#    curl -sS --location "http://$current_ip:$port" --header "Content-Type: application/json" --data "$shutdown_channel_json_data"
#  fi
fi
