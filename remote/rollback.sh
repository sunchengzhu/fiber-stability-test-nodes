#!/bin/bash

pkill fnn

rm -f ../fiber/tmp/fnn
#cp /home/ckb/scz/0_4_0/fnn ../fiber/tmp/fnn
cp /home/ckb/scz/2858151/fnn ../fiber/tmp/fnn
../fiber/tmp/fnn --version

store_name="2858151_store"
config_name="2858151-config.yml"

cd ../fiber/tmp
for dir in $(ls -d ./testnet-fnn/node*); do
  node_id=$(basename "$dir")
  echo "$node_id"
  mv "./testnet-fnn/$node_id/config.yml" "./testnet-fnn/$node_id/0_4_0-config.yml"
  mv "./testnet-fnn/$node_id/bak-config.yml" "./testnet-fnn/$node_id/2858151-config.yml"
  cp "./testnet-fnn/$node_id/$config_name" "./testnet-fnn/$node_id/config.yml"
  rm -rf "./testnet-fnn/$node_id/fiber/store"
  cp -r "./testnet-fnn/$node_id/fiber/$store_name" "./testnet-fnn/$node_id/fiber/store"
#  ./fnn-migrate -p "testnet-fnn/$node_id/fiber/store"
  ls "./testnet-fnn/$node_id"
  ls "./testnet-fnn/$node_id/fiber"
  RUST_LOG=info ./fnn -c "$dir/config.yml" -d "$dir" >"./testnet-fnn/$node_id/$node_id.log" 2>&1 &
  sleep 5
  head -n 1 "./testnet-fnn/$node_id/$node_id.log"
done
