# recisdbのダウンロード
# MirakurunのDockerイメージ内で行う場合、wgetコマンドを追加でインストールしなければならない。これは最終イメージサイズの増加に繋がる。
# そこでMulti-stage buildを採用し、MirakurunのDockerイメージにはダウンロード済のrecisdb.debのみをコピーすることで最終イメージサイズを削減する。
# Note: buildpack-deps:bookworm-curlは、wgetやcurlなどが予め同梱されている最小サイズのDockerイメージ。
#       これを使うことにより、事前ビルド時にダウンロードしなければならないイメージサイズも最小化し、
#       かつ、動的なapt-getコマンド実行を避けることでDockerイメージのビルド時間を高速化する。
FROM buildpack-deps:bookworm-curl AS download-recisdb
WORKDIR /app
RUN wget --no-verbose https://github.com/kazuki0824/recisdb-rs/releases/download/1.2.3/recisdb_1.2.3-1_arm64.deb -O ./recisdb.deb

# MirakurunのDockerイメージを起動
# digestでDockerイメージのバージョンを固定: chinachu/mirakurun:4.0.0-beta.18
FROM chinachu/mirakurun@sha256:0cfb0399862832ceea6db74e8397275d514dcae25e1a467be373a2ae0875deb9
WORKDIR /app
# recisdb.debをMirakurunのDockerイメージ内へコピー
COPY --from=download-recisdb /app/recisdb.deb /tmp
# recisdbのインストール
RUN apt-get install --assume-yes --no-install-recommends /tmp/recisdb.deb && rm /tmp/recisdb.deb
