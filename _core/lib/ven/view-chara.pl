################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

### データ／テンプレート読込 #########################################################################
(my $pcRef, my $SHEET) = setupViewBase(
  generateType => 'VentanglePC',
  unescapeLinesKeys => [qw/freeNote freeHistory bodyArrange/],
  convertViewMap    => [qw/freeNote/],
  updateSub => \&upgradeCharaData,
);
our %pc = %{ $pcRef };

### 固有処理 #########################################################################################
### 閲覧禁止データのマスク --------------------------------------------------
sub maskPcData {
  my ($pc, $forbidden) = @_;
  unless($forbidden eq 'battle'){
    $pc->{aka} = '';
    $pc->{characterName} = noiseText(6,14);
    $pc->{group} = $pc->{tags} = '';
  
    $pc->{age}    = noiseText(1,2);
    $pc->{gender} = noiseText(1,2);
    $pc->{height} = noiseText(2);
    $pc->{weight} = noiseText(2);
    
    $pc->{freeNote} = '';
    foreach(1..int(rand 3)+2){
      $pc->{freeNote} .= '　'.noiseText(18,40)."<br>";
    }
    $pc->{bodyArrange} = '';
    $pc->{freeHistory} = '';
  }
  
  $pc->{level} = noiseText(1);
  $pc->{attribute} = noiseText(2,3);
  
  $pc->{originNum} = $pc->{adeptNum} = $pc->{connectionNum} = $pc->{powerNum} = $pc->{weaponNum} = $pc->{wearNum} = $pc->{itemNum} = $pc->{historyNum} = 0;
}

### リストデータ生成 ==================================================

# ⑤ オリジン
my @origins;
foreach (1 .. $pc{originNum}){
  next if !existsRow "origin$_",'Name';
  push(@origins, {
    NAME          => $pc{'origin'.$_.'Name'},
    POWER_LINEAGE => $pc{'origin'.$_.'PowerLineage'}, 
    REASON        => $pc{'origin'.$_.'Reason'},
    NOTE          => $pc{'origin'.$_.'Note'},
  });
}
$SHEET->param(Origins => \@origins);

# ⑥ アデプト
my @adepts;
foreach (1 .. $pc{adeptNum}){
  next if !existsRow "adept$_",'Name';
  push(@adepts, {
    NAME          => $pc{'adept'.$_.'Name'},
    POWER_LINEAGE => $pc{'adept'.$_.'PowerLineage'}, 
    REASON        => $pc{'adept'.$_.'Reason'},
    NOTE          => $pc{'adept'.$_.'Note'},
  });
}
$SHEET->param(Adepts => \@adepts);

# ⑦ 妖精/神
my @fairys;
foreach (1 .. $pc{fairyNum}){
  next if !existsRow "fairy$_",'NameText';
  push(@fairys, {
    NAME    => $pc{'fairy'.$_.'NameText'},
    FEATURE => $pc{'fairy'.$_.'Feature'},
    NOTE    => $pc{'fairy'.$_.'Note'},
  });
}
$SHEET->param(Fairys => \@fairys);

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

