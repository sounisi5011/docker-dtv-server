#!/bin/bash

# Bashの安全措置
# + 途中でエラーが発生したら即座に終了
# + 未定義変数はエラー
# + パイプの終了コードを伝播させる
set -euo pipefail

# PID 1の時、Bashはシグナルを受け取った場合にプロセス停止処理を行わない。
# 結果、コンテナの停止時に子プロセスが正常終了せず、10秒ほどして強制終了され落とされる。
# これは好ましいことではないため、PID 1の場合は自前のプロセス停止処理を行う。
# see https://note.shiftinc.jp/n/ndc63c45d9f97
#     https://qiita.com/ko1nksm/items/e8c2fbf58687e6979448
#     https://github.com/Chinachu/Mirakurun/blob/61c4155d2535c56fbf6fd379c5e8aba779fd642b/docker/container-init.sh
if [[ $$ == 1 ]]; then
  function trap_exit() {
    local pids
    pids="$(jobs -p)"
    echo
    if [[ "$pids" != '' ]]; then
      # shellcheck disable=SC2086
      echo '[i] Stopping pid:' ${pids}
      # shellcheck disable=SC2086
      kill $pids > /dev/null 2>&1 || echo '[i] Already killed.'
    fi
    echo '[i] exit.'
  }
  trap 'exit 0' 2 3 15
  trap trap_exit 0
fi

CHANNELS_FILEPATH='/mirakurun-config/channels.yml'
TUNERS_FILEPATH='/mirakurun-config/tuners.yml'
CHSET4_FILEPATH='/edcb-setting/BonDriver_LinuxMirakc(LinuxMirakc).ChSet4.txt'
CHSET5_FILEPATH='/edcb-setting/ChSet5.txt'
SCAN_RESULT_DIRPATH=./isdb-scanner-result
readonly CHANNELS_FILEPATH TUNERS_FILEPATH CHSET4_FILEPATH CHSET5_FILEPATH SCAN_RESULT_DIRPATH

##### 設定ファイルの存在チェック #####
# すでに設定ファイルが作成済みである場合は、以降の処理を行わずに終了する
if [[ -s "${CHANNELS_FILEPATH}" && -s "${TUNERS_FILEPATH}" && -s "${CHSET4_FILEPATH}" && -s "${CHSET5_FILEPATH}" ]]; then
  echo 'All configuration files have been created'
  exit 0
fi

##### ISDBScannerを実行 #####
# Note: コンテナ停止時にISDBScannerを正常終了させるため、バックグラウンド実行しつつwaitコマンドで実行終了まで待機させる。
#       どういう理屈なのか見当がつかないが、これがなければコンテナ停止時に10秒ほど経過した後ISDBScannerを強制終了されてしまう。
isdb-scanner "${SCAN_RESULT_DIRPATH}" &
wait

##### Mirakurun用の設定ファイルを作成 #####
cp "${SCAN_RESULT_DIRPATH}/Mirakurun/channels.yml" "${CHANNELS_FILEPATH}"
cp "${SCAN_RESULT_DIRPATH}/Mirakurun/tuners.yml"   "${TUNERS_FILEPATH}"

##### EDCB用の設定ファイルを作成 #####

# ChSet5.txtを作成する
# Note: Linux版EDCBのChSet5.txtは改行コードがLFである一方、
#       Windows版EDCBのChSet5.txtは改行コードはCRLFであるため、
#       改行コードを変換してコピーする
< "${SCAN_RESULT_DIRPATH}/EDCB-Wine/ChSet5.txt" tr -d '\r' > "${CHSET5_FILEPATH}"

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
    "${SCAN_RESULT_DIRPATH}/Channels.json"
} > "${CHSET4_FILEPATH}"
