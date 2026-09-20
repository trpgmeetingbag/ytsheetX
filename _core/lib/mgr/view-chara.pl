################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

### データ読み込み ###################################################################################
require $set::data_class_mgr;
require $set::data_class_tenka;
require $set::data_src;

### データ／テンプレート読込 #########################################################################
(my $pcRef, my $SHEET) = setupViewBase(
  generateType => 'SRSPC',
  unescapeLinesKeys => [qw/items freeNote freeHistory/],
  unescapeSkipKeys  => [qw/stage/],
  convertViewMap    => [qw/items freeNote/],
  updateSub => \&upgradeCharaData,
);
our %pc = %{ $pcRef };

### 固有処理 #########################################################################################
### 閲覧禁止データのマスク --------------------------------------------------
sub maskPcData {
  my ($pc, $forbidden) = @_;
  
  if($forbidden ne 'battle'){
    $pc->{aka} = '';
    $pc->{characterName} = noiseText(6,14);
    $pc->{group} = $pc->{areaTags} = $pc->{tags} = '';
    
    $pc->{age}    = noiseText(1,2);
    $pc->{gender} = noiseText(1,2);

    $pc->{guildName} = noiseText(4,12);
    $pc->{guildMaster} = noiseText(3,12);

    $pc->{freeNote} = '';
    foreach(1..int(rand 5)+4){
      $pc->{freeNote} .= ' '.noiseText(18,40)."<br>";
    }
    $pc->{freeHistory} = '';
  }

  $pc->{level}        = noiseText(1);
  
  # --- MGR: 動的クラスのノイズ化 ---
  $pc->{classesNum} = int(rand 3) + 1;
  foreach (1 .. $pc->{classesNum}){
    $pc->{"class${_}Name"} = noiseText(4,8);
    $pc->{"class${_}Lv"}   = noiseText(1);
  }

  # --- MGR: 能力値のノイズ化 ---
  foreach my $stt ('Tai','Han','Chi','Ri','Ishi','Kou'){
    foreach my $i (1 .. 3){
      $pc->{"sttBase${i}${stt}"} = noiseText(1);
      $pc->{"sttBase${i}Class"}  = noiseText(3,6);
      $pc->{"sttBase${i}Type"}   = noiseText(2,4);
    }
    $pc->{"sttGrow${stt}"}     = noiseText(1);
    $pc->{"sttSkill${stt}"}    = noiseText(1);
    $pc->{"sttOther${stt}"}    = noiseText(1);
    $pc->{"sttTotal${stt}"}    = noiseText(2);
    $pc->{"sttBonusAdd${stt}"} = noiseText(1);
    $pc->{"sttBonus${stt}"}    = noiseText(1);
  }
  
  $pc->{expUsed}  = noiseText(1,3);
  $pc->{expRest}  = noiseText(1,3);
  $pc->{expTotal} = noiseText(1,3);

  $pc->{historyNum} = 0;
  $pc->{history0Exp}   = noiseText(1,3);
  $pc->{history0Honor} = noiseText(1,2);
  $pc->{history0Money} = noiseText(2,4);
}


### サイズの自動抽出・結合（MGR仕様） --------------------------------------------------
my %sizeHash;
foreach (1 .. $pc{armamentsNum}){
  my $part = $pc{"armament${_}Part"} || '';
  next if $part eq '';
  next if $part =~ /主|副|近|遠|武/;
  my $size = $pc{"defenceAuto${_}Size"};
  $sizeHash{$size} = 1 if defined $size && $size ne '';
}
foreach (1 .. $pc{defencesNum}){
  my $size = $pc{"defence${_}Size"};
  $sizeHash{$size} = 1 if defined $size && $size ne '';
}
my $mechaSize = join('/', sort keys %sizeHash);
$SHEET->param(mechaSize => $mechaSize || '―');

### コネクション --------------------------------------------------
my @connections;
foreach (1 .. $pc{connectionsNum}){
  next if !existsRow "connection$_",'Name','Relation','Note';
  push(@connections, {
    NAME     => $pc{'connection'.$_.'Name'},
    RELATION => $pc{'connection'.$_.'Relation'},
    NOTE     => $pc{'connection'.$_.'Note'},
    JOUBI    => $pc{'connection'.$_.'Joubika'} ? '☑' : '',
  });
}
$SHEET->param(Connections => \@connections);

