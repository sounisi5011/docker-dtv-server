FROM buildpack-deps:bookworm-curl
WORKDIR /tmp

# jqコマンドのインストール
# entrypoint.sh内で使用する
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install --assume-yes --no-install-recommends jq

# recisdbのインストール
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    wget --no-verbose https://github.com/kazuki0824/recisdb-rs/releases/download/1.2.3/recisdb_1.2.3-1_arm64.deb -O ./recisdb.deb \
    && apt-get install --assume-yes --no-install-recommends /tmp/recisdb.deb \
    && rm /tmp/recisdb.deb

# isdb-scannerのインストール
RUN wget --no-verbose https://github.com/tsukumijima/ISDBScanner/releases/download/v1.3.2/isdb-scanner-arm -O /usr/local/bin/isdb-scanner \
    && chmod +x /usr/local/bin/isdb-scanner

# entrypoint.shをコンテナ内にコピー
COPY --chmod=755 ./entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /tmp
CMD [ "/usr/local/bin/entrypoint.sh" ]
