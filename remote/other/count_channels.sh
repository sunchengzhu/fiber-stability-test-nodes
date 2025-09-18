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

jq_filter='[.result.channels[] | {state_name: .state.state_name, local_balance: .local_balance, remote_balance: .remote_balance}] | reverse | to_entries | .[] | "Channel \(.key+1): \(.value.state_name) local_balance: \(.value.local_balance) remote_balance: \(.value.remote_balance)"'

if [ "$current_ip" == "18.167.71.41" ]; then
  for i in 0; do
#  for i in 0 1 2 3 4; do
    port="${PORTS[i]}"
    json_data=$(printf "$list_channels_f_json_data" "$port")
    curl -sS --location "http://172.31.23.160:$port" --header "Content-Type: application/json" --data "$json_data" | jq -r "$jq_filter"
    echo ""
  done
elif [ "$current_ip" == "43.198.254.225" ]; then
  port="${PORTS[5]}"
  json_data=$(printf "$list_channels_g_json_data" "$port")
  curl -sS --location "http://172.31.28.209:$port" --header "Content-Type: application/json" --data "$json_data" | jq -r "$jq_filter"
  echo ""
elif [ "$current_ip" == "43.199.108.57" ]; then
  port1="${PORTS[6]}"
  json_data1=$(printf "$list_channels_f_json_data" "$port1")
  curl -sS --location "http://172.31.16.223:$port1" --header "Content-Type: application/json" --data "$json_data1" | jq -r "$jq_filter"
  echo ""

#  port2="${PORTS[7]}"
#  json_data2=$(printf "$list_channels_g_json_data" "$port2")
#  curl -sS --location "http://127.0.0.1:$port2" --header "Content-Type: application/json" --data "$json_data2" | jq -r "$jq_filter"
fi
