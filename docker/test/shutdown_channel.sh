#!/bin/sh
set -eu

BASE_URL="http://172.30.0.1:8231"
TOKEN='EpECCqYBCgVwZWVycwoIcGF5bWVudHMKCGNoYW5uZWxzCghpbnZvaWNlcxgDIgkKBwgAEgMYgAgiCQoHCAESAxiACCIJCgcIARIDGIEIIgkKBwgAEgMYgQgiCQoHCAESAxiCCCIJCgcIABIDGIIIIggKBggAEgIYGCIJCgcIARIDGIMIMiYKJAoCCBsSBggFEgIIBRoWCgQKAggFCggKBiCAwODoBgoEGgIIAhIkCAASIC3KNA3sQcH7HueRbBDT-Kg9Lmu5LwcEy-OMKcCvtVqRGkCg8T6TWf9HIT5nOfBjB0gelDJMwpIjM9utyJQ9JI3m3L5Sll2AJIPNajGsBy0Ywmkx0Z5VFT3n1SlHuWMM_wMFIiIKIMnzUSJrPnRIaFZYVjxVJu64vI-Oi81uftHSZWcuCZUQ'

# 1) 列出 channel_id（可能为空）
CHANNEL_IDS=$(
	curl -sS --location "$BASE_URL" \
		--header "Content-Type: application/json" \
		--header "Authorization: Bearer $TOKEN" \
		--data '{
      "id": "1",
      "jsonrpc": "2.0",
      "method": "list_channels",
      "params": [{"peer_id":"QmWECEVkMvn4j9gkMpWLFZw3aqNVVXzzgQ742JpfBDz8KW"}]
    }' |
		jq -r '.result.channels[]?.channel_id' || true
)

[ -z "$CHANNEL_IDS" ] && {
	echo "No channels found to shutdown."
	exit 0
}

# 2) 逐个关闭
i=0
for cid in $CHANNEL_IDS; do
  [ "$cid" = "null" ] && continue
  i=$((i + 1))
  printf 'shutdown channel %d: %s\n' "$i" "$cid"

  payload=$(jq -n --arg cid "$cid" '{
    id: "2",
    jsonrpc: "2.0",
    method: "shutdown_channel",
    params: [{
      channel_id: $cid,
      close_script: {
        code_hash: "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
        hash_type: "type",
        args: "0xd406d019d1e10732647d2159affab090ab05e514"
      },
      fee_rate: "0x3FC"
    }]
  }')

  curl -sS --location "$BASE_URL" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $TOKEN" \
    --data "$payload" | jq -C .
  echo
done
