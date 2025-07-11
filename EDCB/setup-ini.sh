#!/bin/bash

# Bashの安全措置
# + 途中でエラーが発生したら即座に終了
# + 未定義変数はエラー
# + パイプの終了コードを伝播させる
set -euo pipefail

readonly DEST_DIR="${1%/}"

# EDCBの使用チューナー数をあらかじめ設定
# この設定を追記することで、EDCBが起動した直後からEPG取得を開始できる。
# 事前設定しない場合、Web UIから設定を変更した後にEDCBを再起動する必要がある。
# see https://github.com/xtne6f/EDCB/blob/2b714764ff87199995a68efa065f759816c7bcee/Document/Readme.txt#L84-L86
# Note: 生成された各種iniファイルを確認した限りではUTF-8 LFテキストだったため、おそらくこの書き込み方法で問題はないはず。
#       とはいえ、EDCBのソースコードを確認できていないため確証はない。
#       ChSet4.txtとChSet5.txtはUTF-8 with BOM LFであり、iniファイルと同じではない。不安は残る。
TUNER_COUNT="$(/usr/local/bin/get-tuner-count.pl /mirakurun-config/tuners.yml)"
readonly TUNER_COUNT
# Countは使用可能なチューナー数、EPGCountは使用可能チューナー数の半分に設定
# Bashの算術式を用いて、TUNER_COUNTが奇数の場合は1足した数を算出する
# see https://qiita.com/akinomyoga/items/2dd3f341cf15dd9c330b
cat << END_OF_INI >> /var/local/edcb/EpgTimerSrv.ini
[BonDriver_LinuxMirakc.so]
Count=${TUNER_COUNT}
GetEpg=1
EPGCount=$(( (TUNER_COUNT%2 == 0) ? (TUNER_COUNT/2) : (TUNER_COUNT/2+1) ))
Priority=0
END_OF_INI

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
