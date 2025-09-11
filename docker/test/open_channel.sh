#!/bin/sh

TOKEN="EpECCqYBCgVwZWVycwoIcGF5bWVudHMKCGNoYW5uZWxzCghpbnZvaWNlcxgDIgkKBwgAEgMYgAgiCQoHCAESAxiACCIJCgcIARIDGIEIIgkKBwgAEgMYgQgiCQoHCAESAxiCCCIJCgcIABIDGIIIIggKBggAEgIYGCIJCgcIARIDGIMIMiYKJAoCCBsSBggFEgIIBRoWCgQKAggFCggKBiCAwODoBgoEGgIIAhIkCAASIC3KNA3sQcH7HueRbBDT-Kg9Lmu5LwcEy-OMKcCvtVqRGkCg8T6TWf9HIT5nOfBjB0gelDJMwpIjM9utyJQ9JI3m3L5Sll2AJIPNajGsBy0Ywmkx0Z5VFT3n1SlHuWMM_wMFIiIKIMnzUSJrPnRIaFZYVjxVJu64vI-Oi81uftHSZWcuCZUQ"

# fiber1连fiber2
curl -sS 'http://172.30.0.1:8231' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "id": 1,
    "jsonrpc": "2.0",
    "method": "connect_peer",
    "params": [
      {
        "address": "/ip4/172.30.0.2/tcp/8222/p2p/QmWECEVkMvn4j9gkMpWLFZw3aqNVVXzzgQ742JpfBDz8KW"
      }
    ]
  }' | jq

echo

sleep 5

# fiber1花200ckb和fiber2建立channel
curl -sS 'http://172.30.0.1:8231' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "id": 1,
    "jsonrpc": "2.0",
    "method": "open_channel",
    "params": [
      {
        "peer_id": "QmWECEVkMvn4j9gkMpWLFZw3aqNVVXzzgQ742JpfBDz8KW",
        "funding_amount": "0x4a817c800",
        "public": true
      }
    ]
  }' | jq

  echo
