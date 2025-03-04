#!/bin/bash

pkill fnn

rm -f ../fiber/tmp/fnn
cp /home/ckb/scz/version/0_4_0/fnn ../fiber/tmp/fnn
../fiber/tmp/fnn --version

config_name="0_4_0-config.yml"

cd ../fiber/tmp
for dir in $(ls -d ./testnet-fnn/node*); do
  node_id=$(basename "$dir")
  echo "$node_id"
  rm -f "./testnet-fnn/$node_id/config.yml"
  cp "/home/ckb/scz/version/$node_id/$config_name" "./testnet-fnn/$node_id/config.yml"
  ./fnn-migrate -p "testnet-fnn/$node_id/fiber/store"
  RUST_LOG=info ./fnn -c "$dir/config.yml" -d "$dir" >"./testnet-fnn/$node_id/$node_id.log" 2>&1 &
  sleep 5
  head -n 1 "./testnet-fnn/$node_id/$node_id.log"
done
