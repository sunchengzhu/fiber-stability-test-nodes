#!/bin/bash

edge_0_address="/ip4/35.170.253.64/tcp/8120/p2p/QmUf2ZSuGGBgFQEupTAAjGQbrhcRNoUXKwbHTdVMTGdEg3"
edge_39_address="/ip4/3.224.56.150/tcp/8158/p2p/QmZEGQRyDfzAMUdV7QnncgdDZqkaiTy3fKvrvNd7hCBgEm"
echo "edge_0_address: $edge_0_address"
echo "edge_39_address: $edge_39_address"

current_ip=$(curl -s ifconfig.me)

# 预定义 JSON 数据模板
connect_peer_0_json_data=$(
  cat <<EOF
{
  "id": "%s",
  "jsonrpc": "2.0",
  "method": "connect_peer",
  "params": [
    {
      "address": "$edge_0_address"
    }
  ]
}
EOF
)

connect_peer_39_json_data=$(
  cat <<EOF
{
  "id": "%s",
  "jsonrpc": "2.0",
  "method": "connect_peer",
  "params": [
    {
      "address": "$edge_39_address"
    }
  ]
}
EOF
)

PORTS=($(seq 8231 8238))

if [ "$current_ip" == "18.167.71.41" ]; then
  # a → edge_0
  port="${PORTS[0]}"
  json_data=$(printf "$connect_peer_0_json_data" "$port")
  curl -s --location "http://172.31.23.160:$port" --header "Content-Type: application/json" --data "$json_data"
  echo ""
elif [ "$current_ip" == "43.199.108.57" ]; then
  # g → edge_39
  port="${PORTS[6]}"
  json_data=$(printf "$connect_peer_39_json_data" "$port")
  curl -s --location "http://172.31.16.223:$port" --header "Content-Type: application/json" --data "$json_data"
  echo ""
fi
