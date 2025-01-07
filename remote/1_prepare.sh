#!/bin/bash

MODE=1

cd ..
pkill fnn

if [ "$MODE" -eq 1 ]; then
  rm -rf fiber
  git clone https://github.com/chenyukang/fiber.git
  cd fiber
  git checkout yukang-debug-send-each-other
  cargo build --release
else
  cd fiber
  rm -rf tmp
fi

mkdir tmp
cp target/release/fnn tmp
cd tmp

# 节点范围定义
start_node_id=1
end_node_id=8

# 检查是否已存在 announce_private_addr
if ! yq eval '.fiber.announce_private_addr' "../config/testnet/config.yml" | grep -q true; then
  yq eval '.fiber.announce_private_addr = true' -i "../config/testnet/config.yml"
fi
yq eval '.fiber.announce_private_addr' "../config/testnet/config.yml"

# 创建目录、复制配置文件并设置密钥，同时更新配置并打印配置情况
for ((id = $start_node_id; id <= $end_node_id; id++)); do
  # 创建目录并复制配置文件
  mkdir -p "testnet-fnn/node$id/ckb"
  cp "../config/testnet/config.yml" "testnet-fnn/node$id/config.yml"
  sed -n "${id}p" "../../keys.txt" >"testnet-fnn/node$id/ckb/key"
  chmod 600 "testnet-fnn/node$id/ckb/key"

  # 计算端口号
  fiber_port=$((8220 + id))
  rpc_port=$((8230 + id))

  # 根据 id 修改配置文件中的地址
#  if [ "$id" -ge 1 ] && [ "$id" -le 5 ]; then
#    ip="18.167.71.41"
#  elif [ "$id" -eq 6 ]; then
#    ip="43.198.254.225"
#  elif [ "$id" -ge 7 ] && [ "$id" -le 8 ]; then
#    ip="43.199.108.57"
#  fi
  ip=0.0.0.0

  # 更新配置文件中的地址
  yq eval ".fiber.listening_addr = \"/ip4/$ip/tcp/$fiber_port\"" -i "testnet-fnn/node$id/config.yml"
  yq eval ".rpc.listening_addr = \"$ip:$rpc_port\"" -i "testnet-fnn/node$id/config.yml"

  # 打印配置情况
  echo "node$id config.yml"
  yq eval '.fiber.listening_addr' "testnet-fnn/node$id/config.yml"
  yq eval '.rpc.listening_addr' "testnet-fnn/node$id/config.yml"
  echo ""
done
