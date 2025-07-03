# docker-dtv-server

Dockerで構築するMirakurun + EDCB構成のTV録画環境

## 技術スタック

- [Mirakurun](https://github.com/Chinachu/Mirakurun)
- [tsukumijima/libaribb25](https://github.com/tsukumijima/libaribb25)
- [stz2012/recpt1](https://github.com/stz2012/recpt1)
- [xtne6f/EDCB](https://github.com/xtne6f/EDCB)
- [EDCB_Material_WebUI](https://github.com/EMWUI/EDCB_Material_WebUI)
- [BonDriver_LinuxMirakc](https://github.com/matching/BonDriver_LinuxMirakc)
- [Docker](https://www.docker.com/)

## Getting Started

### 前提条件

- ホストPC上に以下のものが必要です：
  - Docker
  - px4_drvなどのチューナードライバ
- ホストOSは[Raspberry Pi OS Lite (bookworm)](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-64-bit)を想定しています。

### インストール

Mirakurun用に`mirakurun/conf`ディレクトリ以下にchannels.yml、tuners.ymlを作成してください。
[ISDBScanner](https://github.com/tsukumijima/ISDBScanner)などで自動生成できます。

EDCB用に`EDCB/edcb`ディレクトリ以下にCommon.ini、EpgDataCap_Bon.ini、EpgTimerSrv.iniを作成してください。
EpgTimerSrv.iniの以下の項目はお使いのチューナーに合わせて変更してください。

```ini
[BonDriver_LinuxMirakc.so]
Count=4     # チューナー数
GetEpg=1
EPGCount=2  # EPG取得に使用するチューナー数
Priority=0
```

デフォルトの録画保存先ディレクトリは`EDCB/record`に設定されています。必要に応じてcompose.yamlのedcbサービスのボリューム設定を変更してください。

```yaml
      - type: bind
        source: "./EDCB/record" # ここを変更
        target: "/record"
```

設定が完了したら、以下のコマンドでDockerイメージをビルドし、コンテナを起動します：

```bash
docker compose up -d
```

最初にEDCBチャンネルスキャン用のコンテナが立ち上がります。チャンネルスキャンには3〜4分ほどかかりますので、完了するまで待ってからEDCBにアクセスしてください。

チャンネルスキャンが必要ない場合は、次のコマンドでスキップできます：

```bash
docker compose up -d --no-deps mirakurun edcb
```

## ライセンス

docker-dtv-serverは、MITライセンスのもとで公開されています。
