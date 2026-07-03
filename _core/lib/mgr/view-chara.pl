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
  path => ['./', $::core_dir."/skin/mgr", $::core_dir."/skin/_common", $::core_dir],
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
    $pc{group} = $pc{areaTags} = $pc{tags} = '';
    
    $pc{age}    = noiseText(1,2);
    $pc{gender} = noiseText(1,2);

    $pc{guildName} = noiseText(4,12);
    $pc{guildMaster} = noiseText(3,12);

    $pc{freeNote} = '';
    foreach(1..int(rand 5)+4){
      $pc{freeNote} .= '　'.noiseText(18,40)."<br>";
    }
    $pc{freeHistory} = '';
  }

  $pc{level}        = noiseText(1);
  
  # --- MGR: 動的クラスのノイズ化 ---
  $pc{classesNum} = int(rand 3) + 1;
  foreach (1 .. $pc{classesNum}){
    $pc{"class${_}Name"} = noiseText(4,8);
    $pc{"class${_}Lv"}   = noiseText(1);
  }

  # --- MGR: 能力値のノイズ化 ---
  foreach my $stt ('Tai','Han','Chi','Ri','Ishi','Kou'){
    foreach my $i (1 .. 3){
      $pc{"sttBase${i}${stt}"} = noiseText(1);
      $pc{"sttBase${i}Class"}  = noiseText(3,6);
      $pc{"sttBase${i}Type"}   = noiseText(2,4);
    }
    $pc{"sttGrow${stt}"}     = noiseText(1);
    $pc{"sttSkill${stt}"}    = noiseText(1);
    $pc{"sttOther${stt}"}    = noiseText(1);
    $pc{"sttTotal${stt}"}    = noiseText(2);
    $pc{"sttBonusAdd${stt}"} = noiseText(1);
    $pc{"sttBonus${stt}"}    = noiseText(1);
  }





  
  $pc{expUsed}  = noiseText(1,3);
  $pc{expRest}  = noiseText(1,3);
  $pc{expTotal} = noiseText(1,3);

  $pc{historyNum} = 0;
  $pc{history0Exp}   = noiseText(1,3);
  $pc{history0Honor} = noiseText(1,2);
  $pc{history0Money} = noiseText(2,4);
  
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
    if($_ =~ /^(?:items|freeNote|freeHistory|cashbook)$/){
      $pc{$_} = unescapeTagsLines($pc{$_});
    }
    $pc{$_} = unescapeTags($pc{$_});

    $pc{$_} = noiseTextTag $pc{$_} if $pc{forbiddenMode};
  }
}
else {
  $pc{items} = $pc{itemsView} if $pc{itemsView};
  $pc{freeNote} = $pc{freeNoteView} if $pc{freeNoteView};
}

### アップデート --------------------------------------------------
if($pc{ver}){
  %pc = data_update_chara(\%pc);
}

### カラー設定 --------------------------------------------------
setColors();

### 置換後出力 #######################################################################################
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

### エリア --------------------------------------------------
my @areatags;
foreach(split(/ /, $pc{areaTags})){
  push(@areatags, { "TEXT" => $_, });
}
$SHEET->param(AreaTags => \@areatags);

### セリフ --------------------------------------------------
{
  my ($words, $x, $y) = stylizeWords($pc{words},$pc{wordsX},$pc{wordsY});
  $SHEET->param(words => $words);
  $SHEET->param(wordsX => $x);
  $SHEET->param(wordsY => $y);
}


### サイズの自動抽出・結合（MGR仕様） --------------------------------------------------
my %sizeHash;
# ① 装備に連動する自動行のサイズを取得
foreach (1 .. $pc{armamentsNum}){
  my $part = $pc{"armament${_}Part"} || '';
  next if $part eq '';               # 部位が空欄ならスキップ
  next if $part =~ /主|副|近|遠|武/; # 武器系は除外
  
  my $size = $pc{"defenceAuto${_}Size"};
  $sizeHash{$size} = 1 if defined $size && $size ne '';
}
# ② 手動追加行のサイズを取得
foreach (1 .. $pc{defencesNum}){
  my $size = $pc{"defence${_}Size"};
  $sizeHash{$size} = 1 if defined $size && $size ne '';
}

