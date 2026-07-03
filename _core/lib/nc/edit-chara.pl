############# フォーム・キャラクター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'say';
use File::Basename;

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
require $set::lib_palette_sub;
### 各種データライブラリ読み込み --------------------------------------------------
require $set::data_class;

### データ読み込み ###################################################################################
my ($data, $mode, $file, $message) = getSheetData($::in{mode});
our %pc = %{ $data };

my $mode_make = ($mode =~ /^(blanksheet|copy|convert)$/) ? 1 : 0;

### 出力準備 #########################################################################################
if($message){
  my $name = unescapeTags($pc{characterName} || $pc{aka} || '無題');
  $message =~ s/<!NAME>/$name/;
}
### プレイヤー名 --------------------------------------------------
if($mode_make){
  $pc{playerName} = (getplayername($LOGIN_ID))[0];
}
### 初期設定 --------------------------------------------------
if($mode_make){ $pc{protect} ||= $LOGIN_ID ? 'account' : 'password'; }

if($mode eq 'edit' || ($mode eq 'convert' && $pc{ver})){
  %pc = data_update_chara(\%pc);
  if($pc{updateMessage}){
    $message .= "<hr>" if $message;
    $message .= "<h2>アップデート通知</h2><dl>";
    foreach (sort keys %{$pc{updateMessage}}){
      $message .= '<dt>'.$_.'</dt><dd>'.$pc{updateMessage}{$_}.'</dd>';
    }
    (my $lasttimever = $pc{lasttimever}) =~ s/([0-9]{3})$/\.$1/;
    $message .= "</dl><small>前回保存時のバージョン:$lasttimever</small>";
  }
}
elsif($mode eq 'blanksheet'){
  $pc{group} = $set::group_default;
  $pc{history0Exp} = 0;
  $pc{paletteUseBuff} = 1;
  $pc{viewDamage} = 'gray';

  # ▼▼▼ 新規作成時の初期デフォルト値 ▼▼▼
  
  # カルマの初期値
  $pc{karmaNum}  = 1;
  $pc{karma1Name} = '記憶のカケラを獲得する';
  
  # 未練の初期値
  $pc{mirenNum}  = 3;
  $pc{miren1Name} = 'たからもの';
  $pc{miren1Note} = '【依存】';
  $pc{miren1Burst} = '幼児退行（最大行動値－２）';
  $pc{miren1Insanity} = 3;
  $pc{miren2Insanity} = 3;
  
  # スキルと初期パーツ（1〜4をスキル用の空枠とし、5〜16に基本パーツを割り当てる）
  $pc{skillNum} = 16;
  
  $pc{"skill${_}Position"} = 'skill' foreach (1..4); # スキル用空枠
  
  $pc{skill5Position} = 'head'; $pc{skill5Name} = 'のうみそ'; $pc{skill5Source} = '基本パーツ';
  $pc{skill5Lv} = '0';
  $pc{skill5Timing} = 'オート';
  $pc{skill5Cost} = 'なし';
  $pc{skill5Range} = '自身';
  $pc{skill5Initiative} = '2';
  $pc{skill5Note} = '最大行動値＋２。';

  $pc{skill6Position} = 'head'; $pc{skill6Name} = 'めだま';   $pc{skill6Source} = '基本パーツ';
  $pc{skill6Lv} = '0';
  $pc{skill6Timing} = 'オート';
  $pc{skill6Cost} = 'なし';
  $pc{skill6Range} = '自身';
  $pc{skill6Initiative} = '1';
  $pc{skill6Note} = '最大行動値＋１。';

  $pc{skill7Position} = 'head'; $pc{skill7Name} = 'あご';     $pc{skill7Source} = '基本パーツ';
  $pc{skill7Lv} = '0';
  $pc{skill7Timing} = 'アクション';
  $pc{skill7Cost} = '2';
  $pc{skill7Range} = '0';
  $pc{skill7Initiative} = '0';
  $pc{skill7Note} = '肉弾攻撃１。';
  
  $pc{skill8Position} = 'arms'; $pc{skill8Name} = 'こぶし';   $pc{skill8Source} = '基本パーツ';
  $pc{skill8Lv} = '0';
  $pc{skill8Timing} = 'アクション';
  $pc{skill8Cost} = '2';
  $pc{skill8Range} = '0';
  $pc{skill8Initiative} = '0';
  $pc{skill8Note} = '肉弾攻撃１。';

  $pc{skill9Position} = 'arms'; $pc{skill9Name} = 'うで';     $pc{skill9Source} = '基本パーツ';
  $pc{skill9Lv} = '0';
  $pc{skill9Timing} = 'ジャッジ';
  $pc{skill9Cost} = '1';
  $pc{skill9Range} = '0';
  $pc{skill9Initiative} = '0';
  $pc{skill9Note} = '支援１。';

  $pc{skill10Position}= 'arms'; $pc{skill10Name}= 'かた';     $pc{skill10Source} = '基本パーツ';
  $pc{skill10Lv} = '0';
  $pc{skill10Timing} = 'アクション';
  $pc{skill10Cost} = '4';
  $pc{skill10Range} = '自身';
  $pc{skill10Initiative} = '0';
  $pc{skill10Note} = '移動１。';
  
  $pc{skill11Position}= 'torso'; $pc{skill11Name} = 'せぼね';   $pc{skill11Source} = '基本パーツ';
  $pc{skill11Lv} = '0';
  $pc{skill11Timing} = 'アクション';
  $pc{skill11Cost} = '1';
  $pc{skill11Range} = '自身';
  $pc{skill11Initiative} = '0';
  $pc{skill11Note} = '同ターン内の次カウントで使うマニューバ１つのコスト－１（最低０）。';
  
  $pc{skill12Position}= 'torso'; $pc{skill12Name} = 'はらわた'; $pc{skill12Source} = '基本パーツ';
  $pc{skill12Lv} = '0';
  $pc{skill12Timing} = 'オート';
  $pc{skill12Cost} = 'なし';
  $pc{skill12Range} = 'なし';
  $pc{skill12Initiative} = '0';
  $pc{skill12Note} = 'なし。';

  $pc{skill13Position}= 'torso'; $pc{skill13Name} = 'はらわた'; $pc{skill13Source} = '基本パーツ';
  $pc{skill13Lv} = '0';
  $pc{skill13Timing} = 'オート';
  $pc{skill13Cost} = 'なし';
  $pc{skill13Range} = 'なし';
  $pc{skill13Initiative} = '0';
  $pc{skill13Note} = 'なし。';
  
  $pc{skill14Position}= 'legs'; $pc{skill14Name} = 'ほね';     $pc{skill14Source} = '基本パーツ';
  $pc{skill14Lv} = '0';
  $pc{skill14Timing} = 'アクション';
  $pc{skill14Cost} = '3';
  $pc{skill14Range} = '自身';
  $pc{skill14Initiative} = '0';
  $pc{skill14Note} = '移動１。';

  $pc{skill15Position}= 'legs'; $pc{skill15Name} = 'ほね';     $pc{skill15Source} = '基本パーツ';
  $pc{skill15Lv} = '0';
  $pc{skill15Timing} = 'アクション';
  $pc{skill15Cost} = '3';
  $pc{skill15Range} = '自身';
  $pc{skill15Initiative} = '0';
  $pc{skill15Note} = '移動１。';

  $pc{skill16Position}= 'legs'; $pc{skill16Name} = 'あし';     $pc{skill16Source} = '基本パーツ';
  $pc{skill16Lv} = '0';
  $pc{skill16Timing} = 'ジャッジ';
  $pc{skill16Cost} = '1';
  $pc{skill16Range} = '0';
  $pc{skill16Initiative} = '0';
  $pc{skill16Note} = '妨害１。';

  %pc = applyCustomizedInitialValues(\%pc);
}

