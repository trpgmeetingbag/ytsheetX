use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use List::Util qw/max min/;
use Fcntl;

### サブルーチン-DX ##################################################################################

### ユニットステータス出力 --------------------------------------------------
sub createUnitStatus {
  my %pc = %{$_[0]};
  # ▼ クレジット(所持金)の動的計算
  my $total_income = 0;
  my $total_expense = 0;
  my $history_debt = 0;
  for my $i (0 .. ($pc{historyNum} || 0)) {
    $total_income  += s_eval($pc{"history${i}Income"});
    $total_expense += s_eval($pc{"history${i}Expense"});
    $history_debt  += s_eval($pc{"history${i}Debt"});
  }
  my $manual_debt = s_eval($pc{debt});
  
  my $named_weapon_count = 0;
  my $weapon_custom_cost = 0;
  for my $i (1 .. ($pc{weaponNum} || 0)) {
    $named_weapon_count++ if $pc{"weapon${i}Name"};
    for my $j (1 .. ($pc{"weapon${i}CustomNum"} || 0)) {
      $weapon_custom_cost += s_eval($pc{"weapon${i}Custom${j}Price"});
    }
  }
  my $weapon_base_cost = $named_weapon_count > 1 ? ($named_weapon_count - 1) * 50 : 0;
  
  my $wear_cost = 0;
  for my $i (1 .. ($pc{wearNum} || 0)) {
    $wear_cost += s_eval($pc{"wear${i}Price"});
  }
  
  my $item_cost = 0;
  for my $i (1 .. ($pc{itemNum} || 0)) {
    $item_cost += s_eval($pc{"item${i}Price"});
  }

  $total_income += $manual_debt;
  my $equipment_cost = $weapon_base_cost + $weapon_custom_cost + $wear_cost + $item_cost;
  my $credit_rest = $total_income - ($equipment_cost + $total_expense);
  	$credit_rest = 0 if !defined $credit_rest || $credit_rest eq '';


  # ▼ 永続BSのテキストから数値を抽出して合計する処理
  my $bs_total = 0;
  my $bs_text = $pc{permanentBs} || '';
  $bs_text =~ tr/０-９/0-9/; # 全角数字を半角に変換して計算ミスを防ぐ
  while ($bs_text =~ /([0-9]+)/g) {
    $bs_total += $1;
  }

  # ▼ VTTコマデータ用のステータス配列を構築
  my @unitStatus = (
    # { 'レベル' =>   ($pc{level} || 0) },
    { 'プライド' => ($pc{prideTotal} || 0) .'/'. ($pc{prideMaxTotal} || 0) },
    { 'カルマ' => ($pc{karmaTotal} || 0) . '/'. 10},
    { 'クレジット' => $credit_rest . '/' . $credit_rest },
    { 'BS' => $bs_total . '/' . 0 },
    { 'アドバンテージ' => 0 .'/' . 0},
    { 'リロード' => 0 .'/' . 0},
    { 'バリア' => 0 .'/' . 0 },
    { '荒事屋' => 0 . '/'. 3},
    { 'パトロン' => 0 .'/' . 0},

  );

  
  foreach my $key (split ',', $pc{unitStatusNotOutput}){
    @unitStatus = grep { !exists $_->{$key} } @unitStatus;
  }

  foreach my $num (1..$pc{unitStatusNum}){
    next if !$pc{"unitStatus${num}Label"};
    push(@unitStatus, { $pc{"unitStatus${num}Label"} => $pc{"unitStatus${num}Value"} });
  }

  return \@unitStatus;
}

### バージョンアップデート --------------------------------------------------
sub data_update_chara {
  my %pc = %{$_[0]};
  my $ver = $pc{ver};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  if($ver && $ver < 1.10003){
    $pc{comboCalcOff} = 1;
    foreach my $num (1 .. $pc{comboNum}){
      $pc{"combo${num}Skill"} =~ s/[〈〉<>]//g;
      foreach (1..5) {
        $pc{"combo${num}DiceAdd".$_}  = $pc{"combo${num}Dice".$_};
        $pc{"combo${num}FixedAdd".$_} = $pc{"combo${num}Fixed".$_};
      }
    }
  }
  if($ver < 1.11001){
    $pc{paletteUseBuff} = 1;
  }
  if($ver < 1.12012){
    foreach my $num (1 .. $pc{historyNum}){
      $pc{"history${num}ExpApply".$_} = 1 if $pc{"history${num}Exp".$_};
    }
  }
  if($ver < 1.12015){
    $pc{skillRideNum} = $pc{skillNum};
    $pc{skillArtNum}  = $pc{skillNum};
    $pc{skillKnowNum} = $pc{skillNum};
    $pc{skillInfoNum} = $pc{skillNum};
  }
  if($ver < 1.13002){
    ($pc{characterName},$pc{characterNameRuby}) = split(':', $pc{characterName});
    ($pc{aka},$pc{akaRuby}) = split(':', $pc{aka});
  }
  if($ver < 1.22014){
    foreach ([0,'Body'], [1,'Sense'], [2,'Mind'], [3,'Social']){
      my $base1 = exists $data::syndrome_status{$pc{syndrome1}} ? $data::syndrome_status{$pc{syndrome1}}[@$_[0]] : 0;
      my $base2 = exists $data::syndrome_status{$pc{syndrome2}} ? $data::syndrome_status{$pc{syndrome2}}[@$_[0]] : 0;
      $pc{'sttBase'.@$_[1]} = 0;
      $pc{'sttBase'.@$_[1]} += $base1;
      $pc{'sttBase'.@$_[1]} += $pc{syndrome2} ? $base2 : $base1;
    }
  }
  if($ver < 1.24004){
    $pc{history0Exp} -= 130;
    $pc{expSpent} = $pc{expTotal} - 130;
    $pc{createTypeName} = 'フルスクラッチ';
  }
  if($ver < 1.24009){
    foreach my $stt ([0,'Body'], [1,'Sense'], [2,'Mind'], [3,'Social']){
      if($data::syndrome_status{$pc{syndrome1}}){ $pc{'sttSyn1'.@$stt[1]} = $data::syndrome_status{$pc{syndrome1}}[@$stt[0]] }
      if($data::syndrome_status{$pc{syndrome2}}){ $pc{'sttSyn2'.@$stt[1]} = $data::syndrome_status{$pc{syndrome2}}[@$stt[0]] }
    }
  }
  if($ver < 1.24026){
    if($pc{comboCalcOff}){
      $pc{"combo${_}Manual"} = 1 foreach (1 .. $pc{comboNum});
    }
  }
  $pc{ver} = $main::ver;
  $pc{lasttimever} = $ver;
  return %pc;
}

1;