# 重複を排除して「/」で結合（空欄の場合は「―」を代入）
my $mechaSize = join('/', sort keys %sizeHash);
$SHEET->param(mechaSize => $mechaSize || '―');


### パーソナルデータ・ライフパス（項目名切替） --------------------------------------------------
# （※ここから下は既存のコードが続きます）



### コネクション（MGR動的行対応） --------------------------------------------------
my @connections;
foreach (1 .. $pc{connectionsNum}){
  next if !existsRow "connection$_",'Name','Relation','Note';
  push(@connections, {
    NAME     => $pc{'connection'.$_.'Name'},
    RELATION => $pc{'connection'.$_.'Relation'},
    NOTE     => $pc{'connection'.$_.'Note'},
    JOUBI    => $pc{'connection'.$_.'Joubika'} ? '☑' : '', # ☑ または 空白
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
# クラス数が保存されていない場合のフォールバック
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


### 装備品（MGR動的行対応） --------------------------------------------------
my @armaments;
foreach (1 .. $pc{armamentsNum}){
  next if !existsRow "armament$_",'Name','Part';
  my $part = $pc{"armament${_}Part"} || '';
  push(@armaments, {
    ID        => $_, # JSで特定の行を狙い撃つためのID
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
    ZOKUSEI   => $pc{"armament${_}Zokusei"}, # 属性
    KOUGEKI   => $pc{"armament${_}Kougeki"} || 0, # 計算用なので生の値
    SHATEI    => $pc{"armament${_}Shatei"},
    DAISHOU   => $pc{"armament${_}Daishou"},
    DANZUU    => $pc{"armament${_}Danzuu"},
    JOUBI     => $pc{"armament${_}Joubi"},
    SET       => $pc{"armament${_}Set"},

    # ▼ ここから追加：装備解説と機体データのマージ ▼
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
    SIZE      => $pc{"defenceAuto${_}Size"},

    
  });
}
$SHEET->param(Armaments => \@armaments);


### 防御修正とサイズ --------------------------------------------------
my @defences;
# ① 装備に連動する自動行
foreach (1 .. $pc{armamentsNum}){
  my $part = $pc{"armament${_}Part"} || '';
  next if $part eq '';               # 部位が空欄ならスキップ
  next if $part =~ /主|副|近|遠|武/; # 武器系は除外
  
  # （誤動作の原因だった existsRow の判定を削除しました）

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
    SIZE => $pc{"defenceAuto${_}Size"},
  });
}
# ② 手動追加行
foreach (1 .. $pc{defencesNum}){
  next if !existsRow "defence$_",'Part','Name';
  
  push(@armaments, {

    ID        => "manual_def_$_",
    CHECKED   => 'checked', 
    EQUIP     => 1,    # 計算対象にする
    IS_WEAPON => 0,    # 武器リストには表示しないフラグ
    IS_MANUAL_DEF => 1, # ★手動防御行であることを示す専用の目印を追加
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
    SIZE      => $pc{"defence${_}Size"},
    MEICHU=>'', KAIHI=>'', HOUGEKI=>'', BOUHEKI=>'', KOUDOU=>'', RIKIBA=>'', TAIKYU=>'', KANNOU=>'', IDOU=>'', KOUGEKI=>'', JOUBI=>'', SET=>'', NOTE=>'', TYPE=>''
  });
}
$SHEET->param(Armaments => \@armaments);
$SHEET->param(Defences => \@defences);

### 装備解説 --------------------------------------------------
my @armamentNotes;
foreach (1 .. $pc{armamentsNum}){
  next if !$pc{"armamentNoteAuto${_}Part"}; # 部位が空ならスキップ
  push(@armamentNotes, {
    PART => $pc{"armamentNoteAuto${_}Part"},
    NAME => $pc{"armamentNoteAuto${_}Name"},
    NOTE => $pc{"armamentNoteAuto${_}Note"},
    TYPE => $pc{"armamentNoteAuto${_}Type"},
  });
}
$SHEET->param(ArmamentNotes => \@armamentNotes);



### 加護 --------------------------------------------------
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
    TYPE     => $pc{'skill'.$_.'Type'}, # MGR用にそのまま出力
    CATEGORY => $pc{'skill'.$_.'Category'},
    NAME     => textShrink(13,15,17,21,$pc{'skill'.$_.'Name'}),
    LV       => $pc{'skill'.$_.'Lv'},
    TIMING   => textTiming($pc{'skill'.$_.'Timing'}),
    TARGET   => textShrink(6,7,8,8,$pc{'skill'.$_.'Target'}),
    RANGE    => $pc{'skill'.$_.'Range'},
    COST     => $pc{'skill'.$_.'Cost'} || '―',
    REQD     => $pc{'skill'.$_.'Reqd'},
    NOTE     => $pc{'skill'.$_.'Note'},
  });
  $skillCount++;
}
$SHEET->param(Skills => \@skills);
$SHEET->param(skillFullOpen => 'false') if $skillCount <= 10;



