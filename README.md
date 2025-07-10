# docker-dtv-server

Dockerで構築する[Mirakurun] + [EDCB]構成のTV録画環境

[Mirakurun]: https://github.com/Chinachu/Mirakurun
[EDCB]: https://github.com/xtne6f/EDCB

## 概要

2025年の現時点でsounisi5011が調査した限りもっともモダンな構成である、[Mirakurun]と[xtne6f版EDCB][EDCB]を組み合わせたTV録画環境を構築するためのDockerおよびDocker Compose設定ファイル。
[fork元]では[KonomiTV]も採用しているが、この構成は[KonomiTVがサポートしないと明記しているRaspberry Pi 5](https://github.com/tsukumijima/KonomiTV/blob/bfe9577c004bd53bae4cae889245f7a1940798ba/Readme.md#%E5%8B%95%E4%BD%9C%E7%92%B0%E5%A2%83)での稼働を想定しているため、録画機能のみに絞り[KonomiTV]は採用していない。

[fork元]: https://github.com/nunawa/docker-dtv-server

本構成では、録画した`.m2ts`ファイルのエンコード処理などは **一切行わない想定** である点に注意。録画した大容量の`.m2ts`ファイルはNASなどに転送し、別途用意した端末にて[VLCメディアプレイヤー][VLC]で再生する。

[KonomiTV]: https://github.com/tsukumijima/KonomiTV
[VLC]: https://www.videolan.org/vlc/

## fork元からの変更点

- [KonomiTV]の導入を止める
- [recpt1](https://github.com/stz2012/recpt1)および[libaribb25](https://github.com/tsukumijima/libaribb25)の代わりに[recisdb]を使用
- Dockerのログを[`json-file`](https://docs.docker.com/engine/logging/drivers/json-file/)の代わりに[`journald`](https://docs.docker.com/engine/logging/drivers/journald/)を使って書き込む
- 初回起動時に[ISDBScanner]や自動起動コンテナを使用して[Mirakurun]および[EDCB]の設定ファイルを自動生成
  - `Common.ini`
    `/record`を録画保存フォルダとして使用する設定で作成
  - `EpgTimerSrv.ini`
    - `HttpAccessControlList`に`+192.168.0.0/16`を追記
    - 実際に検出したチューナー数に基づき、`BonDriver_LinuxMirakc`を利用するための設定を追記
- コンテナ起動時の[EDCB]のチャンネルスキャン実行を削除（[ISDBScanner]が生成するため不要と判断）
- [EDCB]のビルドに使用するベースイメージを`buildpack-deps:bookworm`に変更（Build Cacheの削減）
- [EDCB]のランタイム依存関係から`ffmpeg`と`ca-certificates`を削除
- [EDCB]用コンテナで設定ファイルのマウントが失敗していた不具合を修正（[`6e4e254`](https://github.com/sounisi5011/docker-dtv-server/commit/6e4e254563286f5ed62fd30c2b75434698af9d4f)）
- 各コンテナに[`pull_policy: never`](https://docs.docker.com/reference/compose-file/services/#pull_policy)を追加

[recisdb]: https://github.com/kazuki0824/recisdb-rs
[ISDBScanner]: https://github.com/tsukumijima/ISDBScanner

## 技術スタック

- [Mirakurun]
- [kazuki0824/recisdb-rs][recisdb]
- [xtne6f/EDCB][EDCB]
- [EDCB_Material_WebUI](https://github.com/EMWUI/EDCB_Material_WebUI)
- [BonDriver_LinuxMirakc](https://github.com/matching/BonDriver_LinuxMirakc)
- [Docker](https://www.docker.com/)

## Getting Started

### 前提条件

- ホストマシン上に以下のものが必要：
  - Docker
  - px4_drvなどのチューナードライバ
- ホストOSは[Raspberry Pi OS Lite (bookworm)](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-64-bit)を想定

### インストール

EDCB用に`EDCB/edcb`ディレクトリ以下に`Common.ini`、`EpgDataCap_Bon.ini`、`EpgTimerSrv.ini`を作成する。`EpgTimerSrv.ini`の以下の項目は使用するチューナーに合わせて変更すること。

```ini
[BonDriver_LinuxMirakc.so]
Count=4     # チューナー数
GetEpg=1
EPGCount=2  # EPG取得に使用するチューナー数
Priority=0
```

デフォルトの録画保存先ディレクトリは`EDCB/record`。必要に応じて`compose.yaml`のedcbサービスのボリューム設定を変更すること。

```yaml
      - type: bind
        source: "./EDCB/record" # ここを変更
        target: "/record"
```

設定が完了したら、以下のコマンドでDockerイメージをビルドし、コンテナを起動する：

```bash
docker compose up -d
```

最初にチューナースキャン用のコンテナが立ち上がり、続いてMirakurun、EDCBチャンネルスキャン用のコンテナ、最後にEDCBが立ち上がる。チューナースキャンには7分前後、チャンネルスキャンには3〜4分ほどかかるため、完了するまで待ってからEDCBにアクセスする。チャンネルスキャンが必要ない場合は、次のコマンドでスキップ可能：

```bash
docker compose up -d --no-deps mirakurun edcb
```

## ライセンス

docker-dtv-serverは[fork元]同様MITライセンスのもとで公開
