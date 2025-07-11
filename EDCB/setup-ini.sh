#!/bin/bash

# Bashの安全措置
# + 途中でエラーが発生したら即座に終了
# + 未定義変数はエラー
# + パイプの終了コードを伝播させる
set -euo pipefail

readonly DEST_DIR="${1%/}"

for filename in 'Common.ini' 'EpgDataCap_Bon.ini' 'EpgTimerSrv.ini'; do
  src_filepath="/var/local/edcb/${filename}"
  dest_filepath="${DEST_DIR}/${filename}"

  # 出力対象のiniファイルのパスに非ファイルが存在する場合は削除する
  if [[ -e "${dest_filepath}" && ! -f "${dest_filepath}" ]]; then
    rm --recursive --force "${dest_filepath}"
  fi

  # 出力対象のiniファイルが空ファイル、または、ファイルが存在しない場合は、デフォルトのiniファイルに置き換える
  if [[ ! -s "${dest_filepath}" ]]; then
    # デフォルトのiniファイルが存在しない場合は、空のファイルを作成する
    touch "${src_filepath}"
    # デフォルトのiniファイルに置き換える
    mv "${src_filepath}" "${dest_filepath}"
  fi
done

# EDCBの使用チューナー数を設定
# もしEpgTimerSrv.iniファイルに使用チューナー数の設定が書き込まれていない場合に追記する。
# この設定を追記することで、EDCBが起動した直後からEPG取得を開始できる。
# 事前設定しない場合、Web UIから設定を変更した後にEDCBを再起動する必要がある。
# see https://github.com/xtne6f/EDCB/blob/2b714764ff87199995a68efa065f759816c7bcee/Document/Readme.txt#L84-L86
#
# Note: 以下の場合は想定しない。
#
#       + `[BonDriver_LinuxMirakc.so]`は存在しているが、`Count`キーは未設定
#       + `[BonDriver_LinuxMirakc.so]`内に`Count`キーは存在するが、値の書式が不正
#
#       コンテナ起動前に既にEpgTimerSrv.iniが存在した場合に発生する可能性はあるが、
#       手動でEpgTimerSrv.iniを編集した場合のみのエッジケースであると思われる。
#       `[BonDriver_LinuxMirakc.so]`以下かつ他の`[...]`が出現するより前の位置の編集が必要であり、
#       適切なiniパーサ無しにBashの範囲で実現するのは困難と判断した。

# `[BonDriver_LinuxMirakc.so]`が記述された行にマッチする正規表現
# Note: EDCBのソースコードを参照したところ、行頭および行末のスペース文字、タブ文字、CR文字を無視していたため、従う。
#       see https://github.com/xtne6f/EDCB/blob/2b714764ff87199995a68efa065f759816c7bcee/Common/PathUtil.cpp#L868-L870
#       ただしCR文字に関しては、Linux版EDCBではiniファイルに含まれないものと思われる。
#       手動編集された場合への対策として想定しておく。
readonly BON_DRIVER_APPNAME_REGEX=$'(^|\n)[\t\r ]*\[BonDriver_LinuxMirakc\.so\][\t\r ]*(\n|$)'
readonly EPG_TIMER_SRV_FILEPATH="${DEST_DIR}/EpgTimerSrv.ini"
epgTimerSrvData="$(< "${EPG_TIMER_SRV_FILEPATH}")"
readonly epgTimerSrvData

# もし`[BonDriver_LinuxMirakc.so]`が存在しない場合は、EDCBの使用チューナー数を自動で取得して追記する
if [[ ! $epgTimerSrvData =~ $BON_DRIVER_APPNAME_REGEX ]]; then
  # Mirakurunのtuners.ymlファイルを解析し、チューナー数を取得する
  tunerCount="$(/usr/local/bin/get-tuner-count.pl /mirakurun-config/tuners.yml)"
  readonly tunerCount

  # EPGCountは使用可能チューナー数の半分に設定
  # Note: Bashの算術式を用いて、tunerCountが奇数の場合は1足した数を算出する
  #       see https://qiita.com/akinomyoga/items/2dd3f341cf15dd9c330b
  readonly epgCount="$(( (tunerCount%2 == 0) ? (tunerCount/2) : (tunerCount/2+1) ))"

  # Note: Linux版EDCBが生成するiniファイルはUTF-8 LFテキストだったため、おそらくこの書き込み方法で問題はないはず。
  #       ただし、EDCBのソースコードを厳密に確認できていないため確証はない。
  #       ChSet4.txtとChSet5.txtはUTF-8 with BOM LFであり、iniファイルと同じではない。不安は残る。
  # Note: 書き込み前のiniファイル末尾のLF文字の有無を正しく考慮するため、
  #       `>>`を使ってファイルに追記せず、変数の値と文字列結合してから書き込む。
  #       Bashではファイル内容を変数に格納した時点で末尾のLF文字が消えるため、
  #       末尾のLF文字が常に存在しない想定で処理することができる。
  cat << END_OF_INI > "${EPG_TIMER_SRV_FILEPATH}"
${epgTimerSrvData}
[BonDriver_LinuxMirakc.so]
Count=${tunerCount}
GetEpg=1
EPGCount=${epgCount}
Priority=0
END_OF_INI
fi
