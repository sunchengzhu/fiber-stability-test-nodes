# 操作步骤

## 三个fiber节点的地址和私钥

```bash
exhibit cruise private verify sister guess glass square write cash nurse auction

path, address, private key

m/44'/309'/0'/0/0, ckt1qzda0cr08m85hc8jlnfp3zer7xulejywt49kt2rr0vthywaa50xwsq0hf9ulez8r0esm7rvepf9ghme3zr24chs7lagpw, 0x35debfbe25ff8aef84c17a87f951d8a94bdb5390f5fb849a6e1ed77062b32109

m/44'/309'/0'/0/1, ckt1qzda0cr08m85hc8jlnfp3zer7xulejywt49kt2rr0vthywaa50xwsq2ln20a2z9nwprnvuj8hnm3ll9glgus25qgvytyv, 0x25b9ced77b10ed9c5c51a22312d8a56673e55fcde58fe4fef0a0e3ecbf718d5f

m/44'/309'/0'/0/2, ckt1qzda0cr08m85hc8jlnfp3zer7xulejywt49kt2rr0vthywaa50xwsqgruvf3a8wp68d28esv088wm6lnxffv5qgv3ahp9, 0x74ef635fc910c1a50ea76c1aef83d8a93ea770a7ca44eb8855e30d99bab7dbe6
```

## 编译出liunx arm架构的fnn二进制

由于本机为 Apple Silicon（ARM64）架构，Docker 在本地默认以 linux/arm64 平台运行容器，因此建议使用linux/arm64 的二进制。

```bash
cd fiber-dockerfile
git clone https://github.com/nervosnetwork/fiber.git
# 把Dockerfile放到fiber目录下
cp Dockerfile fiber/
# 编译出包含fnn二进制的镜像
docker buildx build --platform linux/arm64 -f Dockerfile -t fiber-fnn-builder:arm64 ./fiber --load
# 创建临时容器
cid=$(docker create fiber-fnn-builder:arm64)
# 拷贝到后续docker compose需要的目录下
docker cp "$cid":/out/fnn ../fnn
# 删除临时容器
docker rm "$cid"
# 验证架构
file ../../fnn
# 验证版本
docker run --rm --platform linux/arm64 \
  -v "$PWD/../fnn:/fnn:ro" \
  debian:bookworm-slim \
  /fnn --version
```

## 运行docker compose

``` bash
# cd到docker目录下
cd ..
# 构建镜像并启动
docker compose build && docker compose up -d
# 删除容器和其镜像
docker compose down --rmi all
```

Docker compose会把node1、node2、node3启动起来并分配ip，容器的日志就是fnn的日志。

_之前测试的场景是1和2建了channel，2磁盘爆了，然后不影响1和3之间建channel和发交易。_

test容器会执行test.sh，做如下几件事：

1. 执行open_channel.sh，建立node1和node2之间的channel
2. 改了13_open_channel.sh和的shutdown_channel.sh配置，方便后续手动执行脚本
3. 每10s打印一次node1和node2、node1和node3之间的channel的余额

进入test容器执行`/app/test_1_to_2.sh`，即可测试转账，写了while true ，会一直转。

## 记得回收CKB
可以直接执行脚本

```bash
docker exec -it test /app/shutdown_channel.sh
```

调试命令

channel_id可以在test容器的日志中找到

