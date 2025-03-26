#!/bin/bash

timeout=600
start_time=$(date +%s)

while true; do
    payment_preimage="0x$(openssl rand -hex 32)"

    # 0.01 CKB
    response=$(curl -sS --location 'http://43.199.108.57:8237' \
        --header 'Content-Type: application/json' \
        --data "$(
            cat <<EOF
{
    "id": 1,
    "jsonrpc": "2.0",
    "method": "new_invoice",
    "params": [{
        "amount": "0xf4240",
        "currency": "Fibt",
        "description": "test invoice generated by node g",
        "expiry": "0xe10",
        "final_cltv": "0x28",
        "payment_preimage": "$payment_preimage",
        "hash_algorithm": "sha256"
    }]
}
EOF
        )")

    invoice_address=$(echo "$response" | jq -r '.result.invoice_address')

    payment_hash=$(curl -sS --location 'http://18.167.71.41:8231' \
        --header 'Content-Type: application/json' \
        --data "$(
            cat <<EOF
{
    "id": 2,
    "jsonrpc": "2.0",
    "method": "send_payment",
    "params": [{
        "invoice": "$invoice_address"
    }]
}
EOF
        )" | jq -r '.result.payment_hash')

    payment_response=$(curl -sS --location 'http://18.167.71.41:8231' \
        --header 'Content-Type: application/json' \
        --data "$(
            cat <<EOF
{
    "id": 3,
    "jsonrpc": "2.0",
    "method": "get_payment",
    "params": [
        {
            "payment_hash": "$payment_hash"
        }
    ]
}
EOF
        )")

    status=$(echo "$payment_response" | jq -r '.result.status')
    echo "status is: '$status'"

    if [ "$status" = "Success" ]; then
        elapsed=$(($(date +%s) - start_time))
        echo "Channels is ready after ${elapsed} seconds"
        break
    fi

    elapsed=$(($(date +%s) - start_time))
    if [ "$elapsed" -ge "$timeout" ]; then
        echo "超时：等待channel可用时间超过10分钟" >&2
        exit 1
    fi

    sleep 5
done
