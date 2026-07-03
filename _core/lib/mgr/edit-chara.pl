############# フォーム・キャラクター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'say';
use JSON::PP;

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
require $set::lib_palette_sub;
### 各種データライブラリ読み込み --------------------------------------------------
require $set::data_class;
my @linkage_class;
my @guardian_class;
my @main_class; my @adv_class; my @fate_class; my @legacy_class;
my @support_class; my @area_names; my %area_class;
foreach (sort{$data::class{$a}{sort} cmp $data::class{$b}{sort}} keys %data::class){
  if($data::class{$_}{type} eq 'main'){ push(@main_class, $_); push(@support_class, $_); }
  elsif($data::class{$_}{type} eq 'adv'   ){ push(@adv_class , $_); }
  elsif($data::class{$_}{type} eq 'fate'  ){ push(@fate_class, $_); }
  elsif($data::class{$_}{type} eq 'legacy'){ push(@legacy_class, $_); }
  else {
    if($data::class{$_}{area}){
      push(@area_names, $data::class{$_}{area}) if !$area_class{$data::class{$_}{area}};
      push(@{ $area_class{$data::class{$_}{area}} }, $_);
    }
    else {
      push(@support_class, $_);
    }
  }
  
}
@main_class = (
  'label=基本クラス',@main_class,
  #'label=その他', 'free|<その他（自由記入）>',
);
foreach my $area (@area_names){
  push(@support_class, 'label='.$area, @{$area_class{$area}});
}

# data-class.pl のデータを読み込んで分類する
foreach my $id (sort{$data::class{$a}{sort} cmp $data::class{$b}{sort}} keys %data::class){
  if($data::class{$id}{type} eq 'linkage'){
    push(@linkage_class, $id);
  }
  elsif($data::class{$id}{type} eq 'guardian'){
    push(@guardian_class, $id);
  }
}





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

  $pc{missionsNum} = 2;
  $pc{mission1Note} = "平和を守る";
  $pc{mission2Note} = "";

  # 装備枠を9行に設定
  $pc{armamentsNum} = 11;
  my @default_parts = ('乗機','主／近','副／近','主／遠','副／遠','OP','その他','アシスト','特技','人間用武装','人間用防具');
  for my $i (1 .. 11) {
    $pc{"armament${i}Equip"} = 1;              # チェックボックスを有効化
    $pc{"armament${i}Part"}  = $default_parts[$i-1]; # 指定の部位名を入力

    if ($i == 10) { # 例：2行目（主／近）に初期値を入れる場合
      $pc{"armament${i}Equip"} = 0;              # チェックボックスを有効化
      $pc{"armament${i}Name"} = "素手";
      $pc{"armamentNoteAuto${i}Note"} = "主武装で装備。徒手空拳で戦った際の武器のデータ。";
      $pc{"armamentNoteAuto${i}Type"} = "白兵（格闘）";
      $pc{"armament${i}Meichu"} = 0;
      $pc{"armament${i}Kaihi"} = 0;
      $pc{"armament${i}Hougeki"} = 0;
      $pc{"armament${i}Bouheki"} = 0;
      $pc{"armament${i}Koudou"} = 0;
      $pc{"armament${i}Zokusei"} = "殴";
      $pc{"armament${i}Kougeki"} = 0;
      $pc{"armament${i}Joubi"} = 0;
      $pc{"armament${i}Set"} = "生身";
      

    }
# ▼ ここから初期値の指定を追加 ▼
    if ($i == 11) { # 例：1行目（乗機）にサンプルの初期値を入れる
      $pc{"armament${i}Equip"} = 0;
      $pc{"armament${i}Name"} = "パイロットスーツ";
      $pc{"armament${i}Set"} = "生身";
      $pc{"armament${i}Meichu"} = 0;
      $pc{"armament${i}Kaihi"} = 0;
      $pc{"armament${i}Hougeki"} = 0;
      $pc{"armament${i}Bouheki"} = -1;
      $pc{"armament${i}Koudou"} = -1;
      $pc{"armament${i}Joubi"} = 0;

      # 自動出現する「防御修正とサイズ」の初期値
      $pc{"defenceAuto${i}Zan"}  = 2;
      $pc{"defenceAuto${i}Totsu"} = 1;
      $pc{"defenceAuto${i}Ou"} = 3;
      $pc{"defenceAuto${i}En"} = 3;
      $pc{"defenceAuto${i}Hyou"} = 3;
      $pc{"defenceAuto${i}Rai"} = 3;
      # (Ou, En, Hyou, Rai, Kou, Yami など必要な属性を追加)
      $pc{"defenceAuto${i}Size"} = "";

      # 自動出現する「装備解説」の初期値
      $pc{"armamentNoteAuto${i}Note"} = "リンケージがガーディアンに搭乗する際に着用する衣服。<br>サンプル記入";
      $pc{"armamentNoteAuto${i}Type"} = "防具";
    }
  }
    

  
  
  $pc{history0Exp}   = $set::make_exp;
  $pc{history0Money} = $set::make_money;
  $pc{expTotal} = $pc{history0Exp};
  
  $pc{level} = 1;



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
$pc{skillsNum}      ||=  3;
$pc{connectionsNum} ||=  1;
$pc{geisesNum}      ||=  1;
$pc{historyNum}     ||=  3;

$pc{classesNum}     ||=  1; # クラスの初期行数
$pc{missionsNum}    ||=  1;
$pc{armamentsNum}   ||=  1; # （装備品の初期行数）
$pc{defencesNum}    ||=  1; # （手動追加する防御修正の初期行数）
$pc{kagosNum}       ||=  3; # （加護の初期行数）

$pc{lifestylesNum}  ||=  1;
$pc{housesNum}      ||=  1;
$pc{itemsNum}       ||=  3;

### 折り畳み判断 --------------------------------------------------
my %open;
$open{skills} = 'open';
#foreach (3..$pc{skillsNum}){ if($pc{"skill${_}Name"} || $pc{"skill${_}Lv"}){ $open{skills} = 'open'; last; } }

