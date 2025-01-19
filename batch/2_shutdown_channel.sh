#!/bin/bash

PEER_ID="QmXen3eUHhywmutEzydCsW4hXBoeVmdET2FJvMX69XJ1Eo"
ARGS="0x7bfb5a5f50cc71460db96610b8a957ac1e063306"
IP="127.0.0.1"
PORT="8231"

json_data=$(
  cat <<EOF
{
    "id": 666,
    "jsonrpc": "2.0",
    "method": "list_channels",
    "params": [
        {
            "peer_id": "$PEER_ID"
        }
    ]
}
EOF
)

channel_ids=($(curl -s --location "http://${IP}:${PORT}" --header 'Content-Type: application/json' --data "$json_data" | jq -r '.result.channels[].channel_id'))

shutdown_channel_json_template='{
  "id": "2",
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

for channel_id in "${channel_ids[@]}"; do
  echo "$channel_id"
  shutdown_channel_json_data=$(printf "$shutdown_channel_json_template" "$channel_id" "$ARGS")
  curl -sS --location "http://$IP:$PORT" --header "Content-Type: application/json" --data "$shutdown_channel_json_data"
  echo ""
done
