################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

### データ読み込み ###################################################################################
# require $set::data_races;
# require $set::data_items;
require $set::data_mons;

### テンプレート読み込み #############################################################################
(my $pcRef, my $SHEET) = setupViewBase(
  generateType => 'SRSEnemy',
  defaultPieceImage => $::core_dir.'/skin/mgr/img/default_enemy.png',
  unescapeLinesKeys => [qw/skills description/],
  nameKeys => [qw/characterName monsterName/],
  nameSub  => \&setupMonsterName,
);
our %pc = %{ $pcRef };
$SHEET->param(modeZero => $::SW2_0 ? 1 : 0);

sub setupMonsterName {
  my ($pc) = @_;
  $pc->{titleName} = 
    $pc->{characterName} && $pc->{monsterName}
    ? "$pc->{characterName}（$pc->{monsterName}）"
    : $pc->{characterName} || $pc->{monsterName};
  $pc->{encodedNameLetter} = $pc->{titleName}.'【】';
}

### 固有処理 #########################################################################################
### 閲覧禁止データのマスク --------------------------------------------------
sub maskPcData {
  my ($pc, $forbidden) = @_;
  unless($forbidden eq 'battle'){
    $pc->{monsterName} = noiseText(6,14);
    $pc->{tags} = '';
    
    $pc->{description} = '';
    foreach(1..int(rand 3)+1){
      $pc->{description} .= '　'.noiseText(18,40)."<br>";
    }
  }
  
  $pc->{lv}   = noiseText(1);
  $pc->{taxa} = noiseText(2,5);
  $pc->{intellect}   = noiseText(3);
  $pc->{perception}  = noiseText(3);
  $pc->{disposition} = noiseText(3);
  $pc->{sin}         = noiseText(1);
  $pc->{language}    = noiseText(4,18);
  $pc->{habitat}     = noiseText(3,8);
  $pc->{reputation}  = noiseText(2);
  $pc->{'reputation+'} = noiseText(2);
  $pc->{weakness}    = noiseText(6,10);
  $pc->{initiative}  = noiseText(2);
  $pc->{mobility}    = noiseText(2,6);
  $pc->{statusNum} = int(rand 3)+1;
  $pc->{partsNum}  = noiseText(2);
  $pc->{parts}     = noiseText(3,9);
  $pc->{coreParts} = noiseText(2,5);
  
  foreach(1..$pc->{statusNum}){
    $pc->{'status'.$_.'Style'} = noiseText(3,10);
    $pc->{'status'.$_.'Accuracy'}    = noiseText(1,2);
    $pc->{'status'.$_.'AccuracyFix'} = noiseText(2);
    $pc->{'status'.$_.'Damage'}      = noiseText(4);
    $pc->{'status'.$_.'Evasion'}     = noiseText(1,2);
    $pc->{'status'.$_.'EvasionFix'}  = noiseText(2);
    $pc->{'status'.$_.'Defense'}     = noiseText(2);
    $pc->{'status'.$_.'Hp'}          = noiseText(2,3);
    $pc->{'status'.$_.'Mp'}          = noiseText(2,3);
  }
  $pc->{skills} = '';
  foreach(1..int(rand 4)+1){
    $pc->{skills} .= noiseText(6,18)."<br>";
    $pc->{skills} .= '　'.noiseText(18,40)."<br>";
    $pc->{skills} .= '　'.noiseText(18,40)."<br>" if(int rand 2);
    $pc->{skills} .= "<br>";
  }
}

# ### 価格 --------------------------------------------------
# {
#   my $price;

#   my @prices = (
#       ['購入', $pc{price}],
#       ['レンタル', $pc{priceRental}],
#       ['部位再生', $pc{priceRegenerate}],
#   );

#   foreach (@prices) {
#     (my $term, my $value) = @{$_};
#     my $annotation = $value =~ s/([(（].+?[）)])$// ? $1 : '';
#     my $unit = $value =~ /\d$/ ? 'G' : '';

#     $value = commify($value);
#     $unit = "<small>$unit</small>" if $unit ne '';
#     $annotation = "<small>$annotation</small>" if $annotation ne '';

#     $price .= "<dt>$term</dt><dd>$value$unit$annotation</dd>" if $value;
#   }

