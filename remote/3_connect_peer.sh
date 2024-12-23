#!/bin/bash

PORTS=($(seq 8231 8238))
addresses=()

for idx in "${!PORTS[@]}"; do
  PORT=${PORTS[idx]}
  if [ "$idx" -lt 5 ]; then
    ip="18.167.71.41"
  elif [ "$idx" -eq 5 ]; then
    ip="43.198.254.225"
  elif [ "$idx" -ge 6 ]; then
    ip="43.199.108.57"
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
    address=$(echo "$response" | jq -r '.result.addresses[]' | sed "s/0.0.0.0/$ip/")
    addresses+=("$address")
  else
    echo "Query to port $PORT failed."
  fi
done

f_address="${addresses[5]}"
g_address="${addresses[6]}"

echo "$f_address"
echo "$g_address"

current_ip=$(curl -s ifconfig.me)

# 预定义 JSON 数据模板
connect_peer_f_json_data=$(
  cat <<EOF
{
  "id": "%s",
  "jsonrpc": "2.0",
  "method": "connect_peer",
  "params": [
    {
      "address": "$f_address"
    }
  ]
}
EOF
)

connect_peer_g_json_data=$(
  cat <<EOF
{
  "id": "%s",
  "jsonrpc": "2.0",
  "method": "connect_peer",
  "params": [
    {
      "address": "$g_address"
    }
  ]
}
EOF
)

if [ "$current_ip" == "18.167.71.41" ]; then
  for i in 0 1 2 3 4; do
    port="${PORTS[i]}"
    json_data=$(printf "$connect_peer_f_json_data" "$port")
    curl --location "http://$current_ip:$port" --header "Content-Type: application/json" --data "$json_data"
    echo ""
  done
elif [ "$current_ip" == "43.198.254.225" ]; then
  port="${PORTS[5]}"
  json_data=$(printf "$connect_peer_g_json_data" "$port")
  curl --location "http://$current_ip:$port" --header "Content-Type: application/json" --data "$json_data"
  echo ""
elif [ "$current_ip" == "43.199.108.57" ]; then
  port="${PORTS[6]}"
  json_data=$(printf "$connect_peer_f_json_data" "$port")
  curl --location "http://$current_ip:$port" --header "Content-Type: application/json" --data "$json_data"
  echo ""
  port="${PORTS[7]}"
  json_data=$(printf "$connect_peer_g_json_data" "$port")
  curl --location "http://$current_ip:$port" --header "Content-Type: application/json" --data "$json_data"
  echo ""
fi
