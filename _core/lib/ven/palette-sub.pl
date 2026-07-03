################## チャットパレット用サブルーチン ##################
use strict;
#use warnings;
use utf8;

### プリセット #######################################################################################
sub palettePreset {
  my $tool = shift;
  my $type = shift;
  my $text;
  my %bot;
  if   (!$tool)           { $bot{YTC} = 1; }
  elsif($tool eq 'tekey' ){ $bot{TKY} = $bot{BCD} = 1; }
  elsif($tool eq 'bcdice'){ $bot{BCD} = 1; }
  ## ＰＣ
  if(!$type){
    # 基本判定
    $text .= "VT+{レベル}\@12#(2+{BS}) レベル判定\n";
    $text .= "VT3+{レベル}\@12#(2+{BS}) レベル判定[ :アドバンテージ-1 ]n";
    $text .= "VT\@12#(2+{BS})>={カルマ} カルマ判定\n";
    $text .= "VT\@12#(2+{BS})>={カルマ} カルマ判定[ :カルマ+1L ]\n";
    $text .= "VT3\@12#(2+{BS})>={カルマ} カルマ判定[ :カルマ+1L ][ :アドバンテージ-1 ]\n";
    $text .= "\n";
    $text .= ":アドバンテージ+1 クレジット変化なし\n";
    $text .= ":アドバンテージ+1 :クレジット+\n";
    $text .= ":カルマ-L\n";
    $text .= ":プライド+L\n";
    $text .= ":プライド-L\n";
    $text .= ":BS+\n";
    $text .= ":BS-L\n";
    $text .= ":リロード+\n";
    $text .= ":リロード-L\n";
    $text .= ":バリア+\n";
    $text .= ":バリア-L\n";
    $text .= ":荒事屋+1L\n";
    $text .= ":パトロン+1\n";
    $text .= "\n";
    $text .= "1dkh1　[1d]ダメージ[ :荒事屋-1L ]\n";
    $text .= "2dkh1　[1d]ダメージ[ :荒事屋-1L ][ :アドバンテージ-1L ]\n";
    $text .= "\n";
    
    # パワー
    my $has_power = 0;
    foreach my $num (1 .. $::pc{powerNum}){
      next if !$::pc{'power'.$num.'Name'};
      my $effect = $::pc{'power'.$num.'Note'};
      $effect =~ s/<br>/\\n　　　/gi;
      
      $text .= "《$::pc{'power'.$num.'Name'}》($::pc{'power'.$num.'Type'})$effect\n";
      $has_power = 1;
    }
    $text .= "\n" if $has_power;
    
    # 武器とカスタマイズ
    my $has_weapon = 0;
    foreach my $num (1 .. $::pc{weaponNum}){
      next if !$::pc{'weapon'.$num.'Name'};
      my $customs = '';
      foreach my $c_num (1 .. $::pc{'weapon'.$num.'CustomNum'}){
        if($::pc{'weapon'.$num.'Custom'.$c_num.'Name'}){
          $customs .= "【$::pc{'weapon'.$num.'Custom'.$c_num.'Name'}】";
        }
      }
      $text .= "$::pc{'weapon'.$num.'Name'}　『射程：$::pc{'weapon'.$num.'Range'}』『ダメージ：$::pc{'weapon'.$num.'Damage'}』『補記：$::pc{'weapon'.$num.'Note'}』$customs\n";
      $has_weapon = 1;
    }
    $text .= "\n" if $has_weapon;
    
    # ウェア
    my $has_wear = 0;
    foreach my $num (1 .. $::pc{wearNum}){
      next if !$::pc{'wear'.$num.'Name'};
      my $effect = $::pc{'wear'.$num.'Note'};
      $effect =~ s/<br>/\\n　　　/gi;
      
      $text .= "【$::pc{'wear'.$num.'Name'}】$effect\n";
      $has_wear = 1;
    }
    $text .= "\n" if $has_wear;
    
# アイテム
    foreach my $num (1 .. $::pc{itemNum}){
      next if !$::pc{'item'.$num.'Name'};
      my $effect = $::pc{'item'.$num.'Note'};
      $effect =~ s/<br>/\\n   /gi;
      
      # 使用済にチェックが入っているかどうかで末尾のテキストを分岐
      if ($::pc{'item'.$num.'Used'}) {
        $text .= "【$::pc{'item'.$num.'Name'}】$effect\[ 未所持 \]\n";
      } else {
        $text .= "【$::pc{'item'.$num.'Name'}】$effect\[ :$::pc{'item'.$num.'Name'}=0 \]\n";
      }
    }
  }

  
    $text .= "\n";
    $text .= "初期化　[ :プライド=8 ][ :カルマ=2 ][ :BS=0 ][ :アドバンテージ=0 ][ :リロード=0 ][ :バリア=0 ][ :荒事屋=0 ][ :パトロン=0 ]\n";
    $text .= "\n";
  
  # 余分な連続改行を整理
  $text =~ s/\n{3,}/\n\n/g;
  
  return $text;
}