### アイテム（MGR 3種分割対応） --------------------------------------------------
# ① ライフスタイル
my $lifestyle_property_total = 0; # 合計用の変数を初期化
my @lifestyles;
foreach (1 .. $pc{lifestylesNum}){
  next if !existsRow "lifestyle$_",'Name','Note';
  push(@lifestyles, {
    NAME  => $pc{"lifestyle${_}Name"},
    JOUBI => $pc{"lifestyle${_}Joubika"},
    NOTE  => $pc{"lifestyle${_}Note"},
    # ▼ この2行を追加して、HTMLのTMPL_VARにデータを渡す！ ▼
        TIMING   => $pc{"lifestyle${_}Timing"},
        PROPERTY => $pc{"lifestyle${_}Property"},
  });
  $lifestyle_property_total += ($pc{"lifestyle${_}Property"} || 0);
}
$SHEET->param(Lifestyles => \@lifestyles);
$SHEET->param(lifestylePropertyTotal => $lifestyle_property_total);


# ② 住宅
my @houses;
foreach (1 .. $pc{housesNum}){
  next if !existsRow "house$_",'Name','Note';
  push(@houses, {
    NAME  => $pc{"house${_}Name"},
    JOUBI => $pc{"house${_}Joubika"},
    NOTE  => $pc{"house${_}Note"},
    TIMING => $pc{"house${_}Timing"},
  });
}
$SHEET->param(Houses => \@houses);

# ③ 一般アイテム
my @items;
foreach (1 .. $pc{itemsNum}){
  next if !existsRow "item$_",'Name','Note';
  push(@items, {
    NAME  => $pc{"item${_}Name"},
    JOUBI => $pc{"item${_}Joubika"},
    NOTE  => $pc{"item${_}Note"},
    TIMING => $pc{"item${_}Timing"},
  });
}
$SHEET->param(Items => \@items);