#   if(!$price){ $price = '―' }
#   $SHEET->param(price => "<dl class=\"price\">$price</dl>");
# }
# ### 適正レベル --------------------------------------------------
# my $appLv = $pc{lvMin}.($pc{lvMax} != $pc{lvMin} ? "～$pc{lvMax}":'');
# {
#   $SHEET->param(appLv => $appLv);
# }
# ### 穢れ --------------------------------------------------
# unless(
#   ($pc{taxa} eq 'アンデッド' && ($pc{sin} == 5 || $pc{sin} eq '')) ||
#   ($pc{taxa} ne '蛮族'       && ($pc{sin} == 0 || $pc{sin} eq ''))
# ){
#   $SHEET->param(displaySin => 1);
# }

### 分類とサブカテゴリの結合 --------------------------------------------------
if ($pc{subTaxa} ne '') {
  # 閲覧画面の <TMPL_VAR taxa> を上書きする
  $SHEET->param(taxa => $pc{taxa} . "（$pc{subTaxa}）");
}

### 固有ステータス・基本データ類 --------------------------------------------------

# ① レベル（base1）の読み込み
$SHEET->param(base1Value => $pc{base1Value});

# ② base-list（2番目以降）
my @base_items;
for my $i (2 .. $pc{baseNum}) {
  if ($pc{"base${i}Name"} ne '' && $pc{"base${i}Value"} ne '') {
    push @base_items, { NAME => $pc{"base${i}Name"}, VALUE => $pc{"base${i}Value"} };
  }
}
$SHEET->param(BaseItems => \@base_items);

# ③ stt-list（3要素で改行、空欄はスペーサー扱い）
my $last_stt_idx = 0;
for my $i (1 .. $pc{sttNum}) { $last_stt_idx = $i if ($pc{"stt${i}Name"} ne '' && $pc{"stt${i}Value"} ne ''); }
my @stt_rows; my @current_stt;
for my $i (1 .. $last_stt_idx) {
  my $n = $pc{"stt${i}Name"}; my $v = $pc{"stt${i}Value"};
  if ($n ne '' && $v ne '') {
    my $bonus = ($v =~ /^(-?\d+)/) ? int($1 / 3) : ''; # 数値を抽出して3で割る（文字混じり対策）
    push @current_stt, { NAME => $n, VALUE => $v, BONUS => $bonus };
  } else {
    push @current_stt, { NAME => '', VALUE => '', BONUS => '' }; # スペーサー
  }
  if (@current_stt == 3) { push @stt_rows, { Cols => [@current_stt] }; @current_stt = (); }
}
push @stt_rows, { Cols => \@current_stt } if @current_stt;
$SHEET->param(SttRows => \@stt_rows);

# ④ battle-list（4要素で改行、空欄はスペーサー扱い）
my $last_battle_idx = 0;
for my $i (1 .. $pc{battleNum}) { $last_battle_idx = $i if ($pc{"battle${i}Name"} ne '' && $pc{"battle${i}Value"} ne ''); }
my @battle_rows; my @current_battle;
for my $i (1 .. $last_battle_idx) {
  my $n = $pc{"battle${i}Name"}; my $v = $pc{"battle${i}Value"};
  if ($n ne '' && $v ne '') {
    push @current_battle, { NAME => $n, VALUE => $v };
  } else {
    push @current_battle, { NAME => '', VALUE => '' };
  }
  if (@current_battle == 4) { push @battle_rows, { Cols => [@current_battle] }; @current_battle = (); }
}
push @battle_rows, { Cols => \@current_battle } if @current_battle;
$SHEET->param(BattleRows => \@battle_rows);

# ⑤ defense-list
my @defense_items;
for my $i (1 .. $pc{defenseNum}) {
  if ($pc{"defense${i}Name"} ne '' && $pc{"defense${i}Value"} ne '') {
    push @defense_items, $pc{"defense${i}Name"} . $pc{"defense${i}Value"};
  }
}
$SHEET->param(defenseText => join('／', @defense_items)) if @defense_items;


### ⑥ 攻撃方法（2Dマトリクス可変テーブル） ---------------------------------------
my @attack_heads;
for my $c (1 .. $pc{attackColNum}) {
  push @attack_heads, { NAME => $pc{"attackCol${c}Name"} };
}
$SHEET->param(AttackHeads => \@attack_heads);

my @attack_rows;
for my $r (1 .. $pc{attackRowNum}) {
  my @cells; my $has_data = 0;
  for my $c (1 .. $pc{attackColNum}) {
    my $v = $pc{"attackRow${r}Col${c}Value"};
    $has_data = 1 if $v ne '';
    push @cells, { VALUE => $v };
  }
  push @attack_rows, { Cells => \@cells } if $has_data; # 値が1つもない行は表示しない
}
$SHEET->param(AttackRows => \@attack_rows);