### プリセット（シンプル） ###########################################################################
sub palettePresetSimple {
  my $tool = shift;
  my $type = shift;
  
  my $text = palettePreset($tool,$type);
  my %propaty;
  foreach (paletteProperties($tool,$type)){
    if($_ =~ /^\/\/(.+?)=(.*)$/){
      $propaty{$1} = $2;
    }
  }
  my $hit = 1;
  while ($hit){
    $hit = 0;
    foreach(keys %propaty){
      if($text =~ s/\{$_\}/$propaty{$_}/i){ $hit = 1 }
    }
  }
  1 while $text =~ s/\([+\-*0-9]+\)/s_eval($&)/egi;
  
  return $text;
}

### デフォルト変数 ###################################################################################
sub paletteProperties {
  my $tool = shift;
  my $type = shift;
  my @propaties;
  push @propaties, "//レベル=$::pc{level}";
  # push @propaties, "### ■能力値";
  # push @propaties, "//肉体=$::pc{sttTotalBody}"  ;
  # push @propaties, "//感覚=$::pc{sttTotalSense}" ;
  # push @propaties, "//精神=$::pc{sttTotalMind}"  ;
  # push @propaties, "//社会=$::pc{sttTotalSocial}";
  # push @propaties, "###" if $tool eq 'tekey';
  # push @propaties, "### ■技能";
  # push @propaties, "//白兵=".($::pc{skillTotalMelee}    ||0);
  # push @propaties, "//回避=".($::pc{skillTotalDodge}    ||0);
  # push @propaties, "//射撃=".($::pc{skillTotalRanged}   ||0);
  # push @propaties, "//知覚=".($::pc{skillTotalPercept}  ||0);
  # push @propaties, "//RC="  .($::pc{skillTotalRC}       ||0);
  # push @propaties, "//意志=".($::pc{skillTotalWill}     ||0);
  # push @propaties, "//交渉=".($::pc{skillTotalNegotiate}||0);
  # push @propaties, "//調達=".($::pc{skillTotalProcure}  ||0);
  foreach my $name ('Ride','Art','Know','Info'){
    foreach my $num (1 .. $::pc{'skill'.$name.'Num'}){
      next if !$::pc{'skill'.$name.$num.'Name'};
      push @propaties, "//$::pc{'skill'.$name.$num.'Name'}=".($::pc{'skillTotal'.$name.$num}||0);
    }
  }
  return @propaties;
}

sub textTiming {
  my $text = shift;
  $text =~ s/(オート|メジャー|マイナー)(アクション)?/$1アクション/g;
  $text =~ s/リアク?(ション)?/リアクション/g;
  $text =~ s/(セットアップ|クリンナップ)(プロセス)?/$1プロセス/g;
  return $text;
}

1;