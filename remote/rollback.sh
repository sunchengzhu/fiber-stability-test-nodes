#!/bin/bash

rm -f ../fiber/tmp/fnn
cp /home/ckb/scz/0_4_0/fnn ../fiber/tmp/fnn
#cp /home/ckb/scz/2858151/fnn ../fiber/tmp/fnn
../fiber/tmp/fnn --version

used_store_name="2025-03-03_17_store"
bak_store_name="2858151_store"

cd ../fiber/tmp
for dir in $(ls -d ./testnet-fnn/node*); do
  node_id=$(basename "$dir")
  echo "$node_id"
  mv "./testnet-fnn/$node_id/fiber/store" "./testnet-fnn/$node_id/fiber/$bak_store_name"
  mv "./testnet-fnn/$node_id/fiber/$used_store_name" "./testnet-fnn/$node_id/fiber/store"
  RUST_LOG=info ./fnn -c "$dir/config.yml" -d "$dir" >"./testnet-fnn/$node_id/$node_id.log" 2>&1 &
  sleep 5
  head -n 1 "./testnet-fnn/$node_id/$node_id.log"
done
