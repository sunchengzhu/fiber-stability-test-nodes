#!/bin/bash

pkill fnn

# 获取公共 IP 地址
IP=$(curl -s ifconfig.me)

# 根据 IP 地址决定要删除的节点
case "$IP" in
"18.167.71.41")
  # 删除除 node1 到 node5 以外的节点 (即删除 node6, node7, node8)
#  rm -rf ../fiber/testnet-fnn/node{6..8}
   rm -rf ../fiber/testnet-fnn/node{2..8}
  ;;
"43.198.254.225")
  # 删除除 node6 外的节点 (即删除 node1 到 node5 和 node7 到 node8)
  rm -rf ../fiber/testnet-fnn/node{1..5} ../fiber/testnet-fnn/node{7..8}
  ;;
"43.199.108.57")
  # 删除除 node7 和 node8 外的节点 (即删除 node1 到 node6)
#  rm -rf ../fiber/testnet-fnn/node{1..6}
  rm -rf ../fiber/testnet-fnn/node{1..6} ../fiber/testnet-fnn/node8
  ;;
*)
  echo "不支持的 IP 地址: $IP"
  ;;
esac

ls ../fiber/testnet-fnn

cd ../fiber
for dir in $(ls -d ./testnet-fnn/node*); do
  node_id=$(basename "$dir")
  chmod +x fnn
  RUST_LOG=debug ./fnn -c "$dir/config.yml" -d "$dir" >"./testnet-fnn/$node_id/$node_id.log" 2>&1 &
  sleep 3
  ./fnn --version
  head -n 1 "./testnet-fnn/$node_id/$node_id.log"
done

ps aux | grep '[f]nn'
