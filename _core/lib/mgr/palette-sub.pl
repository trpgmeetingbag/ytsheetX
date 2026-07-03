################## チャットパレット用サブルーチン ##################
use strict;
#use warnings;
use utf8;

### プリセット #######################################################################################
sub palettePreset {
  my $tool = shift;
  my $type = shift;
  my $text;
  my $textWeapn = "";
  my $textAtk = "";
  my $textSkill = "";
  my %bot;
  if   (!$tool)           { $bot{YTC} = 1; }
  elsif($tool eq 'tekey' ){ $bot{TKY} = $bot{BCD} = 1; }
  elsif($tool eq 'bcdice'){ $bot{BCD} = 1; }
  
  ## ＰＣ
  if(!$type){
    # 基本判定
    if($::pc{mechaName}){
      $text .= "機体名：$::pc{mechaName}\n\n";
    }
    $text .= "◆判定\n";
    $text .= "2D6+{体力} 【体力】判定\n";
    $text .= "2D6+{反射} 【反射】判定\n";
    $text .= "2D6+{知覚} 【知覚】判定\n";
    $text .= "2D6+{理知} 【理知】判定\n";
    $text .= "2D6+{意志} 【意志】判定\n";
    $text .= "2D6+{幸運} 【幸運】判定\n\n";
    
    # 戦闘値
    $text .= "◆戦闘値\n";
    $text .= "2D6+{命中値} 命中判定\n";
    $text .= "2D6+{回避値} 回避判定\n";
    $text .= "2D6+{砲撃値} 砲撃判定\n";
    $text .= "2D6+{防壁値} 防壁判定\n\n";
    
    # ダメージロール（武装から動的生成）
    $textWeapn .= "◆武装\n";
    $textAtk .= "◆武装攻撃力\n";
    for my $i (1 .. ($::pc{armamentsNum} || 0)){
      my $name = $::pc{"armament${i}Name"};
      my $part = $::pc{"armament${i}Part"} || '';
      my $attr = $::pc{"armament${i}Zokusei"} || '';
      my $Wtype = '';
      my $Syatei = $::pc{"armament${i}Shatei"} // '';
      my $Taisyo = '';
      my $Wtext = $::pc{"armamentNoteAuto${i}Note"} || '';
      my $atk  = $::pc{"armament${i}Kougeki"} || 0;

      # ★代償の解析とコマンド生成
      my $cost_cmd = parseCost($::pc{"armament${i}Daishou"}, $name, $::pc{"armament${i}Danzuu"});
      
      # 属性が空の場合は省略、ある場合は ＜属性＞ を付与
      my $attr_text = $attr ? "〈$attr〉" : "";



      # 「武装」っぽい部位（主/副/近/遠/武）で、名前がある場合に出力
      if($name && $part =~ /[主副近遠武]/){

        # 武装の部位から近接攻撃か遠隔攻撃か判定
        if($name && $part =~ /[近]/){
          $Wtype = '近接';
        }elsif($name && $part =~ /[遠]/){
          $Wtype = '遠隔';
        }else{
          $Wtype = '武装';
        }

        # 武装の解説テキストを読み込み、「対象」があるか判定する
        if ($Wtext =~ /対象：(.+?)(?:\s|。|」|$)/) {
          $Taisyo = $1;
        }else{
          $Taisyo = '単体';
        }
        if($name && $name =~ /[●]/){
          $Taisyo = '範囲(選択)';
        }

        # ★変数が日本語とくっつかないように結合演算子（.）で安全に繋ぐ
        $textWeapn .= "メジャー ".$Wtype."攻撃：".$attr_text.$name."　「対象：".$Taisyo."」";
        $textWeapn .= "「射程：".$Syatei."」" if $Syatei ne '';
        $textWeapn .= "　$cost_cmd" if $cost_cmd; # 代償があれば連結
        $textWeapn .= "\n";
        $textAtk .= "2D6+{攻撃力}+".$atk." ".$attr_text.$name;
        $textAtk .= "\n";
      }
    }

    # ★追加：特技のパレット出力（動的生成）
    $textSkill .= "◆特技\n";
    for my $i (1 .. ($::pc{skillsNum} || 0)){
      my $name = $::pc{"skill${i}Name"};
      next if !$name;
      
      my $timing = $::pc{"skill${i}Timing"} || '';
      my $target = $::pc{"skill${i}Target"} || '';
      # my $range = $::pc{"skill${i}Range"} || '';
      # my $range = defined $::pc{"skill${i}Range"} ? $::pc{"skill${i}Range"} : '';
      my $range = $::pc{"skill${i}Range"} // '';
      
      my $note = $::pc{"skill${i}Note"} || '';
      $note =~ s/<br>/\\n　　　/gi;
      

      # 特技には独立した「弾数」の入力欄がないため、最大値は空文字('')としてパース
      my $cost_cmd = parseCost($::pc{"skill${i}Cost"}, $name, '');
      
      $textSkill .= " $timing" if $timing;
      $textSkill .= "《$name》";
      $textSkill .= "「対象：".$target."」" if $target;
      # $textSkill .= "「射程：".$range."」" if $range;
      # if ($range ne '') { $textSkill .= "「射程：".$range."」";}
      # $textSkill .= "「射程：".$range."」";
      $textSkill .= "「射程：".$range."」" if $range ne '';
      $textSkill .= " $cost_cmd" if $cost_cmd;
      $textSkill .= "\\n　　　".$note if $note;
      $textSkill .= "\n";
    }
    
    $text .= $textWeapn."\n".$textAtk."\n".$textSkill;
    $text .= "\n###\n" if $bot{YTC} || $bot{TKY};
  }
  
  return $text;
}

