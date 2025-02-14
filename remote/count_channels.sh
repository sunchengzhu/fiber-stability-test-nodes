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

if [ "$current_ip" == "18.167.71.41" ]; then
  for i in 0 1 2 3 4; do
    port="${PORTS[i]}"
    json_data=$(printf "$list_channels_f_json_data" "$port")
    curl -sS --location "http://127.0.0.1:$port" --header "Content-Type: application/json" --data "$json_data" | jq -r '[.result.channels[].state.state_name] | reverse | to_entries | .[] | "Channel \(.key+1): \(.value)"'
    echo ""
  done
elif [ "$current_ip" == "43.198.254.225" ]; then
  port="${PORTS[5]}"
  json_data=$(printf "$list_channels_g_json_data" "$port")
  curl -sS --location "http://127.0.0.1:$port" --header "Content-Type: application/json" --data "$json_data" | jq -r '[.result.channels[].state.state_name] | reverse | to_entries | .[] | "Channel \(.key+1): \(.value)"'
  echo ""
elif [ "$current_ip" == "43.199.108.57" ]; then
  port1="${PORTS[6]}"
  json_data1=$(printf "$list_channels_f_json_data" "$port1")
  curl -sS --location "http://127.0.0.1:$port1" --header "Content-Type: application/json" --data "$json_data1" | jq -r '[.result.channels[].state.state_name] | reverse | to_entries | .[] | "Channel \(.key+1): \(.value)"'
  echo ""

  port2="${PORTS[7]}"
  json_data2=$(printf "$list_channels_g_json_data" "$port2")
  curl -sS --location "http://127.0.0.1:$port2" --header "Content-Type: application/json" --data "$json_data2" | jq -r '[.result.channels[].state.state_name] | reverse | to_entries | .[] | "Channel \(.key+1): \(.value)"'
fi
