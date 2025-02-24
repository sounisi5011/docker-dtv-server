FROM chinachu/mirakurun

# ビルド環境構築
RUN apt update && apt upgrade -y
RUN apt install -y wget git autoconf automake

# デコーダーのインストール
WORKDIR /tmp
RUN wget https://github.com/tsukumijima/libaribb25/releases/download/v0.2.9/libaribb25_0.2.9_amd64.deb
RUN apt install ./libaribb25_0.2.9_amd64.deb

# recpt1のインストール
WORKDIR /tmp
RUN git clone https://github.com/stz2012/recpt1.git
WORKDIR /tmp/recpt1/recpt1
RUN ./autogen.sh
RUN ./configure
RUN make -j8
RUN make install

WORKDIR /app
