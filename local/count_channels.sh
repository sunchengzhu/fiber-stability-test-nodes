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

jq_filter='[.result.channels[] | {state_name: .state.state_name, local_balance: .local_balance, remote_balance: .remote_balance}] | reverse | to_entries | .[] | "Channel \(.key+1): \(.value.state_name) local_balance: \(.value.local_balance) remote_balance: \(.value.remote_balance)"'

for id in 1 3; do
  port=$((8230 + id))

  list_channels_json_data=$(
    cat <<EOF
{
  "id": $port,
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

  curl -sS --location "http://127.0.0.1:$port" --header "Content-Type: application/json" --data "$list_channels_json_data" | jq -r "$jq_filter"
done
