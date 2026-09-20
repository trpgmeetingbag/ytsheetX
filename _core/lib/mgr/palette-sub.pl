################## チャットパレット用サブルーチン ##################
use strict;
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
    # （既存のPC用処理は一切変更せずそのまま残す）
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
    
    $text .= "◆戦闘値\n";
    $text .= "2D6+{命中値} 命中判定\n";
    $text .= "2D6+{回避値} 回避判定\n";
    $text .= "2D6+{砲撃値} 砲撃判定\n";
    $text .= "2D6+{防壁値} 防壁判定\n\n";
    
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

      my $cost_cmd = parseCost($::pc{"armament${i}Daishou"}, $name, $::pc{"armament${i}Danzuu"});
      my $attr_text = $attr ? "〈$attr〉" : "";

      if($name && $part =~ /[主副近遠武]/){
        if($name && $part =~ /[近]/){ $Wtype = '近接'; }
        elsif($name && $part =~ /[遠]/){ $Wtype = '遠隔'; }
        else{ $Wtype = '武装'; }

        if ($Wtext =~ /対象：(.+?)(?:\s|。|」|$)/) { $Taisyo = $1; }
        else{ $Taisyo = '単体'; }
        
        if($name && $name =~ /[●]/){ $Taisyo = '範囲(選択)'; }

        $textWeapn .= "メジャー ".$Wtype."攻撃：".$attr_text.$name." 「対象：".$Taisyo."」";
        $textWeapn .= "「射程：".$Syatei."」" if $Syatei ne '';
        $textWeapn .= " $cost_cmd" if $cost_cmd;
        $textWeapn .= "\n";
        $textAtk .= "2D6+{攻撃力}+".$atk." ".$attr_text.$name;
        $textAtk .= "\n";
      }
    }

    $textSkill .= "◆特技\n";
    for my $i (1 .. ($::pc{skillsNum} || 0)){
      my $name = $::pc{"skill${i}Name"};
      next if !$name;
      
      my $timing = $::pc{"skill${i}Timing"} || '';
      my $target = $::pc{"skill${i}Target"} || '';
      my $range = $::pc{"skill${i}Range"} // '';
      
      my $note = $::pc{"skill${i}Note"} || '';
      $note =~ s/<br>/\\n   /gi;
      
      my $cost_cmd = parseCost($::pc{"skill${i}Cost"}, $name, '');
      
      $textSkill .= " $timing" if $timing;
      $textSkill .= "《$name》";
      $textSkill .= "「対象：".$target."」" if $target;
      $textSkill .= "「射程：".$range."」" if $range ne '';
      $textSkill .= " $cost_cmd" if $cost_cmd;
      $textSkill .= "\\n   ".$note if $note;
      $textSkill .= "\n";
    }
    
    $text .= $textWeapn."\n".$textAtk."\n".$textSkill;
    $text .= "\n###\n" if $bot{YTC} || $bot{TKY};
  }
