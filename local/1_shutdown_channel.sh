#!/bin/bash

response2=$(curl -s -X POST http://127.0.0.1:8232 \
  -H "Content-Type: application/json" \
  -d '{
        "id": 1,
        "jsonrpc": "2.0",
        "method": "node_info",
        "params": []
      }')

if [ $? -eq 0 ]; then
  peer_id2=$(echo "$response2" | jq -r '.result.addresses[0]' | awk -F '/' '{print $NF}' | sed 's/0.0.0.0/127.0.0.1/')
else
  echo "Query to port 8232 failed."
fi

response3=$(curl -s -X POST http://127.0.0.1:8233 \
  -H "Content-Type: application/json" \
  -d '{
        "id": 1,
        "jsonrpc": "2.0",
        "method": "node_info",
        "params": []
      }')

if [ $? -eq 0 ]; then
  peer_id3=$(echo "$response3" | jq -r '.result.addresses[0]' | awk -F '/' '{print $NF}' | sed 's/0.0.0.0/127.0.0.1/')
else
  echo "Query to port 8233 failed."
fi

port1=8231
port2=8232

list_channels_json_data1=$(
  cat <<EOF
{
  "id": $port1,
  "jsonrpc": "2.0",
  "method": "list_channels",
  "params": [
    {
      "peer_id": "$peer_id2"
    }
  ]
}
EOF
)
channel_id1=$(curl -sS --location "http://127.0.0.1:$port1" --header "Content-Type: application/json" --data "$list_channels_json_data1" | jq -r '.result.channels[0].channel_id')

list_channels_json_data2=$(
  cat <<EOF
{
  "id": $port2,
  "jsonrpc": "2.0",
  "method": "list_channels",
  "params": [
    {
      "peer_id": "$peer_id3"
    }
  ]
}
EOF
)
channel_id2=$(curl -sS --location "http://127.0.0.1:$port2" --header "Content-Type: application/json" --data "$list_channels_json_data2" | jq -r '.result.channels[0].channel_id')

for id in 1 2; do
  port=$((8230 + id))

  channel_var_name="channel_id${id}"
  echo "Channel ID: ${!channel_var_name}"

  args=$(sed -n "$((i + 1))p" ../args.txt)
  shutdown_channel_json_data=$(
    cat <<EOF
{
  "id": $port,
  "jsonrpc": "2.0",
  "method": "shutdown_channel",
  "params": [
    {
      "channel_id": "${!channel_var_name}",
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

  if [[ "${!channel_var_name}" != "null" && -n "${!channel_var_name}" ]]; then
    curl -sS --location "http://127.0.0.1:$port" --header "Content-Type: application/json" --data "$shutdown_channel_json_data"
  fi
  echo ""
done