### 改行処理 --------------------------------------------------
foreach (
  'words',
  'items',
  'freeNote',
  'freeHistory',
  'cashbook',
  'chatPalette',
  'armamentHandRNote',
  'armamentHandLNote',
  'armamentHeadNote',
  'armamentBodyNote',
  'armamentSubNote',
  'armamentOtherNote',
  'armamentTotalNote',
  'battleSkillNote',
  'battleOtherNote',
){
  $pc{$_} =~ s/&lt;br&gt;/\n/g;
}
foreach my $i (1 .. $pc{geisesNum}){
  $pc{"geis${i}Note"} =~ s/&lt;br&gt;/\n/g;
}

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
  
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/mgr/css/chara.css?${main::ver}">
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/_common/css/edit.css?${main::ver}">
  
  <link rel="stylesheet" media="all" href="${main::core_dir}/skin/mgr/css/edit.css?${main::ver}">
  <script src="${main::core_dir}/skin/_common/js/lib/Sortable.min.js"></script>
  <script src="${main::core_dir}/skin/_common/js/lib/compressor.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/\@yaireo/tagify"></script>
  <script src="https://cdn.jsdelivr.net/npm/\@yaireo/tagify/dist/tagify.polyfills.min.js"></script>
  <link href="https://cdn.jsdelivr.net/npm/\@yaireo/tagify/dist/tagify.css" rel="stylesheet" type="text/css">
  <script src="${main::core_dir}/lib/edit.js?${main::ver}" defer></script>
  
  <script src="${main::core_dir}/lib/mgr/edit-chara.js?${main::ver}" defer></script>
  <style>
    #image,
    .image-custom-view {
      background-image: url("$pc{imageURL}");
    }
  </style>
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
          <dt>消費経験点</dt>
          <dd>@{[input("history0Exp",'number','changeRegu','step="1"'.($set::make_fix?' readonly':''))]}</dd>
          <dt>ステージ</dt>
          <dd>@{[input('stage')]}</dd>
        </dl>
        <dl class="regulation-note"><dt>備考</dt><dd>@{[ input "history0Note" ]}</dd></dl>
      </details>

      <div id="area-status">
        @{[ imageForm($pc{imageURL}) ]}
        <div class="box-union" id="personal">
          <dl class="box"><dt>性別</dt><dd>@{[ input 'gender','','','list="list-gender"' ]}</dd></dl>
          <dl class="box"><dt>年齢</dt><dd>@{[ input 'age' ]}</dd></dl>
          <dl class="box"><dt>カバー</dt><dd>@{[ input 'cover' ]}</dd></dl>
          <dl class="box"><dt>機体名</dt><dd>@{[ input 'mechaName' ]}</dd></dl>
        </div>

<div class="box-union" id="lp-m-c-union">
        <div class="box" id="lifepath">
          <h2 class="in-toc">ライフパス</h2>
          <table class="edit-table line-tbody no-border-cells">
            <tbody>
              <tr>
                <th>出自</th>
                <td>@{[ input 'lifepathOrigin' ]}</td>
                <td>@{[ input 'lifepathOriginNote','','','placeholder="備考"' ]}</td>
              </tr>
              <tr>
                <th>経験</th>
                <td>@{[ input 'lifepathExperience' ]}</td>
                <td>@{[ input 'lifepathExperienceNote','','','placeholder="備考"' ]}</td>
              </tr>
              <tr>
                <th>邂逅</th>
                <td>@{[ input 'lifepathEncounter' ]}</td>
                <td>@{[ input 'lifepathEncounterNote','','','placeholder="備考"' ]}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="box" id="missions">
          <h2 class="in-toc">ミッション</h2>
          @{[input 'missionsNum','hidden']}
          <table class="edit-table no-border-cells" id="missions-table">
            <colgroup>
              <col class="handle">
              <col>
            </colgroup>
            <tbody>