### クラス／レベル --------------------------------------------------
my @classes;
my $totalClassLv = 0;
foreach (1 .. $pc{classesNum}){
  next if !existsRow "class$_",'Name','Lv';
  push(@classes, {
    NAME => $pc{'class'.$_.'Name'},
    LV   => $pc{'class'.$_.'Lv'},
  });
  $totalClassLv += $pc{'class'.$_.'Lv'};
}
$SHEET->param(Classes => \@classes);
$SHEET->param(totalClassLv => $totalClassLv);

### ミッション --------------------------------------------------
my @missions;
foreach (1 .. $pc{missionsNum}){
  next if !$pc{"mission${_}Note"};
  push(@missions, { NOTE => $pc{"mission${_}Note"} });
}
$SHEET->param(Missions => \@missions);

### 戦闘値：クラス修正行 --------------------------------------------------
my @battleClasses;
my $clNum = $pc{classesNum} || 3;
foreach (1 .. $clNum){
  next if !$pc{"class${_}Name"};
  push(@battleClasses, {
    NAME    => $pc{"class${_}Name"},
    LV      => $pc{"class${_}Lv"},
    MEICHU  => $pc{"battleClass${_}Meichu"},
    KAIHI   => $pc{"battleClass${_}Kaihi"},
    HOUGEKI => $pc{"battleClass${_}Hougeki"},
    BOUHEKI => $pc{"battleClass${_}Bouheki"},
    KOUDOU  => $pc{"battleClass${_}Koudou"},
    RIKIBA  => $pc{"battleClass${_}Rikiba"},
    TAIKYU  => $pc{"battleClass${_}Taikyu"},
    KANNOU  => $pc{"battleClass${_}Kannou"},
    KOUGEKI => $pc{"battleClass${_}Kougeki"},
  });
}
$SHEET->param(BattleClasses => \@battleClasses);

### 装備品 --------------------------------------------------
my @armaments;
foreach (1 .. $pc{armamentsNum}){
  next if !existsRow "armament$_",'Name','Part';
  my $part = $pc{"armament${_}Part"} || '';
  push(@armaments, {
    ID        => $_,
    CHECKED   => $pc{"armament${_}Equip"} ? 'checked' : '', 
    IS_WEAPON => ($part =~ /主|副|近|遠|武/) ? 1 : 0,
    PART      => $part,
    NAME      => $pc{"armament${_}Name"},
    MEICHU    => addNum($pc{"armament${_}Meichu"}),
    KAIHI     => addNum($pc{"armament${_}Kaihi"}),
    HOUGEKI   => addNum($pc{"armament${_}Hougeki"}),
    BOUHEKI   => addNum($pc{"armament${_}Bouheki"}),
    KOUDOU    => addNum($pc{"armament${_}Koudou"}),
    RIKIBA    => addNum($pc{"armament${_}Rikiba"}),
    TAIKYU    => addNum($pc{"armament${_}Taikyu"}),
    KANNOU    => addNum($pc{"armament${_}Kannou"}),
    IDOU      => addNum($pc{"armament${_}Idou"}),
    ZOKUSEI   => $pc{"armament${_}Zokusei"},
    KOUGEKI   => $pc{"armament${_}Kougeki"} || 0,
    SHATEI    => $pc{"armament${_}Shatei"},
    DAISHOU   => $pc{"armament${_}Daishou"},
    DANZUU    => $pc{"armament${_}Danzuu"},
    JOUBI     => $pc{"armament${_}Joubi"},
    SET       => $pc{"armament${_}Set"},
    NOTE      => $pc{"armamentNoteAuto${_}Note"},
    TYPE      => $pc{"armamentNoteAuto${_}Type"},
    ZAN       => $pc{"defenceAuto${_}Zan"},
    TOTSU     => $pc{"defenceAuto${_}Totsu"},
    OU        => $pc{"defenceAuto${_}Ou"},
    EN        => $pc{"defenceAuto${_}En"},
    HYOU      => $pc{"defenceAuto${_}Hyou"},
    RAI       => $pc{"defenceAuto${_}Rai"},
    KOU       => $pc{"defenceAuto${_}Kou"},
    YAMI      => $pc{"defenceAuto${_}Yami"},
    ATTR9     => $pc{"defenceAuto${_}Attr9"}, # （手動防具の場合は "defence${_}Attr9" に直して追加）
    SIZE      => $pc{"defenceAuto${_}Size"},
  });
}

