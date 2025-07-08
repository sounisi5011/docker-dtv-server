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
