#!/bin/bash

pkill fnn
cd ..
rm -rf fiber && mkdir fiber && cd fiber

if [ "$1" == "debug" ]; then
  download_url="http://github-test-logs.ckbapp.dev/fiber/fnn_tunning-find-path_20250418_1515-x86_64-linux-portable.tar.gz"
elif [ "$1" == "develop" ]; then
  download_url="http://github-test-logs.ckbapp.dev/fiber/fnn_develop_20250418_1447-x86_64-linux-portable.tar.gz"
elif [ -z "$1" ] || [ "$1" == "latest" ]; then
  download_url=$(curl -s https://api.github.com/repos/nervosnetwork/fiber/releases |
    jq -r '.[0].assets[] | select(.name | endswith("linux-portable.tar.gz")) | .browser_download_url')
else
  fiber_version="$1"
  download_url="https://github.com/nervosnetwork/fiber/releases/download/v${fiber_version}/fnn_v${fiber_version}-x86_64-linux-portable.tar.gz"
fi
wget -q "$download_url"
tar xzvf fnn_*-linux-portable.tar.gz

# 节点范围定义
start_node_id=1
end_node_id=8

# 创建目录、复制配置文件并设置密钥，同时更新配置并打印配置情况
for ((id = $start_node_id; id <= $end_node_id; id++)); do
  # 创建目录并复制配置文件
  mkdir -p "testnet-fnn/node$id/ckb"
  cp "config/testnet/config.yml" "testnet-fnn/node$id/config.yml"
  sed -n "${id}p" "../keys.txt" >"testnet-fnn/node$id/ckb/key"
  chmod 600 "testnet-fnn/node$id/ckb/key"

  # 计算端口号
  fiber_port=$((8220 + id))
  rpc_port=$((8230 + id))

  # 根据 id 修改配置文件中的地址
  if [ "$id" -eq 6 ] || [ "$id" -eq 7 ]; then
    yq eval '.fiber.announce_private_addr = true' -i "testnet-fnn/node${id}/config.yml"
  fi
  ip="0.0.0.0"

  # 更新配置文件中的地址
  yq eval ".fiber.listening_addr = \"/ip4/$ip/tcp/$fiber_port\"" -i "testnet-fnn/node$id/config.yml"
  yq eval ".rpc.listening_addr = \"$ip:$rpc_port\"" -i "testnet-fnn/node$id/config.yml"

  # 打印配置情况
  echo "node$id config.yml"
  yq eval '.fiber.listening_addr' "testnet-fnn/node$id/config.yml"
  yq eval '.rpc.listening_addr' "testnet-fnn/node$id/config.yml"
  echo ""
done