### 防御修正とサイズ --------------------------------------------------
my @defences;
foreach (1 .. $pc{armamentsNum}){
  my $part = $pc{"armament${_}Part"} || '';
  next if $part eq '';
  next if $part =~ /主|副|近|遠|武/;
  push(@defences, {
    PART => $pc{"defenceAuto${_}Part"},
    NAME => $pc{"defenceAuto${_}Name"},
    ZAN  => $pc{"defenceAuto${_}Zan"},
    TOTSU=> $pc{"defenceAuto${_}Totsu"},
    OU   => $pc{"defenceAuto${_}Ou"},
    EN   => $pc{"defenceAuto${_}En"},
    HYOU => $pc{"defenceAuto${_}Hyou"},
    RAI  => $pc{"defenceAuto${_}Rai"},
    KOU  => $pc{"defenceAuto${_}Kou"},
    YAMI => $pc{"defenceAuto${_}Yami"},
    ATTR9=> $pc{"defenceAuto${_}Attr9"}, # （手動防具の場合は "defence${_}Attr9" に直して追加）
    SIZE => $pc{"defenceAuto${_}Size"},
  });
}
foreach (1 .. $pc{defencesNum}){
  next if !existsRow "defence$_",'Part','Name';
  push(@armaments, {
    ID        => "manual_def_$_",
    CHECKED   => 'checked', 
    EQUIP     => 1,
    IS_WEAPON => 0,
    IS_MANUAL_DEF => 1,
    PART      => $pc{"defence${_}Part"},
    NAME      => $pc{"defence${_}Name"},
    ZAN       => $pc{"defence${_}Zan"},
    TOTSU     => $pc{"defence${_}Totsu"},
    OU        => $pc{"defence${_}Ou"},
    EN        => $pc{"defence${_}En"},
    HYOU      => $pc{"defence${_}Hyou"},
    RAI       => $pc{"defence${_}Rai"},
    KOU       => $pc{"defence${_}Kou"},
    YAMI      => $pc{"defence${_}Yami"},
    ATTR9     => $pc{"defence${_}Attr9"}, # （手動防具の場合は "defence${_}Attr9" に直して追加）
    SIZE      => $pc{"defence${_}Size"},
    MEICHU=>'', KAIHI=>'', HOUGEKI=>'', BOUHEKI=>'', KOUDOU=>'', RIKIBA=>'', TAIKYU=>'', KANNOU=>'', IDOU=>'', KOUGEKI=>'', JOUBI=>'', SET=>'', NOTE=>'', TYPE=>''
  });
}
$SHEET->param(Armaments => \@armaments);
$SHEET->param(Defences => \@defences);

### 装備解説 --------------------------------------------------
my @armamentNotes;
foreach (1 .. $pc{armamentsNum}){
  next if !$pc{"armamentNoteAuto${_}Part"};
  push(@armamentNotes, {
    PART => $pc{"armamentNoteAuto${_}Part"},
    NAME => $pc{"armamentNoteAuto${_}Name"},
    NOTE => $pc{"armamentNoteAuto${_}Note"},
    TYPE => $pc{"armamentNoteAuto${_}Type"},
  });
}
$SHEET->param(ArmamentNotes => \@armamentNotes);

### 加护 --------------------------------------------------
my @kagos;
foreach (1 .. $pc{kagosNum}){
  next if !existsRow "kago$_",'Name','Note';
  push(@kagos, {
    NAME => $pc{"kago${_}Name"},
    NOTE => $pc{"kago${_}Note"},
  });
}
$SHEET->param(Kagos => \@kagos);

### スキル --------------------------------------------------
my @skills; my $skillCount = 0;
foreach (1 .. $pc{skillsNum}){
  next if !existsRow "skill$_",'Name','Lv','Timing','Target','Range','Cost','Reqd','Note';
  push(@skills, {
    TYPE     => $pc{'skill'.$_.'Type'},
    CATEGORY => $pc{'skill'.$_.'Category'},
    NAME     => shrinkText(13,15,17,21,$pc{'skill'.$_.'Name'}),
    LV       => $pc{'skill'.$_.'Lv'},
    TIMING   => renderTiming($pc{'skill'.$_.'Timing'}),
    TARGET   => shrinkText(6,7,8,8,$pc{'skill'.$_.'Target'}),
    RANGE    => $pc{'skill'.$_.'Range'},
    COST     => $pc{'skill'.$_.'Cost'} || '―',
    REQD     => $pc{'skill'.$_.'Reqd'},
    NOTE     => $pc{'skill'.$_.'Note'},
  });
  $skillCount++;
}
$SHEET->param(Skills => \@skills);
$SHEET->param(skillFullOpen => 'false') if $skillCount <= 10;

