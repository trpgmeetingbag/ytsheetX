################## チャットパレット用サブルーチン ##################
use strict;
#use warnings;
use utf8;

### プリセット #######################################################################################
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
    $text .= "◆判定\n";
    $text .= "NC　行動判定\n";
    $text .= "NC　対話判定（対象→）\n";
    $text .= "NC　狂気判定\n";
    $text .= "\n";
    $text .= "NM　姉妹への未練表\n";
    $text .= "NMN　中立者への未練表\n";
    $text .= "NME　敵への未練表\n";
    $text .= "\n";
    $text .= "狂気点減少　[ :狂気点減少可能数(対話判定)-1 ]\n";
    $text .= "パート切り替え　[ :狂気点減少可能数(対話判定)={記憶のカケラ} ]\n";
    $text .= "記憶のカケラ獲得　[ :^狂気点減少可能数(対話判定)+1 ][ :狂気点減少可能数(対話判定)+1L ][ :記憶のカケラ+1 ]\n";
    $text .= "\n";
    $text .= "◆戦闘\n";
    $text .= "\n";
    $text .= "NA　攻撃判定\n";
    $text .= "\n";
    $text .= ":頭+-L 破損・修復\n";
    $text .= ":腕+-L 破損・修復\n";
    $text .= ":胴+-L 破損・修復\n";
    $text .= ":脚+-L 破損・修復\n";
    $text .= "\n";

    my $reset_line = "使用回数リセット";
    
    my @actions = ();
    my @rapids = ();
    my @judges = ();
    my @damages = ();
    my @autos = ();
    
    # スキル・パーツの全走査
    for my $num (1 .. $::pc{skillNum}) {
      my $name = $::pc{"skill${num}Name"};
      next if !$name;
      
      my $timing = $::pc{"skill${num}Timing"};
      my $cost   = $::pc{"skill${num}Cost"};
      my $range  = $::pc{"skill${num}Range"};
      my $note   = $::pc{"skill${num}Note"};
      
      # 改行コードの変換（ノート内改行時のインデント付与）
      $note =~ s/&lt;br&gt;/\n  /g;
      
      # コスト表示判定：0ではなく、かつ数値や計算式（数字と記号の組み合わせ）の場合のみ表示
      my $cost_str = "";
      if ($cost ne '' && $cost ne '0' && $cost =~ /^[0-9\+\-\*\/\(\)\s]+$/) {
        $cost_str = "[ :行動値-$cost ]";
      }
      
      # 使用回数リセット用の文字結合と、消費コマンドの生成
      my $use_str = "";
      if ($timing =~ /ジャッジ|ダメージ|ラピッド/) {
        $reset_line .= "[ :${name}=1 ]";
        $use_str = "[ :${name}-1 ]";
      }
      
      # タイミングごとのリストへ振り分け
      if ($timing =~ /アクション/) {
        push @actions, "【${name}】${cost_str}\\n　　　Ｔ：アクション/Ｃ：${cost}/Ｒ：${range}/効果：${note}\n";
      }
      elsif ($timing =~ /ラピッド/) {
        push @rapids, "【${name}】${cost_str}${use_str}\\n　　　Ｔ：ラピッド/Ｃ：${cost}/Ｒ：${range}/効果：${note}\n";
      }
      elsif ($timing =~ /ジャッジ/) {
        push @judges, "【${name}】${cost_str}${use_str}\\n　　　Ｔ：ジャッジ/Ｃ：${cost}/Ｒ：${range}/効果：${note}\n";
      }
      elsif ($timing =~ /ダメージ/) {
        push @damages, "【${name}】${cost_str}${use_str}\\n　　　Ｔ：ダメージ/Ｃ：${cost}/Ｒ：${range}/効果：${note}\n";
      }
      else {
        # オート等
        push @autos, "【${name}】\\n　　　Ｔ：オート/Ｃ：${cost}/Ｒ：${range}/効果：${note}\n";
      }
    }

    # 各種リセットコマンド等の出力
    $text .= "$reset_line\n";
    $text .= "行動値回復　[ :行動値+{最大行動値}L ]\n";
    $text .= "最大行動値増減　[ :最大行動値+-L ]\n";
    $text .= "\n";
    $text .= "待機　[ :行動値-1 ]\n";
    $text .= "【せぼね】使用　[ :行動値+1L ]\n";
    $text .= "\n";

    # 並び替えたマニューバ群の出力
    $text .= "//---アクション\n" . join("", @actions) if @actions;
    $text .= "//---ラピッド\n"   . join("", @rapids)  if @rapids;
    $text .= "//---ジャッジ\n"   . join("", @judges)  if @judges;
    $text .= "//---ダメージ\n"   . join("", @damages) if @damages;
    $text .= "//---オート\n"     . join("", @autos)   if @autos;
  }
  
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
  push @propaties, "";
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