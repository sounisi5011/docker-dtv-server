FROM buildpack-deps:bookworm AS builder

# ビルド環境構築
# see https://github.com/xtne6f/EDCB/blob/2b714764ff87199995a68efa065f759816c7bcee/Document/HowToBuild.txt#%E3%83%93%E3%83%AB%E3%83%89linux
# see https://github.com/matching/BonDriver_LinuxMirakc/blob/cfbefc6d21dab4009db5f124984c1b720b76d869/README.md#%E3%83%93%E3%83%AB%E3%83%89%E6%96%B9%E6%B3%95
RUN apt-get update \
    && apt-get install --assume-yes --no-install-recommends \
        make gcc g++ \
        liblua5.2-dev lua-zlib \
        curl ca-certificates \
        git \
    && rm --recursive --force /var/lib/apt/lists/*
WORKDIR /tmp

# EDCBのビルド
# see https://github.com/xtne6f/EDCB/blob/2b714764ff87199995a68efa065f759816c7bcee/Document/HowToBuild.txt#%E3%83%93%E3%83%AB%E3%83%89linux
RUN git clone --branch work-plus-s-250531 --depth 1 \
        https://github.com/xtne6f/EDCB.git ./EDCB \
    && cd ./EDCB/Document/Unix \
    && make --jobs="$(nproc)" \
    && make install \
    && make extra --jobs="$(nproc)" \
    && make install_extra \
    && mkdir --parents /var/local/edcb \
    && make setup_ini \
    && sed --in-place 's/^ALLOW_SETTING=.*/ALLOW_SETTING=true/' \
        /var/local/edcb/HttpPublic/legacy/util.lua

# EDCB Material WebUIのインストール
# see https://github.com/EMWUI/EDCB_Material_WebUI/blob/1156dddc12773e14b68ff929e9decb0b5330c636/README.md#%E5%B0%8E%E5%85%A5
RUN git clone --depth 1 https://github.com/EMWUI/EDCB_Material_WebUI.git ./EDCB_Material_WebUI \
    && cp --recursive ./EDCB_Material_WebUI/HttpPublic ./EDCB_Material_WebUI/Setting \
        /var/local/edcb/

# BonDriver_LinuxMirakcのビルド
# see https://github.com/matching/BonDriver_LinuxMirakc/blob/cfbefc6d21dab4009db5f124984c1b720b76d869/README.md#%E3%83%93%E3%83%AB%E3%83%89%E6%96%B9%E6%B3%95
RUN git clone --depth 1 --recurse-submodules \
        https://github.com/matching/BonDriver_LinuxMirakc.git ./BonDriver_LinuxMirakc \
    && cd ./BonDriver_LinuxMirakc \
    && make --jobs="$(nproc)" \
    && cp ./BonDriver_LinuxMirakc.so /usr/local/lib/edcb/ \
    && cp ./BonDriver_LinuxMirakc.so.ini_sample \
        /usr/local/lib/edcb/BonDriver_LinuxMirakc.so.ini

FROM debian:bookworm-slim AS runtime

# ランタイム依存関係のみインストール
RUN apt-get update \
    && apt-get install --assume-yes --no-install-recommends \
        liblua5.2-dev lua-zlib \
    && rm --recursive --force /var/lib/apt/lists/*

# ビルドステージから必要なファイルをコピー
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/lib/edcb/ /usr/local/lib/edcb/
RUN mkdir --parents /var/local/edcb \
    && chmod 777 /var/local/edcb
COPY --from=builder /var/local/edcb/ /var/local/edcb/

# デバッグ用に移動しておく
WORKDIR /var/local/edcb

# entrypoint.shをコピーして実行権限付与
COPY --chmod=755 ./entrypoint.sh /usr/local/bin/entrypoint.sh

CMD [ "/usr/local/bin/entrypoint.sh" ]
