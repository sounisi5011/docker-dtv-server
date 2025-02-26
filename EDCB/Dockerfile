FROM debian:bookworm-slim

# ビルド環境構築
RUN apt update && apt install -y \
    git \
    make \
    gcc \
    g++ \
    liblua5.2-dev \
    lua-zlib \
    curl \
    ffmpeg

# EDCBのインストール
WORKDIR /tmp
RUN git clone -b work-plus-s-250124 --depth=1 \
    https://github.com/xtne6f/EDCB.git
WORKDIR /tmp/EDCB/Document/Unix
RUN make -j8
RUN make install
RUN make extra -j8
RUN make install_extra
RUN mkdir /var/local/edcb
RUN chmod 777 /var/local/edcb
RUN make setup_ini
RUN sed -i -e 's/^ALLOW_SETTING=.*/ALLOW_SETTING=true/' \
    /var/local/edcb/HttpPublic/legacy/util.lua
COPY ./config/EpgTimerSrv.ini /var/local/edcb/EpgTimerSrv.ini
COPY ./config/EpgDataCap_Bon.ini /var/local/edcb/EpgDataCap_Bon.ini

# EDCB Material WebUIのインストール
WORKDIR /tmp
RUN git clone --depth=1 https://github.com/EMWUI/EDCB_Material_WebUI.git
WORKDIR /tmp/EDCB_Material_WebUI
RUN cp -r HttpPublic /var/local/edcb/
RUN cp -r Setting /var/local/edcb/

# BonDriver_LinuxMirakcのインストール
WORKDIR /tmp
RUN git clone --depth=1 --recurse-submodules \
    https://github.com/matching/BonDriver_LinuxMirakc.git
WORKDIR /tmp/BonDriver_LinuxMirakc
RUN make -j8
RUN cp BonDriver_LinuxMirakc.so /usr/local/lib/edcb
RUN cp BonDriver_LinuxMirakc.so.ini_sample \
    /usr/local/lib/edcb/BonDriver_LinuxMirakc.so.ini
RUN mkdir /var/local/edcb/Setting/EpgData

# デバッグ用に移動しておく
WORKDIR /var/local/edcb

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

CMD [ "/usr/local/bin/entrypoint.sh" ]
