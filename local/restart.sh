#!/bin/bash

pkill fnn

cd ../fiber/tmp || exit

start_node_id=1
end_node_id=8

for ((id = $start_node_id; id <= $end_node_id; id++)); do
  RUST_LOG=info ./fnn -c "testnet-fnn/node$id/config.yml" -d "testnet-fnn/node$id" >>"./node$id.log" 2>&1 &
done

ps aux | grep '[f]nn'
