#!/bin/sh

TOKEN="EpECCqYBCgVwZWVycwoIcGF5bWVudHMKCGNoYW5uZWxzCghpbnZvaWNlcxgDIgkKBwgAEgMYgAgiCQoHCAESAxiACCIJCgcIARIDGIEIIgkKBwgAEgMYgQgiCQoHCAESAxiCCCIJCgcIABIDGIIIIggKBggAEgIYGCIJCgcIARIDGIMIMiYKJAoCCBsSBggFEgIIBRoWCgQKAggFCggKBiCAwODoBgoEGgIIAhIkCAASIC3KNA3sQcH7HueRbBDT-Kg9Lmu5LwcEy-OMKcCvtVqRGkCg8T6TWf9HIT5nOfBjB0gelDJMwpIjM9utyJQ9JI3m3L5Sll2AJIPNajGsBy0Ywmkx0Z5VFT3n1SlHuWMM_wMFIiIKIMnzUSJrPnRIaFZYVjxVJu64vI-Oi81uftHSZWcuCZUQ"

jq_filter='[.result.channels[] | {state_name: .state.state_name, local_balance: .local_balance, remote_balance: .remote_balance}] | reverse | to_entries | .[] | "Channel \(.key+1): \(.value.state_name) local_balance: \(.value.local_balance) remote_balance: \(.value.remote_balance)"'

curl -sS 'http://172.30.0.1:8231' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "id": 1,
    "jsonrpc": "2.0",
    "method": "list_channels",
    "params": [
      {
        "peer_id": "QmWECEVkMvn4j9gkMpWLFZw3aqNVVXzzgQ742JpfBDz8KW"
      }
    ]
  }' | jq -r "$jq_filter"