## 画像
$pc{imageFit} = $pc{imageFit} eq 'percent' ? 'percentX' : $pc{imageFit};
$pc{imagePercent}   //= '200';
$pc{imagePositionX} //= '50';
$pc{imagePositionY} //= '50';
$pc{wordsX} ||= '右';
$pc{wordsY} ||= '上';

## カラー
setDefaultColors();

## その他
$pc{createType} ||= 'F';

## ネクロニカ用初期設定
$pc{memoryNum} ||= 3;
$pc{mirenNum}  ||= 3;


$pc{historyNum} ||= 3;


### セレクトボックスの生成関数 --------------------------------------------------
sub optionMiren {
  my $name = shift;
  my $val = $pc{$name} || '';
  my $text = '<option value="">';
  my $is_selected = 0;
  my %seen;
  
  foreach my $arr (@data::NCmiren) {
    my $m_name = $arr->[0];
    my $m_burst = $arr->[1] || '';
    next if !$m_name;

    if ($m_name =~ /^●/) {
      $text .= '<option disabled value="">―― '.$m_name.' ――';
    } else {
      my $display_name = $m_name;
      # JS側のキーと一致させるため、同じ重複回避ルールを適用
      while ($seen{$m_name}) { $m_name .= "\x{200b}"; }
      $seen{$m_name} = 1;

      # 初期値の一致判定
      my $selected = (!$is_selected && $val eq $m_name) ? ' selected' : '';
      if($selected) { $is_selected = 1; }
      
      $text .= '<option value="'.$m_name.'"'.$selected.'>'.$display_name;
    }
  }
  $text .= '<option value="free"'.($val eq 'free' && !$is_selected ? ' selected' : '').'>その他（自由記入）';
  return $text;
}
sub optionPosition {
  my $name = shift;
  my $text = '<option value="">';
  foreach my $i (@data::NCposition){
    $text .= '<option value="'.$i.'"'.($pc{$name} eq $i ? ' selected' : '').'>'.$i;
  }
  $text .= '<option value="free"'.($pc{$name} eq 'free' ? ' selected' : '').'>その他（自由記入）';
  return $text;
}
sub optionClass {
  my $name = shift;
  my $text = '<option value="">';
  foreach my $i (@data::NCclass){
    $text .= '<option value="'.$i.'"'.($pc{$name} eq $i ? ' selected' : '').'>'.$i;
  }
  $text .= '<option value="free"'.($pc{$name} eq 'free' ? ' selected' : '').'>その他（自由記入）';
  return $text;
}

sub optionCategory {
  my $name = shift;
  my $val = $pc{$name} || '';
  my $text = '<option value="">';
  foreach my $i ('通常技','必殺技','行動値増加','補助','妨害','防御／生贄','移動'){
    $text .= '<option value="'.$i.'"'.($val eq $i ? ' selected' : '').'>'.$i;
  }
  $text .= '<option value="free"'.($val eq 'free' ? ' selected' : '').'>その他（自由記入）';
  return $text;
}

### 折り畳み判断 --------------------------------------------------
my %open;
foreach (1..$pc{mirenNum}){ if(existsRowStrict "miren$_"  ,'Name','Note'){ $open{miren} = 'open'; last; } }
foreach (1..$pc{memoryNum}){ if(existsRowStrict "memory$_",'Name','Note'){ $open{memory} = 'open'; last; } }
foreach (1..$pc{karmaNum}){ if(existsRowStrict "karma$_",'Name'){ $open{karma} = 'open'; last; } }

# スキルとパーツの開閉判断
foreach (1..$pc{skillNum}){ 
  if(existsRowStrict "skill$_",'Name','Timing' ){ 
    my $pos = $pc{"skill${_}Position"} || 'skill';
    if($pos eq 'skill'){ $open{skill} = 'open'; }
    else               { $open{"part_$pos"} = 'open'; }
  } 
}

