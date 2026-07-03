################## データ保存 ##################
use strict;
use utf8;
use open ":utf8";
use LWP::UserAgent;
use JSON::PP;

sub urlDataGet {
  my $url = shift;
  
  my $ua  = LWP::UserAgent->new(
      agent    => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      ssl_opts => { verify_hostname => 0 }
  );
  
  my $res = $ua->get($url);
  if ($res->is_success) {
    return $res->decoded_content;
  }
  else {
    return undef;
  }
}

sub dataConvert {
  my $set_url = shift;
  
  ## キャラクターシート倉庫（MGR）
  if($set_url =~ m|character-sheets\.appspot\.com/mgr/|){
    
    my $ajax_url = $set_url;
    $ajax_url =~ s/edit\.html/display/;
    if($ajax_url !~ /ajax=1/){
      $ajax_url =~ s/\?/\?ajax=1\&/; 
    }
    
    my $data = urlDataGet($ajax_url) or error 'キャラクターシート倉庫との通信に失敗しました。';
    
    if($data !~ /^{/) {
      error 'キャラクターシート倉庫から正しいJSONデータが返ってきませんでした。URLを確認してください。';
    }
    
    my %in = %{ decode_json(encode('utf8', (join '', $data))) };

    return convertSoukoToYtsheet(\%in);
  }
  
  ## ゆとシートⅡからのコンバート（標準装備）
  {
    my $data = urlDataGet($set_url.'&mode=json') or error 'コンバート元のデータが取得できませんでした';
    if($data !~ /^{/){ error 'JSONデータが取得できませんでした' }
    $data = escapeThanSign($data);
    my %pc = utf8::is_utf8($data) ? %{ decode_json(encode('utf8', (join '', $data))) } : %{ decode_json(join '', $data) };
    if($pc{result} eq 'OK'){
      our $base_url = $set_url;
      $base_url =~ s|/[^/]+?$|/|;
      $pc{convertSource} = '別のゆとシートⅡ';
      return %pc;
    }
    elsif($pc{result}) {
      error 'コンバート元のゆとシートⅡでエラーがありました<br>>'.$pc{result};
    }
    else {
      error '有効なデータが取得できませんでした';
    }
  }
}

### キャラクターシート倉庫（MGR）=> ゆとシートⅡ --------------------------------------------------
### キャラクターシート倉庫（MGR）=> ゆとシートⅡ --------------------------------------------------
sub convertSoukoToYtsheet {
  my %in = %{$_[0]};

  # ▼▼ ここから3行をデバッグ用に追加 ▼▼
  # use Data::Dumper;
  # $Data::Dumper::Sortkeys = 1;
  # error "【デバッグ】baseの内容:<br><pre>" . Dumper($in{'base'}) . "</pre>";
  # ▲▲ ここまで ▲▲

  # ▼ 修正：プレイヤー名の処理をハッシュ %pc を定義する「前」に行う
# my $p_name = ref($in{'base'}) eq 'HASH' ? $in{'base'}{'player'} : '';

  my %pc = (
    convertSource => 'キャラクターシート倉庫',

    # --- パーソナルデータ ---
    # player        => $p_name, # 追加
    # playerName    => $p_name,
    playerName => $in{'base'}{'player'},

    characterName => ref($in{'base'}) eq 'HASH' ? $in{'base'}{'name'}   : '',
    age           => ref($in{'base'}) eq 'HASH' ? $in{'base'}{'age'}    : '',
    gender        => ref($in{'base'}) eq 'HASH' ? $in{'base'}{'sex'}    : '',
    cover         => ref($in{'base'}) eq 'HASH' ? $in{'base'}{'cover'}  : '',
    mechaName     => ref($in{'base'}) eq 'HASH' && ref($in{'base'}{'guardian'}) eq 'HASH' ? $in{'base'}{'guardian'}{'name'} : '',
    freeNote      => ref($in{'base'}) eq 'HASH' ? $in{'base'}{'memo'}   : '',
  );

  # --- 初期クラス（能力値ベース用） ---
  if (ref($in{'abl'}) eq 'HASH' && ref($in{'abl'}{'name'}) eq 'HASH') {
    $pc{sttBase1Class} = $in{'abl'}{'name'}{'1st'} || '';
    $pc{sttBase2Class} = $in{'abl'}{'name'}{'2nd'} || '';
    $pc{sttBase3Class} = $in{'abl'}{'name'}{'3rd'} || '';
  }

  # --- ライフパス ---
  if (ref($in{'lifepath'}) eq 'HASH') {
    $pc{lifepathOrigin}         = $in{'lifepath'}{'birth'} || '';
    $pc{lifepathExperience}     = $in{'lifepath'}{'environment'} || '';
    $pc{lifepathEncounter}      = $in{'lifepath'}{'encounter'} || '';
    
    $pc{missionsNum} = 0;
    if (ref($in{'lifepath'}{'quest'}) eq 'ARRAY') {
      my $i = 1;
      foreach my $q (@{$in{'lifepath'}{'quest'}}) {
        next unless ref($q) eq 'HASH';
        $pc{"mission${i}Note"} = $q->{'name'} || '';
        $i++;
      }
      $pc{missionsNum} = $i - 1;
    }
    
    $pc{connectionsNum} = 0;
    if (ref($in{'lifepath'}{'connection'}) eq 'ARRAY') {
      my $i = 1;
      foreach my $c (@{$in{'lifepath'}{'connection'}}) {
        next unless ref($c) eq 'HASH';
        $pc{"connection${i}Relation"} = $c->{'relation'} || '';
        $pc{"connection${i}Name"}     = $c->{'name'} || '';
        $i++;
      }
      $pc{connectionsNum} = $i - 1;
    }
  }

  # --- クラス ---
  $pc{classesNum} = 0;
  if (ref($in{'classes'}) eq 'ARRAY') {
    my $i = 1;
    foreach my $cls (@{$in{'classes'}}) {
      next unless ref($cls) eq 'HASH';
      $pc{"class${i}Name"} = $cls->{'name'} || '';
      $pc{"class${i}Lv"}   = $cls->{'level'} || '';
      $i++;
    }
    $pc{classesNum} = $i - 1;
  }

  # --- 能力値（abl） ---
  my %stt_map = ('strong'=>'Tai', 'reflex'=>'Han', 'sense'=>'Chi', 'intellect'=>'Ri', 'will'=>'Ishi', 'bllesing'=>'Kou');
  if (ref($in{'abl'}) eq 'HASH') {
    foreach my $souko_stt (keys %stt_map) {
      my $yt_stt = $stt_map{$souko_stt};
      if (ref($in{'abl'}{$souko_stt}) eq 'HASH') {
        # ▼その他の修正にボーナスが入ってしまうのを防ぐためコメントアウト
        # my $add = ($in{'abl'}{$souko_stt}{'bonus'} || 0) + ($in{'abl'}{$souko_stt}{'modify'} || 0);
        # $pc{"sttOther$yt_stt"} = $add == 0 ? '' : $add;
        
        $pc{"sttGrow$yt_stt"}  = $in{'abl'}{$souko_stt}{'growth'} || '';
        $pc{"sttOther$yt_stt"}  = $in{'abl'}{$souko_stt}{'modify'} || '';
        
        # ▼割り振り（フリーポイント）のチェックを入れる
# ▼ 明示的なif文でチェックボックスに1を代入
        if ($in{'abl'}{$souko_stt}{'selected'}) {
            $pc{"sttPoint$yt_stt"} = 1;
        } else {
            $pc{"sttPoint$yt_stt"} = '';
        }
        
      }
    }
  }

  # --- 戦闘値のその他の修正（battlemod） ---
  my %battle_map = ('hit'=>'Meichu', 'dodge'=>'Kaihi', 'attack'=>'Hougeki', 'countermagic'=>'Bouheki', 'action'=>'Koudou', 'fp'=>'Rikiba', 'hp'=>'Taikyu', 'magic'=>'Kannou');
  if (ref($in{'battlemod'}) eq 'HASH') {
    foreach my $b_key (keys %battle_map) {
      my $yt_key = $battle_map{$b_key};
      $pc{"battleBaseAdd$yt_key"} = $in{'battlemod'}{$b_key} || '';
    }
  }

  # --- アイテム ---
  $pc{itemsNum} = 0;
  if (ref($in{'items'}) eq 'ARRAY') {
    my $i = 1;
    foreach my $item (@{$in{'items'}}) {
      next unless ref($item) eq 'HASH';
      next if !$item->{'name'}; # 空のデータはスキップ
      $pc{"item${i}Name"}    = $item->{'name'} || '';
      $pc{"item${i}Joubika"} = $item->{'point'} || '';
      $pc{"item${i}Note"}    = $item->{'effect'} || '';
      $i++;
    }
    $pc{itemsNum} = $i - 1;
  }

  # --- 加護 ---
  $pc{kagosNum} = 0;
  if (ref($in{'specials'}) eq 'ARRAY') {
    my $i = 1;
    foreach my $sp (@{$in{'specials'}}) {
      next unless ref($sp) eq 'HASH';
      $pc{"kago${i}Name"} = $sp->{'name'} || '';
      $pc{"kago${i}Note"} = $sp->{'effect'} || '';
      $i++;
    }
    $pc{kagosNum} = $i - 1;
  }

# ▼ 数値のみを抽出するフィルター関数（1(1) → 1、自動取得 → 空欄 に変換）
  my $to_num = sub {
    my $v = shift;
    return '' if !defined $v || $v eq '';
    return $1 if $v =~ /^\s*([+-]?\d+)/;
    return '';
  };

  # --- 特技 ---
  $pc{skillsNum} = 0;

# 特技（skills）の流し込み
  if (ref($in{'skills'}) eq 'ARRAY') {
    my $i = 1;

    # 現在のキャラクターが取得しているクラス名のリストを作成
    my @acquired_classes;
    foreach my $c_i (1 .. $pc{classesNum} || 3) {
      push(@acquired_classes, $pc{"class${c_i}Name"}) if $pc{"class${c_i}Name"};
    }

    # 半角カナ→全角カナ変換用の辞書
    my %kana_map = (
      'ｶﾞ'=>'ガ', 'ｷﾞ'=>'ギ', 'ｸﾞ'=>'グ', 'ｹﾞ'=>'ゲ', 'ｺﾞ'=>'ゴ',
      'ｻﾞ'=>'ザ', 'ｼﾞ'=>'ジ', 'ｽﾞ'=>'ズ', 'ｾﾞ'=>'ゼ', 'ｿﾞ'=>'ゾ',
      'ﾀﾞ'=>'ダ', 'ﾁﾞ'=>'ヂ', 'ﾂﾞ'=>'ヅ', 'ﾃﾞ'=>'デ', 'ﾄﾞ'=>'ド',
      'ﾊﾞ'=>'バ', 'ﾋﾞ'=>'ビ', 'ﾌﾞ'=>'ブ', 'ﾍﾞ'=>'ベ', 'ﾎﾞ'=>'ボ',
      'ﾊﾟ'=>'パ', 'ﾋﾟ'=>'ピ', 'ﾌﾟ'=>'プ', 'ﾍﾟ'=>'ペ', 'ﾎﾟ'=>'ポ',
      'ｳﾞ'=>'ヴ',
      'ｱ'=>'ア', 'ｲ'=>'イ', 'ｳ'=>'ウ', 'ｴ'=>'エ', 'ｵ'=>'オ',
      'ｶ'=>'カ', 'ｷ'=>'キ', 'ｸ'=>'ク', 'ｹ'=>'ケ', 'ｺ'=>'コ',
      'ｻ'=>'サ', 'ｼ'=>'シ', 'ｽ'=>'ス', 'ｾ'=>'セ', 'ｿ'=>'ソ',
      'ﾀ'=>'タ', 'ﾁ'=>'チ', 'ﾂ'=>'ツ', 'ﾃ'=>'テ', 'ﾄ'=>'ト',
      'ﾅ'=>'ナ', 'ﾆ'=>'ニ', 'ﾇ'=>'ヌ', 'ﾈ'=>'ネ', 'ﾉ'=>'ノ',
      'ﾊ'=>'ハ', 'ﾋ'=>'ヒ', 'ﾌ'=>'フ', 'ﾍ'=>'ヘ', 'ﾎ'=>'ホ',
      'ﾏ'=>'マ', 'ﾐ'=>'ミ', 'ﾑ'=>'ム', 'ﾒ'=>'メ', 'ﾓ'=>'モ',
      'ﾔ'=>'ヤ', 'ﾕ'=>'ユ', 'ﾖ'=>'ヨ',
      'ﾗ'=>'ラ', 'ﾘ'=>'リ', 'ﾙ'=>'ル', 'ﾚ'=>'レ', 'ﾛ'=>'ロ',
      'ﾜ'=>'ワ', 'ｦ'=>'ヲ', 'ﾝ'=>'ン',
      'ｧ'=>'ァ', 'ｨ'=>'ィ', 'ｩ'=>'ゥ', 'ｪ'=>'ェ', 'ｫ'=>'ォ',
      'ｯ'=>'ッ', 'ｬ'=>'ャ', 'ｭ'=>'ュ', 'ｮ'=>'ョ',
      'ｰ'=>'ー', '･'=>'・', 'ﾞ'=>'゛', 'ﾟ'=>'゜'
    );
    # 文字数が長いもの（濁点・半濁点付きの2文字）から優先してマッチさせる
    my $kana_keys = join('|', sort { length($b) <=> length($a) } keys %kana_map);

    foreach my $sk (@{$in{'skills'}}) {
      next unless ref($sk) eq 'HASH';
      
      # --------------------------------------------------
      # ① 取得元のコンバート（切り出しと自動マッピング）
      # --------------------------------------------------
      my $raw_class = $sk->{'class'} || '';
      
      # 1. 半角カナを全角に変換
      $raw_class =~ s/($kana_keys)/$kana_map{$1}/g;

      # 2. 有効文字の切り出し（数字やカッコ、特定の記号の前までを残す）
      $raw_class =~ s/[0-9０-９\(\)（）\n].*//;
      $raw_class =~ s/^\s+|\s+$//g; # 前後の空白を削除

      # 3. 取得元（Type）の自動判定
      my $skill_type = '';
      if ($raw_class =~ /^(ガーディアン|ガーディアン特技)$/) {
          $skill_type = 'ガーディアン';
      } elsif ($raw_class =~ /^(汎用|ライフパス)$/) {
          $skill_type = '汎用';
      } else {
          # コンバートされた自身のクラス名リストと照合
          foreach my $c (@acquired_classes) {
              if ($raw_class eq $c) {
                  $skill_type = $c;
                  last;
              }
          }
      }
      
      # 以前のフォールバック処理（type値による判定）も念のため残す
      if (!$skill_type && defined $sk->{'type'}) {
          $skill_type = 'ガーディアン' if $sk->{'type'} eq '0';
          $skill_type = '汎用'         if $sk->{'type'} eq '1';
          $skill_type = 'アシスト'     if $sk->{'type'} eq '2';
      }
      
      $pc{"skill${i}Type"} = $skill_type || $raw_class; # 見つからなければ加工後の文字を入れる

      # --------------------------------------------------
      # ② レベルの改修（全角数字を半角数字に変換してフィルターへ）
      # --------------------------------------------------
      my $lv = $sk->{'level'} || '';
      $lv =~ tr/０-９/0-9/; # 全角を半角に変換
      
      # --------------------------------------------------
      # ③ データの代入（ご提示いただいた変数名に統一）
      # --------------------------------------------------
      $pc{"skill${i}Name"}     = $sk->{'name'} || '';
      $pc{"skill${i}Lv"}       = (ref $to_num eq 'CODE') ? $to_num->($lv) : $lv;
      $pc{"skill${i}Timing"}   = $sk->{'timing'} || '';
      $pc{"skill${i}Target"}   = $sk->{'target'} || '';
      $pc{"skill${i}Range"}    = $sk->{'range'} || '';
      $pc{"skill${i}Cost"}     = $sk->{'cost'} || '';
      $pc{"skill${i}Category"} = $sk->{'type'} || '';
      $pc{"skill${i}Note"}     = $sk->{'memo'} || '';
      
      $i++;
    }
    $pc{skillsNum} = $i - 1;
  }



# --- 装備（武装・防具・解説）と防御修正の分離統合マッピング ---
  my @processed_armaments;
  my %armour_used_idx; # 防御データの紐付け管理用
  my @manual_defences;

  # 部位の並び順と日本語名のマッピング
  my @part_order = (
    ['guardian', '乗機'],
    ['main_weapon_short', '主／近'],
    ['sub_weapon_short', '副／近'],
    ['main_weapon_long', '主／遠'],
    ['sub_weapon_long', '副／遠'],
    ['option', 'OP'],
    ['other', 'その他']
  );

  # 1. outfits（装備実体）を順番通りに収集
  if (ref($in{'outfits'}) eq 'HASH') {
    foreach my $order (@part_order) {
      my ($key, $label) = @$order;
      if (ref($in{'outfits'}{$key}) eq 'ARRAY') {
        foreach my $out (@{$in{'outfits'}{$key}}) {
          next unless ref($out) eq 'HASH';
          my $name = $out->{'name'} || next;

          # この装備に対応する防御データを探す
          my $matched_arm = {};
          if (ref($in{'armours'}) eq 'ARRAY') {
            for (my $j = 0; $j < scalar @{$in{'armours'}}; $j++) {
              my $arm = $in{'armours'}[$j];
              # 名前が一致し、かつ未投入の防御データを使用
              if ($arm->{'name'} eq $name && !$armour_used_idx{$j}) {
                $matched_arm = $arm;
                $armour_used_idx{$j} = 1;
                last;
              }
            }
          }

          push(@processed_armaments, {
            out => $out,
            arm => $matched_arm,
            part => $label
          });
        }
      }
    }
  }

  # 2. 余った防御データを手動防御としてストック
  if (ref($in{'armours'}) eq 'ARRAY') {
    for (my $j = 0; $j < scalar @{$in{'armours'}}; $j++) {
      if (!$armour_used_idx{$j}) {
        push(@manual_defences, $in{'armours'}[$j]);
      }
    }
  }

  # 3. YtSheetの各行に流し込み
  my $arm_i = 1;
  foreach my $item (@processed_armaments) {
    my $out = $item->{out};
    my $arm = $item->{arm};

    $pc{"armament${arm_i}Equip"}   = ($arm->{'selected'} || $out->{'selected'}) ? 1 : 0;
    $pc{"armament${arm_i}Name"}    = $out->{'name'};
    $pc{"armament${arm_i}Part"}    = $item->{part};
    $pc{"armament${arm_i}Meichu"}  = $to_num->($out->{'hit'} || $arm->{'hit'});
    $pc{"armament${arm_i}Kaihi"}   = $to_num->($out->{'dodge'} || $arm->{'dodge'});
    $pc{"armament${arm_i}Hougeki"}  = $to_num->($out->{'magic'} || $arm->{'magic'});
    $pc{"armament${arm_i}Bouheki"}   = $to_num->($out->{'countermagic'} || $arm->{'countermagic'});
    $pc{"armament${arm_i}Kougeki"} = $out->{'attack'} || '';
    $pc{"armament${arm_i}Koudou"}  = $to_num->($out->{'action'} || $arm->{'action'});

    $pc{"armament${arm_i}Rikiba"}  = $to_num->($out->{'fp'} || $arm->{'fp'});
    $pc{"armament${arm_i}Taikyu"}  = $to_num->($out->{'hp'} || $arm->{'hp'});
    $pc{"armament${arm_i}Kannou"}  = $to_num->($out->{'mp'} || $arm->{'mp'});
    $pc{"armament${arm_i}Idou"}  = $to_num->($out->{'speed'} || $arm->{'speed'});

    $pc{"armament${arm_i}Shatei"}  = $out->{'range'} || '';
    $pc{"armament${arm_i}Joubi"}   = $to_num->($out->{'point'} || $arm->{'point'});
    $pc{"armament${arm_i}Daishou"} = $out->{'strong'} || '';
    $pc{"armament${arm_i}Zokusei"} = $out->{'damagetype'} || '';

    # 防御修正（Auto に代入）
    if ($arm->{'slash'} || $arm->{'pierce'} || $arm->{'crash'} || $arm->{'fire'} || $arm->{'ice'} || $arm->{'thunder'} || $arm->{'light'} || $arm->{'dark'}) {
       $pc{"defenceAuto${arm_i}Part"}  = $item->{part};
       $pc{"defenceAuto${arm_i}Name"}  = $out->{'name'};
       $pc{"defenceAuto${arm_i}Zan"}   = $to_num->($arm->{'slash'});
       $pc{"defenceAuto${arm_i}Totsu"} = $to_num->($arm->{'pierce'});
       $pc{"defenceAuto${arm_i}Ou"}    = $to_num->($arm->{'crash'});
       $pc{"defenceAuto${arm_i}En"}    = $to_num->($arm->{'fire'});
       $pc{"defenceAuto${arm_i}Hyou"}  = $to_num->($arm->{'ice'});
       $pc{"defenceAuto${arm_i}Rai"}   = $to_num->($arm->{'thunder'});
       $pc{"defenceAuto${arm_i}Kou"}   = $to_num->($arm->{'light'});
       $pc{"defenceAuto${arm_i}Yami"}  = $to_num->($arm->{'dark'});
    }

    my $memo = $out->{'memo'} || $arm->{'memo'} || '';
    if ($memo) {
       $pc{"armamentNoteAuto${arm_i}Name"} = $out->{'name'};
       $pc{"armamentNoteAuto${arm_i}Note"} = $memo;
    }

    $arm_i++;
  }
  
  # 4. YtSheetの「追加の防御修正（defence）」行に流し込む（合致しなかったもの）
  my $def_i = 1;
  foreach my $arm (@manual_defences) {
       $pc{"defence${def_i}Part"}  = $arm->{'part'} || '';
       $pc{"defence${def_i}Name"}  = $arm->{'name'} || '';
       $pc{"defence${def_i}Zan"}   = $to_num->($arm->{'slash'});
       $pc{"defence${def_i}Totsu"} = $to_num->($arm->{'pierce'});
       $pc{"defence${def_i}Ou"}    = $to_num->($arm->{'crash'});
       $pc{"defence${def_i}En"}    = $to_num->($arm->{'fire'});
       $pc{"defence${def_i}Hyou"}  = $to_num->($arm->{'ice'});
       $pc{"defence${def_i}Rai"}   = $to_num->($arm->{'thunder'});
       $pc{"defence${def_i}Kou"}   = $to_num->($arm->{'light'});
       $pc{"defence${def_i}Yami"}  = $to_num->($arm->{'dark'});
       $def_i++;
  }

  $pc{armamentsNum} = $arm_i - 1;
  $pc{defencesNum}  = $def_i - 1;

  $pc{history0Exp}    = ref($in{'base'}) eq 'HASH' ? $in{'base'}{'exp'} : 0;
  $pc{historyNum}     = 0;
  $pc{joubikaExpUsed}    = ref($in{'itemstotal'}) eq 'HASH' ? $in{'itemstotal'}{'exp'} : 0;

  $pc{ver} = 0;
  return %pc;
}

1;