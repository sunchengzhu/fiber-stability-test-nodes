#!/bin/bash

payment_preimage="0x$(openssl rand -hex 32)"

response=$(curl -sS --location 'http:/18.167.71.41:8231' \
    --header 'Content-Type: application/json' \
    --data "$(
        cat <<EOF
{
    "id": 1,
    "jsonrpc": "2.0",
    "method": "new_invoice",
    "params": [{
        "amount": "0xbebc200",
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

echo "$response" | jq -r '.result'
invoice_address=$(echo "$response" | jq -r '.result.invoice_address')

curl -sS --location 'http://43.199.108.57:8237' --header 'Content-Type: application/json' --data "$(
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
)" | jq -r