## 魔物（エネミー）
  elsif($type eq 'm'){
    require $set::data_mons; # ★辞書の読み込み漏れを防止
    my $sys_data  = $data::srs_system_mons{$::pc{system}} || {};
    my $resources = $sys_data->{resources} || {};

    $text .= "◆能力値判定\n";
    for my $i (1 .. ($::pc{sttNum} || 15)) {
      my $name = $::pc{"stt${i}Name"};
      $text .= "2D6+{${name}B} 【${name}】判定\n" if $name;
    }
    $text .= "\n";

    $text .= "◆戦闘値判定\n";
    # ★保険として最大15回ループを回す
    for my $i (1 .. ($::pc{battleNum} || 15)) {
      my $name = $::pc{"battle${i}Name"};
      next if !$name;
      
      # ★指定漏れ対策：リソース(1)や固定値(2)でないものは、すべて判定用コマンドとして出力する
      if (!$resources->{$name} || $resources->{$name} == 3) {
        $text .= "2D6+{${name}} 【${name}】判定\n";
      }
    }
    $text .= "\n";

    $textWeapn .= "◆攻撃方法\n";
    # ★ 行数（attackRowNum）でループ
    for my $r (1 .. ($::pc{attackRowNum} || 15)) {
      # 1列目を「名称（atk_name）」として取得
      my $atk_name = $::pc{"attackRow${r}Col1Value"} // '';
      
      my @cols;
      my $has_data = 0;
      
      # ★ 2列目以降を「見出し：内容」としてカッコで括る
      for my $c (2 .. ($::pc{attackColNum} || 15)) {
        my $header = $::pc{"attackCol${c}Name"} // '';
        my $val    = $::pc{"attackRow${r}Col${c}Value"} // '';
        
        # 見出しと内容が両方存在する場合のみ出力
        if ($header ne '' && $val ne '') {
          push(@cols, "「${header}：${val}」");
          $has_data = 1; # データが存在したことを記録
        }
      }
      
      # 1列目に名前があるか、2列目以降にデータが存在する行のみ出力
      if ($atk_name ne '' || $has_data) {
        $textWeapn .= "${atk_name} " . join("", @cols) . "\n";
      }
    }
    
    $text .= $textWeapn;
    $text .= "\n###\n" if $bot{YTC} || $bot{TKY};
  }
  
  return $text;
}

# --------------------------------------------------
# 代償（コスト）のパースとリソース操作コマンド生成
# --------------------------------------------------
sub parseCost {
  # （既存のまま一切変更しない）
  my ($cost_text, $name, $max_ammo) = @_;
  return '' if !defined $cost_text || $cost_text eq '';
  $cost_text =~ tr/０-９Ａ-Ｚａ-ｚ/0-9A-Za-z/;
  $cost_text =~ s/弾数\s*([0-9]+)\s*[\/／]\s*([0-9]+)/AMMOTOKEN${1}MAX${2}/g;
  my @parts = split(/[ \x{3000}、，,／\/_\-]+/, $cost_text);
  my $result = '';
  foreach my $part (@parts) {
    next if $part eq '';
    if ($part =~ /^AMMOTOKEN([0-9]+)MAX([0-9]+)$/) {
      my $x = $1;
      $result .= "[ :$name-$x ]";
    }
    elsif ($part =~ /^(FP|HP|EN)([0-9]+)$/i) {
      my $resource = uc($1);
      my $val = $2;
      $result .= "[ :$resource-($val*(1-{ブレイク})) ]";
    }
    elsif ($part =~ /^([0-9]+)(FP|HP|EN)$/i) {
      my $val = $1;
      my $resource = uc($2);
      $result .= "[ :$resource-($val*(1-{ブレイク})) ]";
    }
    elsif ($part =~ /^弾数\s*([0-9]+)$/) {
      my $x = $1;
      if (defined $max_ammo && $max_ammo ne '') {
        $result .= "[ :$name-$x ]";
      } else {
        $result .= "[弾数-$x]";
      }
    }
    else {
      $result .= "[$part]";
    }
  }
  return $result;
}

### プリセット（シンプル） ###########################################################################
sub palettePresetSimple {
  # （既存のまま一切変更しない）
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
    # （既存のまま一切変更しない）
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
## 魔物（エネミー）
  elsif($type eq 'm'){
    push @propaties, "### ■能力値ボーナス";
    for my $i (1 .. ($::pc{sttNum} || 15)) {
      my $name = $::pc{"stt${i}Name"};
      my $val = int(($::pc{"stt${i}Value"} || 0) / 3);
      push(@propaties, "//${name}B=${val}") if $name;
    }
    
    push @propaties, "### ■戦闘値";
    for my $i (1 .. ($::pc{battleNum} || 15)) {
      my $name = $::pc{"battle${i}Name"};
      my $val = $::pc{"battle${i}Value"} || 0;
      push(@propaties, "//${name}=${val}") if $name;
    }
  }
  
  return @propaties;
}

1;