### ⑦ 追加テキストエリア（加護など） ----------------------------------------------
my @extra_skills;
my $all_skill_text = $pc{skills} . "\n"; # 特技サマリ抽出用にも統合
for my $i (1 .. 3) {
  if ($pc{"extra${i}Name"} && $pc{"extra${i}Text"}) {
    my $text = $pc{"extra${i}Text"};
    $all_skill_text .= $text . "\n"; # サマリ抽出用に合流
    $text =~ s/\n/<br>/gi;
    push @extra_skills, { NAME => $pc{"extra${i}Name"}, TEXT => $text };
  }
}
$SHEET->param(ExtraSkills => \@extra_skills);


### ⑨ 特技サマリ抽出処理 ----------------------------------------------------------
my %skill_summary_map;
my @extracted_skills;
my $skill_dict = $data::srs_mons_skills{$pc{system}} || {};
my %exclude_skills;

# --- ① 表記揺れ吸収関数 ---
sub normalize_skill_name {
  my $name = shift;
  $name =~ s/\(/（/g;
  $name =~ s/\)/）/g;
  $name =~ s/:/：/g;
  return $name;
}

# 辞書のキーを解析可能な正規表現に変換
my @dict_regexes;
for my $key (keys %$skill_dict) {
  my $norm_key = normalize_skill_name($key);
  my $regex_str = quotemeta($norm_key);
  my @placeholders;
  while ($regex_str =~ m/\\\%([a-zA-Z0-9_]+)\\\%/) {
    push @placeholders, "%$1%";
    my $repl = ($1 =~ /^num/) ? '(\d+)' : '(.+?)';
    $regex_str =~ s/\\\%([a-zA-Z0-9_]+)\\\%/$repl/;
  }
  push @dict_regexes, { key => $key, regex => qr/^$regex_str$/, placeholders => \@placeholders };
}

# --- ③ 独自サマリの抽出（テキストの消去はまだ行わない） ---
while ($all_skill_text =~ /(?:^|<br>|\n)\s*(?:>>|&gt;&gt;|＞＞)(《[^》]+》)(.*?)(?=<br>|\n|$)/g) {
  my $match = $1;
  my $desc = $2;
  my $norm_match = normalize_skill_name($match);
  
  if (!$skill_summary_map{$norm_match}) {
    push @extracted_skills, { NAME => $norm_match, TEXT => $desc };
    $skill_summary_map{$norm_match} = 1;
  }
}

# --- ② 例外判定（◆《...》）のリストアップ ---
while ($all_skill_text =~ /◆(《[^》]+》)/g) {
  my $norm_match = normalize_skill_name($1);
  $exclude_skills{$norm_match} = 1;
}

# --- 通常の特技の抽出 ---
while ($all_skill_text =~ /(《[^》]+》)/g) {
  my $match = $1;
  my $norm_match = normalize_skill_name($match);

  next if $skill_summary_map{$norm_match};
  next if $exclude_skills{$norm_match};

  my $summary_text = "";
  for my $dict_entry (@dict_regexes) {
    if ($norm_match =~ $dict_entry->{regex}) {
      my @captures = ($1, $2, $3, $4, $5); 
      $summary_text = $skill_dict->{$dict_entry->{key}};

      my $placeholders = $dict_entry->{placeholders};
      for my $i (0 .. $#$placeholders) {
        my $p = $placeholders->[$i];
        my $v = $captures[$i] // '';
        $v = normalize_skill_name($v);
        $summary_text =~ s/$p/$v/g;
      }
      last;
    }
  }

  if ($summary_text) {
    $summary_text =~ s/\n/<br>/g;
    push @extracted_skills, { NAME => $norm_match, TEXT => $summary_text };
    $skill_summary_map{$norm_match} = 1;
  }
}

# サマリデータをテンプレートに登録
$SHEET->param(SkillSummary => \@extracted_skills) if @extracted_skills;

