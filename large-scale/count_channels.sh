#!/bin/bash

PORTS=($(seq 8231 8238))
peer_ids=()

edge_0_peer_id="QmfJqF7hGRvYnm3q9Tsx61poS39JpfAuFik5AMC9Aqg9sr"
edge_39_peer_id="Qma2PNg4qdPchSXqusPyEL2ttEtjRmn3BNoeabquFSWBcz"

current_ip=$(curl -s ifconfig.me)

list_channels_0_json_data=$(
  cat <<EOF
{
  "id": "%s",
  "jsonrpc": "2.0",
  "method": "list_channels",
  "params": [
    {
      "peer_id": "$edge_0_peer_id"
    }
  ]
}
EOF
)

list_channels_39_json_data=$(
  cat <<EOF
{
  "id": "%s",
  "jsonrpc": "2.0",
  "method": "list_channels",
  "params": [
    {
      "peer_id": "$edge_39_peer_id"
    }
  ]
}
EOF
)

jq_filter='[.result.channels[] | {state_name: .state.state_name, local_balance: .local_balance, remote_balance: .remote_balance}] | reverse | to_entries | .[] | "Channel \(.key+1): \(.value.state_name) local_balance: \(.value.local_balance) remote_balance: \(.value.remote_balance)"'

if [ "$current_ip" == "18.167.71.41" ]; then
  port="${PORTS[0]}"
  json_data=$(printf "$list_channels_0_json_data" "$port")
  curl -sS --location "http://172.31.23.160:$port" --header "Content-Type: application/json" --data "$json_data" | jq -r "$jq_filter"
  echo ""
elif [ "$current_ip" == "43.199.108.57" ]; then
  port="${PORTS[6]}"
  json_data=$(printf "$list_channels_39_json_data" "$port")
  curl -sS --location "http://172.31.16.223:$port" --header "Content-Type: application/json" --data "$json_data" | jq -r "$jq_filter"
  echo ""
fi
