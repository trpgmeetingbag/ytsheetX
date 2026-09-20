################## データ保存 ##################
use strict;
#use warnings;
use utf8;

require $set::data_class_mgr;

sub dataCalc {
  my %pc = %{$_[0]};
  my %st;
  
  ### アップデート --------------------------------------------------
  if($pc{ver}){
    %pc = upgradeCharaData(\%pc);
  }

  ### 経験点計算 --------------------------------------------------
  ## 履歴から 
  $pc{expTotal} = s_eval($pc{history0Exp});
  foreach my $i (1 .. $pc{historyNum}){
    if($pc{"history${i}Check"}) {
      $pc{expTotal} += s_eval($pc{"history${i}Exp"});
    }
  }
  $pc{historyExpTotal} = $pc{expTotal};

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
  foreach my $s ('Tai','Han','Chi','Ri','Ishi','Kou'){
    delete $pc{'sttPoint'.$s}    if !$pc{'sttPoint'.$s};
    delete $pc{'sttGrow'.$s}     if !$pc{'sttGrow'.$s};
    delete $pc{'sttSkill'.$s}    if !$pc{'sttSkill'.$s};
    delete $pc{'sttOther'.$s}    if !$pc{'sttOther'.$s};
    delete $pc{'sttBonusAdd'.$s} if !$pc{'sttBonusAdd'.$s};
  }

  #### 改行を<br>に変換 --------------------------------------------------
#### 改行を<br>に変換 --------------------------------------------------
  convertNewlinesToBrTag(\%pc,
    qw/freeNote freeHistory chatPalette/,
    ( map { 'words'.$_ } '', 2 .. ($set::image_maxcount || 1) ),
  );
  
  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }

  #### エスケープ --------------------------------------------------
  $pc{$_} = escapePcData($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});
  
  ### 最終参加卓 --------------------------------------------------
  foreach my $i (reverse 1 .. $pc{historyNum}){
    if($pc{"history${i}Gm"} && $pc{"history${i}Title"}){ $pc{lastSession} = removeTags unescapeTags $pc{"history${i}Title"}; last; }
  }

  ### updatedLine --------------------------------------------------
  my %NL;
  $NL{name}  = ($pc{aka} ? "“$pc{aka}”" : "").$pc{characterName};
  $NL{$_} = $pc{$_} foreach ('playerName','cover','gender','age','mechaName');
  foreach (keys %NL){
    $NL{$_} =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
    $NL{$_} = removeTags unescapeTags $NL{$_} =~ s/^\s|\s$//gr;
  }
  
  if(length($NL{name}) > 108){
    if($NL{name} =~ s/“.+”//r){ $NL{name} =~ s/“.+”// }
    if(length($NL{name}) > 108){
      $NL{name} = substr($NL{name}, 0, 108).'..' if length($NL{name}) > 108;
    }
  }
  $NL{playerName} = substr($NL{playerName}, 0, 25).'..' if length($NL{playerName}) > 25;
  $NL{cover}      = substr($NL{cover}     , 0, 20).'..' if length($NL{cover}     ) > 20;
  $NL{gender}     = substr($NL{gender}    , 0, 20).'..' if length($NL{gender}    ) > 20;
  $NL{age}        = substr($NL{age}       , 0, 20).'..' if length($NL{age}       ) > 20;
  $NL{mechaName}  = substr($NL{mechaName} , 0, 30).'..' if length($NL{mechaName} ) > 30;

  # ▼ システム名を一覧画面(list-chara)に送るための準備
  $NL{srsSystem} = $pc{srsSystem} || 'メタリックガーディアンRPG';
  $NL{srsSystem} =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  $NL{srsSystem} = removeTags unescapeTags $NL{srsSystem} =~ s/^\s|\s$//gr;
  $NL{srsSystem} = substr($NL{srsSystem}, 0, 30).'..' if length($NL{srsSystem}) > 30;

  my @class_list;
  foreach my $i (1 .. ($pc{classesNum} || 1)) {
    push(@class_list, $pc{"class${i}Name"}) if $pc{"class${i}Name"};
  }
  $NL{classes} = join('/', @class_list);
  $NL{classes} =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;
  $NL{classes} = removeTags unescapeTags $NL{classes} =~ s/^\s|\s$//gr;
  $NL{classes} = substr($NL{classes}, 0, 40).'..' if length($NL{classes}) > 40;

  $pc{lastSession} = removeTags unescapeTags $pc{lastSession};

  $::updatedLine =
    "$pc{id}<>$::file<>"
    . "$pc{birthTime}<>$::now<>$NL{name}<>$NL{playerName}<>$pc{group}<>"
    . setUpdatatLineImage(\%pc)."<> $pc{tags} <>$pc{hide}<>"
    . "$NL{cover}<>$NL{gender}<>$NL{age}<>"
    . "$pc{expTotal}<>$pc{level}<>$NL{classes}<>$NL{mechaName}<>$NL{srsSystem}<><><>"
    . "$pc{lastSession}<>";

  return %pc;
}

1;