# --------------------------------------------------
# 代償（コスト）のパースとリソース操作コマンド生成
# --------------------------------------------------
sub parseCost {
  my ($cost_text, $name, $max_ammo) = @_;
  return '' if !defined $cost_text || $cost_text eq '';

  # 全角英数字を半角に変換（大文字小文字も揃える）
  $cost_text =~ tr/０-９Ａ-Ｚａ-ｚ/0-9A-Za-z/;
  
  # ① 「弾数X/Y」の形が区切り文字（/）で分割されないように一旦保護
  $cost_text =~ s/弾数\s*([0-9]+)\s*[\/／]\s*([0-9]+)/AMMOTOKEN${1}MAX${2}/g;

  # ② 指定された区切り文字で配列に分割（半角全角スペース, 、, ,, /, ／, _, -）
  my @parts = split(/[ \x{3000}、，,／\/_\-]+/, $cost_text);

  my $result = '';
  foreach my $part (@parts) {
    next if $part eq '';

    if ($part =~ /^AMMOTOKEN([0-9]+)MAX([0-9]+)$/) {
      # 弾数X/Y の場合（最大値の有無に関わらず武装名/特技名で生成）
      my $x = $1;
      $result .= "[ :$name-$x ]";
    }
    elsif ($part =~ /^(FP|HP|EN)([0-9]+)$/i) {
      # HP5 などの場合
      my $resource = uc($1);
      my $val = $2;
      $result .= "[ :$resource-($val*(1-{ブレイク})) ]";
    }
    elsif ($part =~ /^([0-9]+)(FP|HP|EN)$/i) {
      # 5HP などの場合（★ここを分離しました）
      my $val = $1;
      my $resource = uc($2);
      $result .= "[ :$resource-($val*(1-{ブレイク})) ]";
    }
    elsif ($part =~ /^弾数\s*([0-9]+)$/) {
      # 弾数X（最大値なし）の場合
      my $x = $1;
      if (defined $max_ammo && $max_ammo ne '') {
        $result .= "[ :$name-$x ]"; # 弾数欄が設定されていれば武装/特技名
      } else {
        $result .= "[弾数-$x]";    # 弾数欄がなければそのまま
      }
    }
    else {
      # その他の文字列
      $result .= "[$part]";
    }
  }

  return $result;
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
  
  ## PC
  if  (!$type){
    push @propaties, "### ■能力値";
    push @propaties, "//CL=$::pc{level}";
push @propaties, "//体力=$::pc{sttBonusTai}";
    push @propaties, "//反射=$::pc{sttBonusHan}";
    push @propaties, "//知覚=$::pc{sttBonusChi}";
    push @propaties, "//理知=$::pc{sttBonusRi}";
    push @propaties, "//意志=$::pc{sttBonusIshi}";
    push @propaties, "//幸運=$::pc{sttBonusKou}";
    
    push @propaties, "### ■戦闘値";
    push @propaties, "//命中値=$::pc{battleTotalMeichu}";
    push @propaties, "//回避値=$::pc{battleTotalKaihi}";
    push @propaties, "//砲撃値=$::pc{battleTotalHougeki}";
    push @propaties, "//防壁値=$::pc{battleTotalBouheki}";
    push @propaties, "//行動値=$::pc{battleTotalKoudou}";
    push @propaties, "//移動力=$::pc{battleTotalIdou}";
    push @propaties, "//攻撃力=$::pc{battleTotalKougeki}";

  }
  
  return @propaties;
}

1;