HTML
foreach my $num ('TMPL', 1 .. $pc{missionsNum}){
  if($num eq 'TMPL'){ print '<template id="mission-template">' }
  print <<"HTML";
              <tr id="mission-row${num}">
                <td class="handle"></td>
                <td>@{[ input "mission${num}Note" ]}</td>
              </tr>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
            </tbody>
          </table>
          <div class="add-del-button"><a onclick="addMission()">▼</a><a onclick="delMission()">▲</a></div>
        </div>

        <div class="box" id="connections">
          <h2 class="in-toc">コネクション</h2>
          @{[input 'connectionsNum','hidden']}
          <table class="edit-table no-border-cells" id="connections-table">
            <thead>
              <tr>
                <th class="col-handle"></th>
                <th class="col-joubi">常備</th>
                <th class="col-name">名前</th>
                <th class="col-rel">関係</th>
                <th class="col-note">備考</th>
              </tr>
            </thead>
            <tbody>
HTML
foreach my $num ('TMPL', 1 .. $pc{connectionsNum}) {
  if($num eq 'TMPL'){ print '<template id="connection-template">' }
  print <<"HTML";
              <tr id="connection-row${num}">
                <td class="handle"></td>
                <td class="col-joubi">@{[ input "connection${num}Joubika", 'checkbox', 'calcConnections' ]}</td>
                <td class="col-name">@{[ input "connection${num}Name", 'text', '', 'placeholder="名前"' ]}</td>
                <td class="col-rel">@{[ input "connection${num}Relation", 'text', '', 'placeholder="関係"' ]}</td>
                <td class="col-note">@{[ input "connection${num}Note", 'text', '', 'placeholder="備考"' ]}</td>
              </tr>
HTML
  if($num eq 'TMPL'){ print '</template>' }
  
}


print <<"HTML";
            </tbody>
          </table>
          <div class="add-del-button"><a onclick="addConnection()">▼</a><a onclick="delConnection()">▲</a></div>
        </div>
      </div>

<div class="box" id="classes">
          <h2 class="in-toc">クラス／レベル</h2>
          @{[input 'classesNum','hidden']}
          <table class="edit-table no-border-cells" id="classes-table">
<thead>
              <tr>
                <th></th>
                <th>クラス名</th>
                <th>レベル</th>
              </tr>
            </thead>
            <tbody>
HTML
foreach my $num ('TMPL', 1 .. $pc{classesNum}) {
  if($num eq 'TMPL'){ print '<template id="class-template">' }
  
  # 現在の値がリストにない「自由記入」状態か、Perl側で初期判定する
  my $is_free = ($pc{"class${num}Name"} ne '' && !grep { $_ eq $pc{"class${num}Name"} } (@linkage_class, @guardian_class)) ? 1 : 0;
  my $display = $is_free ? 'inline-block' : 'none';

  print <<"HTML";
              <tr id="class-row${num}">
                <td class="handle"></td>
                <td>
                  <select onchange="let i=document.getElementsByName('class${num}Name')[0]; if(this.value==='free'){ i.style.display='inline-block'; }else{ i.style.display='none'; i.value=this.value; } calcClasses();">
                    <option value=""></option>
                    <optgroup label="リンケージ">
                      @{[ join("", map { '<option value="'.$_.'"'.($pc{"class${num}Name"} eq $_ ? ' selected' : '').'>'.$_.'</option>' } @linkage_class) ]}
                    </optgroup>
                    <optgroup label="ガーディアン">
                      @{[ join("", map { '<option value="'.$_.'"'.($pc{"class${num}Name"} eq $_ ? ' selected' : '').'>'.$_.'</option>' } @guardian_class) ]}
                    </optgroup>
                    <option value="free" @{[ $is_free ? 'selected' : '' ]}>その他（自由記入）</option>
                  </select>
                  
                  @{[ input "class${num}Name", 'text', 'calcClasses', qq(placeholder="自由記入" style="display:$display; width:auto;") ]}
                </td>
                <td>@{[ input "class${num}Lv", 'number', 'calcClasses', 'min="1" placeholder="Lv"' ]}</td>
              </tr>
HTML
  if($num eq 'TMPL'){ print '</template>' }
  
}

print <<"HTML";
            </tbody>
          </table>
          <div class="add-del-button"><a onclick="addClass()">▼</a><a onclick="delClass()">▲</a></div>
        </div>
        
        <details class="box" id="status" open>
          <summary class="in-toc">能力値</summary>
          <table class="edit-table" id="status-main">
            <colgroup>
              <col class="class-name">
              <col class="type">
              <col class="stt" span="6">
            </colgroup>
            <thead>
              <tr>
                <th colspan="8">能力値</th>
              </tr>
              <tr>
                <th>初期クラス</th>
                <th class="small">種別</th>
                <th>体力</th>
                <th>反射</th>
                <th>知覚</th>
                <th>理知</th>
                <th>意志</th>
                <th>幸運</th>
              </tr>
            </thead>
            <tbody>
HTML
# 初期クラスと基本値（3行分）
foreach my $i (1 .. 3) {
  # 現在の値がリストにない「自由記入」状態か、Perl側で初期判定する
  my $is_free = ($pc{"sttBase${i}Class"} ne '' && !grep { $_ eq $pc{"sttBase${i}Class"} } (@linkage_class, @guardian_class)) ? 1 : 0;
  my $display = $is_free ? 'inline-block' : 'none';
  print <<"HTML";
              <tr>
                <td>
                  <select onchange="let el=document.getElementsByName('sttBase${i}Class')[0]; if(this.value==='free'){ el.style.display='inline-block'; }else{ el.style.display='none'; el.value=this.value; } changeBaseClass(${i});">
                    <option value=""></option>
                    <optgroup label="リンケージ">
                      @{[ join("", map { '<option value="'.$_.'"'.($pc{"sttBase${i}Class"} eq $_ ? ' selected' : '').'>'.$_.'</option>' } @linkage_class) ]}
                    </optgroup>
                    <optgroup label="ガーディアン">
                      @{[ join("", map { '<option value="'.$_.'"'.($pc{"sttBase${i}Class"} eq $_ ? ' selected' : '').'>'.$_.'</option>' } @guardian_class) ]}
                    </optgroup>
                    <option value="free" @{[ $is_free ? 'selected' : '' ]}>その他（自由記入）</option>
                  </select>
                  
                  @{[ input "sttBase${i}Class", 'text', "changeBaseClass(${i})", qq(placeholder="自由記入" style="display:$display; width:auto;") ]}
                </td>
                
                <td>@{[ input "sttBase${i}Type",  'text', '', 'readonly tabindex="-1"' ]}</td>
HTML
  foreach my $stt ('Tai', 'Han', 'Chi', 'Ri', 'Ishi', 'Kou') {
    print '<td>'.input("sttBase${i}${stt}", 'number', 'calcStt')."</td>\n";
  }
  print "              </tr>\n";
}

print <<"HTML";
            </tbody>
            <tbody class="calc-rows">
              <tr>
                <th colspan="2">割り振り</th>
HTML
foreach my $stt ('Tai', 'Han', 'Chi', 'Ri', 'Ishi', 'Kou') {
  print '<td>'.input("sttPoint${stt}", 'checkbox', 'calcStt')."</td>\n";
}

print <<"HTML";
              </tr>
              <tr>
                <th colspan="2">成長</th>
HTML
foreach my $stt ('Tai', 'Han', 'Chi', 'Ri', 'Ishi', 'Kou') {
  print '<td>'.input("sttGrow${stt}", 'number', 'calcStt')."</td>\n";
}

print <<"HTML";
              </tr>
              <tr>
                <th colspan="2">特技の修正</th>
HTML
foreach my $stt ('Tai', 'Han', 'Chi', 'Ri', 'Ishi', 'Kou') {
  print '<td>'.input("sttSkill${stt}", 'number', 'calcStt')."</td>\n";
}

print <<"HTML";
              </tr>
              <tr>
                <th colspan="2">その他の修正</th>
HTML
foreach my $stt ('Tai', 'Han', 'Chi', 'Ri', 'Ishi', 'Kou') {
  print '<td>'.input("sttOther${stt}", 'number', 'calcStt')."</td>\n";
}

print <<"HTML";
              </tr>
              <tr class="total-row">
                <th colspan="2">合計</th>
HTML
foreach my $stt ('Tai', 'Han', 'Chi', 'Ri', 'Ishi', 'Kou') {
  print '<td>'.input("sttTotal${stt}", 'number', '', 'readonly tabindex="-1"')."</td>\n";
}

print <<"HTML";
              </tr>
              <tr>
                <th colspan="2">能力値ボーナスへの修正</th>
HTML
foreach my $stt ('Tai', 'Han', 'Chi', 'Ri', 'Ishi', 'Kou') {
  print '<td>'.input("sttBonusAdd${stt}", 'number', 'calcStt')."</td>\n";
}

print <<"HTML";
              </tr>
              <tr class="bonus-row">
                <th colspan="2">能力値ボーナス</th>
HTML
foreach my $stt ('Tai', 'Han', 'Chi', 'Ri', 'Ishi', 'Kou') {
  print '<td>'.input("sttBonus${stt}", 'number', '', 'readonly tabindex="-1"')."</td>\n";
}


print <<"HTML";
            </tbody>
          </table>
          
        </div>
      </details>
      
      <details class="box" id="battle-values" open>
          <summary class="in-toc">戦闘値と装備</summary>
          @{[input 'armamentsNum','hidden']}
          <table class="edit-table no-border-cells" id="battle-table">
            <thead>
              <tr class="header-row">
              </tr>
              <tr class="subheader-row">
                <th colspan="4"></th>
                <th>命中</th>
                <th>回避</th>
                <th>砲撃</th>
                <th>防壁</th>
                <th>行動</th>
                <th>力場</th>
                <th>耐久</th>
                <th>感応</th>
                <th>移動</th>
                <th class="dead-space"></th>
                <th>攻撃</th>
                <th colspan="5" class="dead-space"></th>
              </tr>
            </thead>
            
            <tbody class="battle-calc-area">
              <tr class="battle-base-add">
                <th colspan="4" class="right">ベースの修正値</th>
HTML
foreach my $stt ('Meichu', 'Kaihi', 'Hougeki', 'Bouheki', 'Koudou', 'Rikiba', 'Taikyu', 'Kannou') {
  print '<td>'.input("battleBaseAdd${stt}", 'number', 'calcBattle')."</td>\n";
}
print <<"HTML";
                <td>@{[ input 'battleBaseAddIdou', 'number', 'calcBattle' ]}</td>
                <td class="dead-space"></td>
                <td>@{[ input 'battleBaseAddKougeki', 'number', 'calcBattle' ]}</td>
                <td colspan="5" class="dead-space"></td>
              </tr>
              <tr class="battle-base">
                <th colspan="4" class="right">ベース</th>
HTML
foreach my $stt ('Meichu', 'Kaihi', 'Hougeki', 'Bouheki', 'Koudou', 'Rikiba', 'Taikyu', 'Kannou') {
  print '<td>'.input("battleBase${stt}", 'number', '', 'readonly tabindex="-1"')."</td>\n";
}
print <<"HTML";
                <td>@{[ input 'battleBaseIdou', 'number', '', 'readonly tabindex="-1"' ]}</td>
                <td class="dead-space"></td>
                <td class="dead-space"></td>
                <td colspan="5" class="dead-space"></td>
              </tr>
            </tbody>

<tbody id="battle-classes-area">
HTML
# クラス修正行（上部のクラス欄の数だけループ生成）
foreach my $num (1 .. $pc{classesNum}) {
  my $dispName = $pc{"class${num}Name"} || 'クラス名';
  my $dispLv   = $pc{"class${num}Lv"} || 'Lv';
  print <<"HTML";
              <tr id="battle-class-row${num}">
                <th colspan="3" class="class-name right" id="battle-class-name${num}">$dispName</th>
                <th class="class-lv" id="battle-class-lv${num}">$dispLv</th>


HTML
  foreach my $stt ('Meichu', 'Kaihi', 'Hougeki', 'Bouheki', 'Koudou', 'Rikiba', 'Taikyu', 'Kannou') {
    print '<td>'.input("battleClass${num}${stt}", 'number', 'calcBattle', 'readonly tabindex="-1"')."</td>\n";
  }
  print <<"HTML";
                <td class="dead-space"></td>
                <td class="dead-space"></td>
                <td>@{[ input "battleClass${num}Kougeki", 'number', 'calcBattle', 'readonly tabindex="-1"' ]}</td>
                <td colspan="5" class="dead-space"></td>
              </tr>
HTML
}
print <<"HTML";
            </tbody>

            <tbody class="battle-subtotal-area">
              <tr class="battle-subtotal">
                <th colspan="4" class="right">未装備小計</th>
HTML
foreach my $stt ('Meichu', 'Kaihi', 'Hougeki', 'Bouheki', 'Koudou', 'Rikiba', 'Taikyu', 'Kannou') {
  print '<td>'.input("battleSubtotal${stt}", 'number', '', 'readonly tabindex="-1"')."</td>\n";
}
print <<"HTML";
                <td>@{[ input 'battleSubtotalIdou', 'number', '', 'readonly tabindex="-1"' ]}</td>
                <td class="dead-space"></td>
                <td>@{[ input 'battleSubtotalKougeki', 'number', '', 'readonly tabindex="-1"' ]}</td>
                <td colspan="5" class="dead-space"></td>
              </tr>
            </tbody>

 <tbody class="equipment-header-area">
              <tr class="equipment-header">
                <th></th>
                <th>装</th>
                <th>部位</th>
                <th>名称</th>
                <th class="small">命中</th>
                <th class="small">回避</th>
                <th class="small">砲撃</th>
                <th class="small">防壁</th>
                <th class="small">行動</th>
                <th class="small">力場</th>
                <th class="small">耐久</th>
                <th class="small">感応</th>
                <th class="small">移動</th>
                <th>属性</th>
                <th class="small">攻撃</th>
                <th>射程</th>
                <th>代償</th>
                <th>弾数</th>
                <th>常備</th>
                <th>セット</th>
              </tr>
            </tbody>

            <tbody id="armaments-area">
HTML
# 装備品行（動的追加）
foreach my $num ('TMPL', 1 .. $pc{armamentsNum}){
  if($num eq 'TMPL'){ print '<template id="armament-template">' }
  print <<"HTML";
              <tr id="armament-row${num}">
                <td class="handle"></td>
                <td>@{[ input "armament${num}Equip", 'checkbox', 'calcBattle' ]}</td>
                <td>@{[ input "armament${num}Part", 'text', "initArmamentParts(${num})", 'list="list-parts"' ]}</td>
                <td>@{[ input "armament${num}Name" ]}</td>
HTML
  foreach my $stt ('Meichu', 'Kaihi', 'Hougeki', 'Bouheki', 'Koudou', 'Rikiba', 'Taikyu', 'Kannou') {
    print '<td>'.input("armament${num}${stt}", 'number', 'calcBattle')."</td>\n";
  }
  print <<"HTML";
                <td>@{[ input "armament${num}Idou", 'number', 'calcBattle' ]}</td>
                <td>@{[ input "armament${num}Zokusei", 'text', '', 'list="list-zokusei" readonly tabindex="-1"' ]}</td>
                <td>@{[ input "armament${num}Kougeki", 'number', 'calcBattle' ]}</td>
                <td>@{[ input "armament${num}Shatei", 'text', '', 'list="list-range"' ]}</td>
                <td>@{[ input "armament${num}Daishou", 'text', '', 'list="list-costW"' ]}</td>
                <td>@{[ input "armament${num}Danzuu", 'number' ]}</td>
                <td>@{[ input "armament${num}Joubi", 'number', 'calcPrice' ]}</td>
                <td>@{[ input "armament${num}Set" ]}</td>
              </tr>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
            </tbody>
            
            <tfoot>
              <tr class="equipment-buttons">
                <td colspan="20">
                  <div class="add-del-button"><a onclick="addArmament()">▼</a><a onclick="delArmament()">▲</a></div>
                </td>
              </tr>
              <tr class="battle-total">
                <th colspan="4" class="right">合計</th>
HTML
foreach my $stt ('Meichu', 'Kaihi', 'Hougeki', 'Bouheki', 'Koudou', 'Rikiba', 'Taikyu', 'Kannou') {
  print '<td>'.input("battleTotal${stt}", 'number', '', 'readonly tabindex="-1"')."</td>\n";
}
print <<"HTML";
                <td>@{[ input 'battleTotalIdou', 'number', '', 'readonly tabindex="-1"' ]}</td>
                <td class="dead-space"></td>
                <td>@{[ input 'battleTotalKougeki', 'number', '', 'readonly tabindex="-1"' ]}</td>
                <td colspan="3" class="dead-space"></td>
                <td>@{[ input 'battleTotalJoubi', 'number', '', 'readonly tabindex="-1"' ]}</td>
                <td class="dead-space"></td>
              </tr>
            </tfoot>
          </table>
        </details>
      
        <details class="box" id="defences" open>
          <summary class="in-toc">防御修正とサイズ</summary>
          @{[input 'defencesNum','hidden']}
          <table class="edit-table no-border-cells" id="defences-table">
            <thead>
              <tr>
                <th></th>
                <th>部位</th>
                <th>名称</th>
                <th class="small">斬</th>
                <th class="small">刺</th>
                <th class="small">殴</th>
                <th class="small">炎</th>
                <th class="small">氷</th>
                <th class="small">雷</th>
                <th class="small">光</th>
                <th class="small">闇</th>
                <th>サイズ</th>
              </tr>
            </thead>
            
            <tbody id="defences-auto-area">
HTML
# ① 装備欄に連動する自動生成行（装備の数だけ事前に準備）
foreach my $num (1 .. $pc{armamentsNum}) {
  # CGIレンダリング時、既に条件を満たしている場合のみ初期表示する
  my $part = $pc{"armament${num}Part"} || '';
  my $display = ($part =~ /乗機|オプション|その他/) ? '' : 'style="display:none;"';
  print <<"HTML";
              <tr id="defence-auto-row${num}" class="defence-auto-row" $display>
                <td></td>
                <td>@{[ input "defenceAuto${num}Part", 'text', '', 'readonly tabindex="-1"' ]}</td>
                <td>@{[ input "defenceAuto${num}Name", 'text', '', 'readonly tabindex="-1"' ]}</td>
HTML
  foreach my $zokusei ('Zan', 'Totsu', 'Ou', 'En', 'Hyou', 'Rai', 'Kou', 'Yami') {
    print '<td>'.input("defenceAuto${num}${zokusei}", 'number', 'calcBattle')."</td>\n";
  }
  print <<"HTML";
                <td>@{[ input "defenceAuto${num}Size",'','','placeholder="サイズ" list="list-size"' ]}</td>
                
              </tr>
HTML
}
print <<"HTML";
            </tbody>
            
            <tbody id="defences-area">
HTML
# ② 任意追加できる手動行
foreach my $num ('TMPL', 1 .. $pc{defencesNum}) {
  if($num eq 'TMPL'){ print '<template id="defence-template">' }
  print <<"HTML";
              <tr id="defence-row${num}">
                <td class="handle"></td>
                <td>@{[ input "defence${num}Part", 'text', '', 'list="list-parts"' ]}</td>
                <td>@{[ input "defence${num}Name" ]}</td>
HTML
  foreach my $zokusei ('Zan', 'Totsu', 'Ou', 'En', 'Hyou', 'Rai', 'Kou', 'Yami') {
    print '<td>'.input("defence${num}${zokusei}", 'number', 'calcBattle')."</td>\n";
  }
  print <<"HTML";
                <td>@{[ input "defence${num}Size",'','','placeholder="サイズ" list="list-size"' ]}</td>
              </tr>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
            </tbody>
          </table>
          <div class="add-del-button"><a onclick="addDefence()">▼</a><a onclick="delDefence()">▲</a></div>
        </details>

        <details class="box" id="armament-notes" open>
          <summary class="in-toc">装備解説</summary>
          <table class="edit-table no-border-cells" id="armament-notes-table">
            <thead>
              <tr>
                <th>部位</th>
                <th>名称</th>
                <th>解説</th>
                <th>種別</th>
              </tr>
            </thead>
            
            <tbody id="armament-notes-auto-area">
HTML
# 装備欄に連動する自動生成行（装備の数だけ事前に準備）
foreach my $num (1 .. $pc{armamentsNum}) {
  # CGIレンダリング時の初期表示判定
  # 部位が入力されてのみ表示
  my $part = $pc{"armament${num}Part"} || '';
  my $display = ($part ne '') ? '' : 'style="display:none;"';
  
  print <<"HTML";
              <tr id="armament-note-auto-row${num}" class="armament-note-auto-row" $display>
                <td>@{[ input "armamentNoteAuto${num}Part", 'text', '', 'readonly tabindex="-1"' ]}</td>
                <td>@{[ input "armamentNoteAuto${num}Name", 'text', '', 'readonly tabindex="-1"' ]}</td>
                <td class="left">@{[ input "armamentNoteAuto${num}Note", 'text', '', 'placeholder="解説"' ]}</td>
                <td>@{[ input "armamentNoteAuto${num}Type", 'text', '', 'placeholder="種別"' ]}</td>
              </tr>
HTML
}
print <<"HTML";
            </tbody>
          </table>
        </details>



        <details class="box" id="kagos" open>
        <summary class="in-toc">加護</summary>
        @{[input 'kagosNum','hidden']}
        <table class="edit-table no-border-cells" id="kagos-table">
          <thead>
            <tr>
              <th></th>
              <th>名称</th>
              <th>効果</th>
            </tr>
          </thead>
          <tbody>
HTML
foreach my $num ('TMPL', 1 .. $pc{kagosNum}) {
  if($num eq 'TMPL'){ print '<template id="kago-template">' }
  print <<"HTML";
            <tr id="kago-row${num}">
              <td class="handle"></td>
              <td>@{[ input "kago${num}Name", 'text', '', 'placeholder="名称"' ]}</td>
              <td class="left">@{[ input "kago${num}Note", 'text', '', 'placeholder="効果"' ]}</td>
            </tr>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
          </tbody>
        </table>
        <div class="add-del-button"><a onclick="addKago()">▼</a><a onclick="delKago()">▲</a></div>
      </details>

<details class="box" id="skills" open>
        <summary class="in-toc">特技</summary>
      <table class="edit-table line-tbody no-border-cells" id="skills-table">


      <thead id="skill-head">
              <tr><th></th><th>名称</th><th>Lv</th><th>種別</th><th>タイミング</th><th>対象</th><th>射程</th><th>代償</th><th>参照</th></tr>
            </thead>
HTML
foreach my $num ('TMPL',1 .. $pc{skillsNum}) {
  if($num eq 'TMPL'){ print '<template id="skill-template">' }
  # 現在入力されている全てのクラス名を取得（空欄は除外）
  my @current_classes;
  foreach my $i (1 .. $pc{classesNum}) {
      push(@current_classes, $pc{"class${i}Name"}) if $pc{"class${i}Name"} ne '';
  }
  
  # 現在の特技の「取得元」が、自由記入モードかどうかを判定する
  my $current_type = $pc{"skill${num}Type"} || '';
  my $is_free = ($current_type ne '' && !grep { $_ eq $current_type } (@current_classes, 'ガーディアン', '汎用', 'アシスト', '勲章')) ? 1 : 0;
  my $display = $is_free ? 'inline-block' : 'none';
print <<"HTML";
            <tbody id="skill-row${num}">
              <tr>
                <td rowspan="2" class="handle"></td> 
                <td>@{[input "skill${num}Name",'','calcSkillsDebounced','placeholder="名称"']}</td>
                <td>@{[input "skill${num}Lv",'number','calcSkillsDebounced','placeholder="Lv"']}</td>
                <td>@{[input "skill${num}Category",'','calcSkillsDebounced','placeholder="種別" list="list-category"']}</td>
                <td>@{[input "skill${num}Timing",'','','placeholder="タイミング" list="list-timing"']}</td>
                <td>@{[input "skill${num}Target",'','','placeholder="対象" list="list-target"']}</td>
                <td>@{[input "skill${num}Range",'','','placeholder="射程" list="list-range"']}</td>
                <td>@{[input "skill${num}Cost",'','','placeholder="代償" list="list-costS"']}</td>
                <td>@{[input "skill${num}Reqd",'','','placeholder="参照" list="list-reqd"']}</td>
              </tr>
              <tr>
                <td colspan="8">
                  <div class="skill-second-row">
                    <b>取得元</b>


                      <span class="select-or-input">
                      <select onchange="let el=document.getElementsByName('skill${num}Type')[0]; if(this.value==='free'){ el.style.display='inline-block'; }else{ el.style.display='none'; el.value=this.value; } calcSkills();">
                        <option value=""></option>
                        @{[ option "skill${num}Type", @current_classes, 'ガーディアン', '汎用', 'アシスト', '勲章' ]}
                        <option value="free" @{[ $is_free ? 'selected' : '' ]}>その他（自由記入）</option>
                      </select>
                      
                      @{[ input "skill${num}Type", 'text', 'calcSkills', qq(placeholder="自由記入" style="display:$display; width:auto;") ]}
                    </span>

                    <b>取得時Lv</b>@{[input "skill${num}GetLv",'number','calcSkillsDebounced','min="1" placeholder="Lv"']}
                    <b>効果</b>@{[input "skill${num}Note", 'text', '', 'placeholder="効果"']}
                  </div>
                </td>
              </tr>
            </tbody>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
            <tfoot id="skill-foot">
              <tr><th></th><th>名称</th><th>Lv</th><th>種別</th><th>タイミング</th><th>対象</th><th>射程</th><th>代償</th><th>参照</th></tr>
            </tfoot>
          </table>
          
          <div class="add-del-button"><a onclick="addSkill()">▼</a><a onclick="delSkill()">▲</a></div>
          @{[input 'skillsNum','hidden']}

          <div class="box trash-box" id="skills-trash" style="display:none;">
        <h2><span class="material-symbols-outlined">delete</span><span class="shorten">削除スキル</span></h2>
        <table class="edit-table line-tbody" id="skills-trash-table"></table>
        <i class="material-symbols-outlined close-button" onclick="document.getElementById('skills-trash').style.display = 'none';">close</i>
      </div>
    </details>
</div>
      <div id="area-items">
        <details class="box" id="items-area" open>
          <summary class="in-toc">アイテム</summary>

          <div id="joubika-add">
            <h3>常備化ポイント追加</h3>
            <table class="edit-table no-border-cells" id="joubika-add-table">
              <tbody>
                <tr>
                  <th class="right">特技追加：</th>
                  <td>@{[ input 'joubikaSkillAdd', 'number', 'calcJoubika' ]}</td>
                  <th class="right">経験点変換分：</th>
                  <td>@{[ input 'joubikaExpAdd', 'number', '', 'readonly tabindex="-1"' ]}</td>
                  <th class="right">消費経験点：</th>
                  <td>@{[ input 'joubikaExpUsed', 'number', 'calcJoubika' ]}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div id="items">
            <h3>ライフスタイル</h3>
            @{[input 'lifestylesNum','hidden']}
            <table class="edit-table no-border-cells" id="lifestyles-table">
              <thead>
                <tr>
                  <th></th>
                  <th>名称</th>
                  <th>常備化</th>
                  <th>タイミング</th>
                  <th>財産P</th>
                  <th>解説</th>
                </tr>
              </thead>
              <tbody>
HTML
foreach my $num ('TMPL', 1 .. $pc{lifestylesNum}){
  if($num eq 'TMPL'){ print '<template id="lifestyle-template">' }
  print <<"HTML";
                <tr id="lifestyle-row${num}">
                  <td class="handle"></td>
                  <td>@{[ input "lifestyle${num}Name" ]}</td>
                  <td>@{[ input "lifestyle${num}Joubika", 'number', 'calcJoubika' ]}</td>
                  <td>@{[ input "lifestyle${num}Timing", 'text', '', 'list="list-timing"' ]}</td>
                  <td>@{[ input "lifestyle${num}Property", 'number' ]}</td>
                  <td class="left">@{[ input "lifestyle${num}Note" ]}</td>
                </tr>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
              </tbody>
            </table>
            <div class="add-del-button"><a onclick="addLifestyle()">▼</a><a onclick="delLifestyle()">▲</a></div>

            <h3>住宅</h3>
            @{[input 'housesNum','hidden']}
            <table class="edit-table no-border-cells" id="houses-table">
              <thead>
                <tr>
                  <th></th>
                  <th>名称</th>
                  <th>常備化</th>
                  <th>タイミング</th>
                  <th>解説</th>
                </tr>
              </thead>
              <tbody>
HTML
foreach my $num ('TMPL', 1 .. $pc{housesNum}){
  if($num eq 'TMPL'){ print '<template id="house-template">' }
  print <<"HTML";
                <tr id="house-row${num}">
                  <td class="handle"></td>
                  <td>@{[ input "house${num}Name" ]}</td>
                  <td>@{[ input "house${num}Joubika", 'number', 'calcJoubika' ]}</td>
                  <td>@{[ input "house${num}Timing", 'text', '', 'list="list-timing"' ]}</td>
                  <td class="left">@{[ input "house${num}Note" ]}</td>
                </tr>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
              </tbody>
            </table>
            <div class="add-del-button"><a onclick="addHouse()">▼</a><a onclick="delHouse()">▲</a></div>

            <h3>一般アイテム</h3>
            @{[input 'itemsNum','hidden']}
            <table class="edit-table no-border-cells" id="items-table">
              <thead>
                <tr>
                  <th></th>
                  <th>名称</th>
                  <th>常備化</th>
                  <th>タイミング</th>
                  <th>解説</th>
                </tr>
              </thead>
              <tbody>
HTML
foreach my $num ('TMPL', 1 .. $pc{itemsNum}){
  if($num eq 'TMPL'){ print '<template id="item-template">' }
  print <<"HTML";
                <tr id="item-row${num}">
                  <td class="handle"></td>
                  <td>@{[ input "item${num}Name" ]}</td>
                  <td>@{[ input "item${num}Joubika", 'number', 'calcJoubika' ]}</td>
                  <td>@{[ input "item${num}Timing", 'text', '', 'list="list-timing"' ]}</td>
                  <td class="left">@{[ input "item${num}Note" ]}</td>
                </tr>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
              </tbody>
            </table>
            <div class="add-del-button"><a onclick="addItem()">▼</a><a onclick="delItem()">▲</a></div>
          </div>

          <div id="joubika-footer">
            <table class="edit-table no-border-cells">
              <tbody>
                <tr>
                  <th class="right">常備化小計：</th>
                  <td><span id="joubika-items-total">0</span></td>
                  <th class="right">武具小計：</th>
                  <td><span id="joubika-armaments-total">0</span></td>

<th class="right">常備化ポイント残：</th>
          <td class="right"><span id="joubika-rest" style="font-size:1.2em;font-weight:bold;">0</span> / <span id="joubika-max">0</span>
          <input type="hidden" name="joubikaMax" value="$pc{joubikaMax}">
          <input type="hidden" name="joubikaRest" value="$pc{joubikaRest}">
          </td>

                </tr>
              </tbody>
            </table>
          </div>
        </details>
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
      
      <details class="box" id="history">
        <summary class="in-toc">セッション履歴</summary>
        @{[input 'historyNum','hidden']}
        <table class="edit-table line-tbody no-border-cells" id="history-table">
          <colgroup>
            <col>
            <col class="date">
            <col class="title">
            <col class="exp">
            <col class="apply">
            <col class="gm">
            <col class="member">
          </colgroup>
          <thead>
            <tr>
              <th></th>
              <th class="date">日付</th>
              <th class="title">セッション名</th>
              <th class="exp">経験点</th>
              <td class="apply">適用</td> <th class="gm">GM</th>
              <th class="member">参加者</th>
            </tr>
          </thead>
          <tbody id="history0-row">
            <tr>
              <td></td>
              <td></td>
              <td>キャラクター作成</td>
              <td class="exp" id="history0-exp">0</td>
              <td class="apply"><label><input type="checkbox" checked disabled><b>適用</b></label></td>
              <td></td>
              <td></td>
            </tr>
          </tbody>
HTML
foreach my $num ('TMPL', 1 .. $pc{historyNum}) {
  if($num eq 'TMPL'){ print '<template id="history-template">' }
print <<"HTML";
          <tbody id="history-row${num}">
            <tr>
              <td class="handle" rowspan="2"></td>
              <td class="date">@{[input("history${num}Date")]}</td>
              <td class="title">@{[input("history${num}Title")]}</td>
              <td class="exp">@{[input("history${num}Exp",'text','calcExp')]}</td>
              <td class="apply"><label>@{[input("history${num}Check", 'checkbox', 'calcExp', 'value="1"')]}<b>適用</b></label></td>
              <td class="gm">@{[input("history${num}Gm")]}</td>
              <td class="member">@{[input("history${num}Member")]}</td>
            </tr>
            <tr>
              <td colspan="6" class="left">@{[input("history${num}Note",'','','placeholder="備考"')]}</td>
            </tr>
HTML
  if($num eq 'TMPL'){ print '</template>' }
}
print <<"HTML";
          <tfoot id="history-foot">
            <tr>
              <td colspan="3" class="right">経験点合計</td>
              <td id="history-exp-total">0</td>
              <td colspan="3"></td>
            </tr>
          </tfoot>
        </table>
        <div class="add-del-button"><a onclick="addHistory()">▼</a><a onclick="delHistory()">▲</a></div>
      </details>

      <details class="box box-v-gap" id="skill-history">
        <summary class="in-toc">特技取得履歴</summary>
        <div id="skill-history-table-container"></div>
      </details>
      
<div class="box" id="exp-footer">
        <p>
        経験点[<b id="exp-total"></b>] - 
        ( ＣＬ[<b id="exp-used-level"></b>]
        + 汎用特技[<b id="exp-used-general-skills"></b>]
        + コネ[<b id="exp-used-connections"></b>]
        + 常備化P[<b id="exp-used-joubika"></b>]
        + 能力値[<b id="exp-used-stt"></b>]
        ) = 残り[<b id="exp-rest"></b>]点
        </p>

<input type="hidden" name="expUsedLevel" value="$pc{expUsedLevel}">
        <input type="hidden" name="expUsedGeneralSkills" value="$pc{expUsedGeneralSkills}">
        <input type="hidden" name="expUsedConnections" value="$pc{expUsedConnections}">
        <input type="hidden" name="expUsedJoubika" value="$pc{expUsedJoubika}">
        <input type="hidden" name="expUsedStt" value="$pc{expUsedStt}">
      </div>

      </section>
      
      @{[ chatPaletteForm ]}
      
      @{[ colorCostomForm ]}
      
      @{[ input 'birthTime','hidden' ]}
      <input type="hidden" name="id" value="$::in{id}">
    </form>
    @{[ deleteForm($mode) ]}
    </article>
HTML
# ヘルプ
print textRuleArea( '','「容姿・経歴・その他メモ」「履歴（自由記入）」「所持品」「収支履歴」' );

print <<"HTML";
  </main>
  <footer>
    <p class="notes">©FarEast Amusement Research Co.,Ltd.「メタリックガーディアンRPG」</p>
    <p class="copyright">©<a href="https://yutorize.2-d.jp">ゆとらいず工房</a>「ゆとシートⅡ」ver.${main::ver}　……の改造品</p>
  </footer>
  <datalist id="list-gender">
    <option value="男">
    <option value="女">
    <option value="その他">
    <option value="なし">
    <option value="不明">
    <option value="不詳">
  </datalist>
<datalist id="list-parts">
    <option value="乗機">
    <option value="主／近">
    <option value="副／近">
    <option value="特技／近">
    <option value="主／遠">
    <option value="副／遠">
    <option value="特技／遠">
    <option value="OP">
    <option value="その他">
    <option value="アシスト">
    <option value="特技">
    <option value="人間用武装">
    <option value="人間用防具">
  </datalist>
<datalist id="list-zokusei">
    <option value="斬">
    <option value="刺">
    <option value="殴">
    <option value="炎">
    <option value="氷">
    <option value="雷">
    <option value="光">
    <option value="闇">
    <option value="歌">
    <option value="神">
  </datalist>
  
<datalist id="list-target">
    <option value="自身">
    <option value="単体">
    <option value="単体☆">
    <option value="範囲X">
    <option value="範囲X(選択)">
    <option value="直線X">
    <option value="直線X(選択)">
    <option value="場面">
    <option value="場面(選択)">
    <option value="1スクウェア">
    <option value="RSX">
    <option value="放射X">
    <option value="放射X(選択)">
    <option value="X幅直線Y">
    <option value="X幅直線Y(選択)">
    <option value="突破">
    <option value="突破(選択)">
    <option value="本文">
  </datalist>
  <datalist id="list-costW">
    <option value="なし">
    <option value="0HP">
    <option value="0EN">
    <option value="0FP">
    <option value="弾数1">
    <option value="加護">
    <option value="捕縛">
    <option value="失速">
    <option value="本文">
  </datalist>
  <datalist id="list-costS">
    <option value="なし">
    <option value="0HP">
    <option value="0EN">
    <option value="0FP">
    <option value="弾数1">
    <option value="弾数1/1">
    <option value="弾数1/3">
    <option value="加護">
    <option value="捕縛">
    <option value="失速">
    <option value="放心">
    <option value="侵蝕3、マヒ">
    <option value="重圧、パワーダウン">
    <option value="本文">
  </datalist>
    <datalist id="list-category">
    <option value="－">
    <option value="自">
    <option value="選">
    <option value="ビ">
    <option value="ア">
    <option value="操">
    <option value="機">
    <option value="命">
    <option value="砲">
    <option value="特">
    <option value="ダ">
    <option value="防">
    <option value="回">
    <option value="増">
    <option value="ヴ">
    <option value="プ">
  </datalist>
  <datalist id="list-timing">
    <option value="－">
    <option value="常時">
    <option value="ムーブ">
    <option value="マイナー">
    <option value="メジャー">
    <option value="リアクション">
    <option value="セットアップ">
    <option value="イニシアチブ">
    <option value="クリンナップ">
    <option value="判定の直前">
    <option value="判定の直後">
    <option value="命中判定の直前">
    <option value="命中判定の直後">
    <option value="DRの直前">
    <option value="DRの直後">
    <option value="対象選択の直前">
    <option value="いつでも">
    <option value="合体中">
    <option value="《》">
    <option value="本文">
  </datalist>
  <datalist id="list-range">
    <option value="なし">
    <option value="0">
    <option value="0～X">
    <option value="1～X">
    <option value="A～X">
    <option value="装備">
    <option value="視界">
    <option value="本文">
  </datalist>
  <datalist id="list-size">
    <option value="SS">
    <option value="S">
    <option value="M">
    <option value="L">
    <option value="XL">
  </datalist>
  <datalist id="list-reqd">
    <option value="『MGR』P">
    <option value="『MGA』P">
    <option value="『RDB』P">
    <option value="『DGF』P">
    <option value="『SOF』P">
    <option value="『DOW』P">
    <option value="『MGE』P">
    <option value="『MGC』P">
    <option value="『MGS』P">
  </datalist>






  <datalist id="list-classes">
    @{[ option '', @linkage_class, @guardian_class ]}
  </datalist>


<script>

let skillDebounceTimer;
  // ディバウンス化された計算関数
  function calcSkillsDebounced() {
    clearTimeout(skillDebounceTimer); // 入力があるたびにタイマーをリセット
    skillDebounceTimer = setTimeout(calcSkills, 500); // 300ミリ秒（0.3秒）操作がなければ計算を実行
  }
  // 文字化けを修正し、MGR用の項目を追加した安全な変数定義
// 修正後
          let expUse = {
            'level'      : '$pc{expUsedLevel}' || 0,
            'skills'     : '$pc{expUsedGeneralSkills}' || 0,
            'connections': '$pc{expUsedConnections}' || 0,
            'joubika'    : '$pc{expUsedJoubika}' || 0,
            'stt'        : '$pc{expUsedStt}' || 0
          };

          // 2. data-class.pl から読み込んだクラスデータの展開
  // Perlのハッシュ %data::class を JSON に変換して JSの mgrClasses に代入します
  
  const mgrClasses = @{[ JSON::PP->new->utf8(0)->canonical->encode(\%data::class) ]};
@{[ &commonJSVariable ]}
</script>

</body>
</html>
HTML

1;