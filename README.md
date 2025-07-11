# docker-dtv-server

Dockerで構築する[Mirakurun] + [EDCB]構成のTV録画環境

[Mirakurun]: https://github.com/Chinachu/Mirakurun
[EDCB]: https://github.com/xtne6f/EDCB

## 概要

2025年の現時点でsounisi5011が調査した限りもっともモダンな構成である、[Mirakurun]と[xtne6f版EDCB][EDCB]を組み合わせたTV録画環境を構築するためのDockerおよびDocker Compose設定ファイル。
[fork元]では[KonomiTV]も採用しているが、この構成は[KonomiTVがサポートしないと明記しているRaspberry Pi 5](https://github.com/tsukumijima/KonomiTV/blob/bfe9577c004bd53bae4cae889245f7a1940798ba/Readme.md#%E5%8B%95%E4%BD%9C%E7%92%B0%E5%A2%83)での稼働を想定しているため、録画機能のみに絞り[KonomiTV]は採用していない。

[fork元]: https://github.com/nunawa/docker-dtv-server

本構成では、リアルタイム視聴および録画した番組の再生に必要なエンコード処理などは **一切行わない想定** である点に注意。前述したとおり録画機能のみに特化しており、サーバ単体ではライブ視聴もできない。

録画した大容量の`.ts`ファイルはNASなどに転送し、別途用意した端末にて[VLCメディアプレイヤー][VLC]で再生する。

リアルタイム視聴は[Mirakurun]の`/api/channels/{type}/{channel}/services/{id}/stream`や`/api/services/{id}/stream`から[VLCメディアプレイヤー][VLC]で観ることができる。しかし[EDCB]を経由しない方法なので非推奨。チューナーを確保できず録画が失敗する可能性がある（未検証）。

[KonomiTV]: https://github.com/tsukumijima/KonomiTV
[VLC]: https://www.videolan.org/vlc/

## fork元からの変更点

- [KonomiTV]の導入を止める
- ホストのpcscdを使う
  - `/var/run/pcscd/pcscd.comm`が存在しない場合は、コンテナの起動そのものを禁止する
- [recpt1](https://github.com/stz2012/recpt1)および[libaribb25](https://github.com/tsukumijima/libaribb25)の代わりに[recisdb]を使用
- Dockerのログを[`json-file`](https://docs.docker.com/engine/logging/drivers/json-file/)の代わりに[`journald`](https://docs.docker.com/engine/logging/drivers/journald/)を使って書き込む
- 初回起動時に[ISDBScanner]や自動起動コンテナを使用して[Mirakurun]および[EDCB]の設定ファイルを自動生成
  - `./EDCB/edcb/Common.ini`  
    `/record`を録画保存フォルダとして使用する設定で作成
  - `./EDCB/edcb/EpgTimerSrv.ini`
    - `HttpAccessControlList`に`+192.168.0.0/16`を追記
    - 実際に検出したチューナー数に基づき、`BonDriver_LinuxMirakc`を利用するための設定を追記
- [EDCB]の録画保存先ディレクトリを環境変数`DTV_RECORD_DIR_PATH`で定義できるように変更
- 情報通知ログ、デバッグ出力ログ、同梱プラグインの設定ファイルもホスト側の`./EDCB/edcb`内にマウントするように変更
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
  - pcscd
  - px4_drvなどのチューナードライバ
- ホストOSは[Raspberry Pi OS Lite (bookworm)](https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-64-bit)を想定

### インストール

本構成全体を格納するディレクトリへ移動後、以下のコマンドでこのリポジトリをダウンロード：

```bash
# ダウンロード先ディレクトリの名称を変えたい場合は指定すること（この例では./dtv-server）
# 省略した場合はdocker-dtv-serverになる
git clone --depth 1 https://github.com/sounisi5011/docker-dtv-server.git ./dtv-server
```

その後、ダウンロードしたディレクトリ内（`./compose.yaml`ファイルが存在するディレクトリの直下）へ移動し、コンテナを起動する。

最初にチューナー・チャンネルスキャン用のコンテナが立ち上がり、続いてMirakurun、EDCB設定ファイル事前作成用のコンテナ、最後にEDCBが立ち上がる。チューナースキャンとチャンネルスキャンには7分前後かかるため、完了するまで待ってからEDCBにアクセスする。

> [!NOTE]
> ラズパイなどの、SDカードがメインストレージのシングルボードコンピュータで運用する場合、
> 外付けHDDやSSDなどを接続してマウントしたうえで、録画保存先ディレクトリを変更（下の方にやり方を記載）して起動する事を強く推奨する。
>
> SDカードは寿命が短く、容量も少ないため、録画データの記録先には不適当。

```bash
docker compose up -d
```

コンテナを停止する場合は以下のコマンドを実行。

```bash
docker compose down
```

構成内のシェルスクリプトや`Dockerfile`を変更した場合は、`--build`オプションを指定してコンテナを再構築してから起動すること。

```bash
docker compose up -d --build
```

デフォルトの録画保存先ディレクトリは`./EDCB/record`。環境変数`DTV_RECORD_DIR_PATH`を指定することで変更することができる。
以下のいずれかの方法を選択（方法2は方法1の設定を上書きする）：

1. `.env`ファイルを`compose.yaml`と同じ階層に作成。

    ```
    DTV_RECORD_DIR_PATH=/mnt/sda1/record
    ```

    その後、コンテナを起動する。

    ```bash
    docker compose up -d
    ```

2. コンテナの起動時に環境変数`DTV_RECORD_DIR_PATH`を指定する。

    ```bash
    DTV_RECORD_DIR_PATH=/mnt/sda1/record docker compose up -d
    ```

## 設定ファイルやデータファイルなどの配置場所

Mirakurunの設定ファイルやデータファイルは`./mirakurun/`ディレクトリ以下に、EDCBの設定ファイルやデータファイルは`./EDCB/edcb/`ディレクトリ以下に配置される。

作成されたファイルの一覧を確認したい場合は、以下のコマンドを実行することで表示できる。  
※正確には、`.gitignore`で無視されているファイルの一覧を表示するコマンド。

```bash
git ls-files -oi --exclude-standard
```

なお、EDCBは`/var/local/edcb/`ディレクトリ内の特定の設定ファイルやログファイルを個別にマウントしている関係上、一部のファイルは上記コマンドでは確認できない。  
（`/var/local/edcb/HttpAccess.log`、新しく導入したプラグインによって生成された未知の設定ファイル、など）

確認したい場合は、`docker diff`コマンドを使って新規作成・更新されたファイルの一覧を確認し、

```bash
docker diff EDCB
# Mirakurunの場合は`docker diff Mirakurun`
```

必要に応じて、`docker exec`コマンドなどで内部から確認する。

```bash
# EDCBのコンテナ内でBashを起動して入る
docker exec -it EDCB bash
# EDCBのコンテナ内でlsを実行する
docker exec EDCB ls -lhpa /var/local/edcb/
```

## ファイル名変換PlugIn および 出力PlugIn の設定に関わる注意事項

> [!NOTE]
> とくに明記しない限り、以下の説明にある`/usr/local/lib/edcb/`や`/var/local/edcb/`はEDCBのコンテナ内のファイルパスである点に注意。
> ホストのラズパイにsshで入った状態で`/usr/local/lib/edcb/`や`/var/local/edcb/`を確認しても何も無い。
>
> もし直接確認する必要がある場合は、コンテナ起動後に`docker exec -it EDCB bash`コマンドでEDCBのコンテナ内のシェルに入ったり、`docker cp`コマンドでホスト↔コンテナ間でファイルをコピーすること。

EDCBは`/usr/local/lib/edcb/`ディレクトリ直下に置かれた2種類のプラグインファイルを認識する。

+ ファイル名変換PlugIn（`RecName*.so`ファイルを自動で認識）
+ 出力PlugIn（`Write*.so`ファイルを自動で認識）

各プラグインに対して設定を書き込むと、EDCBは`/var/local/edcb/`ディレクトリ内に`{プラグインファイル名}.ini`という名称の設定ファイルを作成する。

+ `RecName_Macro.so` → `RecName_Macro.so.ini`
+ `Write_Default.so` → `Write_Default.so.ini`

もし、`/usr/local/lib/edcb/`ディレクトリ内に追加のプラグインを導入する場合は、`./compose.yaml`のedcbサービスのボリューム設定を変更すること。

```yaml
...
      # ファイル名変換PlugInの設定ファイル
      # Note: もし /usr/local/lib/edcb ディレクトリ内に RecName*.so ファイルを追加配置する場合は、
      #       対応する設定ファイルのパスもここに記載しマウントすること。
      #       EDCB/setup-ini.sh の更新も忘れずに。
      - ./EDCB/edcb/RecName_Macro.so.ini:/var/local/edcb/RecName_Macro.so.ini
      # 出力PlugInの設定ファイル
      # Note: もし /usr/local/lib/edcb ディレクトリ内に Write*.so ファイルを追加配置する場合は、
      #       対応する設定ファイルのパスもここに記載しマウントすること。
      #       EDCB/setup-ini.sh の更新も忘れずに。
      - ./EDCB/edcb/Write_Default.so.ini:/var/local/edcb/Write_Default.so.ini
...
```

また、対応する設定ファイルを（空の内容で良いので）事前に作成するか、もしくは`./EDCB/setup-ini.sh`を編集して自動作成するように変更すること。

```bash
...
for filename in 'Common.ini' 'EpgDataCap_Bon.ini' 'EpgTimerSrv.ini' \
    'EpgTimerSrvDebugLog.txt' 'EpgTimerSrvNotify.log' \
    'RecName_Macro.so.ini' \
    'Write_Default.so.ini' \
; do
...
```

変更しなければ、コンテナを終了するたびにプラグインの設定が消滅してしまうので注意。

## オススメ設定

この構成では[Mirakurun]および[EDCB]の各種設定ファイルを自動生成しており、必須の設定を書き込んでいる。

だが、必須ではないが推奨される設定項目もある。以下にメモとして書き残しておく。必要であれば手動でファイルを編集すること。

> [!IMPORTANT]
> EDCBの設定ファイルを自動生成する`PrepareEDCB-CreateConfigFiles`コンテナでは、
> **既存の設定ファイルが存在しないまたは空の場合に生成**する。
> 言い換えれば、空ではない設定ファイルの場合はいかなる内容であっても上書きされない。  
> ※`EpgTimerSrv.ini`のチューナー数設定を除く
>
> 手動で設定ファイルを編集する場合は、コンテナ起動後に書き込むか、
> もしくは以下のコマンドを実行した後に編集すること。
>
> ```bash
> docker compose run edcb_create_config
> ```

### `./EDCB/edcb/EpgTimerSrv.ini`

`SaveNotifyLog=1`、`SaveDebugLog=1`、あとはRecName_Macroを使用するための設定をオススメする。

```ini
[SET]
; HTTPサーバを有効化。自動生成されるので書き換えなくても可。
EnableHttpSrv=2
; HTTPサーバのアクセス制御。自動生成されるので書き換えなくても可。
HttpAccessControlList=+127.0.0.1,+::1,+::ffff:127.0.0.1,+192.168.0.0/16
; 情報通知ログの保存を有効化。EDCB/edcb/EpgTimerSrvNotify.logファイルに書き込まれる。
; トラブル時に確認するため有効化したほうが良いだろう。
SaveNotifyLog=1
; デバッグ出力の保存を有効化。EDCB/edcb/EpgTimerSrvDebugLog.txtファイルに書き込まれる。
; トラブル時に確認するため有効化したほうが良いだろう。
SaveDebugLog=1
; 録画時のファイル名にファイル名変換PlugInのRecName_Macro.so（Windows版EDCBにおけるRecName_Macro.dll）を使用。
; 使用しない場合、録画ファイルのファイル名にはEpgDataCap_Bonの録画ファイル名設定が使われるらしい（未確認）。
; RecName_Macroはとても便利なので必ず有効化すべし。
RecNamePlugIn=1
RecNamePlugInFile=RecName_Macro.so
; 以下、チューナー数設定。自動生成されるうえにWeb UIからの編集のほうが分かりやすいので書き換えなくても可。
[BonDriver_LinuxMirakc.so]
Count=4
GetEpg=1
EPGCount=2
Priority=0
```

### `./EDCB/edcb/RecName_Macro.so.ini`

ファイル名変換PlugInの`RecName_Macro.so`（Windows版EDCBにおける`RecName_Macro.dll`）を使ってどのような録画ファイル名にするかの設定。
個人的には`20XX-11-21-01-28.放送局名半角英数.[新]番組名半角英数[字][デ].ts`書式を使っている。

```ini
[SET]
Macro=$SDYYYY$-$SDMM$-$SDDD$-$STHH$-$STMM$.$ZtoH(ServiceName)$.$ZtoH(Title)$.ts
```

## ライセンス

docker-dtv-serverは[fork元]同様MITライセンスのもとで公開
