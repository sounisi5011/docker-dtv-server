# docker-dtv-server

Dockerで構築するMirakurun + EDCB + KonomiTVなTV視聴・録画環境

## Getting Started

### 前提条件

- ホストPC上に以下のものが必要です：
  - Docker
  - px4_drvなどのチューナードライバ
  - カードリーダ用のpcscd（ただしpcscd.socketは停止させてください）
- ホストOSはUbuntu 24.04 LTSを想定しています。

### インストール

Mirakurun用に`mirakurun/conf`ディレクトリ以下にchannels.yml、tuners.ymlを作成してください。
[ISDBScanner](https://github.com/tsukumijima/ISDBScanner)などで自動生成できます。

EDCB用に`EDCB/config`ディレクトリ以下にEpgTimerSrv.ini、EpgDataCap_Bon.iniを作成してください。
特に、EpgTimerSrv.iniの以下の項目はお使いのチューナーに合わせて変更してください。

```text
[BonDriver_LinuxMirakc.so]
Count=4
GetEpg=2
EPGCount=2
Priority=0
```

KonomiTV用に`KonomiTV`ディレクトリ以下にconfig.yamlを作成してください。

設定が完了したら、以下のコマンドでDockerイメージをビルドし、コンテナを起動します：

```bash
docker compose up -d
```

最初にEDCBチャンネルスキャン用のコンテナが立ち上がります。チャンネルスキャンには3〜4分ほどかかりますので、完了するまで待ってからEDCBとKonomiTVにアクセスしてください。

チャンネルスキャンが必要ない場合は、次のコマンドでスキップできます：

```bash
docker compose up -d --no-deps mirakurun edcb konomitv
```

## ライセンス

docker-dtv-serverは、MITライセンスのもとで公開されています。
