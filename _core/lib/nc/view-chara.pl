################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
require $set::data_class;

### テンプレート読み込み #############################################################################
my $SHEET;
$SHEET = HTML::Template->new( filename => $set::skin_sheet, utf8 => 1,
  path => ['./', $::core_dir."/skin/nc", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  loop_context_vars => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

### キャラクターデータ読み込み #######################################################################
our %pc = getSheetData();

### タグ置換前処理 ###################################################################################
### 閲覧禁止データ --------------------------------------------------
if($pc{forbidden} && !$pc{yourAuthor}){
  my $author = $pc{playerName};
  my $protect   = $pc{protect};
  my $forbidden = $pc{forbidden};
  
  if($forbidden eq 'all'){
    %pc = ();
  }
  if($forbidden ne 'battle'){
    $pc{aka} = '';
    $pc{characterName} = noiseText(6,14);
    $pc{group} = $pc{stage} = $pc{tags} = '';
  
    $pc{age}    = noiseText(1,2);
    $pc{height} = noiseText(2);
    $pc{weight} = noiseText(2);
    $pc{anji}   = noiseText(3);
    
    $pc{freeNote} = '';
    foreach(1..int(rand 3)+2){
      $pc{freeNote} .= '　'.noiseText(18,40)."\n";
    }
    $pc{freeHistory} = '';
    
    foreach my $i (1..$pc{memoryNum}){
      $pc{"memory${i}Name"} = noiseText(3,8);
      $pc{"memory${i}Note"} = noiseText(10,20);
    }
    foreach my $i (1..$pc{mirenNum}){
      $pc{"miren${i}Name"} = noiseText(3,8);
      $pc{"miren${i}Note"} = noiseText(3,6);
      $pc{"miren${i}Burst"} = noiseText(5,10);
    }
    foreach my $i (1..$pc{karmaNum}){
      $pc{"karma${i}Name"} = noiseText(5,15);
    }
  }
  
  $pc{playerName} = $author;
  $pc{protect} = $protect;
  $pc{forbidden} = $forbidden;
  $pc{forbiddenMode} = 1;
}

### その他 --------------------------------------------------
$SHEET->param(rawName => $pc{characterName} || ($pc{aka} ? "“$pc{aka}”" : ''));

### タグ置換 #########################################################################################
if($pc{ver}){
  foreach (keys %pc) {
    next if($_ =~ /^image/);
    if($_ =~ /^(?:freeNote|freeHistory)$/){
      $pc{$_} = unescapeTagsLines($pc{$_});
    }
    $pc{$_} = unescapeTags($pc{$_});

    $pc{$_} = noiseTextTag $pc{$_} if $pc{forbiddenMode};
  }
}
else {
  $pc{freeNote} = $pc{freeNoteView} if $pc{freeNoteView};
}

### アップデート --------------------------------------------------
if($pc{ver}){
  %pc = data_update_chara(\%pc);
}

### カラー設定 --------------------------------------------------
setColors();

### 出力準備 #########################################################################################
### 表示用加工 --------------------------------------------------
$pc{placement} = $pc{placementFree} if $pc{placement} eq 'free';
$pc{position}  = $pc{positionFree}  if $pc{position}  eq 'free';
$pc{mainClass} = $pc{mainClassFree} if $pc{mainClass} eq 'free';
$pc{subClass}  = $pc{subClassFree}  if $pc{subClass}  eq 'free';

# 暗示に「】」の後の文字列があるか、または改行が含まれる場合は2段表示にするフラグを立てる
my $anji_plain = removeTags($pc{anji} || '');
$SHEET->param(isAnjiLong => ($anji_plain =~ /】\s*\S/ || $pc{anji} =~ /<br>/) ? 1 : 0);

### データ全体 --------------------------------------------------
while (my ($key, $value) = each(%pc)){
  $SHEET->param("$key" => $value);
}
### ID / URL--------------------------------------------------
$SHEET->param(id => $::in{id});

if($::in{url}){
  $SHEET->param(convertMode => 1);
  $SHEET->param(convertUrl => $::in{url});
}

### キャラクター名 --------------------------------------------------
$SHEET->param(characterName => stylizeCharacterName $pc{characterName},$pc{characterNameRuby});
$SHEET->param(aka => stylizeCharacterName $pc{aka},$pc{akaRuby});

### プレイヤー名 --------------------------------------------------
if($set::playerlist){
  my $pl_id = (split(/-/, $::in{id}))[0];
  $SHEET->param(playerName => '<a href="'.$set::playerlist.'?id='.$pl_id.'">'.$pc{playerName}.'</a>');
}
### グループ --------------------------------------------------
if($::in{url}){
  $SHEET->param(group => '');
}
else {
  if(!$pc{group}) {
    $pc{group} = $set::group_default;
    $SHEET->param(group => $set::group_default);
  }
  foreach (@set::groups){
    if($pc{group} eq @$_[0]){
      $SHEET->param(groupName => @$_[2]);
      last;
    }
  }
}

### タグ --------------------------------------------------
my @tags;
foreach(split(/ /, $pc{tags})){
  push(@tags, {
    URL  => uri_escape_utf8($_),
    TEXT => $_,
  });
}
$SHEET->param(Tags => \@tags);

### セリフ --------------------------------------------------
{
  my ($words, $x, $y) = stylizeWords($pc{words},$pc{wordsX},$pc{wordsY});
  $SHEET->param(words => $words);
  $SHEET->param(wordsX => $x);
  $SHEET->param(wordsY => $y);
}

### カルマ --------------------------------------------------
my @karmas;
foreach (1 .. $pc{karmaNum}){
  next if !$pc{'karma'.$_.'Name'};
  push(@karmas, {
    CHECK => $pc{'karma'.$_.'Check'} ? 'checked' : '',
    NAME  => $pc{'karma'.$_.'Name'},
  });
}
$SHEET->param(Karmas => \@karmas);

### 記憶のカケラ --------------------------------------------------
my @memories;
foreach (1 .. $pc{memoryNum}){
  next if !$pc{'memory'.$_.'Name'} && !$pc{'memory'.$_.'Note'};
  push(@memories, {
    NAME => $pc{'memory'.$_.'Name'},
    NOTE => $pc{'memory'.$_.'Note'},
  });
}
$SHEET->param(Memories => \@memories);

### 未練 --------------------------------------------------
my @mirens;
foreach (1 .. $pc{mirenNum}){
  next if !$pc{'miren'.$_.'Name'} && !$pc{'miren'.$_.'Note'};
  push(@mirens, {
    NAME     => $pc{'miren'.$_.'Name'},
    NOTE     => ($pc{'miren'.$_.'Note'} eq 'free' && $pc{'miren'.$_.'NoteFree'}) ? $pc{'miren'.$_.'NoteFree'} : $pc{'miren'.$_.'Note'},
    INSANITY => $pc{'miren'.$_.'Insanity'},
    BURST    => $pc{'miren'.$_.'Burst'},
  });
}
$SHEET->param(Mirens => \@mirens);

### スキル・パーツ --------------------------------------------------
my @skills;
my @parts_head;
my @parts_arms;
my @parts_torso;
my @parts_legs;

foreach my $i (1 .. $pc{skillNum}){
  next if !$pc{"skill${i}Name"} && !$pc{"skill${i}Timing"};
  
  my $source = ($pc{"skill${i}Source"} eq 'free' && $pc{"skill${i}SourceFree"}) ? $pc{"skill${i}SourceFree"} : $pc{"skill${i}Source"};
  my $category = ($pc{"skill${i}Category"} eq 'free' && $pc{"skill${i}CategoryFree"}) ? $pc{"skill${i}CategoryFree"} : $pc{"skill${i}Category"};
  
  my $damageClass = $pc{"skill${i}Damage"} ? 'damage' : '';

  my $hash = {
    NAME       => $pc{"skill${i}Name"},
    LV         => $pc{"skill${i}Lv"},
    TIMING     => $pc{"skill${i}Timing"},
    COST       => $pc{"skill${i}Cost"},
    RANGE      => $pc{"skill${i}Range"},
    INITIATIVE => $pc{"skill${i}Initiative"},
    CATEGORY   => $category,
    SOURCE     => $source,
    NOTE       => $pc{"skill${i}Note"},
    DAMAGE     => $damageClass,
    IS_DAMAGE  => $pc{"skill${i}Damage"} ? 1 : 0,
  };
  
  my $pos = $pc{"skill${i}Position"};
  if   ($pos eq 'skill'){ push(@skills, $hash); }
  elsif($pos eq 'head') { push(@parts_head, $hash); }
  elsif($pos eq 'arms') { push(@parts_arms, $hash); }
  elsif($pos eq 'torso'){ push(@parts_torso, $hash); }
  elsif($pos eq 'legs') { push(@parts_legs, $hash); }
}

$SHEET->param(Skills => \@skills);
$SHEET->param(PartsHead => \@parts_head);
$SHEET->param(PartsArms => \@parts_arms);
$SHEET->param(PartsTorso => \@parts_torso);
$SHEET->param(PartsLegs => \@parts_legs);

### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
$pc{history0Title} = 'キャラクター作成';
foreach (0 .. $pc{historyNum}){
  next if(!existsRow "history${_}",'Date','Title','Exp','Gm','Member','Note');
  $h_num++ if $pc{'history'.$_.'Gm'};
  if ($set::log_dir && $pc{'history'.$_.'Date'} =~ s/([^0-9]*?_[0-9]+(?:#[0-9a-zA-Z]+?)?)$//){
    my $room = $1;
    (my $date = $pc{'history'.$_.'Date'}) =~ s/[\-\/]//g;
    $pc{'history'.$_.'Date'} = "<a href=\"$set::log_dir$date$room.html\">$pc{'history'.$_.'Date'}<\/a>";
  }
  if ($set::sessionlist && $pc{'history'.$_.'Title'} =~ s/^#([0-9]+)//){
    $pc{'history'.$_.'Title'} = "<a href=\"$set::sessionlist?num=$1\" data-num=\"$1\">$pc{'history'.$_.'Title'}<\/a>";
  }
  my $members;
  $pc{'history'.$_.'Member'} =~ s/((?:\G|>)[^<]*?)[,、]+/$1　/g;
  foreach my $mem (split(/　/,$pc{'history'.$_.'Member'})){
    $members .= '<span>'.$mem.'</span>';
  }
  push(@history, {
    NUM    => ($pc{'history'.$_.'Gm'} ? $h_num : ''),
    DATE   => $pc{'history'.$_.'Date'},
    TITLE  => $pc{'history'.$_.'Title'},
    EXP    => $pc{'history'.$_.'Exp'},
    MIREN  => $pc{'history'.$_.'Miren'},
    INSANITY => $pc{'history'.$_.'Insanity'},
    BASEPART => $pc{'history'.$_.'BasePart'},
    ENHANCEDPART => $pc{'history'.$_.'EnhancedPart'},
    GM     => $pc{'history'.$_.'Gm'},
    MEMBER => $members,
    NOTE   => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);

### 寵愛点詳細計算 --------------------------------------------------
my $totalGrow = ($pc{growBuso} || 0) + ($pc{growHenI} || 0) + ($pc{growKaizo} || 0);

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
  
  if(grep { $_ eq $source } @validClasses){ $countClass++; }
  else { $countOther++; }
}

my $countMiren = 0;
my $countInsanity = 0;
my $countBasePart = 0;
my $countEnhancedPart = 0;
for my $i (1 .. $pc{historyNum}){
  $countMiren    += $pc{"history${i}Miren"} || 0;
  $countInsanity += $pc{"history${i}Insanity"} || 0;
  $countBasePart += $pc{"history${i}BasePart"} || 0;
  $countEnhancedPart += $pc{"history${i}EnhancedPart"} || 0;
}

$SHEET->param(
  countGrow   => $totalGrow,
  countClass  => $countClass,
  countOther  => $countOther,
  countMiren  => $countMiren,
  countInsanity => $countInsanity,
  countBasePart => $countBasePart,
  countEnhancedPart => $countEnhancedPart,
);

### 損傷表示設定 --------------------------------------------------
$SHEET->param("viewDamage".ucfirst($pc{viewDamage} || 'normal') => 1);

### 強化パーツ取得状況計算 --------------------------------------------------
my %cat_map = ('武装'=>'Buso', '変異'=>'HenI', '改造'=>'Kaizo');
my @circles = ('⓪','①','②','③','④','⑤','⑥','⑦','⑧','⑨','⑩');

foreach my $name (sort keys %cat_map) {
  my $id = $cat_map{$name};
  my $sttValue = $pc{"sttTotal".$id} || 0;
  
  my @availableSlots;
  # data-class.pl の %NCparts_level を参照
  if (ref($data::NCparts_level{$sttValue}) eq 'ARRAY') {
    my $counts = $data::NCparts_level{$sttValue};
    for my $i (0..2) {
      for (1..($counts->[$i]||0)) { push(@availableSlots, $i+1); }
    }
  } else {
    # 未定義時のフォールバック計算
    for (1..$sttValue) { push(@availableSlots, ($_ - 1) % 3 + 1); }
  }
  @availableSlots = sort { $a <=> $b } @availableSlots;
  my $available_str = join('', map { $circles[$_] || "($_)" } @availableSlots);

  my @acquiredLevels;
  for my $i (1..$pc{skillNum}) {
    next if $pc{"skill${i}CalcOff"};
    my $source = ($pc{"skill${i}Source"} eq 'free' && $pc{"skill${i}SourceFree"}) ? $pc{"skill${i}SourceFree"} : $pc{"skill${i}Source"};
    if ($source eq $name) {
      my $lv = $pc{"skill${i}Lv"} || 0;
      push(@acquiredLevels, $lv) if $lv > 0;
    }
  }
  @acquiredLevels = sort { $b <=> $a } @acquiredLevels;

  my @validate_results;
  my @temp_slots = @availableSlots;
  foreach my $acqLv (@acquiredLevels) {
    my $matchIdx = -1;
    for (my $i=0; $i < @temp_slots; $i++) {
      if ($temp_slots[$i] >= $acqLv) {
        $matchIdx = $i;
        last;
      }
    }
    if ($matchIdx != -1) {
      splice(@temp_slots, $matchIdx, 1);
      push(@validate_results, { lv => $acqLv, err => 0 });
    } else {
      push(@validate_results, { lv => $acqLv, err => 1 });
    }
  }
  @validate_results = sort { $a->{lv} <=> $b->{lv} } @validate_results;

  # （前略：ロジックや $acquired_html の生成までは変更なし）
  
  my $acquired_html = join('', map { 
    my $c = $circles[$_->{lv}] || "($_->{lv})";
    $_->{err} ? "<span class=\"part-status-error\">$c</span>" : $c;
  } @validate_results);

  # ▼ 修正後：閲覧画面（HTML）へ編集画面と全く同じ標準テーブル構造を流し込む
  $SHEET->param("partsStatus".$id => 
    "<table class=\"data-table\">".
    "<thead><tr><th colspan=\"2\">$name($sttValue)</th></tr></thead>".
    "<tbody>".
    "<tr><th>取得可能枠</th><td>".($available_str || 'なし')."</td></tr>".
    "<tr><th>取得状況</th><td>".($acquired_html || 'なし')."</td></tr>".
    "</tbody></table>"
  );
}

### バックアップ --------------------------------------------------
if($::in{id}){
  my($selected, $list) = getLogList($set::char_dir, $main::file);
  $SHEET->param(LogList => $list);
  $SHEET->param(selectedLogName => $selected);
  if($pc{yourAuthor} || $pc{protect} eq 'password'){
    $SHEET->param(viewLogNaming => 1);
  }
}

### タイトル --------------------------------------------------
$SHEET->param(title => $set::title);
if($pc{forbidden} eq 'all' && $pc{forbiddenMode}){
  $SHEET->param(titleName => '非公開データ');
}
else {
  $SHEET->param(titleName => removeTags removeRuby($pc{characterName}||"“$pc{aka}”"));
}

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url().($::in{url} ? "?url=$::in{url}" : "?id=$::in{id}"));
if($pc{image}) { $SHEET->param(ogImg => $pc{imageURL}); }
  my $anji2;
  $anji2 = $pc{anji};
    # 暗示：【】の中身のみを抽出
    if ($anji2 =~ /【(.+?)】/) {
        $anji2 = "【".$1."】";
    }
$SHEET->param(ogDescript => removeTags "享年:$pc{age}　暗示:$anji2　ポジション:$pc{position}　クラス:$pc{mainClass}/$pc{subClass}");

### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);
$SHEET->param(gameDir => 'nc');
$SHEET->param(sheetType => 'chara');
$SHEET->param(generateType => 'NechronicaPC');
$SHEET->param(defaultImage => $::core_dir.'/skin/nc/img/default_pc.png');

### メニュー --------------------------------------------------
my @menu = ();
if(!$pc{modeDownload}){
  push(@menu, { TEXT => '⏎', TYPE => "href", VALUE => './', });
  if($::in{url}){
    push(@menu, { TEXT => 'コンバート', TYPE => "href", VALUE => "./?mode=convert&url=$::in{url}" });
  }
  else {
    if($pc{logId}){
      push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => 'loglistOn()', });
      if($pc{reqdPassword}){ push(@menu, { TEXT => '復元', TYPE => "onclick", VALUE => "editOn()", }); }
      else                 { push(@menu, { TEXT => '復元', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{id}&log=$pc{logId}", }); }
    }
    else {
      if(!$pc{forbiddenMode}){
        push(@menu, { TEXT => 'パレット', TYPE => "onclick", VALUE => "chatPaletteOn()",   });
        push(@menu, { TEXT => '出力'    , TYPE => "onclick", VALUE => "downloadListOn()",  });
        push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => "loglistOn()",      });
      }
      if($pc{reqdPassword}){ push(@menu, { TEXT => '編集', TYPE => "onclick", VALUE => "editOn()", }); }
      else                 { push(@menu, { TEXT => '編集', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{id}", }); }
    }
  }
}
$SHEET->param(Menu => sheetMenuCreate @menu);

### エラー --------------------------------------------------
$SHEET->param(error => $main::login_error);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
if($pc{modeDownload}){
  if($pc{forbidden} && $pc{yourAuthor}){ $SHEET->param(forbidden => ''); }
  print downloadModeSheetConvert $SHEET->output;
}
else {
  print $SHEET->output;
}

1;