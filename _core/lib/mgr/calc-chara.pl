################## データ保存 ##################
use strict;
#use warnings;
use utf8;

require $set::data_races;
require $set::data_class;

sub data_calc {
  my %pc = %{$_[0]};
  my %st;
  ### アップデート --------------------------------------------------
  if($pc{ver}){
    %pc = data_update_chara(\%pc);
  }
  

  ### 経験点／ゴールド計算 --------------------------------------------------
  ## 履歴から 
  $pc{moneyTotal}   = 0;
  #$pc{depositTotal} = 0;
  #$pc{debtTotal}    = 0;
  $pc{payment}    = 0;
  $pc{expTotal}   = s_eval($pc{history0Exp});
  $pc{moneyTotal} = s_eval($pc{history0Money});
  foreach my $i (1 .. $pc{historyNum}){
    if($pc{"history${i}Check"}) {
      $pc{expTotal} += s_eval($pc{"history${i}Exp"});
    }
    $pc{payment}    += s_eval($pc{"history${i}Payment"});
    $pc{moneyTotal} += s_eval($pc{"history${i}Money"});
  }
  $pc{expTotal} -= $pc{payment};
  $pc{historyExpTotal} = $pc{expTotal};
  $pc{historyMoneyTotal} = $pc{moneyTotal};
  ## 収支履歴計算
  my $cashbook = $pc{cashbook};
  $cashbook =~ s/::((?:[\+\-\*\/]?[0-9]+)+)/$pc{moneyTotal} += eval($1)/eg;
  #$cashbook =~ s/:>((?:[\+\-\*\/]?[0-9]+)+)/$pc{depositTotal} += eval($1)/eg;
  #$cashbook =~ s/:<((?:[\+\-\*\/]?[0-9]+)+)/$pc{debtTotal} += eval($1)/eg;
  #$pc{moneyTotal} += $pc{debtTotal} - $pc{depositTotal};

  ## スキルレベル
  $pc{skillLvTotal} = $pc{skillLvGeneral} = 0;
  my %skill;

  $pc{skillLvLimitAdd} = !$pc{skillLvLimitAdd} ? '' : $pc{skillLvLimitAdd} > 0 ? "+$pc{skillLvLimitAdd}" : $pc{skillLvLimitAdd};



## 成長点消費（MGR仕様フロントエンド連携）
  # 編集画面から送られてきた各消費項目を単純に合計し、残りを算出する
  $pc{expUsed} = ($pc{expUsedLevel} || 0)
               + ($pc{expUsedGeneralSkills} || 0)
               + ($pc{expUsedConnections} || 0)
               + ($pc{expUsedJoubika} || 0)
               + ($pc{expUsedStt} || 0);
  $pc{expRest} = $pc{expTotal} - $pc{expUsed};
  


### クラス・能力値（MGR仕様） --------------------------------------------------
  # キャラクター一覧（index）の表示用に、代表クラスを抽出してセットします
  $pc{classMain}    = $pc{"class1Name"} || '';
  $pc{classSupport} = $pc{"class2Name"} || '';
  $pc{classTitle}   = $pc{"class3Name"} || '';

  # キャラクターレベル(CL)のバックエンド再計算（一覧画面用）
  $pc{level} = 0;
  foreach my $i (1 .. $pc{classesNum}){
    $pc{level} += $pc{"class${i}Lv"} || 0;
  }

  # ※MGRの能力値は全てフロントエンド（JS）で緻密に計算・出力されており、
  # formから送信された値をそのままデータベースに保存するため、
  # ここにあったAR2E用の能力値・HP・フェイト等の再計算ロジックは全て削除しました。


 

  ### グレード自動変更 --------------------------------------------------
  if (@set::grades){
    my $flag;
    foreach(@set::grades){
      if ($pc{group} eq @$_[0]){ $flag = 1; last; }
    }
    if($flag ne ''){
      foreach(@set::grades){
        if ($pc{level} <= @$_[1] && $pc{expTotal} <= @$_[2]){ $pc{group} = @$_[0]; last; }
      }
    }
  }

  ### 0を消去 --------------------------------------------------
  foreach my $s ('Str','Dex','Agi','Int','Sen','Mnd','Luk'){
    foreach my $type ('Make','BaseAdd','Main','Support','Add'){
      delete $pc{'stt'.$s.$type} if !$pc{'stt'.$s.$type};
    }
    delete $pc{'roll'.$s.'Add'} if !$pc{'roll'.$s.'Add'};
  }
  #### 改行を<br>に変換 --------------------------------------------------
  foreach (
    'words',
    'items',
    'freeNote',
    'freeHistory',
    'cashbook',
    'chatPalette',
    'armamentHandRNote',
    'armamentHandLNote',
    'armamentHeadNote',
    'armamentBodyNote',
    'armamentSubNote',
    'armamentOtherNote',
    'armamentTotalNote',
    'battleSkillNote',
    'battleOtherNote',
  ){
    $pc{$_} =~ s/\r\n?|\n/<br>/g;
  }
  foreach my $i (1 .. $pc{geisesNum}){
    $pc{"geis${i}Note"} =~ s/\r\n?|\n/<br>/g;
  }
  
  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }

  #### エスケープ --------------------------------------------------
  $pc{$_} = pcEscape($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});
  
  ### 最終参加卓 --------------------------------------------------
  foreach my $i (reverse 1 .. $pc{historyNum}){
    if($pc{"history${i}Gm"} && $pc{"history${i}Title"}){ $pc{lastSession} = removeTags unescapeTags $pc{"history${i}Title"}; last; }
  }

  ### newline --------------------------------------------------
### newline --------------------------------------------------
  my $charactername = ($pc{aka} ? "“$pc{aka}”" : "").$pc{characterName};
  $charactername =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  
  # ▼ エラーの原因解決：クラスを「/」区切りで繋げた文字列（$classes）を生成する
  my @class_list;
  foreach my $i (1 .. ($pc{classesNum} || 1)) {
    push(@class_list, $pc{"class${i}Name"}) if $pc{"class${i}Name"};
  }
  my $classes = join('/', @class_list);
  # ▲ ここまで ▲

  $pc{lastSession} = removeTags unescapeTags $pc{lastSession};

  # ▼ 保存用の1行データを生成（番目がズレないように空の <> を補填しています）
  $::newline = "$pc{id}<>$::file<>".
               "$pc{birthTime}<>$::now<>$charactername<>$pc{playerName}<>$pc{group}<>".
               "$pc{image}<> $pc{tags} <>$pc{hide}<>".
               "$pc{cover}<>$pc{gender}<>$pc{age}<>".
               "$pc{expTotal}<>$pc{level}<>$classes<>$pc{mechaName}<><><><>".
               "$pc{lastSession}<>";

  return %pc;
}


1;