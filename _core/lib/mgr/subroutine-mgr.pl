use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use List::Util qw/max min/;
use Fcntl;

### サブルーチン-AR ##################################################################################

### ユニットステータス出力 --------------------------------------------------
sub createUnitStatus {
  my %pc = %{$_[0]};
  my $target = $_[1] || '';
  my @unitStatus;


  # ===== エネミー（魔物）用の処理 =====
  if ($pc{type} eq 'm') {
    require $set::data_mons; # 辞書を確実に読み込む
    my $sys_data  = $data::srs_system_mons{$pc{system}} || {};
    my $resources = $sys_data->{resources} || {};
    my @unitMemo;

    # battleNumが取得できない場合の保険として「|| 15」を設定
    for my $i (1 .. ($pc{battleNum} || 15)) {
      my $name  = $pc{"battle${i}Name"};
      my $val   = $pc{"battle${i}Value"};
      next if !$name;

      if ($resources->{$name} == 1) {
        # 1指定: リソースとして現在値/最大値を出力（ココフォリアのバー等になる）
        push(@unitStatus, { $name => "$val/$val" });
      } elsif ($resources->{$name} == 2) {
        # 2指定: ステータスとして現在値のみ出力
        push(@unitStatus, { $name => $val });
      } else {
        # 3指定・未指定: リソースではない重要な戦闘値（VTTに応じてメモ等に退避）
        if ($target eq 'udonarium') {
          push(@unitStatus, { $name => $val });
        } else {
          push(@unitMemo, "$name:$val");
        }
      }
    }

    # SW2.5の思想を踏襲し、非リソース要素をココフォリア等ではメモに結合する
    if (@unitMemo) {
      if ($target eq 'udonarium') {
        push(@unitStatus, {'メモ' => join(" ", @unitMemo)});
      } elsif ($target eq 'ccfolia') {
        push(@unitStatus, {'メモ' => join("\n", @unitMemo)});
      } else {
        push(@unitStatus, {'メモ' => join("<br>", @unitMemo)});
      }
    }
  }
  # ===== キャラクター（PC）用の処理（一切変更なし） =====
  else {
@unitStatus = (
      { '行動値' => $pc{battleTotalKoudou} },
      { 'FP' => ($pc{battleTotalRikiba} || 0) . '/' . ($pc{battleTotalRikiba} || 0) },
      { 'HP' => ($pc{battleTotalTaikyu} || 0) . '/' . ($pc{battleTotalTaikyu} || 0) },
      { 'EN' => ($pc{battleTotalKannou} || 0) . '/' . ($pc{battleTotalKannou} || 0) },
      { 'ブレイク' => '0/1' }
    );

  # ★追加：現在装備している乗機のサイズを取得
  my $mecha_size = '';
  for my $i (1 .. ($pc{armamentsNum} || 0)){
    # 「装備中(Equip)」のチェックが入っており、かつ「部位(Part)」に「乗機」が含まれるものを探す
    if($pc{"armament${i}Equip"} && $pc{"armament${i}Part"} =~ /乗機/){
      $mecha_size = $pc{"defenceAuto${i}Size"};
      last; # 複数装備は想定せず、最初に見つけたものを採用
    }
  }
  
  # サイズが入力されていれば、最大値を持たない文字列パラメータとして出力
  if ($mecha_size ne '') {
    push(@unitStatus, { 'サイズ' => $mecha_size });
  }

  # 弾数のリソース管理（武装ループ）
  for my $i (1 .. ($pc{armamentsNum} || 0)){
    next if !$pc{"armament${i}Name"};
    # 弾数欄に何かが入力されている武器だけを抽出
    if($pc{"armament${i}Danzuu"} ne ''){
      my $danzuu = $pc{"armament${i}Danzuu"};
      # 「武器名(弾数)」という名前でステータスバーに追加
      push(@unitStatus, { $pc{"armament${i}Name"}."(弾数)" => $danzuu . '/' . $danzuu });
    }
  }

  # ★追加：② 特技の弾数リソース管理（特技ループ）
  for my $i (1 .. ($pc{skillsNum} || 0)){
    next if !$pc{"skill${i}Name"};
    my $cost = $pc{"skill${i}Cost"} || '';
    
    # 代償欄から「弾数X/Y」の記述を探し、スラッシュの後ろの「Y（最大値）」を抽出する
    # ※全角のスラッシュ「／」や全角数字「１〜９」で入力された場合にも対応
    if($cost =~ /弾数\s*[0-9０-９]+\s*[\/／]\s*([0-9０-９]+)/){
      my $max_ammo = $1;
      $max_ammo =~ tr/０-９/0-9/; # 全角数字を半角数字に変換
      
      # 武装と同じく「特技名(弾数)」という名前でステータスバーに追加
      push(@unitStatus, { $pc{"skill${i}Name"}."(弾数)" => $max_ammo . '/' . $max_ammo });
    }
  }

  # ゆとシートの標準機能（チェックボックスによる非表示や手動追加項目）も維持
  foreach my $key (split ',', $pc{unitStatusNotOutput}){
    @unitStatus = grep { !exists $_->{$key} } @unitStatus;
  }
}

  foreach my $num (1..$pc{unitStatusNum}){
    next if !$pc{"unitStatus${num}Label"};
    push(@unitStatus, { $pc{"unitStatus${num}Label"} => $pc{"unitStatus${num}Value"} });
  }


  return \@unitStatus;
}

### テキスト整形ルール --------------------------------------------------
## 複数行対応覧
our %multilineTargets = (
  ''  => '「容姿・経歴・その他メモ」「履歴（自由記入）」',
);

### バージョンアップデート --------------------------------------------------
### バージョンアップデート --------------------------------------------------
sub upgradeData {
  my $data = $_[0];
  my $type = $_[1];
  if   ($type eq 'm'){ return upgradeMonsterData($data) }
  else               { return upgradeCharaData($data) }
}
sub upgradeCharaData {
  my %pc = %{$_[0]};
  my $ver = $pc{ver};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  delete $pc{updateMessage};
  
  if($ver < 1.24024){
    if($pc{money} =~ /^(?:自動|auto)$/i){ $pc{moneyAuto} = 1; $pc{money} = commify $pc{moneyTotal}; }
  }
  $pc{ver} = $main::ver;
  $pc{lasttimever} = $ver;
  return %pc;
}
sub upgradeMonsterData {
  my %pc = %{$_[0]};
  my $ver = $pc{ver};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  delete $pc{updateMessage};

  if($ver < 1.26000){
    $pc{partsManualInput} = 1;
  }

  $pc{lasttimever} = $pc{ver};
  $pc{ver} = $main::ver;
  return %pc;
}

1;