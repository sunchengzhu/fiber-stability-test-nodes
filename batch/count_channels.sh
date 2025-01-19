#!/bin/bash

PEER_ID="QmXen3eUHhywmutEzydCsW4hXBoeVmdET2FJvMX69XJ1Eo"

curl -s --location 'http://127.0.0.1:8231' --header 'Content-Type: application/json' --data "{
    \"id\": 3,
    \"jsonrpc\": \"2.0\",
    \"method\": \"list_channels\",
    \"params\": [
        {
            \"peer_id\": \"$PEER_ID\"
        }
    ]
}" | jq -r '[.result.channels[].state.state_name] | reverse | to_entries | .[] | "Channel \(.key+1): \(.value)"'
