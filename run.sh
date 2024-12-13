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

  # 对于 id 大于 1 的节点，更新配置文件中的端口
  if [ $id -gt 1 ]; then
    # 计算端口号
    fiber_port=$((8227 + 2 * (id - 1)))
    rpc_port=$((8227 + 2 * (id - 1) + 1))

    # 更新配置文件中的端口
    yq eval ".fiber.listening_addr = \"/ip4/127.0.0.1/tcp/$fiber_port\"" -i "testnet-fnn/node$id/config.yml"
    yq eval ".rpc.listening_addr = \"127.0.0.1:$rpc_port\"" -i "testnet-fnn/node$id/config.yml"
  fi
  # 打印配置情况
  echo "node$id config.yml"
  yq eval '.fiber.listening_addr' "testnet-fnn/node$id/config.yml"
  yq eval '.rpc.listening_addr' "testnet-fnn/node$id/config.yml"
  echo ""
done

# 启动节点
for ((id = $start_node_id; id <= $end_node_id; id++)); do
  RUST_LOG=info ./fnn -c "testnet-fnn/node$id/config.yml" -d "testnet-fnn/node$id" >"./node$id.log" 2>&1 &
done
