#!/bin/bash

address2=$(curl -s -X POST http://127.0.0.1:8232 \
  -H "Content-Type: application/json" \
  -d '{
    "id": 1,
    "jsonrpc": "2.0",
    "method": "node_info",
    "params": []
}' | jq -r '.result.addresses[]')

echo "$address2"

curl -s --location 'http://127.0.0.1:8231' \
  --header 'Content-Type: application/json' \
  --data "{
    \"id\": 8231,
    \"jsonrpc\": \"2.0\",
    \"method\": \"connect_peer\",
    \"params\": [
        {
            \"address\": \"$address2\"
        }
    ]
}"

echo

curl -s --location 'http://127.0.0.1:8233' \
  --header 'Content-Type: application/json' \
  --data "{
    \"id\": 8233,
    \"jsonrpc\": \"2.0\",
    \"method\": \"connect_peer\",
    \"params\": [
        {
            \"address\": \"$address2\"
        }
    ]
}"