sub textTiming {
  my $text = shift;
  $text =~ s#([^<])[／\/]#$1<hr class="dotted">#g;
  $text =~ s#(ムーブ|メジャー|マイナー)(アクション)?#<span class="thin">$1<span class="shorten">アクション</span></span>#g;
  $text =~ s#リアク?(ション)?#<span class="thin">リア<span class="shorten">クション</span></span>#g;
  $text =~ s#(セットアップ|クリンナップ)(プロセス)?#<span class="thiner">$1<span class="shorten">プロセス</span></span>#g;
  $text =~ s#(?:DR|ダメージロール)の?(直[前後])#<span class="thin">DR<span class="shorten">の</span>$1</span>#g;
  $text =~ s#(?:判定)の?(直[前後])#判定<span class="shorten">の</span>$1#g;
  return $text;
}
sub textShrink {
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




### 履歴（nc・MGR仕様 2行1セット対応） --------------------------------------------------
my @history;

# 0行目（キャラクター作成）をセッション履歴の先頭に挿入
push(@history, {
  NUM    => '作成',
  APPLY  => '☑', # 作成時の経験点は常に適用扱い
  DATE   => '―',
  TITLE  => 'キャラクター作成',
  EXP    => $pc{history0Exp} || '0',
  GM     => '―',
  MEMBER => '―',
  NOTE   => $pc{history0Note} || '',
});

# 1行目以降（通常のセッション履歴）
foreach (1 .. $pc{historyNum}){
  next if !existsRow "history$_",'Date','Title','Exp','Gm','Member','Note';
  
  push(@history, {
    NUM    => $_,
    APPLY  => $pc{"history${_}Check"} ? 1 : 0,
    DATE   => $pc{"history${_}Date"},
    TITLE  => $pc{"history${_}Title"},
    EXP    => $pc{"history${_}Exp"},
    GM     => $pc{"history${_}Gm"},
    MEMBER => $pc{"history${_}Member"},
    NOTE   => $pc{"history${_}Note"},
  });
}
$SHEET->param(History => \@history);


### 特技取得履歴 --------------------------------------------------
### 特技取得履歴 --------------------------------------------------
my %class_lv_map = ( 'ガーディアン' => $pc{level} );
foreach (1 .. $pc{classesNum}){
  my $c = $pc{"class${_}Name"};
  my $l = $pc{"class${_}Lv"} || 0;
  if($c){ $class_lv_map{$c} += $l; }
}

my @skillHistoryCols;
# ガーディアンを先頭に固定
push(@skillHistoryCols, { NAME => 'ガーディアン', LV => $class_lv_map{'ガーディアン'}, LV_DISP => '' });
# 他のクラスをレベルの数値が高い順（数値比較 <=>）に並べる
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

  # [自][選] プレフィックス
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
    # ★修正：ガーディアン列はレベル上限によるグレーアウトを除外
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



#if($pc{deposit} =~ /^(?:自動|auto)$/i){
#  $SHEET->param(deposit => $pc{depositTotal}.' G ／ '.$pc{debtTotal});
#}
$pc{cashbook} =~ s/(:(?:\:|&lt;|&gt;))((?:[\+\-\*\/]?[0-9]+)+)/$1.cashCheck($2)/eg;
  $SHEET->param(cashbook => $pc{cashbook});
sub cashCheck(){
  my $text = shift;
  my $num = s_eval($text);
  if   ($num > 0) { return '<b class="cash plus">'.$text.'</b>'; }
  elsif($num < 0) { return '<b class="cash minus">'.$text.'</b>'; }
  else { return '<b class="cash">'.$text.'</b>'; }
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

### フェロー --------------------------------------------------
$SHEET->param(FellowMode => $::in{f});

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
$SHEET->param(ogDescript => removeTags "性別:$pc{gender}　年齢:$pc{age}　機体名:$pc{mechaName}　クラス:$pc{classMain}／$pc{classSupport}".($pc{classTitle}?"／$pc{classTitle}":''));

### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);
$SHEET->param(gameDir => 'mgr');
$SHEET->param(sheetType => 'chara');
$SHEET->param(generateType => 'Arianrhod2PC');
$SHEET->param(defaultImage => $::core_dir.'/skin/mgr/img/default_pc.png');

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

# --- デバッグ用：Armamentsの中身をJSON化してテンプレートに渡す ---
use JSON::PP;
my $json = JSON::PP->new->utf8(0)->canonical->encode(\@armaments);
$SHEET->param(debugArmaments => $json);

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