# --- ④ 表示用データのフィルタリング（実際のデータは変えず、表示だけ隠す） ---
# HTMLテンプレートへ渡される直前のデータから、独自サマリ行をHTMLコメントに変換する
my $hide_custom_summary = sub {
  my $val = shift;
  return $val unless defined $val;
  # 該当行を HTML の <!-- --> でコメントアウト
  $val =~ s/(?:^|<br>|\n)\s*(?:>>|&gt;&gt;|＞＞)(《[^》]+》)(.*?)(?=<br>|\n|$)/<!-- 独自サマリ非表示: $1 -->/g;
  # 先頭に余分な空行が残った場合のクリーニング
  $val =~ s/^(?:<!--[^>]*-->)*\s*(?:<br>|\n)+//;
  return $val;
};

# すでにテンプレート（$SHEET）に格納されている全変数をスキャンしてフィルタ適用
my @param_names = $SHEET->param();
for my $p (@param_names) {
  next if $p eq 'SkillSummary'; # 今抽出したサマリ本体は処理しない
  
  my $val = $SHEET->param($p);
  next unless defined $val;
  
  if (!ref($val)) {
    # 単純なテキストデータの場合
    # 「>>」等の記号が含まれている場合のみ、安全に上書きを試みる（構造変数への誤代入エラーを防止）
    if ($val =~ /(?:>>|&gt;&gt;|＞＞)/) {
      eval { $SHEET->param($p => $hide_custom_summary->($val)); };
    }
  } elsif (ref($val) eq 'ARRAY') {
    # 複数行のリストデータ（特技リストなど）の場合
    foreach my $row (@$val) {
      if (ref($row) eq 'HASH') {
        foreach my $k (keys %$row) {
          if (!ref($row->{$k}) && defined($row->{$k})) {
            # 参照先のデータを直接書き換えるため eval は不要
            $row->{$k} = $hide_custom_summary->($row->{$k});
          }
        }
      }
    }
  }
}

### 特殊能力 --------------------------------------------------
# $pc{skills} =~ s/<br>/\n/gi;
# $pc{skills} =~ s#(<p>|</p>|</details>)#$1\n#gi;
# $pc{skills} =~ s/^●(.*?)$/<\/p><h3>●$1<\/h3><p>/gim;
# $pc{skills} = checkSkillName($pc{skills});
# $pc{skills} =~ s/^((?:<i class="s-icon [a-z0]+?">.+?<\/i>)+.*?)(　|$)/<\/p><h5>$1<\/h5><p>$2/gim;
# $pc{skills} =~ s/\n+<\/p>/<\/p>/gi;
# $pc{skills} =~ s/(^|<p(?:.*?)>|<hr(?:.*?)>)\n/$1/gi;
# $pc{skills} = "<p>$pc{skills}</p>";
# $pc{skills} =~ s#(</p>|</details>)\n#$1#gi;
# $pc{skills} =~ s/<p><\/p>//gi;
# $pc{skills} =~ s/\n/<br>/gi;
# $SHEET->param(skills => $pc{skills});

#if($pc{description} =~ s/#login-only//i){
#  $pc{description} .= '<span class="login-only">［ログイン限定公開］</span>';
#  $pc{forbidden} = 'all' if !$::LOGIN_ID;
#}

### 戦利品 --------------------------------------------------
my @loots;
foreach (1 .. $pc{lootsNum}){
  next if !$pc{'loots'.$_.'Num'} && !$pc{'loots'.$_.'Item'};
  push(@loots, {
    NUM  => $pc{'loots'.$_.'Num'},
    ITEM => $pc{'loots'.$_.'Item'},
  } );
}
$SHEET->param(Loots => \@loots);

### OGP --------------------------------------------------
if ($pc{subTaxa} ne '') {
  $SHEET->param(ogDescript => removeTags(
    "レベル:$pc{base1Value}".
    "　分類:$pc{taxa}"."（$pc{subTaxa}）"
  ));
}else{
  $SHEET->param(ogDescript => removeTags(
    "レベル:$pc{base1Value}".
    "　分類:$pc{taxa}"
  ));
}


### メニュー --------------------------------------------------
setSheetMenu();

### コピーライト情報の動的取得 --------------------------------------------------
# データライブラリ（%srs_system_mons）から、現在選択されているシステムのデータを取得
my $system_data = $data::srs_system_mons{$pc{system}} || {};

# copyright が設定されていればHTMLテンプレートに渡す
if ($system_data->{copyright}) {
  $SHEET->param(copyright => $system_data->{copyright});
}else{
  $SHEET->param(copyright => 'スタンダードRPGシステム');
}

### 出力 #############################################################################################
printFinalizedView();

1;
