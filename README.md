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

[recisdb]: https://github.com/kazuki0824/recisdb-rs

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

Mirakurun用に`mirakurun/conf`ディレクトリ以下に`channels.yml`、`tuners.yml`を作成する。[ISDBScanner](https://github.com/tsukumijima/ISDBScanner)などで自動生成可能。

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

最初にEDCBチャンネルスキャン用のコンテナが立ち上がる。チャンネルスキャンには3〜4分ほどかかるため、完了するまで待ってからEDCBにアクセスする。チャンネルスキャンが必要ない場合は、次のコマンドでスキップ可能：

```bash
docker compose up -d --no-deps mirakurun edcb
```

## ライセンス

docker-dtv-serverは[fork元]同様MITライセンスのもとで公開