```bash
TOKEN='EpECCqYBCgVwZWVycwoIcGF5bWVudHMKCGNoYW5uZWxzCghpbnZvaWNlcxgDIgkKBwgAEgMYgAgiCQoHCAESAxiACCIJCgcIARIDGIEIIgkKBwgAEgMYgQgiCQoHCAESAxiCCCIJCgcIABIDGIIIIggKBggAEgIYGCIJCgcIARIDGIMIMiYKJAoCCBsSBggFEgIIBRoWCgQKAggFCggKBiCAwODoBgoEGgIIAhIkCAASIC3KNA3sQcH7HueRbBDT-Kg9Lmu5LwcEy-OMKcCvtVqRGkCg8T6TWf9HIT5nOfBjB0gelDJMwpIjM9utyJQ9JI3m3L5Sll2AJIPNajGsBy0Ywmkx0Z5VFT3n1SlHuWMM_wMFIiIKIMnzUSJrPnRIaFZYVjxVJu64vI-Oi81uftHSZWcuCZUQ'

curl -sS 'http://172.30.0.1:8231' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "id": 1,
    "jsonrpc": "2.0",
    "method": "shutdown_channel",
    "params": [
      {
        "channel_id": "0xaac96d081210022b45d69ea1938794eae66d0b874f272c61ee5804c139040bce",
        "close_script": {
          "code_hash": "0x9bd7e06f3ecf4be0f2fcd2188b23f1b9fcc88e5d4b65a8637b17723bbda3cce8",
          "hash_type": "type",
          "args": "0xf74979fc88e37e61bf0d990a4a8bef3110d55c5e"
        },
        "fee_rate": "0x2710"
      }
    ]
  }' | jq
```

可以在这看shutdown的状态：http://18.167.71.41:8130/

**目前shutdown_channel会出现RPC ERROR**且节点自己没发起shutdown

```yaml
  2026-01-07T15:34:50.799239Z ERROR fnn::ckb::actor: [ckb] send transaction Byte32(0xfecd0e2e81e0c26f3b719b9c596e65f72ddeba5b4b854094fcf9a899c05101ca) failed: Rpc(Error { code: ServerError(-301), message: "TransactionFailedToResolve: Resolve failed Unknown(OutPoint(0x5a5288769cecde6451cb5d301416c297a6da43dc3ac2f3253542b4082478b19b00000000))", data: Some(String("Resolve(Unknown(OutPoint(0x5a5288769cecde6451cb5d301416c297a6da43dc3ac2f3253542b4082478b19b00000000)))")) })

    at crates/fiber-lib/src/ckb/actor.rs:183

    in ractor::actor::Actor with id: "0.23"


  2026-01-07T15:34:50.799354Z ERROR fnn::fiber::in_flight_ckb_tx_actor: failed to send tx Hash256(0xfecd0e2e81e0c26f3b719b9c596e65f72ddeba5b4b854094fcf9a899c05101ca) because of rpc error: jsonrpc error: `Server error: TransactionFailedToResolve: Resolve failed Unknown(OutPoint(0x5a5288769cecde6451cb5d301416c297a6da43dc3ac2f3253542b4082478b19b00000000))`

    at crates/fiber-lib/src/fiber/in_flight_ckb_tx_actor.rs:226

    in ractor::actor::Actor with id: "0.23"


  2026-01-07T15:35:19.265161Z ERROR fnn::fiber::in_flight_ckb_tx_actor: Closing transaction Hash256(0xfecd0e2e81e0c26f3b719b9c596e65f72ddeba5b4b854094fcf9a899c05101ca) failed to be confirmed with final status Rejected("{\"type\":\"Resolve\",\"description\":\"Resolve failed Unknown(OutPoint(0x5a5288769cecde6451cb5d301416c297a6da43dc3ac2f3253542b4082478b19b00000000))\"}")

    at crates/fiber-lib/src/fiber/in_flight_ckb_tx_actor.rs:301

    in ractor::actor::Actor with id: "0.23"


  2026-01-07T15:35:19.265628Z ERROR fnn::fiber::network: Closing transaction failed for channel Byte32(0xfecd0e2e81e0c26f3b719b9c596e65f72ddeba5b4b854094fcf9a899c05101ca), tx hash: Hash256(0x7f049379809997c7a19bc44acb70b139e5e93aaf4c58dcea799fdbdf376489eb), peer id: PeerId(QmVih63mUcaaohw7T9pW152Dd89MdrV7MweywHA8FX2ov6)

    at crates/fiber-lib/src/fiber/network.rs:923

    in ractor::actor::Actor with id: "0.23"
```

