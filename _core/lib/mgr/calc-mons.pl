################## データ保存 ##################
use strict;
#use warnings;
use utf8;

require $set::data_mons;

sub dataCalc {
  my %pc = %{$_[0]};

  ####  --------------------------------------------------
  $pc{partsNum} ||= 1;
  # 分類リストで「その他」が選ばれ、自由入力された場合のフォロー[cite: 3]
  if(!$pc{taxa} && $pc{taxaSelect} eq 'その他'){ $pc{taxa} = 'その他' }

  #### 改行を<br>に変換 --------------------------------------------------
  # 特殊能力（特技）や解説欄の改行をHTMLタグに変換[cite: 3]
  convertNewlinesToBrTag(\%pc,
    qw/skills description chatPalette/,
  );

  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }

  #### ★「その他」選択時の自由記入欄の上書き反映 ---------------------------------
  if ($pc{system} eq 'その他' && $pc{systemFree} ne '') {
    $pc{system} = $pc{systemFree};
  }
  if ($pc{taxa} eq 'その他' && $pc{taxaFree} ne '') {
    $pc{taxa} = $pc{taxaFree};
  }

  #### エスケープ --------------------------------------------------
  $pc{$_} = escapePcData($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});

  ### updatedLine 用のデータ整形 --------------------------------------------------
  my %NL;
  $NL{name} = $pc{characterName} ? $pc{characterName} : $pc{monsterName};
  
  # システム名と分類
  $NL{system} = $pc{system} || '未定義';
  $NL{taxa}   = (($pc{taxa} && !grep { @$_[0] eq $pc{taxa} } @data::taxa) ? 'その他:' : '') . $pc{taxa};

  # ★サブカテゴリが入力されていれば、分類の横に（）付きで結合して一覧用に保存する
  if ($pc{subTaxa} ne '') {
    $NL{taxa} .= "（$pc{subTaxa}）";
  }

# ★ここから追記：特技・加護の抽出と文字列化
  my %extracted_skills;
  
  # %pc（保存される全ての入力データ）の中身を丸ごと連結して検索対象にする
  my $target_texts = join("\n", values %pc);
  
  while ($target_texts =~ /《(.+?)》/g) {
    my $skill = $1;
    
    # バイト破壊を起こす tr/// ではなく、安全な s///g を使って全角化する
    $skill =~ s/\(/（/g;
    $skill =~ s/\)/）/g;
    $skill =~ s/:/：/g;
    
    $extracted_skills{$skill} = 1;
  }
  
  # %NL に格納（この後 $::updatedLine に連結させる）
  $NL{skill_search} = join(',', keys %extracted_skills);
  
  # base-listの1要素目の値（基本的にレベルが入る）
  $NL{base1}  = $pc{base1Value} || '';

  $NL{$_} = $pc{$_} foreach ('author');

  foreach (keys %NL){
    $NL{$_} =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
    $NL{$_} = removeTags unescapeTags $NL{$_} =~ s/^\s|\s$//gr;
  }
  
  # 文字数制限（一覧画面のレイアウト崩れ防止）[cite: 3]
  $NL{name}    = substr($NL{name}   , 0, 108).'..' if length($NL{name}   ) > 108;
  $NL{author}  = substr($NL{author} , 0,  25).'..' if length($NL{author} ) >  25;
  $NL{system}  = substr($NL{system} , 0,  40).'..' if length($NL{system} ) >  40;
  $NL{taxa}    = substr($NL{taxa}   , 0,  20).'..' if length($NL{taxa}   ) >  20;
  $NL{base1}   = substr($NL{base1}  , 0,  15).'..' if length($NL{base1}  ) >  15;

  $pc{hide} = 'IN' if(!$pc{hide} && $pc{description} =~ /#login-only/i);
  
  # SRS用の updatedLine 生成（list.cgi等で読み込む並び順になります）
  $::updatedLine =
    "$pc{id}<>$::file<>"
    . "$pc{birthTime}<>$::now<>$NL{name}<>$pc{author}<>$NL{system}<>$NL{taxa}<>$NL{base1}<>"
    . setUpdatatLineImage(\%pc)."<> $pc{tags} <>$pc{hide}<>"
    . "$pc{partsNum}<>$NL{skill_search}<>";

  return %pc;
}

1;