#!/bin/bash

PORTS=(8227 8230 8232 8234 8236 8238 8240 8242)
id=1
addresses=()

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
  else
    echo "Query to port $PORT failed."
  fi

  ((id++))
done

#for addr in "${addresses[@]}"; do
#  echo "$addr"
#done

f_address="${addresses[5]}"
g_address="${addresses[6]}"

echo "$f_address"
echo "$g_address"

for i in 0 1 2 3 4 6; do
  port="${PORTS[i]}"

  connect_peer_json_data=$(
    cat <<EOF
{
  "id": "$port",
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

  curl --location "http://127.0.0.1:$port" --header "Content-Type: application/json" --data "$connect_peer_json_data"
  echo ""
done


for i in 5 7; do
  port="${PORTS[i]}"

  connect_peer_json_data=$(
    cat <<EOF
{
  "id": "$port",
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

  curl --location "http://127.0.0.1:$port" --header "Content-Type: application/json" --data "$connect_peer_json_data"
  echo ""
done
