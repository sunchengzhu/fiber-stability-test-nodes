## Dir
``` bash
cd /home/ckb/scz/fiber-stability-test-nodes/remote
cd /home/ckb/scz/fiber-stability-test-nodes/fiber/tmp/testnet-fnn/node6
head -n 1 /home/ckb/scz/fiber-stability-test-nodes/fiber/tmp/testnet-fnn/node6/node6.log
```

#### node_info 

get node A peer_id

```bash
curl -s --location 'http://18.167.71.41:8231' --header 'Content-Type: application/json' --data '{
    "id": 1,
    "jsonrpc": "2.0",
    "method": "node_info",
    "params": []
}' | jq '.result.peer_id'
```

#### open_channel

node F(162ckb) -> node A(0)

```bash
curl -s --location 'http://43.198.254.225:8236' --header 'Content-Type: application/json' --data '{
    "id": 2,
    "jsonrpc": "2.0",
    "method": "open_channel",
    "params": [
        {
            "peer_id": "Qmatp8rTwawwiYULB7k4md49XEhTH51Mb2Q9p1UyttbE8k",
            "funding_amount": "0x3c5986200",
            "public": true
        }
    ]
}'
```

#### list_channels

get node F peer_id

```bash
curl -s --location 'http://43.198.254.225:8236' --header 'Content-Type: application/json' --data '{
    "id": 3,
    "jsonrpc": "2.0",
    "method": "node_info",
    "params": []
}' | jq '.result.peer_id'
```

get node F -> node A channel_id

```bash
curl -s --location 'http://18.167.71.41:8231' --header 'Content-Type: application/json' --data '{
    "id": 4,
    "jsonrpc": "2.0",
    "method": "list_channels",
    "params": [
        {
            "peer_id": "Qme8LsbKbMAQmw9S8uPbjbEEnSi7LiMaexLqNpkhwWpLKj"
        }
    ]
}' | jq
```

#### shutdown_channel

```bash
curl -s --location 'http://43.198.254.225:8236' --header 'Content-Type: application/json' --data '{
    "id": 5,
    "jsonrpc": "2.0",
    "method": "shutdown_channel",
    "params": [
        {
            "channel_id": "0x0e5e4bd0da6920cc8a336a1a5cf17e2e4f439871a84ced68da483469180a2ed0",
            "close_script": {
                "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
                "hash_type": "type",
                "args": "0x9a80134a79c349ffc74db855f967df8ccc5f4177"
            },
            "fee_rate": "0x3FC"
        }
    ]
}'
```



## Addresses

Node1: ckt1qzda0cr08m85hc8jlnfp3zer7xulejywt49kt2rr0vthywaa50xwsqf5hnukanfv6appjv7nj8zykjhq6a8zzrczscmjz
Node6: ckt1qzda0cr08m85hc8jlnfp3zer7xulejywt49kt2rr0vthywaa50xwsqv6sqf557wrf8luwndc2huk0huve305zac47lcdw
