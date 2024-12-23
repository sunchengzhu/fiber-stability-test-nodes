# 获取公共 IP 地址
IP=$(curl -s ifconfig.me)

# 根据 IP 地址决定要删除的节点
case "$IP" in
"18.167.71.41")
  # 删除除 node1 到 node5 以外的节点 (即删除 node6, node7, node8)
  rm -rf ../fiber/tmp/testnet-fnn/node{6..8}
  ;;
"43.198.254.225")
  # 删除除 node6 外的节点 (即删除 node1 到 node5 和 node7 到 node8)
  rm -rf ../fiber/tmp/testnet-fnn/node{1..5} ../fiber/tmp/testnet-fnn/node{7..8}
  ;;
"43.199.108.57")
  # 删除除 node7 和 node8 外的节点 (即删除 node1 到 node6)
  rm -rf ../fiber/tmp/testnet-fnn/node{1..6}
  ;;
*)
  echo "不支持的 IP 地址: $IP"
  ;;
esac

ls ../fiber/tmp/testnet-fnn

cd ../fiber/tmp
for dir in $(ls -d ./testnet-fnn/node*); do
  node_id=$(basename "$dir")
  RUST_LOG=info ./fnn -c "$dir/config.yml" -d "$dir" >"./testnet-fnn/$node_id/$node_id.log" 2>&1 &
done

ps aux | grep '[f]nn'