#!/bin/bash

cd ..
pkill fnn

#rm -rf fiber
#git clone https://github.com/nervosnetwork/fiber.git
cd fiber
#cargo build --release

rm -rf tmp && mkdir tmp && cd tmp

cp ../target/release/fnn .


# 节点范围定义
start_node_id=1
end_node_id=3

# 创建目录、复制配置文件并设置密钥，同时更新配置并打印配置情况
for ((id = $start_node_id; id <= $end_node_id; id++)); do
  # 创建目录并复制配置文件
  mkdir -p "testnet-fnn/node$id/ckb"
  cp "../config/testnet/config.yml" "testnet-fnn/node$id/config.yml"
  sed -n "${id}p" "../../keys.txt" >"testnet-fnn/node$id/ckb/key"

  # 检查是否已存在 announce_private_addr
  if ! yq eval '.fiber.announce_private_addr' "testnet-fnn/node$id/config.yml" | grep -q true; then
    yq eval '.fiber.announce_private_addr = true' -i "testnet-fnn/node$id/config.yml"
  fi

  # 计算端口号
  fiber_port=$((8220 + id))
  rpc_port=$((8230 + id))

  # 更新配置文件中的端口
  yq eval ".fiber.listening_addr = \"/ip4/127.0.0.1/tcp/$fiber_port\"" -i "testnet-fnn/node$id/config.yml"
  yq eval ".rpc.listening_addr = \"127.0.0.1:$rpc_port\"" -i "testnet-fnn/node$id/config.yml"
  # 打印配置情况
  echo "node$id config.yml"
  yq eval '.fiber.listening_addr' "testnet-fnn/node$id/config.yml"
  yq eval '.rpc.listening_addr' "testnet-fnn/node$id/config.yml"
  yq eval '.fiber.announce_private_addr' "testnet-fnn/node$id/config.yml"
  echo ""
done
