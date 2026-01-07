# 操作步骤

### 三个fiber节点的地址和私钥

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
docker cp "$cid":/out/fnn ../../fnn
# 删除临时容器
docker rm "$cid"
# 验证架构
file ../../fnn
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

删容器之前记得shutdown

```bash
docker exec -it test /app/shutdown_channel.sh
```

可以在这看shutdown的状态：http://18.167.71.41:8130/

