FROM debian:bookworm-slim
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
    ca-certificates libgcc-s1 libstdc++6 bash curl jq \
  && rm -rf /var/lib/apt/lists/*

COPY fnn /app/fnn
RUN chmod +x /app/fnn && mkdir -p /app/node/ckb

ENV FIBER_SECRET_KEY_PASSWORD=123 \
    RUST_LOG=info \
    PATH="/app:${PATH}"

CMD ["/app/fnn", "-c", "/app/config.yml", "-d", "/app/node"]
