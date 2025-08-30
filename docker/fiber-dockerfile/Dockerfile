# 仅用于“编译出二进制”，不含运行环境
# 支持 amd64 / arm64，按 --platform 切
FROM --platform=$BUILDPLATFORM rust:1.80-bullseye AS builder

# 选择输出目标三元组
ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive

# RocksDB 及 C/C++ 构建依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake clang pkg-config \
    zlib1g-dev libbz2-dev liblz4-dev libzstd-dev libsnappy-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# 先缓存依赖（加速后续构建）
COPY Cargo.toml Cargo.lock ./
# 若是 workspace，可额外 COPY 各子 crate 的 Cargo.toml（可选）
RUN mkdir -p src && echo "fn main(){}" > src/main.rs && cargo build --release || true

# 正式拷贝源码
COPY . .

# 计算目标 triple
# arm64 -> aarch64-unknown-linux-gnu；amd64 -> x86_64-unknown-linux-gnu
RUN case "$TARGETARCH" in \
      arm64) echo aarch64-unknown-linux-gnu > /rust-target ;; \
      amd64) echo x86_64-unknown-linux-gnu  > /rust-target ;; \
      *) echo "Unsupported TARGETARCH=$TARGETARCH" && exit 1 ;; \
    esac \
 && rustup target add "$(cat /rust-target)"

# 对 rocksdb-sys 友好
ENV ROCKSDB_SYS_PORTABLE=1 ROCKSDB_SYS_FORCE_FPIC=1

# 编译 fiber 的二进制：fnn
RUN cargo build --release --bin fnn --target "$(cat /rust-target)"

# 导出产物到固定路径
RUN mkdir -p /out && cp "target/$(cat /rust-target)/release/fnn" /out/fnn
