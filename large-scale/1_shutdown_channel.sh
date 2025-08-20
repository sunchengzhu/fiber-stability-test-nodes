#!/bin/bash

PORTS=($(seq 8231 8238))

edge_0_peer_id="QmUf2ZSuGGBgFQEupTAAjGQbrhcRNoUXKwbHTdVMTGdEg3"
edge_39_peer_id="QmZEGQRyDfzAMUdV7QnncgdDZqkaiTy3fKvrvNd7hCBgEm"

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

shutdown_channel_json_template='{
  "id": "%s",
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

if [ "$current_ip" == "18.167.71.41" ]; then
  #  for i in 0 1 2 3 4; do
  for i in 0; do
    port="${PORTS[i]}"
    json_data=$(printf "$list_channels_0_json_data" "$port")

    channel_ids=$(curl -sS --location "http://$current_ip:$port" \
      --header "Content-Type: application/json" \
      --data "$json_data" | jq -r '.result.channels[].channel_id')

    if [[ -n "$channel_ids" ]]; then
      args=$(sed -n "$((5 + 1))p" ../args.txt)

      for channel_id in $channel_ids; do
        if [[ "$channel_id" != "null" && -n "$channel_id" ]]; then
          echo "$channel_id"
          shutdown_channel_json_data=$(printf "$shutdown_channel_json_template" "$port" "$channel_id" "$args")
          curl -sS --location "http://$current_ip:$port" \
            --header "Content-Type: application/json" \
            --data "$shutdown_channel_json_data"
        fi
        echo ""
      done
    else
      echo "No channels found to shutdown."
    fi
  done

 elif [ "$current_ip" == "43.199.108.57" ]; then
   port="${PORTS[6]}"
   json_data=$(printf "$list_channels_39_json_data" "$port")
   channel_id=$(curl -sS --location "http://$current_ip:$port" --header "Content-Type: application/json" --data "$json_data" | jq -r '.result.channels[0].channel_id')
   echo "$channel_id"
   echo ""
   args=$(sed -n "$((6 + 1))p" ../args.txt)
   shutdown_channel_json_data=$(printf "$shutdown_channel_json_template" "$port" "$channel_id" "$args")
   if [[ "$channel_id" != "null" && -n "$channel_id" ]]; then
     curl -sS --location "http://$current_ip:$port" --header "Content-Type: application/json" --data "$shutdown_channel_json_data"
   fi
   echo ""
fi
