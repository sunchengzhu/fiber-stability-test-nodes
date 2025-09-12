#!/bin/sh

TOKEN="EpECCqYBCgVwZWVycwoIcGF5bWVudHMKCGNoYW5uZWxzCghpbnZvaWNlcxgDIgkKBwgAEgMYgAgiCQoHCAESAxiACCIJCgcIARIDGIEIIgkKBwgAEgMYgQgiCQoHCAESAxiCCCIJCgcIABIDGIIIIggKBggAEgIYGCIJCgcIARIDGIMIMiYKJAoCCBsSBggFEgIIBRoWCgQKAggFCggKBiCAwODoBgoEGgIIAhIkCAASIC3KNA3sQcH7HueRbBDT-Kg9Lmu5LwcEy-OMKcCvtVqRGkCg8T6TWf9HIT5nOfBjB0gelDJMwpIjM9utyJQ9JI3m3L5Sll2AJIPNajGsBy0Ywmkx0Z5VFT3n1SlHuWMM_wMFIiIKIMnzUSJrPnRIaFZYVjxVJu64vI-Oi81uftHSZWcuCZUQ"

# fiber1连fiber3
curl -sS 'http://172.30.0.1:8231' \
	-H 'Content-Type: application/json' \
	-H "Authorization: Bearer $TOKEN" \
	-d '{
    "id": 13,
    "jsonrpc": "2.0",
    "method": "connect_peer",
    "params": [
      {
        "address": "/ip4/172.30.0.3/tcp/8223/p2p/QmZPivdNrYkLowXCSTZtbba1kgqfgUWBsHo4AX3PoqJmnL"
      }
    ]
  }' | jq

echo

sleep 5

# fiber1花300ckb和fiber3建立channel
curl -sS 'http://172.30.0.1:8231' \
	-H 'Content-Type: application/json' \
	-H "Authorization: Bearer $TOKEN" \
	-d '{
    "id": 13,
    "jsonrpc": "2.0",
    "method": "open_channel",
    "params": [
      {
        "peer_id": "QmZPivdNrYkLowXCSTZtbba1kgqfgUWBsHo4AX3PoqJmnL",
        "funding_amount": "0x6fc23ac00",
        "public": true
      }
    ]
  }' | jq

echo
