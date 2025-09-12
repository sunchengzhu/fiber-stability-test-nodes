FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive TZ=Asia/Shanghai
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash curl jq tzdata openssl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY ./*.sh ./
RUN chmod +x ./*.sh

ENTRYPOINT ["/app/test.sh"]
