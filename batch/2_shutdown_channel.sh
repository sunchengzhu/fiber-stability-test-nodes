#!/bin/bash

ARGS="0xd406d019d1e10732647d2159affab090ab05e514"
IP="18.167.71.41"
PORT="8232"

channel_ids=($(curl -s --location "http://${IP}:${PORT}" --header 'Content-Type: application/json' --data '{
    "id": 666,
    "jsonrpc": "2.0",
    "method": "list_channels",
    "params": [
        {
            "peer_id": "QmU2iS4UkAKm6Sq3udeVgmm7Naxr8BKFoVr6pxZ4Ty4iYe"
        }
    ]
}' | jq -r '.result.channels[].channel_id'))

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
        "args": "0xd406d019d1e10732647d2159affab090ab05e514"
      },
      "fee_rate": "0x3FC"
    }
  ]
}'

for channel_id in "${channel_ids[@]}"; do
  echo "$channel_id"
  shutdown_channel_json_data=$(printf "$shutdown_channel_json_template" "$channel_id")
  curl -sS --location "http://$IP:$PORT" --header "Content-Type: application/json" --data "$shutdown_channel_json_data"
  echo ""
done
