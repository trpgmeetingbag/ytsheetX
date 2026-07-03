################## データ保存 ##################
use strict;
#use warnings;
use utf8;

sub data_calc {
  my %pc = %{$_[0]};
  
  ### 資金・借金計算 --------------------------------------------------
  $pc{incomeTotal}  = $pc{history0Income}  || 0;
  $pc{expenseTotal} = $pc{history0Expense} || 0;
  $pc{debtTotal}    = $pc{history0Debt}    || 0;
  foreach my $i (1 .. $pc{historyNum}){
    $pc{incomeTotal}  += s_eval($pc{"history${i}Income"})  if $pc{"history${i}Income"};
    $pc{expenseTotal} += s_eval($pc{"history${i}Expense"}) if $pc{"history${i}Expense"};
    $pc{debtTotal}    += s_eval($pc{"history${i}Debt"})    if $pc{"history${i}Debt"};
  }
  # 現在の所持金（収入 - 支出）
  $pc{moneyTotal} = $pc{incomeTotal} - $pc{expenseTotal};

  ### 初期数値（プライド・カルマ）の自動合算 --------------------------------------------------
  $pc{prideTotal}    = 8 + ($pc{prideBase} || 0) - ($pc{pridePenalty} || 0);
  $pc{prideMaxTotal} = 16 + ($pc{prideMax} || 0);
  $pc{karmaTotal}    = 2 + ($pc{karmaBase} || 0) + ($pc{karmaPenalty} || 0);

  #### 空欄データの消去 --------------------------------------------------
  # （必要に応じて、不要な空データを削除してファイルサイズを節約します）

  #### 改行を<br>に変換 --------------------------------------------------
  $pc{words}         =~ s/\r\n?|\n/<br>/g;
  $pc{freeNote}      =~ s/\r\n?|\n/<br>/g;
  $pc{freeHistory}   =~ s/\r\n?|\n/<br>/g;
  $pc{chatPalette}   =~ s/\r\n?|\n/<br>/g;
  
  $pc{bodyArrange}   =~ s/\r\n?|\n/<br>/g;
  
  $pc{"weapon${_}Note"}  =~ s/\r\n?|\n/<br>/g foreach (1 .. $pc{weaponNum});
  foreach my $num (1 .. $pc{weaponNum}){
    $pc{"weapon${num}Custom${_}Effect"} =~ s/\r\n?|\n/<br>/g foreach (1 .. $pc{"weapon${num}CustomNum"});
  }
  
  #### 保存処理でなければここまで --------------------------------------------------
  if(!$::mode_save){ return %pc; }
  
  #### エスケープ --------------------------------------------------
  $pc{$_} = pcEscape($pc{$_}) foreach (keys %pc);
  $pc{tags} = normalizeHashtags($pc{tags});
  
  ### 最終参加卓 --------------------------------------------------
  foreach my $i (reverse 1 .. $pc{historyNum}){
    if($pc{"history${i}Gm"} && $pc{"history${i}Title"}){ $pc{lastSession} = removeTags unescapeTags $pc{"history${i}Title"}; last; }
  }

  ### キャラクター一覧表示用データ生成 (newline) --------------------------------------------------
  my $charactername = ($pc{aka} ? "“$pc{aka}”" : "").$pc{characterName};
  $charactername =~ s/[|｜]([^|｜]+?)《.+?》/$1/g;

  
  

# ▼ 追加1：オリジン・アデプト・妖精の一覧文字列化 ▼
my @origins;
for my $i (1 .. ($pc{originNum} || 0)) {
  if ($pc{"origin${i}Name"}) {
    my $name = $pc{"origin${i}Name"};
    my $lineage = $pc{"origin${i}PowerLineage"};
    push(@origins, $lineage ? "${name}(${lineage})" : $name);
  }
}
my $origin_list = join(' / ', @origins);

my @adepts;
for my $i (1 .. ($pc{adeptNum} || 0)) {
  if ($pc{"adept${i}Name"}) {
    my $name = $pc{"adept${i}Name"};
    my $lineage = $pc{"adept${i}PowerLineage"};
    push(@adepts, $lineage ? "${name}(${lineage})" : $name);
  }
}
my $adept_list = join(' / ', @adepts);

my @fairys;
for my $i (1 .. ($pc{fairyNum} || 0)) {
  if ($pc{"fairy${i}NameText"}) {
    push(@fairys, $pc{"fairy${i}NameText"});
  }
}
my $fairy_list = join(' / ', @fairys);

# ▼ 追加2：一覧用のクレジット・維持費計算（view-charaと同じ安全な四則演算） ▼
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

$total_income += $manual_debt;
my $equipment_cost = $weapon_base_cost + $weapon_custom_cost + $wear_cost + $item_cost;
my $credit_rest = $total_income - ($equipment_cost  + $total_expense);
my $base_maint = s_eval($pc{level}) * 10;
my $total_maint = $base_maint + $weapon_base_maint + $weapon_custom_maint + $wear_maint;

$total_income = $equipment_cost; #総収入を総資産に変えるのがめんどいので雑に上書き


# ▼ 修正：一覧データ($::newline)の書き込み ▼
# （既存の使わない1件目のみの変数を置き換え、末尾にクレジット関連を追加）
$::newline = "$pc{id}<>$::file<>".
             "$pc{birthTime}<>$::now<>$charactername<>$pc{playerName}<>$pc{group}<>".
             "$pc{level}<>$pc{attribute}<>$pc{age}<>$pc{gender}<>$origin_list<>".
             "$adept_list<>$fairy_list<>$total_income<>".
             "$pc{lastSession}<>$pc{image}<> $pc{tags} <>$pc{hide}<>".
             "$credit_rest<>$total_maint<>$total_debt<>";

  return %pc;
}

1;