### 改行処理 --------------------------------------------------
$pc{words}         =~ s/&lt;br&gt;/\n/g;
$pc{freeNote}      =~ s/&lt;br&gt;/\n/g;
$pc{freeHistory}   =~ s/&lt;br&gt;/\n/g;
$pc{chatPalette}   =~ s/&lt;br&gt;/\n/g;
$pc{"skill${_}Note"}   =~ s/&lt;br&gt;/\n/g foreach (1 .. $pc{skillNum});

### フォーム表示 #####################################################################################
my $titlebarname = removeTags removeRuby unescapeTags ($pc{characterName}||"“$pc{aka}”");
print <<"HTML";
Content-type: text/html\n
<!DOCTYPE html>
<html lang="ja">

<head>
  <meta charset="UTF-8">
  <title>@{[$mode eq 'edit'?"編集：$titlebarname" : '新規作成']} - $set::title</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/base.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/sheet.css?${main::ver}">
  
  <--<link rel="stylesheet" media="all" href="${main::core_dir}/skin/nc/css/chara.css?${main::ver}">  
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/nc/css/edit.css?${main::ver}">

  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/skin/_common/js/lib/compressor.min.js"></script>
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  <!-- ネクロニカ用JS -->
  <script src="${main::core_dir}/lib/nc/edit-chara.js?${main::ver}" defer></script>

</head>
<body>
  <script src="${main::core_dir}/skin/_common/js/common.js?${main::ver}"></script>
  <header>
    <h1>$set::title</h1>
  </header>

  <main>
    <article>
      <form name="sheet" method="post" action="./" enctype="multipart/form-data">
      <input type="hidden" name="ver" value="${main::ver}">
HTML
if($mode_make){
  print '<input type="hidden" name="_token" value="'.tokenMake().'">'."\n";
}
print <<"HTML";
      <input type="hidden" name="mode" value="@{[ $mode eq 'edit' ? 'save' : 'make' ]}">
      
      <div id="header-menu">
        <h2><span></span></h2>
        <ul>
          <li onclick="sectionSelect('common');"><span>キャラ<span class="shorten">クター</span></span><span>データ</span>
          <li onclick="sectionSelect('palette');"><span><span class="shorten">ユニット(</span>コマ<span class="shorten">)</span></span><span>設定</span>
          <li onclick="sectionSelect('color');" class="color-icon" title="カラーカスタム">
          <li onclick="view('text-rule')" class="help-icon" title="テキスト整形ルール">
          <li onclick="nightModeChange()" class="nightmode-icon" title="ナイトモード切替">
          <li onclick="exportAsJson()" class="download-icon" title="JSON出力">
          <li class="buttons">
            <ul>
              <li @{[ display ($mode eq 'edit') ]} class="view-icon" title="閲覧画面"><a href="./?id=$::in{id}"></a>
              <li @{[ display ($mode eq 'edit') ]} class="copy" onclick="window.open('./?mode=copy&id=$::in{id}@{[  $::in{log}?"&log=$::in{log}":'' ]}');">複製
              <li class="submit" onclick="formSubmit()" title="Ctrl+S">保存
            </ul>
          </li>
        </ul>
        <div id="save-state"></div>
      </div>
      
      <aside class="message">$message</aside>

      <section id="section-common">
HTML
if($set::user_reqd){
  print <<"HTML";
    <input type="hidden" name="protect" value="account">
    <input type="hidden" name="protectOld" value="$pc{protect}">
    <input type="hidden" name="pass" value="$::in{pass}">
HTML
}
else {
  if($set::registerkey && $mode_make){
    print '登録キー：<input type="text" name="registerkey" required>'."\n";
  }
  print <<"HTML";
      <details class="box" id="edit-protect" @{[$mode eq 'edit' ? '':'open']}>
      <summary>編集保護設定</summary>
      <fieldset id="edit-protect-view"><input type="hidden" name="protectOld" value="$pc{protect}">
HTML
  if($LOGIN_ID){
    print '<input type="radio" name="protect" value="account"'.($pc{protect} eq 'account'?' checked':'').'> アカウントに紐付ける（ログイン中のみ編集可能になります）<br>';
  }
    print '<input type="radio" name="protect" value="password"'.($pc{protect} eq 'password'?' checked':'').'> パスワードで保護 ';
  if ($mode eq 'edit' && $pc{protect} eq 'password' && $::in{pass}) {
    print '<input type="hidden" name="pass" value="'.$::in{pass}.'"><br>';
  } else {
    print '<input type="password" name="pass"><br>';
  }
  print <<"HTML";
<input type="radio" name="protect" value="none"@{[ $pc{protect} eq 'none'?' checked':'' ]}> 保護しない（誰でも編集できるようになります）
      </fieldset>
      </details>
HTML
}
  print <<"HTML";
      <dl class="box" id="hide-options">
        <dt>閲覧可否設定
        <dd id="forbidden-checkbox">
          <select name="forbidden">
            <option value="">内容を全て開示
            <option value="battle" @{[ $pc{forbidden} eq 'battle' ? 'selected' : '' ]}>データ・数値のみ秘匿
            <option value="all"    @{[ $pc{forbidden} eq 'all'    ? 'selected' : '' ]}>内容を全て秘匿
          </select>
        <dd id="hide-checkbox">
          <select name="hide">
            <option value="">一覧に表示
            <option value="1" @{[ $pc{hide} ? 'selected' : '' ]}>一覧には非表示
          </select>
        <dd>※「一覧に非表示」でもタグ検索結果・マイリストには表示されます
      </dl>
      <div class="box" id="group">
        <dl>
          <dt>グループ
          <dd><select name="group">
