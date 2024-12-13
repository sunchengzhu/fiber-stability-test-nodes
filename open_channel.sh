#!/bin/bash

PORTS=(8227 8230 8232 8234 8236 8238 8240 8242)
id=1
addresses=()
peer_ids=()

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
    peer_id=$(echo "$response" | jq -r '.result.peer_id')
    peer_ids+=("$peer_id")
  else
    echo "Query to port $PORT failed."
  fi

  ((id++))
done

for addr in "${addresses[@]}"; do
  echo "$addr"
done

f_peer_id="${peer_ids[5]}"
g_peer_id="${peer_ids[6]}"

for i in 0 1 2 3 4 6; do
  port="${PORTS[i]}"

  json_data=$(
    cat <<EOF
{
  "id": "$port",
  "jsonrpc": "2.0",
  "method": "open_channel",
  "params": [
    {
      "peer_id": "$f_peer_id",
      "funding_amount": "0x174876e800",
      "public": true
    }
  ]
}
EOF
  )

  curl --location "http://127.0.0.1:$port" --header "Content-Type: application/json" --data "$json_data"
  echo ""
  sleep 30
done

for i in 5 7; do
  port="${PORTS[i]}"

  json_data=$(
    cat <<EOF
{
  "id": "$port",
  "jsonrpc": "2.0",
  "method": "open_channel",
  "params": [
    {
      "peer_id": "$g_peer_id",
      "funding_amount": "0x174876e800",
      "public": true
    }
  ]
}
EOF
  )

  curl --location "http://127.0.0.1:$port" --header "Content-Type: application/json" --data "$json_data"
  echo ""
  sleep 30
done
