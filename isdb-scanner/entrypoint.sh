#!/bin/bash

##### ISDBScannerを実行 #####
isdb-scanner ./isdb-scanner-result

##### Mirakurun用の設定ファイルを作成 #####
cp ./isdb-scanner-result/Mirakurun/{channels.yml,tuners.yml} /mirakurun-config/

##### EDCB用の設定ファイルを作成 #####

# ChSet5.txtを作成する
# Note: Linux版EDCBのChSet5.txtは改行コードがLFである一方、
#       Windows版EDCBのChSet5.txtは改行コードはCRLFであるため、
#       改行コードを変換してコピーする
< ./isdb-scanner-result/EDCB-Wine/ChSet5.txt tr -d '\r' > /edcb-setting/ChSet5.txt

# ChSet4.txtを作成する
# Note: 検証した結果、ISDBScannerが作成するWindows版EDCB & BonDriver_mirakc向けのChSet4.txtと
#       実際に生成したLinux版EDCB & BonDriver_LinuxMirakc向けのChSet4.txtのファイル内容は
#       + 改行コードが異なる
#       + chNameが"Terrestrial:${physical_channel}"形式ではなく"${network_name}"形式
#       である点以外は等しいと思われるため、ISDBScannerの内部処理をjqコマンドで再現して生成する
#       see https://github.com/tsukumijima/ISDBScanner/blob/d491e8ac73be354a79aa071c3f8023b89d2d22ec/isdb_scanner/formatter.py#L123-L219
# Note: 現検証環境上ではBSおよびCSを受信できず、適切なファイル形式の調査が不可能なため、
#       BonDriver_LinuxMirakcに対応したBS・CS用のChSet4.txtファイルの作成処理は書いていない
{
  # ファイルの先頭にUTF08 BOMを出力する
  # Note: 調査の結果、Linux版EDCBの場合でもChSet4.txtはUTF-8 BOM形式だったため、念の為に従っておく
  echo -n $'\xef\xbb\xbf';
  # ISDBScannerのスキャン結果JSONからChSet4.txtのTSVデータを生成し出力する
  jq --raw-output '
      .Terrestrial | sort_by(.physical_channel) | to_entries[] | .value as $info | .key as $info_index
      | $info.services | sort_by(.service_id)[] as $service
      | [
        $info.network_name,
        $service.service_name,
        $info.network_name,
        0,
        $info_index,
        $info.network_id,
        $info.transport_stream_id,
        $service.service_id,
        $service.service_type,
        if $service.is_oneseg then 1 else 0 end,
        if $service.service_type | IN(1, 165, 173) then 1 else 0 end,
        $info.remote_control_key_id // 0
      ] | join("\t")
    ' \
    ./isdb-scanner-result/Channels.json
} > '/edcb-setting/BonDriver_LinuxMirakc(LinuxMirakc).ChSet4.txt'