sub renderTiming {
  my $text = shift;
  $text =~ s#([^<])[／\/]#$1<hr class="dotted">#g;
  $text =~ s#(ムーブ|メジャー|マイナー)(アクション)?#<span class="thin">$1<span class="shorten">アクション</span></span>#g;
  $text =~ s#リアク?(ション)?#<span class="thin">リア<span class="shorten">クション</span></span>#g;
  $text =~ s#(セットアップ|クリンナップ)(プロセス)?#<span class="thiner">$1<span class="shorten">プロセス</span></span>#g;
  $text =~ s#(?:DR|ダメージロール)の?(直[前後])#<span class="thin">DR<span class="shorten">の</span>$1</span>#g;
  $text =~ s#(?:判定)の?(直[前後])#判定<span class="shorten">の</span>$1#g;
  return $text;
}
sub shrinkText {
  my $thin    = shift;
  my $thiner  = shift;
  my $thinest = shift;
  my $small   = shift;
  my $text = shift;
  my $check = $text;
  $check =~ s|<rp>(.+?)</rp>||g;
  $check =~ s|<rt>(.+?)</rt>||g;
  $check =~ s|<.+?>||g;
  if(length($check) >= $small) {
    return '<span class="thinest small">'.$text.'</span>';
  }
  if(length($check) >= $thinest) {
    return '<span class="thinest">'.$text.'</span>';
  }
  elsif(length($check) >= $thiner) {
    return '<span class="thiner">'.$text.'</span>';
  }
  elsif(length($check) >= $thin) {
    return '<span class="thin">'.$text.'</span>';
  }
  return $text;
}

### アイテム --------------------------------------------------
my $lifestyle_property_total = 0;
my @lifestyles;
foreach (1 .. $pc{lifestylesNum}){
  next if !existsRow "lifestyle$_",'Name','Note';
  push(@lifestyles, {
    NAME     => $pc{"lifestyle${_}Name"},
    JOUBI    => $pc{"lifestyle${_}Joubika"},
    NOTE     => $pc{"lifestyle${_}Note"},
    TIMING   => $pc{"lifestyle${_}Timing"},
    PROPERTY => $pc{"lifestyle${_}Property"},
  });
  $lifestyle_property_total += ($pc{"lifestyle${_}Property"} || 0);
}
$SHEET->param(Lifestyles => \@lifestyles);
$SHEET->param(lifestylePropertyTotal => $lifestyle_property_total);

my @houses;
foreach (1 .. $pc{housesNum}){
  next if !existsRow "house$_",'Name','Note';
  push(@houses, {
    NAME   => $pc{"house${_}Name"},
    JOUBI  => $pc{"house${_}Joubika"},
    NOTE   => $pc{"house${_}Note"},
    TIMING => $pc{"house${_}Timing"},
  });
}
$SHEET->param(Houses => \@houses);

my @items;
foreach (1 .. $pc{itemsNum}){
  next if !existsRow "item$_",'Name','Note';
  push(@items, {
    NAME   => $pc{"item${_}Name"},
    JOUBI  => $pc{"item${_}Joubika"},
    NOTE   => $pc{"item${_}Note"},
    TIMING => $pc{"item${_}Timing"},
  });
}
$SHEET->param(Items => \@items);

### 履歴 --------------------------------------------------
my @history;
push(@history, {
  NUM    => '作成',
  APPLY  => '☑',
  DATE   => '―',
  TITLE  => 'キャラクター作成',
  EXP    => $pc{history0Exp} || '0',
  GM     => '―',
  MEMBER => '―',
  NOTE   => $pc{history0Note} || '',
});