HTML
foreach (@set::groups){
  my $id   = @$_[0];
  my $name = @$_[2];
  my $exclusive = @$_[4];
  next if($exclusive && (!$LOGIN_ID || $LOGIN_ID !~ /^($exclusive)$/));
  print '<option value="'.$id.'"'.($pc{group} eq $id ? ' selected': '').'>'.$name.'</option>';
}
print <<"HTML";
          </select>
          <dt>タグ
          <dd>@{[ input 'tags','','','' ]}
        </dl>
      </div>
      
      <div class="box in-toc" id="name-form" data-content-title="キャラクター名・プレイヤー名">
        <div>
          <dl id="character-name">
            <dt>キャラクター名
            <dd>@{[input('characterName','text',"setName")]}
            <dt class="ruby">ふりがな
            <dd>@{[input('characterNameRuby','text',"setName")]}
          </dl>
            <dl id="aka">
            <dt>二つ名・異名など
            <dd>@{[input('aka','text',"setName")]}
            <dt class="ruby">フリガナ
            <dd>@{[input('akaRuby','text',"setName")]}
          </dl>
        </div>
        <dl id="player-name">
          <dt>プレイヤー名
          <dd>@{[input('playerName')]}
        </dl>
      </div>

      <details class="box" id="regulation" @{[$mode eq 'edit' ? '':'open']}>
        <summary class="in-toc">作成レギュレーション</summary>
        <dl>
          <dt>初期保有寵愛点
          <dd>@{[input("history0Exp",'number','changeRegu')]}
          <dt>備考
          <dd>@{[ input "history0Note" ]}
        </dl>
      </details>

      <div id="area-status">
        @{[ imageForm($pc{imageURL}) ]}

        <div class="box-union" id="personal">
          <dl class="box"><dt>享年<dd>@{[input "age"]}</dl>
          <dl class="box"><dt>身長<dd>@{[input "height"]}</dl>
          <dl class="box"><dt>体重<dd>@{[input "weight"]}</dl>
        </div>
        <div class="box-union" id="personal-bottom">
          <dl class="box"><dt>暗示<dd>@{[input "anji", 'text', '', 'list="list-anji"']}</dl>
          ※暗示は【】の右にテキストを入力したかどうかで表示結果が変化します。
        </div>

        <div class="box" id="class-status">
          <h2 class="in-toc" data-content-title="クラス／強化値">クラス／強化値 [<span id="exp-status">0</span>]</h2>
          <table class="edit-table">
            <thead>
              <tr>
                <th colspan="3">
                <th>武装
                <th>変異
                <th>改造
              </tr>
            </thead>
            <tbody>
              <tr>
                <th>ポジション
                <td>
                  <select name="position" onchange="changeClass()">@{[ optionPosition('position') ]}</select>
                  @{[ input 'positionFree', 'text', '', 'class="free-input" placeholder="自由記入" style="display:none;"' ]}
                <td colspan="4">
              </tr>
              <tr>
                <th>メインクラス
                <td>
                  <select name="mainClass" onchange="changeClass()">@{[ optionClass('mainClass') ]}</select>
                  @{[ input 'mainClassFree', 'text', '', 'class="free-input" placeholder="自由記入" style="display:none;"' ]}
                <td colspan="1">　
                <td>@{[ input "mainBuso" , 'number', 'calcStt' ]}
                <td>@{[ input "mainHenI" , 'number', 'calcStt' ]}
                <td>@{[ input "mainKaizo", 'number', 'calcStt' ]}
              </tr>
              <tr>
                <th>サブクラス
                <td>
                  <select name="subClass" onchange="changeClass()">@{[ optionClass('subClass') ]}</select>
                  @{[ input 'subClassFree', 'text', '', 'class="free-input" placeholder="自由記入" style="display:none;"' ]}
                <td colspan="1">　
                <td>@{[ input "subBuso" , 'number', 'calcStt' ]}
                <td>@{[ input "subHenI" , 'number', 'calcStt' ]}
                <td>@{[ input "subKaizo", 'number', 'calcStt' ]}
              </tr>
              <tr>
                <th colspan="3" class="right">作成ボーナス
                <td>@{[ radio 'sttPre', 'deselectable,calcStt', 'buso' , '+1' ]}
                <td>@{[ radio 'sttPre', 'deselectable,calcStt', 'heni' , '+1' ]}
                <td>@{[ radio 'sttPre', 'deselectable,calcStt', 'kaizo', '+1' ]}
              </tr>
              <tr>
                <th colspan="3" class="right">成長
                <td>@{[input "growBuso" , 'number', 'calcStt']}
                <td>@{[input "growHenI" , 'number', 'calcStt']}
                <td>@{[input "growKaizo", 'number', 'calcStt']}
              </tr>
              <tr>
                <th colspan="3" class="right">その他の修正
                <td>@{[input "addBuso" , 'number', 'calcStt']}
                <td>@{[input "addHenI" , 'number', 'calcStt']}
                <td>@{[input "addKaizo", 'number', 'calcStt']}
              </tr>
              <tr>
                <th colspan="3" class="right">合計
                <td id="stt-total-buso" >0</td>
                <td id="stt-total-heni" >0</td>
                <td id="stt-total-kaizo" >0</td>
              </tr>
            </tbody>
          </table>
        </div>

        <details class="box" id="karma" $open{karma}>
          <summary class="in-toc" data-content-title="カルマ">カルマ</summary>
          @{[input 'karmaNum','hidden']}
          <table class="edit-table line-tbody no-border-cells" id="karma-table">
            <thead>
              <tr>
                <th>
                <th>達成
                <th>内容
              </tr>
            </thead>
