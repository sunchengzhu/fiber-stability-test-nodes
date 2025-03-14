#!/bin/bash

INTERNAL_PORTS=(8236 8237)
IPS=("172.31.28.209" "172.31.16.223")

for idx in "${!INTERNAL_PORTS[@]}"; do
  INTERNAL_PORT=${INTERNAL_PORTS[idx]}
  IP=${IPS[idx]}

  response=$(curl -s -X POST "http://$IP:$INTERNAL_PORT" \
    -H "Content-Type: application/json" \
    -d '{
          "id": 1,
          "jsonrpc": "2.0",
          "method": "node_info",
          "params": []
        }')

  address=$(echo "$response" | jq -r '.result.addresses[]')

  if [ "$idx" -eq 0 ]; then
    f_address="$address"
  elif [ "$idx" -eq 1 ]; then
    g_address="$address"
  fi
done

echo "f_address: $f_address"
echo "g_address: $g_address"

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

PORTS=($(seq 8231 8238))

if [ "$current_ip" == "18.167.71.41" ]; then
  for i in 0 1 2 3 4; do
    port="${PORTS[i]}"
    json_data=$(printf "$connect_peer_f_json_data" "$port")
    curl --location "http://172.31.23.160:$port" --header "Content-Type: application/json" --data "$json_data"
    echo ""
  done
elif [ "$current_ip" == "43.198.254.225" ]; then
  port="${PORTS[5]}"
  json_data=$(printf "$connect_peer_g_json_data" "$port")
  curl --location "http://172.31.28.209:$port" --header "Content-Type: application/json" --data "$json_data"
  echo ""
elif [ "$current_ip" == "43.199.108.57" ]; then
  # g → f
  port1="${PORTS[6]}"
  json_data1=$(printf "$connect_peer_f_json_data" "$port1")
  curl --location "http://172.31.16.223:$port1" --header "Content-Type: application/json" --data "$json_data1"
  echo ""
  # h → g
  port2="${PORTS[7]}"
  json_data2=$(printf "$connect_peer_g_json_data" "$port2")
  curl --location "http://172.31.16.223:$port2" --header "Content-Type: application/json" --data "$json_data2"
  echo ""
fi