foreach (1 .. $pc{historyNum}){
  next if !existsRow "history$_",'Date','Title','Exp','Gm','Member','Note';
  
  if ($set::log_dir && $pc{"history${_}Date"} =~ s/([^0-9]*?_[0-9]+(?:#[0-9a-zA-Z]+?)?)$//){
    my $room = $1;
    (my $date = $pc{"history${_}Date"}) =~ y#\-\/##d;
    $pc{"history${_}Date"} = "<a href=\"$set::log_dir$date$room.html\">$pc{\"history${_}Date\"}<\/a>";
  }
  if ($set::sessionlist && $pc{"history${_}Title"} =~ s/^#([0-9]+)//){
    $pc{"history${_}Title"} = "<a href=\"$set::sessionlist?num=$1\" data-num=\"$1\">$pc{\"history${_}Title\"}<\/a>";
  }
  my $members;
  $pc{"history${_}Member"} =~ s/((?:\G|>)[^<]*?)[,、]+/$1 /g;
  foreach my $mem (split(/ /,$pc{"history${_}Member"})){
    $members .= '<span>'.$mem.'</span>';
  }
  if($_ && !$pc{"history${_}Check"} && $pc{"history${_}Exp"} ne '') {
    $pc{"history${_}Exp"} = '<s>'.$pc{"history${_}Exp"}.'</s>';
  }

  push(@history, {
    NUM    => $_,
    APPLY  => $pc{"history${_}Check"} ? 1 : 0,
    DATE   => $pc{"history${_}Date"},
    TITLE  => $pc{"history${_}Title"},
    EXP    => $pc{"history${_}Exp"},
    GM     => $pc{"history${_}Gm"},
    MEMBER => $members,
    NOTE   => $pc{"history${_}Note"},
  });
}
$SHEET->param(History => \@history);

### 特技取得履歴 --------------------------------------------------
my %class_lv_map = ( 'ガーディアン' => $pc{level} );
foreach (1 .. $pc{classesNum}){
  my $c = $pc{"class${_}Name"};
  my $l = $pc{"class${_}Lv"} || 0;
  if($c){ $class_lv_map{$c} += $l; }
}

my @skillHistoryCols;
push(@skillHistoryCols, { NAME => 'ガーディアン', LV => $class_lv_map{'ガーディアン'}, LV_DISP => '' });
foreach my $c (sort { $class_lv_map{$b} <=> $class_lv_map{$a} } keys %class_lv_map) {
  next if $c eq 'ガーディアン';
  push(@skillHistoryCols, { NAME => $c, LV => $class_lv_map{$c}, LV_DISP => "($class_lv_map{$c})" });
}

my $max_get_lv = 1;
my %skill_hist;
foreach (1 .. $pc{skillsNum}){
  next if !existsRow "skill$_",'Name','Lv';
  my $get_lv = $pc{"skill${_}GetLv"} || 0;
  next if $get_lv < 1;
  $max_get_lv = $get_lv if $get_lv > $max_get_lv;

  my $type = $pc{"skill${_}Type"};
  my $name = $pc{"skill${_}Name"};
  my $lv   = $pc{"skill${_}Lv"} || 1;
  my $cat  = $pc{"skill${_}Category"} || '';

  my $prefix = ($cat =~ /自/) ? '[自]' : ($cat =~ /選/) ? '[選]' : '';

  push(@{$skill_hist{$get_lv}{$type}}, {
    NAME    => $prefix . $name,
    LV      => $lv,
    IS_OVER => ($lv > $get_lv) ? 1 : 0,
  });
}

my @skillHistoryRows;
foreach my $lv (1 .. $max_get_lv){
  my @cols;
  foreach my $col (@skillHistoryCols){
    my @items;
    my $is_disabled = ($col->{NAME} ne 'ガーディアン' && $lv > $col->{LV}) ? 1 : 0;
    if(!$is_disabled && $skill_hist{$lv}{$col->{NAME}}){
      foreach my $item (@{$skill_hist{$lv}{$col->{NAME}}}){
        push(@items, $item);
      }
    }
    push(@cols, { Items => \@items, DISABLED => $is_disabled });
  }
  push(@skillHistoryRows, { LV => $lv, Cols => \@cols });
}
$SHEET->param(SkillHistoryHeaders => \@skillHistoryCols);
$SHEET->param(SkillHistoryRows => \@skillHistoryRows);

### SRSシステムに応じた見出しの生成 --------------------------------------------------
my $sysName = $pc{srsSystem} || 'メタリックガーディアンRPG';
$SHEET->param(srsSystem => $sysName);

my $srs = $data::srs_system{$sysName} || $data::srs_system{'その他（自由記入）'};

foreach my $i (1 .. 6) {
  $SHEET->param("sttName${i}" => $pc{"sttName${i}"} || $srs->{stt_names}[$i-1] || '　');
}
foreach my $i (1 .. 8) {
  $SHEET->param("battleName${i}" => $pc{"battleName${i}"} || $srs->{battle_names}[$i-1] || '　');
}
foreach my $i (1 .. 9) {
  $SHEET->param("defName${i}" => $pc{"defName${i}"} || $srs->{defense_names}[$i-1] || '　');
}

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags "性別:$pc{gender} 年齢:$pc{age} 機体名:$pc{mechaName} クラス:$pc{classMain}／$pc{classSupport}".($pc{classTitle}?"／$pc{classTitle}":''));

### メニュー --------------------------------------------------
setSheetMenu();

# --- デバッグ用：Armamentsの中身をJSON化してテンプレートに渡す ---
use JSON::PP;
my $json = JSON::PP->new->utf8(0)->canonical->encode(\@armaments);
$SHEET->param(debugArmaments => $json);

### 出力 #############################################################################################
printFinalizedView();

1;