HTML
foreach my $num ('TMPL',1 .. $pc{karmaNum}) {
  if($num eq 'TMPL'){ print '<template id="karma-template">' }
print <<"HTML";
            <tbody id="karma-row${num}">
              <tr>
                <td class="handle">
                <td>@{[input "karma${num}Check",'checkbox']}
                <td>@{[input "karma${num}Name"]}
              </tr>
            </tbody>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
          </table>
          <div class="add-del-button"><a onclick="addKarma()">▼</a><a onclick="delKarma()">▲</a></div>
        </details>
      </div>

      <details class="box" id="memory" $open{memory}>
        <summary class="in-toc" data-content-title="記憶のカケラ">記憶のカケラ</summary>
        @{[input 'memoryNum','hidden']}
        <div>
          <table class="edit-table no-border-cells" id="memory-table">
            <thead>
              <tr>
                <th>
                <th>タイトル
                <th>記憶の内容
              </tr>
            <tbody>
HTML
foreach my $num ('TMPL', 1 .. $pc{memoryNum}) {
  if($num eq 'TMPL'){ print '<template id="memory-template">' }
print <<"HTML";
            <tr id="memory${num}">
              <td class="handle">
              <td>@{[input "memory${num}Name"]}
              <td>@{[input "memory${num}Note", 'text', '', 'style="width:100%"']}
            </tr>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
            </tbody>
          </table>
        </div>
        <div class="add-del-button"><a onclick="addMemory()">▼</a><a onclick="delMemory()">▲</a></div>
      </details>
      
      <details class="box" id="miren" $open{miren} style="position:relative">
        <summary class="in-toc" data-content-title="未練">未練</summary>
        @{[input 'mirenNum','hidden']}
        <div>
          <table class="edit-table no-border-cells" id="miren-table">
            <colgroup>
              <col class="handle">
              <col>
              <col class="miren-to">
              <col>
              <col>
              <col>
            </colgroup>
            <thead>
              <tr>
                <th>
                <th>未練の対象
                <th colspan="2">未練の内容
                <th>狂気点
                <th>発狂内容
              </tr>
            <tbody>
HTML
foreach my $num ('TMPL', 1 .. $pc{mirenNum}) {
  if($num eq 'TMPL'){ print '<template id="miren-template">' }
print <<"HTML";
              <tr id="miren${num}">
                <td class="handle">
                <td>@{[input "miren${num}Name"]}
                <td class="miren-to">への
                <td>
                  <select name="miren${num}Note" onchange="changeMirenNote(this)">
                    @{[ optionMiren("miren${num}Note") ]}
                  </select>
                  @{[input "miren${num}NoteFree", 'text', '', 'class="free-input" placeholder="自由記入" style="display:none;"']}
                <td>
                  <div class="insanity-gauge" data-target="miren${num}Insanity">
                    <span class="dot reset" onclick="setInsanity(this, 0)">◎</span>
                    <span class="dot" onclick="setInsanity(this, 1)">①</span>
                    <span class="dot" onclick="setInsanity(this, 2)">②</span>
                    <span class="dot" onclick="setInsanity(this, 3)">③</span>
                    <span class="dot" onclick="setInsanity(this, 4)">④</span>
                  </div>
                  @{[input "miren${num}Insanity", 'hidden']}
                <td>@{[input "miren${num}Burst"]}
              </tr>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
            </tbody>
          </table>
        </div>
        <div class="add-del-button"><a onclick="addMiren()">▼</a><a onclick="delMiren()">▲</a></div>
      </details>

HTML

### スキル・パーツのHTML生成処理
my %skills_html = (
  'skill' => '',
  'head'  => '',
  'arms'  => '',
  'torso' => '',
  'legs'  => '',
);

foreach my $num ('TMPL',1 .. $pc{skillNum}) {
  my $pos = $pc{"skill${num}Position"} || 'skill';
  if($num eq 'TMPL'){ $pos = 'skill'; } # テンプレートは便宜上skill枠に出力

  my $row_html = <<"HTML";
            <tbody id="skill-row${num}">
              <tr>
                <td rowspan="2" class="handle"> 
                <td>
                  <span class="damage-checkbox">@{[input "skill${num}Damage", 'checkbox', 'calcSubStt']}</span>
                <td>
                  @{[input "skill${num}Name",'','','placeholder="名称"']}
                  @{[input "skill${num}Position",'hidden']}
                <td>@{[input "skill${num}Timing",'','','placeholder="タイミング" list="list-timing"']}
                <td>@{[input "skill${num}Cost",'','','placeholder="コスト" list="list-cost"']}
                <td>@{[input "skill${num}Range",'','','placeholder="射程" list="list-range"']}
                <td>@{[input "skill${num}Initiative",'number','calcSubStt','placeholder="行動値"']}
                <td>
                  <select name="skill${num}Category" onchange="calcSkillCategory()">
                    @{[ optionCategory("skill${num}Category") ]}
                  </select>
                  @{[input "skill${num}CategoryFree", 'text', '', 'class="free-input" placeholder="自由記入" style="display:none;" oninput="calcSkillCategory()"']}
                <td>
                  <span class="part-level-input">@{[input "skill${num}Lv",'number','calcSubStt','min="1" placeholder="Lv"']}</span>
              </tr>
              <tr>
                <td colspan="8">
                  <div>
                    <label>@{[input "skill${num}CalcOff", 'checkbox', 'calcSubStt']} 計算に含まない</label>
                    <b>取得先</b>
                    <select name="skill${num}Source" onchange="changeSkillSource(this)">
                      <option value="$pc{"skill${num}Source"}">$pc{"skill${num}Source"}</option>
                    </select>
                    @{[input "skill${num}SourceFree", 'text', '', 'class="free-input" placeholder="自由記入" style="display:none;" oninput="calcSubStt()"']}
                    <b>効果</b> @{[input "skill${num}Note", 'text', '', 'style="width: 50%"']}
                  </div>
                </td>
              </tr>
            </tbody>
HTML

  if ($num eq 'TMPL') {
    $skills_html{'skill'} .= "<template id=\"skill-template\">\n" . $row_html . "</template>\n";
  } else {
    $skills_html{$pos} .= $row_html;
  }
}

print <<"HTML";
      <!-- スキル枠 -->
      <details class="box" id="skill" $open{skill}>
        <summary class="in-toc" data-content-title="スキル">スキル [<span id="exp-skill">0</span>]</summary>
        <div class="skill-area">
          <table class="edit-table line-tbody no-border-cells" id="skill-table" data-position="skill">
            <thead id="skill-head">
              <tr>
                <th><th><span class="damage-checkbox">損傷</span><th>名称<th>タイミング(T)<th>コスト(C)<th>射程(R)<th>上昇行動値<th>カテゴリ<th><span class="part-level-input">パーツLv</span>
              </tr>
            </thead>
            $skills_html{'skill'}
          </table>
        </div>
        <div class="add-del-button"><a onclick="addManeuver('skill')">▼</a><a onclick="delManeuver('skill')">▲</a></div>
        @{[input 'skillNum','hidden']}
      </details>
      <div class="box trash-box" id="skill-trash">
        <h2><span class="material-symbols-outlined">delete</span><span class="shorten">削除スキル・パーツ</span></h2>
        <table class="edit-table line-tbody" id="skill-trash-table"></table>
        <i class="material-symbols-outlined close-button" onclick="document.getElementById('skill-trash').style.display = 'none';">close</i>
      </div>

        <div id="sub-status">
          <dl class="box" id="status-max-action">
            <dt>最大行動値</dt>
            <dd>6 + <span id="skill-initiative-total">0</span> = <b id="initiative-total">6</b>
          </dl>


          <div id="status-action-breakdown"></div>
          <div id="status-spacer"></div>

          <dl class="box" id="status-initial-position">
            <dt>初期配置</dt>
            <dd>
              <select name="placement" onchange="changePlacement()">
            <option value="">
            <option value="煉獄" @{[ $pc{placement} eq '煉獄' ? 'selected' : '' ]}>煉獄
            <option value="花園" @{[ $pc{placement} eq '花園' ? 'selected' : '' ]}>花園
            <option value="楽園" @{[ $pc{placement} eq '楽園' ? 'selected' : '' ]}>楽園
            <option value="free" @{[ $pc{placement} eq 'free' ? 'selected' : '' ]}>その他(自由記入)
          </select>
          @{[ input 'placementFree', 'text', '', 'class="free-input" placeholder="自由記入" style="display:none; width: auto;"' ]}

            </dd>
          </dl>
        </div>
      
      <!--<dl class="box" id="max-initiative">
        <dt>最大行動値
        <dd>6 + <span id="skill-initiative-total">0</span> = <b id="initiative-total">6</b>
      </dl>
      
      <dl class="box" id="placement">
        <dt>初期配置
        <dd>
          <select name="placement" onchange="changePlacement()">
            <option value="">
            <option value="煉獄" @{[ $pc{placement} eq '煉獄' ? 'selected' : '' ]}>煉獄
            <option value="花園" @{[ $pc{placement} eq '花園' ? 'selected' : '' ]}>花園
            <option value="楽園" @{[ $pc{placement} eq '楽園' ? 'selected' : '' ]}>楽園
            <option value="free" @{[ $pc{placement} eq 'free' ? 'selected' : '' ]}>その他(自由記入)
          </select>
          @{[ input 'placementFree', 'text', '', 'class="free-input" placeholder="自由記入" style="display:none; width: auto;"' ]}
      </dl>-->

      <!-- パーツ：頭枠 -->
      <details class="box" id="part-head" $open{part_head}>
        <summary class="in-toc" data-content-title="頭">頭</summary>
        <div class="part-area">
          <table class="edit-table line-tbody no-border-cells" id="part-head-table" data-position="head">
            <thead id="part-head-head">
              <tr>
                <th><th><span class="damage-checkbox">損傷</span><th>名称<th>タイミング(T)<th>コスト(C)<th>射程(R)<th>上昇行動値<th>カテゴリ<th><span class="part-level-input">パーツLv</span>
              </tr>
            </thead>
            $skills_html{'head'}
          </table>
        </div>
        <div class="add-del-button"><a onclick="addManeuver('head')">▼</a><a onclick="delManeuver('head')">▲</a></div>
      </details>

      <!-- パーツ：腕枠 -->
      <details class="box" id="part-arms" $open{part_arms}>
        <summary class="in-toc" data-content-title="腕">腕</summary>
        <div class="part-area">
          <table class="edit-table line-tbody no-border-cells" id="part-arms-table" data-position="arms">
            <thead id="part-arms-head">
              <tr>
                <th><th><span class="damage-checkbox">損傷</span><th>名称<th>タイミング(T)<th>コスト(C)<th>射程(R)<th>上昇行動値<th>カテゴリ<th><span class="part-level-input">パーツLv</span>
              </tr>
            </thead>
            $skills_html{'arms'}
          </table>
        </div>
        <div class="add-del-button"><a onclick="addManeuver('arms')">▼</a><a onclick="delManeuver('arms')">▲</a></div>
      </details>

      <!-- パーツ：胴枠 -->
      <details class="box" id="part-torso" $open{part_torso}>
        <summary class="in-toc" data-content-title="胴">胴</summary>
        <div class="part-area">
          <table class="edit-table line-tbody no-border-cells" id="part-torso-table" data-position="torso">
            <thead id="part-torso-head">
              <tr>
                <th><th><span class="damage-checkbox">損傷</span><th>名称<th>タイミング(T)<th>コスト(C)<th>射程(R)<th>上昇行動値<th>カテゴリ<th><span class="part-level-input">パーツLv</span>
              </tr>
            </thead>
            $skills_html{'torso'}
          </table>
        </div>
        <div class="add-del-button"><a onclick="addManeuver('torso')">▼</a><a onclick="delManeuver('torso')">▲</a></div>
      </details>

      <!-- パーツ：脚枠 -->
      <details class="box" id="part-legs" $open{part_legs}>
        <summary class="in-toc" data-content-title="脚">脚</summary>
        <div class="part-area">
          <table class="edit-table line-tbody no-border-cells" id="part-legs-table" data-position="legs">
            <thead id="part-legs-head">
              <tr>
                <th><th><span class="damage-checkbox">損傷</span><th>名称<th>タイミング(T)<th>コスト(C)<th>射程(R)<th>上昇行動値<th>カテゴリ<th><span class="part-level-input">パーツLv</span>
              </tr>
            </thead>
            $skills_html{'legs'}
          </table>
        </div>
        <div class="add-del-button"><a onclick="addManeuver('legs')">▼</a><a onclick="delManeuver('legs')">▲</a></div>
      </details>
      
      <details class="box" id="parts-status" open>
      <summary class="in-toc" data-content-title="強化パーツ取得状況">強化パーツ取得状況</summary>
          <div class="parts-status-tables">
            <div id="parts-status-buso">
              <TMPL_VAR partsStatusBuso>
            </div>
            <div id="parts-status-heni">
              <TMPL_VAR partsStatusHenI>
            </div>
            <div id="parts-status-kaizo">
              <TMPL_VAR partsStatusKaizo>
            </div>
          </div>
      </details>

      <div class="box" id="view-options">
        <h2 class="in-toc">閲覧時のオプション</h2>
        <dl>
          <dt>マニューバのカテゴリ
          <dd>@{[ checkbox 'viewCategory', '一覧にカテゴリを表示する' ]}
          <dt>損傷パーツの表示
          <dd>@{[ radios 'viewDamage', '', 'normal=>通常表示', 'gray=>グレーアウト', 'hide=>非表示' ]}
        </dl>
      </div>


      
      
      <details class="box" id="free-note" @{[$pc{freeNote}?'open':'']}>
        <summary class="in-toc">容姿・経歴・その他メモ</summary>
        <textarea name="freeNote">$pc{freeNote}</textarea>
        @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestSingleData(\'freeNote\')">最新のメモを適用する</button>' : '' ]}
      </details>
      
      <details class="box" id="free-history" @{[$pc{freeHistory}?'open':'']}>
        <summary class="in-toc">履歴（自由記入）</summary>
        <textarea name="freeHistory">$pc{freeHistory}</textarea>
        @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestSingleData(\'freeHistory\')">最新の履歴（自由記入）を適用する</button>' : '' ]}
      </details>
      
<div class="box" id="history">
        <h2 class="in-toc">セッション履歴</h2>
        @{[input 'historyNum','hidden']}
        <table class="edit-table line-tbody no-border-cells" id="history-table">

          <thead>
              <tr>
                <th rowspan="2" class="col-no">No.</th>
                <th rowspan="2" class="col-date">日付</th>
                <th rowspan="2" class="col-title">タイトル</th>
                <th rowspan="2" class="col-exp">寵愛点</th>
                <th colspan="4" class="col-consume-head">消費寵愛点</th>
                <th rowspan="2" class="col-gm">GM</th>
                <th rowspan="2" class="col-member">参加者</th>
              </tr>
              <tr>
                <th class="small col-miren">未練変更</th>
                <th class="small col-insan">狂気点<br>減少</th>
                <th class="small col-basep">基本パーツ<br>修復</th>
                <th class="small col-enhp">強化パーツ<br>修復</th>
              </tr>
            </thead>
          <thead id="history-head">



            <tr>
              <td>-
              <td>
              <td>キャラクター作成
              <td id="history0-exp">$pc{history0Exp}
              <td>
              <td>
              <td>
              <td>
              <td>
              <td>
HTML
foreach my $num ('TMPL',1 .. $pc{historyNum}) {
  if($num eq 'TMPL'){ print '<template id="history-template">' }
print <<"HTML";
          <tbody id="history-row${num}">
            <tr>
              <td class="handle" rowspan="2">
              <td class="date  " rowspan="2">@{[input "history${num}Date" ]}
              <td class="title " rowspan="2">@{[input "history${num}Title" ]}
              <td class="exp   " rowspan="1">@{[ input "history${num}Exp", 'number', 'calcExp' ]}
              <td>@{[ input "history${num}Miren", 'number', 'calcExp' ]}
              <td>@{[ input "history${num}Insanity", 'number', 'calcExp' ]}
              <td>@{[ input "history${num}BasePart", 'number', 'calcExp' ]}
              <td>@{[ input "history${num}EnhancedPart", 'number', 'calcExp' ]}
              <td class="gm    " rowspan="1">@{[ input "history${num}Gm" ]}
              <td class="member" rowspan="1">@{[ input "history${num}Member" ]}
            <tr>
              <td colspan="7" class="left">@{[input("history${num}Note",'','','placeholder="備考"')]}
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
          <tfoot id="history-foot">
            <tr>
              <th colspan="3" class="right">合計
              <td id="history-exp-total">0
              <td id="history-miren-total">0
              <td id="history-insanity-total">0
              <td id="history-basepart-total">0
              <td id="history-enhancedpart-total">0
              <th colspan="2">
            </tr>
          </tfoot>
        </table>
        <div class="add-del-button"><a onclick="addHistory()">▼</a><a onclick="delHistory()">▲</a></div>
        
        <h2>記入例</h2>
        <table class="example edit-table line-tbody no-border-cells" id="history">
          <thead>
              <tr>
                <th rowspan="2" class="col-no">No.</th>
                <th rowspan="2" class="col-date">日付</th>
                <th rowspan="2" class="col-title">タイトル</th>
                <th rowspan="2" class="col-exp">寵愛点</th>
                <th colspan="4" class="col-consume-head">消費寵愛点</th>
                <th rowspan="2" class="col-gm">GM</th>
                <th rowspan="2" class="col-member">参加者</th>
              </tr>
              <tr>
                <th class="small col-miren">未練変更</th>
                <th class="small col-insan">狂気点<br>減少</th>
                <th class="small col-basep">基本パーツ<br>修復</th>
                <th class="small col-enhp">強化パーツ<br>修復</th>
              </tr>
          </thead>
          <tbody>
            <tr>
              <td class="handle" rowspan="1">
              <td class="date  " rowspan="1"><input type="text" value="2026-05-08" disabled>
              <td class="date  " rowspan="1"><input type="text" value="第一話「初めての悪夢」" disabled>
              <td class="title " rowspan="1"><input type="text" value="10" disabled>
              <td><input type="text" value="2" disabled>
              <td><input type="text" value="3" disabled>
              <td><input type="text" value="" disabled>
              <td><input type="text" value="" disabled>
              <td class="gm    " rowspan="1"><input type="text" value="サンプルNC" disabled>
              <td class="member" rowspan="1"><input type="text" value="姉妹1　姉妹2" disabled>
            </tr>
          </tbody>
        </table>
        @{[ $::in{log} ? '<button type="button" class="set-newest" onclick="setNewestHistoryData()">最新のセッション履歴を適用する</button>' : '' ]}
      </div>
      </section>
      
      <div class="box" id="exp-footer">
        <p>
        寵愛点[<b id="exp-total">0</b>] - ( 強化値[<b id="exp-footer-status">0</b>] + スキル[<b id="exp-footer-skill">0</b>] + 取得クラス外スキル[<b id="exp-footer-skill-other">0</b>] + 未練の変更[<b id="exp-footer-miren">0</b>] + 狂気点の減少[<b id="exp-footer-insanity">0</b>] + 基本パーツの修復[<b id="exp-footer-base">0</b>] + 強化パーツの修復[<b id="exp-footer-enhanced">0</b>] ) = 残り[<b id="exp-rest">0</b>]点
        </p>
      </div>

      @{[ chatPaletteForm ]}
      
      @{[ colorCostomForm ]}
      
      @{[ input 'birthTime','hidden' ]}
      <input type="hidden" name="id" value="$::in{id}">
    </form>
    @{[ deleteForm($mode) ]}
    </article>
HTML
# ヘルプ
print textRuleArea( '','「容姿・経歴・その他メモ」「履歴（自由記入）」' );

print <<"HTML";
  </main>
  <footer>
    <p class="notes">©インコグ・ラボ「永い後日談のネクロニカ」</p>
    <p class="copyright">©<a href="https://yutorize.2-d.jp">ゆとらいず工房</a>「ゆとシートⅡ」ver.${main::ver}</p>
  </footer>
  <datalist id="list-timing">
    <option value="オート">
    <option value="アクション">
    <option value="ジャッジ">
    <option value="ダメージ">
    <option value="ラピッド">
  </datalist>
  <datalist id="list-range">
    <option value="なし">
    <option value="自身">
    <option value="0">
    <option value="1">
    <option value="0～1">
    <option value="0～2">
    <option value="0～3">
    <option value="1～2">
    <option value="1～3">
    <option value="2～3">
    <option value="効果参照">
  </datalist>
  <datalist id="list-anji">
    <option value="【破局】">
    <option value="【絶望】">
    <option value="【陥穽】">
    <option value="【人形】">
    <option value="【罪人】">
    <option value="【喪失】">
    <option value="【渇望】">
    <option value="【反転】">
    <option value="【希望】">
    <option value="【幸福】">
  </datalist>
  <datalist id="list-cost">
    <option value="なし">
    <option value="0">
    <option value="1">
    <option value="2">
    <option value="3">
    <option value="4">
    <option value="効果参照">
  </datalist>
  <script>
HTML

# ネクロニカのクラスステータスデータをJSに渡す
print 'const classStats = {';
foreach my $key (keys %data::NCclass_status) {
  next if !$key;
  my $val = $data::NCclass_status{$key};
  # data-class.plで [1,1,0] と書かれている前提の処理
  my @ar = (ref($val) eq 'ARRAY') ? @$val : (ref($val) eq 'HASH') ? keys %$val : ();
  print '"'.$key.'":{"buso":'.($ar[0]//0).',"heni":'.($ar[1]//0).',"kaizo":'.($ar[2]//0).'},'
}
print "};\n";

print 'const ncPartsLevel = {';
foreach my $key (keys %data::NCparts_level) {
  next if !$key;
  my $val = $data::NCparts_level{$key};
  my @ar = (ref($val) eq 'ARRAY') ? @$val : (ref($val) eq 'HASH') ? keys %$val : ();
  print '"'.$key.'":['.join(',', @ar).'],';
}
print "};\n";

# ネクロニカの未練データをJSに渡す（重複回避対応）
print 'const ncMiren = {';
if (@data::NCmiren) {
  my %seen; # 重複チェック用
  foreach my $miren (@data::NCmiren) {
    my $key = $miren->[0] || '';
    my $val = $miren->[1] || '';
    $key =~ s/"/\\"/g;
    $val =~ s/"/\\"/g;
    
    # すでに同じ名前がある場合、末尾にゼロ幅スペース（見えない文字）を足して重複を避ける
    while ($seen{$key}) { $key .= "\x{200b}"; }
    $seen{$key} = 1;
    
    print '"'.$key.'":"'.$val.'",';
  }
}
print "};\n";

print <<"HTML";
@{[ &commonJSVariable ]}
  </script>
</body>

</html>
HTML

1;