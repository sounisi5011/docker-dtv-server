#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use List::Util;

# 入力ファイル全体を読み込む
# ダイヤモンド演算子`<>`と、入力レコードセパレーター`$/`の一時的な変更を駆使して、ファイルの全内容を変数に格納する
# see https://perlzemi.com/blog/20080722121673.html
# see https://qiita.com/mhangyo/items/081f15ece23d6249e74c#%E7%89%B9%E6%AE%8A%E5%A4%89%E6%95%B0%E3%82%92%E7%A9%BA%E3%81%AB%E3%81%99%E3%82%8B
my $content = do { local $/; <> };

my %count_hash;
# インデントされた配列要素全体にマッチさせループ処理
# see https://www.koikikukan.com/archives/2014/11/21-015555.php
while ($content =~ /^( *)-[^\n]*(?:\n\1 +[^\n]*)*$/gm) {
  my $array_str = $&;

  # isDisabledフィールドの値がfalseか判定
  # もしfalseでなければ、この配列要素をスキップ
  my $is_enabled = $array_str =~ /^ *(?:- *)?isDisabled: *false *$/m;
  next if !$is_enabled;

  # インデントされたtypesフィールド全体の取得
  if ($array_str =~ /^( *)types:(?:\n\1 +-[^\n]+)+|^( *)-( *)types:(?:\n\2 \3 +-[^\n]+)+/m) {
    # 先頭の`types:`を置換して削除
    # rフラグを使用して変数`$&`を書き換えずに置換結果を代入
    # see http://basicwerk.com/blog/archives/1777
    my $types_value = $& =~ s/^[ -]*types://r;

    # 格納された各配列要素ごとに出現数をカウント
    while ($types_value =~ /^ +- *(\w+)/gm) {
      my $type = $1;
      $count_hash{$type}++;
    }
  }
}

# count_hashに格納された全ての値のうち、最小の値を取得
# see https://jp-seemore.com/sys/21582/#toc8
my $min_count = List::Util::min(values(%count_hash));
print $min_count;
