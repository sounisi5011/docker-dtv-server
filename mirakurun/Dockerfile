FROM chinachu/mirakurun

# ビルド環境構築
RUN apt update && apt install -y --no-install-recommends \
    wget \
    git \
    autoconf \
    automake \
    && rm -rf /var/lib/apt/lists/*

# デコーダーのインストール
WORKDIR /tmp
RUN wget https://github.com/tsukumijima/libaribb25/releases/download/v0.2.9/libaribb25_0.2.9_amd64.deb
RUN apt install ./libaribb25_0.2.9_amd64.deb

# recpt1のインストール
WORKDIR /tmp
RUN git clone --depth=1 https://github.com/stz2012/recpt1.git
WORKDIR /tmp/recpt1/recpt1
RUN ./autogen.sh
RUN ./configure
RUN make -j "$(nproc)"
RUN make install
RUN make clean

WORKDIR /app
