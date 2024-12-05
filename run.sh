#!/bin/bash

pkill fnn
rm -rf fiber

git clone https://github.com/nervosnetwork/fiber.git
cd fiber
cargo build --release
wget https://github.com/nervosnetwork/ckb/releases/download/v0.117.0/ckb_v0.117.0_aarch64-apple-darwin-portable.zip
unzip ckb_v0.117.0_aarch64-apple-darwin-portable.zip
mkdir tmp

cp target/release/fnn tmp
cp ckb_v0.117.0_aarch64-apple-darwin-portable/ckb-cli tmp
cd tmp

# 节点范围定义
start_node=1
end_node=8

# 检查是否已存在 announce_private_addr
if ! yq eval '.fiber.announce_private_addr' "../config/testnet/config.yml" | grep -q true; then
  yq eval '.fiber.announce_private_addr = true' -i "../config/testnet/config.yml"
fi
yq eval '.fiber.announce_private_addr' "../config/testnet/config.yml"

# 创建目录、复制配置文件并设置密钥
for ((node = $start_node; node <= $end_node; node++)); do
  mkdir -p "testnet-fnn/node$node/ckb"
  cp "../config/testnet/config.yml" "testnet-fnn/node$node/config.yml"
  sed -n "${node}p" "../../keys.txt" >"testnet-fnn/node$node/ckb/key"
done

# 更新配置并打印配置情况
for ((node = $start_node + 1; node <= $end_node; node++)); do
  # 计算端口号
  fiber_port=$((8225 + 2 * node))
  rpc_port=$((8225 + 2 * node + 1))

  # 更新配置
  yq eval ".fiber.listening_addr = \"/ip4/127.0.0.1/tcp/$fiber_port\"" -i "testnet-fnn/node$node/config.yml"
  yq eval ".rpc.listening_addr = \"127.0.0.1:$rpc_port\"" -i "testnet-fnn/node$node/config.yml"

  # 打印配置情况
  echo "node$node config.yml"
  yq eval '.fiber.listening_addr' "testnet-fnn/node$node/config.yml"
  yq eval '.rpc.listening_addr' "testnet-fnn/node$node/config.yml"
  echo ""
done

# 启动节点
for ((node = $start_node; node <= $end_node; node++)); do
  RUST_LOG=info ./fnn -c "testnet-fnn/node$node/config.yml" -d "testnet-fnn/node$node" >>"./node$node.log" 2>&1 &
done
