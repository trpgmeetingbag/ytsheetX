################## データ保存 ##################
use strict;
#use warnings;
use utf8;

require $set::data_class;

sub data_calc {
  my %pc = %{$_[0]};
  ### アップデート --------------------------------------------------
  if($pc{ver}){
    %pc = data_update_chara(\%pc);
  }
  
  ### ステータス（強化値） --------------------------------------------------
  my @sttKeys = ('Buso', 'HenI', 'Kaizo');
  my @sttKeysLower = ('buso', 'heni', 'kaizo');
  my $totalGrow = 0;
  
  for(my $i = 0; $i < 3; $i++) {
    my $k = $sttKeys[$i];
    my $kl = $sttKeysLower[$i];
    
    # 選択されたクラスから基本値を取得
    if($pc{mainClass} ne 'free' && $data::NCclass_status{$pc{mainClass}}){
      $pc{"main$k"} = (ref($data::NCclass_status{$pc{mainClass}}) eq 'ARRAY') ? $data::NCclass_status{$pc{mainClass}}->[$i] : 0;
    }
    if($pc{subClass} ne 'free' && $data::NCclass_status{$pc{subClass}}){
      $pc{"sub$k"}  = (ref($data::NCclass_status{$pc{subClass}}) eq 'ARRAY') ? $data::NCclass_status{$pc{subClass}}->[$i] : 0;
    }
    
    my $mainVal = $pc{"main$k"} || 0;
    my $subVal  = $pc{"sub$k"}  || 0;
    my $preVal  = ($pc{sttPre} eq $kl) ? 1 : 0;
    $pc{"pre$k"} = $preVal;
    my $growVal = $pc{"grow$k"} || 0;
    my $addVal  = $pc{"add$k"}  || 0;
    
    $totalGrow += $growVal;
    $pc{"sttTotal$k"} = $mainVal + $subVal + $preVal + $growVal + $addVal;
  }
  
  ### サブステータス（行動値） --------------------------------------------------
  my $skillInitiative = 0;
  for my $i (1 .. $pc{skillNum}){
    next if $pc{"skill${i}CalcOff"};
    next if $pc{"skill${i}Damage"};
    $skillInitiative += $pc{"skill${i}Initiative"} || 0;
  }
  $pc{initiativeTotal} = 6 + $skillInitiative;
  $pc{initiativeTotal} = 0 if $pc{initiativeTotal} < 0;
  
  ### 寵愛点計算 --------------------------------------------------
  my $expTotal = $pc{history0Exp} || 0;
  my $totalMiren = 0;
  my $totalInsanity = 0;
  my $totalBase = 0;
  my $totalEnhanced = 0;
  
  for my $i (1 .. $pc{historyNum}){
    $expTotal += $pc{"history${i}Exp"} || 0;
    $totalMiren    += $pc{"history${i}Miren"} || 0;
    $totalInsanity += $pc{"history${i}Insanity"} || 0;
    $totalBase     += $pc{"history${i}BasePart"} || 0;
    $totalEnhanced += $pc{"history${i}EnhancedPart"} || 0;
  }
  
  my $expMiren = $totalMiren * 2;
  my $expInsanity = $totalInsanity * 4;
  my $expBase = $totalBase * 4;
  my $expEnhanced = $totalEnhanced * 6;
  
  my $usedStatus = $totalGrow * 10;
  
  # スキル取得にかかる消費
  my $countClass = 0;
  my $countOther = 0;
  my @validClasses;
  push(@validClasses, $pc{positionFree} || $pc{position}) if $pc{position};
  push(@validClasses, $pc{mainClassFree} || $pc{mainClass}) if $pc{mainClass};
  push(@validClasses, $pc{subClassFree} || $pc{subClass}) if $pc{subClass};
  
  for my $i (1 .. $pc{skillNum}){
    next if $pc{"skill${i}Position"} ne 'skill';
    next if $pc{"skill${i}CalcOff"};
    
    my $source = ($pc{"skill${i}Source"} eq 'free' && $pc{"skill${i}SourceFree"}) ? $pc{"skill${i}SourceFree"} : $pc{"skill${i}Source"};
    next if !$source;
    next if $source =~ /^(武装|変異|改造|基本パーツ|たからもの)$/;
    
    if(grep { $_ eq $source } @validClasses){
      $countClass++;
    } else {
      $countOther++;
    }
  }
  
  my $usedSkillClass = $countClass * 10 - 40;
  my $usedSkillOther = $countOther * 20;
  
  $pc{expTotal} = $expTotal;
  $pc{expUsed} = $usedStatus + $usedSkillClass + $usedSkillOther + $expMiren + $expInsanity + $expBase + $expEnhanced;
  $pc{expRest} = $pc{expTotal} - $pc{expUsed};
  
  #### 改行を<br>に変換 --------------------------------------------------
  $pc{words}         =~ s/\r\n?|\n/<br>/g;
  $pc{freeNote}      =~ s/\r\n?|\n/<br>/g;
  $pc{freeHistory}   =~ s/\r\n?|\n/<br>/g;
  $pc{chatPalette}   =~ s/\r\n?|\n/<br>/g;
  $pc{"skill${_}Note"}   =~ s/\r\n?|\n/<br>/g foreach (1 .. $pc{skillNum});
  
  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }
  
  #### エスケープ --------------------------------------------------
  $pc{$_} = pcEscape($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});
  
  ### 最終参加卓 --------------------------------------------------
  foreach my $i (reverse 1 .. $pc{historyNum}){
    if($pc{"history${i}Gm"} && $pc{"history${i}Title"}){ $pc{lastSession} = removeTags unescapeTags $pc{"history${i}Title"}; last; }
  }

  ### newline（キャラクター一覧表示用の1行データ） --------------------------------------------------
  my $charactername = ($pc{aka} ? "“$pc{aka}”" : "").$pc{characterName};
  
  my $class_text = "";
  $class_text .= ($pc{positionFree} || $pc{position}) if $pc{position};
  $class_text .= " / ".($pc{mainClassFree} || $pc{mainClass}) if $pc{mainClass};
  $class_text .= " / ".($pc{subClassFree} || $pc{subClass}) if $pc{subClass};
  
  # index.cgi等のキャラクター一覧で表示するための項目順
  $::newline = "$pc{id}<>$::file<>".
               "$pc{birthTime}<>$::now<>$charactername<>$pc{playerName}<>$pc{group}<>".
               "$pc{expTotal}<><>$pc{age}<>$pc{height}<>$pc{weight}<>$pc{anji}<>".
               "$class_text<><>".
               "$pc{lastSession}<>$pc{image}<> $pc{tags} <>$pc{hide}<>$pc{placement}<>";

  return %pc;
}

1;