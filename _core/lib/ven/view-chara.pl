################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### テンプレート読み込み #############################################################################
my $SHEET;
$SHEET = HTML::Template->new( filename => $set::skin_sheet, utf8 => 1,
  path => ['./', $::core_dir."/skin/ven", $::core_dir."/skin/_common", $::core_dir],
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
    $pc{group} = $pc{tags} = '';
  
    $pc{age}    = noiseText(1,2);
    $pc{gender} = noiseText(1,2);
    $pc{height} = noiseText(2);
    $pc{weight} = noiseText(2);
    
    $pc{freeNote} = '';
    $pc{bodyArrange} = '';
    $pc{freeHistory} = '';
  }
  
  $pc{level} = noiseText(1);
  $pc{attribute} = noiseText(2,3);
  
  $pc{originNum} = $pc{adeptNum} = $pc{connectionNum} = $pc{powerNum} = $pc{weaponNum} = $pc{wearNum} = $pc{itemNum} = $pc{historyNum} = 0;
  
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
    if($_ =~ /^(?:freeNote|freeHistory|bodyArrange)$/){
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
if($pc{ver}){ %pc = data_update_chara(\%pc); }

### カラー設定 --------------------------------------------------
setColors();

### 出力準備 #########################################################################################
### データ全体 --------------------------------------------------
while (my ($key, $value) = each(%pc)){
  $SHEET->param("$key" => $value);
}
### ID / URL--------------------------------------------------
$SHEET->param(id => $::in{id});

### キャラクター名 --------------------------------------------------
$SHEET->param(characterName => stylizeCharacterName $pc{characterName},$pc{characterNameRuby});
$SHEET->param(aka => stylizeCharacterName $pc{aka},$pc{akaRuby});

### プレイヤー名 --------------------------------------------------
if($set::playerlist){
  my $pl_id = (split(/-/, $::in{id}))[0];
  $SHEET->param(playerName => '<a href="'.$set::playerlist.'?id='.$pl_id.'">'.$pc{playerName}.'</a>');
}
### グループ --------------------------------------------------
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

### タグ --------------------------------------------------
my @tags;
foreach(split(/ /, $pc{tags})){ push(@tags, { URL => uri_escape_utf8($_), TEXT => $_ }); }
$SHEET->param(Tags => \@tags);

### セリフ --------------------------------------------------
my ($words, $x, $y) = stylizeWords($pc{words},$pc{wordsX},$pc{wordsY});
$SHEET->param(words => $words);
$SHEET->param(wordsX => $x);
$SHEET->param(wordsY => $y);

### リストデータ生成 ==================================================

# ⑤ オリジン
my @origins;
foreach (1 .. $pc{originNum}){
  next if !existsRow "origin$_",'Name'; # ★ 'NameText' を 'Name' に変更
  push(@origins, {
    NAME          => $pc{'origin'.$_.'Name'}, # ★ 'NameText' を 'Name' に変更
    POWER_LINEAGE => $pc{'origin'.$_.'PowerLineage'}, 
    REASON        => $pc{'origin'.$_.'Reason'}, # ★ 'ReasonText' を 'Reason' に変更
    NOTE          => $pc{'origin'.$_.'Note'},
  });
}
$SHEET->param(Origins => \@origins);

# ⑥ アデプト
my @adepts;
foreach (1 .. $pc{adeptNum}){
  next if !existsRow "adept$_",'Name'; # ★ 'NameText' を 'Name' に変更
  push(@adepts, {
    NAME          => $pc{'adept'.$_.'Name'}, # ★ 'NameText' を 'Name' に変更
    POWER_LINEAGE => $pc{'adept'.$_.'PowerLineage'}, 
    REASON        => $pc{'adept'.$_.'Reason'}, # ★ 'ReasonText' を 'Reason' に変更
    NOTE          => $pc{'adept'.$_.'Note'},
  });
}
$SHEET->param(Adepts => \@adepts);

# ⑦ 妖精/神（3列のテキスト仕様に変更）
my @fairys;
foreach (1 .. $pc{fairyNum}){
  next if !existsRow "fairy$_",'NameText';
  push(@fairys, {
    NAME    => $pc{'fairy'.$_.'NameText'},
    FEATURE => $pc{'fairy'.$_.'Feature'}, # 追加
    NOTE    => $pc{'fairy'.$_.'Note'},    # 追加
  });
}
$SHEET->param(Fairys => \@fairys);

# ※ ⑧ 追加のパワー系統 (additionalPowerLineage) はハッシュの全展開によって
# 自動的に $SHEET->param に引き渡されるため、ここでの個別ループ処理は不要です。

# ⑨ 人脈
my @connections;
foreach (1 .. $pc{connectionNum}){
  next if !existsRow "connection$_",'Name';
  push(@connections, {
    NAME     => $pc{'connection'.$_.'Name'},
    TYPE     => $pc{'connection'.$_.'Type'},
    RELATION => $pc{'connection'.$_.'Relation'},
    NOTE     => $pc{'connection'.$_.'Note'},
  });
}
$SHEET->param(Connections => \@connections);

# ⑩ パワー
my @powers;
foreach (1 .. $pc{powerNum}){
  next if !existsRow "power$_",'Name';
  push(@powers, {
    FROM   => $pc{'power'.$_.'Source'}, # ← ★この行が正しく入っているか確認！
    NAME   => $pc{'power'.$_.'Name'},
    TYPE   => $pc{'power'.$_.'Type'},
    EFFECT => $pc{'power'.$_.'Note'},
    REF    => $pc{'power'.$_.'Ref'},
  });
}
$SHEET->param(Powers => \@powers);

# ⑬ 武器
# ⑦ 武器とカスタマイズ
my @weapons;
my $zebra_counter = 0; # 全体の連続ゼブラ用カウンター

foreach my $i (1 .. $pc{weaponNum}){
  next if !existsRow "weapon$i",'Name';

  $zebra_counter++; # 武器本体で1カウント
  my %w = (
    NAME   => $pc{"weapon${i}Name"},
    RANGE  => $pc{"weapon${i}Range"},
    DAMAGE => $pc{"weapon${i}Damage"},
    NOTE   => $pc{"weapon${i}Note"},
    MAINT  => $pc{"weapon${i}Maint"},
    REF    => $pc{"weapon${i}Ref"},
    ZEBRA  => ($zebra_counter % 2 == 0) ? 'even' : 'odd', # 偶数か奇数かを判定
    CUSTOMS => [],
  );
  
  foreach my $j (1 .. $pc{"weapon${i}CustomNum"}){
    next if !$pc{"weapon${i}Custom${j}Name"};

    $zebra_counter++; # カスタマイズ行ごとに1カウント
    
    # カテゴリが存在する場合はカッコで囲み、効果と結合して CEFFECT を生成する
    my $cat = $pc{"weapon${i}Custom${j}Category"} ? "［$pc{\"weapon${i}Custom${j}Category\"}］ " : "";
    my $note = $pc{"weapon${i}Custom${j}Note"} || "";
    my $ceffect = $cat . $note;

    push(@{$w{CUSTOMS}}, {
      CNAME   => $pc{"weapon${i}Custom${j}Name"},
      CPRICE  => $pc{"weapon${i}Custom${j}Price"},
      CMAINT  => $pc{"weapon${i}Custom${j}Maint"},
      CEFFECT => $ceffect, # 結合した文字列を渡す
      CREF    => $pc{"weapon${i}Custom${j}Ref"},
      CZEBRA  => ($zebra_counter % 2 == 0) ? 'even' : 'odd', # 偶数か奇数かを判定
    });
  }
  
  if (scalar @{$w{CUSTOMS}} > 0) {
    $w{CUSTOMS}->[-1]{IS_LAST} = 1;
  }
  
  push(@weapons, \%w);
}
$SHEET->param(Weapons => \@weapons);

# ⑫ ウェア
my @wears;
foreach (1 .. $pc{wearNum}){
  next if !existsRow "wear$_",'Name';
  push(@wears, {
    CATEGORY => $pc{'wear'.$_.'Category'}, # ← 追加
    NAME   => $pc{'wear'.$_.'Name'},
    EFFECT => $pc{'wear'.$_.'Note'},
    PRICE  => $pc{'wear'.$_.'Price'},
    MAINT  => $pc{'wear'.$_.'Maint'},
    REF    => $pc{'wear'.$_.'Ref'},
  });
}
$SHEET->param(Wears => \@wears);

# ⑬ アイテム
my @items;
foreach (1 .. $pc{itemNum}){
  next if !existsRow "item$_",'Name';
  push(@items, {
    USED   => $pc{'item'.$_.'Used'},
    NAME   => $pc{'item'.$_.'Name'},
    EFFECT => $pc{'item'.$_.'Note'},
    PRICE  => $pc{'item'.$_.'Price'},
    REF    => $pc{'item'.$_.'Ref'},
  });
}
$SHEET->param(Items => \@items);

# ⑲ ライフスタイル表示判定と備考なしフラグの生成
my $no_lifestyle_notes = (!$pc{lifestyleWeaknessNote} && !$pc{lifestyleHobbyNote} && !$pc{lifestyleMotivationNote}) ? 1 : 0;
my $has_lifestyle = ($pc{lifestyleWeakness} || $pc{lifestyleHobby} || $pc{lifestyleMotivation} || !$no_lifestyle_notes) ? 1 : 0;

$SHEET->param(lifestyleNoNotes => $no_lifestyle_notes);
$SHEET->param(hasLifestyle => $has_lifestyle);


### クレジット・維持費計算 --------------------------------------------------
my $total_income = 0;
my $total_expense = 0;
my $history_debt = 0;
for my $i (0 .. ($pc{historyNum} || 0)) {
  $total_income  += s_eval($pc{"history${i}Income"});
  $total_expense += s_eval($pc{"history${i}Expense"});
  $history_debt  += s_eval($pc{"history${i}Debt"});
}

my $manual_debt = s_eval($pc{debt});
my $total_debt = $manual_debt + $history_debt;
my $debt_interest = $total_debt > 0 ? int(($total_debt + 9) / 10) : 0;

my $named_weapon_count = 0;
my $weapon_custom_cost = 0;
my $weapon_base_maint = 0;
my $weapon_custom_maint = 0;
for my $i (1 .. ($pc{weaponNum} || 0)) {
  if ($pc{"weapon${i}Name"}) {
    $named_weapon_count++;
    $weapon_base_maint += s_eval($pc{"weapon${i}Maint"}); # 武器本体の維持費
  }
  for my $j (1 .. ($pc{"weapon${i}CustomNum"} || 0)) {
    my $price = s_eval($pc{"weapon${i}Custom${j}Price"});
    $weapon_custom_cost += $price;
    $weapon_custom_maint += int(($price + 9) / 10) if $price > 0;
  }
}
my $weapon_base_cost = $named_weapon_count > 1 ? ($named_weapon_count) * 50 : 0;

my $wear_cost = 0;
my $wear_maint = 0;
for my $i (1 .. ($pc{wearNum} || 0)) {
  my $price = s_eval($pc{"wear${i}Price"});
  $wear_cost += $price;
  $wear_maint += int(($price + 9) / 10) if $price > 0;
}

my $item_cost = 0;
for my $i (1 .. ($pc{itemNum} || 0)) {
  $item_cost += s_eval($pc{"item${i}Price"});
}

# 自主的な借金を総収入に加算
$total_income += $manual_debt;

my $equipment_cost = $weapon_base_cost + $weapon_custom_cost + $wear_cost + $item_cost;
my $credit_rest = $total_income - ($equipment_cost  + $total_expense);
my $base_maint = s_eval($pc{level}) * 10;
my $total_maint = $base_maint + $weapon_base_maint + $weapon_custom_maint + $wear_maint;



$SHEET->param(
  creditTotalAsset   => $equipment_cost,
  creditTotalIncome  => $total_income,
  creditTotalExpense => $total_expense,
  creditTotalDebt    => $total_debt,
  creditDebtView     => "$total_debt ($debt_interest)",
  creditRest         => $credit_rest,
  creditRestStyle    => ($credit_rest < 0 ? 'color: red;' : ''),
  
  creditTotalMaint   => $total_maint,
  creditMaintLevel   => $base_maint,
  creditMaintWeaponBase   => $weapon_base_maint,
  creditMaintWeaponCustom => $weapon_custom_maint,
  creditMaintWear    => $wear_maint,
  
  creditWeaponBase   => $weapon_base_cost,
  creditWeaponCustom => $weapon_custom_cost,
  creditWear         => $wear_cost,
  creditItem         => $item_cost,
);

### 履歴 --------------------------------------------------
my @history;
my $h_num = 0;
$pc{history0Title} = 'キャラクター作成';
foreach (0 .. $pc{historyNum}){
  next if(!existsRow "history${_}",'Date','Title','Income','Expense','Debt','Gm','Member','Note');
  $h_num++ if $pc{'history'.$_.'Gm'};
  
  my $members;
  $pc{'history'.$_.'Member'} =~ s/((?:\G|>)[^<]*?)[,、]+/$1 /g;
  foreach my $mem (split(/ /,$pc{'history'.$_.'Member'})){
    $members .= '<span>'.$mem.'</span>';
  }
  
  push(@history, {
    NUM     => ($pc{'history'.$_.'Gm'} ? $h_num : ''),
    DATE    => $pc{'history'.$_.'Date'},
    TITLE   => $pc{'history'.$_.'Title'},
    INCOME  => $pc{'history'.$_.'Income'},
    EXPENSE => $pc{'history'.$_.'Expense'},
    DEBT    => $pc{'history'.$_.'Debt'},
    GM      => $pc{'history'.$_.'Gm'},
    MEMBER  => $members,
    NOTE    => $pc{'history'.$_.'Note'},
  } );
}
$SHEET->param(History => \@history);

### バックアップ等 --------------------------------------------------
if($::in{id}){
  my($selected, $list) = getLogList($set::char_dir, $main::file);
  $SHEET->param(LogList => $list);
  $SHEET->param(selectedLogName => $selected);
  if($pc{yourAuthor} || $pc{protect} eq 'password'){
    $SHEET->param(viewLogNaming => 1);
  }
}

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
$SHEET->param(ogDescript => removeTags "性別:$pc{gender}　年齢:$pc{age}　オリジン:$pc{origin1Name} $pc{origin2Name}　アデプト:$pc{adept1Name} $pc{adept2Name}");


### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);
$SHEET->param(gameDir => 'ven');
$SHEET->param(sheetType => 'chara');
$SHEET->param(generateType => 'VentanglePC');
$SHEET->param(defaultImage => $::core_dir.'/skin/ven/img/default_pc.png');

### メニュー --------------------------------------------------
my @menu = ();
if(!$pc{modeDownload}){
  push(@menu, { TEXT => '⏎', TYPE => "href", VALUE => './', });
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