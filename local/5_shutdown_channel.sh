#!/bin/bash

response=$(curl -s -X POST http://127.0.0.1:8232 \
  -H "Content-Type: application/json" \
  -d '{
        "id": 1,
        "jsonrpc": "2.0",
        "method": "node_info",
        "params": []
      }')

if [ $? -eq 0 ]; then
  peer_id=$(echo "$response" | jq -r '.result.addresses[0]' | awk -F '/' '{print $NF}' | sed 's/0.0.0.0/127.0.0.1/')
else
  echo "Query to port 8232 failed."
fi

list_channels_json_data=$(
  cat <<EOF
{
  "id": $(($i + 1)),
  "jsonrpc": "2.0",
  "method": "list_channels",
  "params": [
    {
      "peer_id": "$peer_id"
    }
  ]
}
EOF
)

for id in 1 3; do
  port=$((8230 + id))

  channel_id=$(curl -sS --location "http://127.0.0.1:$port" --header "Content-Type: application/json" --data "$list_channels_json_data" | jq -r '.result.channels[0].channel_id')
  echo "Channel ID: $channel_id"

  args=$(sed -n "$((i + 1))p" ../args.txt)
  shutdown_channel_json_data=$(
    cat <<EOF
{
  "id": $((i + 1)),
  "jsonrpc": "2.0",
  "method": "shutdown_channel",
  "params": [
    {
      "channel_id": "$channel_id",
      "close_script": {
        "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
        "hash_type": "type",
        "args": "$args"
      },
      "fee_rate": "0x3FC"
    }
  ]
}
EOF
  )

  if [[ "$channel_id" != "null" && -n "$channel_id" ]]; then
    curl -sS --location "http://127.0.0.1:$port" --header "Content-Type: application/json" --data "$shutdown_channel_json_data"
  fi
  echo ""
done