sub renderTiming {
  my $text = shift;
  $text =~ s#([^<])[／\/]#$1<hr class="dotted">#g;
  $text =~ s#(オート|メジャー|マイナー)(アクション)?#<span class="thin">$1<span class="shorten">アクション</span></span>#g;
  $text =~ s#リアク?(ション)?#<span class="thin">リア<span class="shorten">クション</span></span>#g;
  $text =~ s#(セットアップ|クリンナップ)(プロセス)?#<span class="thiner">$1<span class="shorten">プロセス</span></span>#g;
  return $text;
}
sub renderSkill {
  my $text = shift;
  $text =~ s#(〈.*?〉|【.*?】)#<span>$1</span>#g;
  $text =~ s#(シンドローム)#<span class="thin">$1</span>#g;
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

# ⑩ パワー
my @powers;
foreach (1 .. $pc{powerNum}){
  next if !existsRow "power$_",'Name';
  push(@powers, {
    FROM   => $pc{'power'.$_.'Source'},
    NAME => shrinkText(18,19,20,21, $pc{'power'.$_.'Name'}),
    TYPE   => $pc{'power'.$_.'Type'},
    EFFECT => $pc{'power'.$_.'Note'},
    REF    => $pc{'power'.$_.'Ref'},
  });
}
$SHEET->param(Powers => \@powers);

# ⑬ 武器とカスタマイズ
my @weapons;
my $zebra_counter = 0;

foreach my $i (1 .. $pc{weaponNum}){
  next if !existsRow "weapon$i",'Name';

  $zebra_counter++;
  my %w = (
    # 名前が長い場合に自動で細字にする shrinkText を適用
    NAME   => shrinkText(18,19,20,21, $pc{"weapon${i}Name"}),
    RANGE  => $pc{"weapon${i}Range"},
    DAMAGE => $pc{"weapon${i}Damage"},
    NOTE   => $pc{"weapon${i}Note"},
    MAINT  => $pc{"weapon${i}Maint"},
    REF    => $pc{"weapon${i}Ref"},
    ZEBRA  => ($zebra_counter % 2 == 0) ? 'even' : 'odd',
    CUSTOMS => [],
  );
  
  foreach my $j (1 .. $pc{"weapon${i}CustomNum"}){
    next if !$pc{"weapon${i}Custom${j}Name"};

    $zebra_counter++;
    my $cat = $pc{"weapon${i}Custom${j}Category"} ? "［$pc{\"weapon${i}Custom${j}Category\"}］ " : "";
    my $note = $pc{"weapon${i}Custom${j}Note"} || "";
    my $ceffect = $cat . $note;

    push(@{$w{CUSTOMS}}, {
      CNAME   => shrinkText(18,19,20,21, $pc{"weapon${i}Custom${j}Name"}),
      CPRICE  => $pc{"weapon${i}Custom${j}Price"},
      CMAINT  => $pc{"weapon${i}Custom${j}Maint"},
      CEFFECT => $ceffect,
      CREF    => $pc{"weapon${i}Custom${j}Ref"},
      CZEBRA  => ($zebra_counter % 2 == 0) ? 'even' : 'odd',
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
    CATEGORY => $pc{'wear'.$_.'Category'},
    NAME     => shrinkText(18,19,20,21, $pc{'wear'.$_.'Name'}),
    EFFECT   => $pc{'wear'.$_.'Note'},
    PRICE    => $pc{'wear'.$_.'Price'},
    MAINT    => $pc{'wear'.$_.'Maint'},
    REF      => $pc{'wear'.$_.'Ref'},
  });
}
$SHEET->param(Wears => \@wears);

# ⑬ アイテム
my @items;
foreach (1 .. $pc{itemNum}){
  next if !existsRow "item$_",'Name';
  push(@items, {
    USED   => $pc{'item'.$_.'Used'},
    NAME   => shrinkText(12,13,14,15, $pc{'item'.$_.'Name'}),
    EFFECT => $pc{'item'.$_.'Note'},
    PRICE  => $pc{'item'.$_.'Price'},
    REF    => $pc{'item'.$_.'Ref'},
  });
}
$SHEET->param(Items => \@items);

# ⑲ ライフスタイル表示判定
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
    $weapon_base_maint += s_eval($pc{"weapon${i}Maint"});
  }
  for my $j (1 .. ($pc{"weapon${i}CustomNum"} || 0)) {
    my $price = s_eval($pc{"weapon${i}Custom${j}Price"});
    $weapon_custom_cost += $price;
    $weapon_custom_maint += int(($price + 9) / 10) if $price > 0;
  }
}
my $weapon_base_cost = $named_weapon_count > 0 ? ($named_weapon_count) * 50 : 0;

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
  
  # ▼過去ログへの自動リンク生成機能▼
  if ($set::log_dir && $pc{'history'.$_.'Date'} =~ s/([^0-9]*?_[0-9]+(?:#[0-9a-zA-Z]+?)?)$//){
    my $room = $1;
    (my $date = $pc{'history'.$_.'Date'}) =~ y#\-\/##d;
    $pc{'history'.$_.'Date'} = "<a href=\"$set::log_dir$date$room.html\">$pc{'history'.$_.'Date'}<\/a>";
  }

  # ▼セッション募集・一覧への自動リンク生成機能▼
  if ($set::sessionlist && $pc{'history'.$_.'Title'} =~ s/^#([0-9]+)//){
    $pc{'history'.$_.'Title'} = "<a href=\"$set::sessionlist?num=$1\" data-num=\"$1\">$pc{'history'.$_.'Title'}<\/a>";
  }
  
  # ▼参加者名の <span> 分割処理▼
  my $members;
  $pc{'history'.$_.'Member'} =~ s/((?:\G|>)[^<]*?)[,、]+/$1 /g;
  foreach my $mem (split(/ /,$pc{'history'.$_.'Member'})){
    # 括弧（〈〉や【】）を含むスキル名などが書かれていた場合に色付けする renderSkill も適用可能
    $members .= '<span>'.renderSkill($mem).'</span>';
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

### OGP --------------------------------------------------
$SHEET->param(ogDescript => removeTags "性別:$pc{gender} 年齢:$pc{age} オリジン:$pc{origin1Name} $pc{origin2Name} アデプト:$pc{adept1Name} $pc{adept2Name}");

### メニューと出力 ###################################################################################
setSheetMenu();
printFinalizedView();

1;