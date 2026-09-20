############# フォーム・キャラクター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'signatures';
no warnings 'experimental::signatures';

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
require $set::lib_palette_sub;
### 各種データライブラリ読み込み --------------------------------------------------
require $set::data_syndrome;
require $set::data_class;
my @awakens;
my @impulses;
push(@awakens , @$_[0]) foreach(@data::awakens);
push(@impulses, @$_[0]) foreach(@data::impulses);

### データ読み込み ###################################################################################
my ($data, $file, $message) = loadSheetData();
our %pc = %{ $data };

our $isNewSheet = isNewSheet();

### 出力準備 #########################################################################################
$message = applyMessageName($message, $pc{characterName} || $pc{aka} || '無題');

### 初期設定 --------------------------------------------------
if($isNewSheet){
  $pc{playerName} = (getPlayerName($LOGIN_ID))[0];
  $pc{protect} ||= $LOGIN_ID ? 'account' : 'password';
}

if($::mode eq 'edit' || ($::mode =~ /^(?:convert|copy)$/ && $pc{ver})){
  %pc = upgradeCharaData(\%pc);
  if($pc{updateMessage}){
    $message .= "<hr>" if $message;
    $message .= "<h2>アップデート通知</h2><dl>";
    foreach (sort keys %{$pc{updateMessage}}){
      $message .= '<dt>'.$_.'</dt><dd>'.$pc{updateMessage}{$_}.'</dd>';
    }
    $message .= "</dl><small>前回保存時のバージョン:$pc{lasttimever}</small>";
  }
}
elsif($::mode eq 'blanksheet'){
  $pc{group} = $set::group_default;

  $pc{history0Income}   = 200;
  $pc{level}         = 2;

  $pc{originNum}     = 1; # オリジン
  $pc{adeptNum}      = 1; # アデプト
  $pc{fairyNum}      = 1; # 妖精／神
  $pc{connectionNum} = 1; # 人脈
  $pc{powerNum}      = 2; # パワー
  $pc{weapon1CustomNum}      = 1;
  $pc{weapon2CustomNum}      = 1;

  $pc{paletteUseBuff} = 1;

  %pc = applyCustomizedInitialValues(\%pc);
}

## 画像・セリフ位置
setDefaultImageStyle(\%pc);
setDefaultWordsPosition(\%pc);

## カラー
setDefaultColors(\%pc);

## その他

$pc{skillRideNum} ||= 2;
$pc{skillArtNum}  ||= 2;
$pc{skillKnowNum} ||= 2;
$pc{skillInfoNum} ||= 2;
$pc{effectNum}  ||= 5;
$pc{magicNum}   ||= 2;
$pc{weaponNum}  ||= 2;
$pc{armorNum}   ||= 1;
$pc{wearNum}    ||= 2;
$pc{itemNum}    ||= 2;
$pc{historyNum} ||= 3;

### 折り畳み判断 --------------------------------------------------
my %open;

# パワーに1つでも入力があれば開く
foreach (1..$pc{powerNum}){ if(existsRow "power$_",'Name','Type','Price'){ $open{power} = 'open'; last; } }

# 武器、ウェア、アイテムのどれかに入力があれば「アイテム」の枠を開く
foreach (1..$pc{weaponNum}){ if(existsRow "weapon$_",'Name','Range','Damage'){ $open{weapon} = 'open'; last; } }
foreach (1..$pc{wearNum}){ if(existsRow "wear$_",'Name','Type','Price'){ $open{wear} = 'open'; last; } }
foreach (1..$pc{itemNum}){ if(existsRow "item$_",'Name','Type','Price'){ $open{item} = 'open'; last; } }

# コネクションに入力があれば開く
foreach (1..$pc{connectionNum}){ if(existsRow "connection$_",'Name','Type'){ $open{connection} = 'open'; last; } }


### 改行処理 --------------------------------------------------
# ゆとシート2.0の機能を利用して改行タグへの変換を共通化します
convertEscapedBrToNewlines(\%pc,
  qw/freeNote freeHistory chatPalette bodyArrange/,
  ( map { 'words'.$_ } '', 2 .. ($set::image_maxcount || 1) ),
  ( map { "combo${_}Note"   } 1..$pc{comboNum} ),
  ( map { "weapon${_}Note"  } 1..$pc{weaponNum} ),
  ( map { "armor${_}Note"   } 1..$pc{armorNum} ),
  ( map { "vehicle${_}Note" } 1..$pc{vehicleNum} ),
  ( map { "item${_}Note"    } 1..$pc{itemNum} ),
);

### フォーム表示 #####################################################################################
print renderEditPageStart(
  title => (removeTags removeRuby unescapeTags ($pc{characterName} || qq|“$pc{aka}”|)),
);

print renderEditHeaderMenu(
  tabsHtml => <<~'HTML',
    <li onclick="sectionSelect('common');" class="sheet-main"><span>キャラ<span class="shorten">クター</span></span><span>データ</span>
    <li onclick="sectionSelect('palette');" class="unit-setting"><span><span class="shorten">ユニット(</span>コマ<span class="shorten">)</span></span><span>設定</span>
  HTML
);

print qq|<aside class="message">$message</aside>| if $message;


## 旧コード◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆
### コンボ欄用選択肢 --------------------------------------------------
my @setComboSkills = qw/― 白兵 射撃 RC 交渉 回避 知覚 意志 調達/;
foreach my $id ('Ride','Art','Know','Info'){
  foreach my $num (1 .. $pc{'skill'.$id.'Num'}){
    push(@setComboSkills, $pc{'skill'.$id.$num.'Name'}) if $pc{'skill'.$id.$num.'Name'};
  }
}
push(@setComboSkills, '解説参照');
 
my @setComboStatus = qw/DEF==>自動（技能に合った能力値） LABEL=▼エフェクト等による差し替え 肉体 感覚 精神 社会/;
## 旧コード◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆◆





print <<"HTML";
  <section id="section-common">
    @{[ renderProtectBlock() ]}
    @{[ renderVisibilityBlock() ]}
    <div class="box" id="group">
      <dl>
        <dt>グループ
        <dd><select name="group">@{[ renderGroupOptions ]}</select>
        <dt>タグ
        <dd>@{[ input 'tags' ]}
      </dl>
    </div>

    <div class="box in-toc" id="name-form" data-content-title="キャラクター名・プレイヤー名">
      <div>
        <dl id="character-name">
          <dt>キャラクター名
          <dd>@{[ input 'characterName','text',"setName",'id="main-name"' ]}
          <dt class="ruby">ふりがな
          <dd>@{[ input 'characterNameRuby','text',"setName" ]}
        </dl>
        <dl id="aka">
          <dt>ハンターネーム
          <dd>@{[ input 'aka','text',"setName" ]}
          <dt class="ruby">フリガナ
          <dd>@{[ input 'akaRuby','text',"setName" ]}
        </dl>
      </div>
      <dl id="player-name">
        <dt>プレイヤー名
        <dd>@{[ input 'playerName' ]}
      </dl>
    </div>

    <details class="box" id="regulation" @{[$::mode eq 'edit' ? '':'open']}>
      <summary class="in-toc">作成レギュレーション</summary>
      <dl>
        <dt>作成方法
        <dd>
          <label>@{[ input "isAmateur", 'checkbox', 'calcRegulation()' ]} アマチュア</label> 
          <label>@{[ input "noAdept", 'checkbox', 'calcRegulation()' ]} アデプトなし</label>
        <dt>初期クレジット
        <dd>
          @{[ input "initialCredit", 'number', 'syncCredit', ($set::make_fix?' readonly':'') ]}
          <input type="hidden" name="history0Income" value="$pc{history0Income}">
          <span id="credit-penalty-view" style="color: #e70; font-weight: bold; margin-left: 0.5em;"></span>
        <dt>初期借金
        <dd style="width: 7em;">
          @{[ input 'debt','number','calcDebt','placeholder="0"' ]}
        <dt>備考
        <dd>@{[ input "history0Note" ]}
      </dl>
      <ul class="annotate">
        <li>初期クレジットは「初期取得する武器」を50クレジットとして計算しているため200がデフォルトになっています。<br>このため、1本目の武器の取得にも50クレジット消費されますが、正常な挙動ですのでご安心ください。
        <li>初期借金に記入した金額は初期状態で使用可能なクレジットに含まれます。以降新たにする借金は「収入」として処理してください。また、返済は「支出」として行います。
      </ul>
    </details>

    <div id="area-status">
      @{[ renderImageForm() ]}

      <div class="box-union" id="personal">
        <dl class="box"><dt>年齢  <dd>@{[ input 'age' ]}</dl>
        <dl class="box"><dt>性別  <dd>@{[ input 'gender','','','list="list-gender"' ]}</dl>
        <dl class="box"><dt>身長  <dd>@{[ input 'height' ]}</dl>
        <dl class="box"><dt>体重  <dd>@{[ input 'weight' ]}</dl>
      </div>

      <div class="box-union" id="personal2">
        <dl class="box"><dt>レベル<dd>@{[ input 'level','number' ]}</dl>
        <dl class="box"><dt>属性  <dd>@{[ input 'attribute','','','list="list-element"' ]}</dl>
      </div>

      <div class="box-union" id="personal3">
        <dl class="box"><dt>衣装  <dd>@{[ input 'outfit','','','list="list-outfit"' ]}</dl>
        <dl class="box"><dt>住居  <dd>@{[ input 'housing','','','list="list-housing"' ]}</dl>
      </div>

      <div class="box-union" id="initial-values">
        <dl class="box">
          <dt>プライド</dt>
          <dd>
            <span id="pride-base-calc">8</span> + @{[ input 'prideBase', 'number' ]} ／ 16 + @{[ input 'prideMax', 'number' ]}
            <div class="penalty-wrap">
              金策等の一時的減少：@{[ input 'pridePenalty', 'number', 'calcInitialValues' ]}
            </div>
          </dd>
        </dl>
        <dl class="box">
          <dt>カルマ</dt>
          <dd>
            <span id="karma-base-calc">2</span> + @{[ input 'karmaBase', 'number' ]}
            <div class="penalty-wrap">
              金策等の一時的増加：@{[ input 'karmaPenalty', 'number', 'calcInitialValues' ]}
            </div>
          </dd>
        </dl>
      </div>

      <details class="box" id="permanent-bs" @{[$pc{permanentBs}?'open':'']}>
        <summary class="in-toc">永続BS</summary>
        @{[ input 'permanentBs', 'text', '', 'placeholder="未記入の場合は非表示"' ]}
      </details>

<details class="box" id="origin-adept-section" open>
        <summary class="in-toc">オリジン／アデプト</summary>
        
        @{[ do {
          our @origin_keys;
          for (my $i = 0; $i < @data::origin; $i += 2) { push(@origin_keys, $data::origin[$i]); }
          our @adept_keys;
          for (my $i = 0; $i < @data::adept; $i += 2) { push(@adept_keys, $data::adept[$i]); }
          '';
        } ]}

        <table class="edit-table no-border-cells" id="origin-table">
          <thead><tr><th><th>オリジン<th>パワー系統<th>事情<th>備考</tr></thead>
          @{[ renderTemplateLoop(
            'origin',
            sub ($num) {
              my @origin_reasons;
              if($pc{"origin${num}Name"}) {
                for (my $i = 0; $i < @data::origin; $i += 2) {
                  if ($data::origin[$i] eq $pc{"origin${num}Name"}) {
                    my $ref = $data::origin[$i+1];
                    @origin_reasons = ref($ref) eq 'ARRAY' ? @$ref : ();
                    last;
                  }
                }
              }
              return <<~"ROW";
              <tbody id="origin-row${num}">
                <tr>
                  <td class="handle">
                  <td>@{[ selectInput "origin${num}Name", "updateOriginDropdown(this, '$num')", @main::origin_keys ]}
                  <td>@{[ selectInput "origin${num}PowerLineage", "", @data::powers ]}
                  <td>@{[ selectInput "origin${num}Reason", "", @origin_reasons ]}
                  <td>@{[ input "origin${num}Note", 'text', '', 'placeholder="備考"' ]}
                </tr>
              </tbody>
              ROW
            }
          ) ]}
        </table>
        @{[ renderAddDelButtons('origin') ]}

        <hr style="border-top: 1px dashed var(--box-border); margin: 15px 0;">

        <table class="edit-table no-border-cells" id="adept-table">
          <thead><tr><th><th>アデプト<th>パワー系統<th>経歴<th>備考</tr></thead>
          @{[ renderTemplateLoop(
            'adept',
            sub ($num) {
              my @adept_reasons;
              if($pc{"adept${num}Name"}) {
                for (my $i = 0; $i < @data::adept; $i += 2) {
                  if ($data::adept[$i] eq $pc{"adept${num}Name"}) {
                    my $ref = $data::adept[$i+1];
                    @adept_reasons = ref($ref) eq 'ARRAY' ? @$ref : ();
                    last;
                  }
                }
              }
              return <<~"ROW";
              <tbody id="adept-row${num}">
                <tr>
                  <td class="handle">
                  <td>@{[ selectInput "adept${num}Name", "updateAdeptDropdown(this, '$num')", @main::adept_keys ]}
                  <td>@{[ selectInput "adept${num}PowerLineage", "", @data::powers ]}
                  <td>@{[ selectInput "adept${num}Reason", "", @adept_reasons ]}
                  <td>@{[ input "adept${num}Note", 'text', '', 'placeholder="備考"' ]}
                </tr>
              </tbody>
              ROW
            }
          ) ]}
        </table>
        @{[ renderAddDelButtons('adept') ]}

        <hr style="border-top: 1px dashed var(--box-border); margin: 15px 0;">

        <div style="margin-top: 10px;">
          <table class="edit-table no-border-cells" id="fairy-table">
            <thead><tr><th><th>妖精／神／獣<th>性質<th>備考</tr></thead>
            @{[ renderTemplateLoop(
              'fairy',
              sub ($num) {
                return <<~"ROW";
                <tbody id="fairy-row${num}">
                  <tr>
                    <td class="handle">
                    <td>@{[ input "fairy${num}NameText", 'text', '', 'placeholder="名称"' ]}
                    <td>@{[ input "fairy${num}Feature", 'text', '', 'placeholder="性質"' ]}
                    <td>@{[ input "fairy${num}Note", 'text', '', 'placeholder="備考"' ]}
                  </tr>
                </tbody>
                ROW
              }
            ) ]}
          </table>
          @{[ renderAddDelButtons('fairy') ]}
        </div>

        <hr style="border-top: 1px dashed var(--box-border); margin: 15px 0;">

        <div style="margin-top: 10px;">
          <dl class="box" style="display: flex; align-items: center; gap: 10px; border: none; padding: 0;">
            <dt style="font-weight: bold; min-width: 120px;">追加のパワー系統</dt>
            <dd style="flex-grow: 1;">@{[ input "additionalPowerLineage", 'text', '', 'placeholder="《アウェイクン》の《エキスパート》等で増加した時に使用" list="list-powers"' ]}</dd>
          </dl>
        </div>
      </details>

<details class="box" id="lifestyle" open>
        <summary class="in-toc">ライフスタイル</summary>
        <table class="edit-table line-tbody">
          <tbody>
            <tr>
              <th>弱点
              <td>@{[ input "lifestyleWeakness", 'text', '', 'placeholder="弱点"' ]}
              <td class="left">@{[ input "lifestyleWeaknessNote", 'text', '', 'placeholder="備考"' ]}
          <tbody>
            <tr>
              <th>趣味
              <td>@{[ input "lifestyleHobby", 'text', '', 'placeholder="趣味"' ]}
              <td class="left">@{[ input "lifestyleHobbyNote", 'text', '', 'placeholder="備考"' ]}
          <tbody>
            <tr>
              <th>モチベ
              <td>@{[ input "lifestyleMotivation", 'text', '', 'placeholder="モチベーション"' ]}
              <td class="left">@{[ input "lifestyleMotivationNote", 'text', '', 'placeholder="備考"' ]}
        </table>
        <ul class="annotate">
          <li>ライフスタイルは未入力時は非表示、備考未入力時は簡易表示となります。全年齢版のご利用時にご活用ください。
        </ul>
      </details>

      <details class="box" id="body-arrange" @{[$pc{bodyArrange}?'open':'']}>
        <summary class="in-toc">ボディアレンジ</summary>
        <textarea name="bodyArrange" placeholder="大量に記入する場合はその他メモ欄の利用を推奨します">$pc{bodyArrange}</textarea>
      </details>



      







    </div>


          <details class="box" id="connection" $open{connection}>
        <summary class="in-toc">人脈</summary>
        <div>
          <table class="edit-table no-border-cells" id="connection-table">
            <thead>
              <tr><th><th>NPC名<th>タイプ<th>関係<th>備考</tr></thead>
            @{[ renderTemplateLoop(
              'connection',
              sub ($num) {
                return <<~"ROW";
                <tbody id="connection-row${num}">
                  <tr>
                    <td class="handle">
                    <td>@{[ input "connection${num}Name", 'text', '', 'placeholder="NPC名"' ]}
                    <td>@{[ input "connection${num}Type", '', '', 'placeholder="タイプ" list="list-conetype"' ]}
                    <td>@{[ input "connection${num}Relation", 'text', '', 'placeholder="関係"' ]}
                    <td>@{[ input "connection${num}Note", 'text', '', 'placeholder="備考"' ]}
                  </tr>
                </tbody>
                ROW
              }
            ) ]}
          </table>
        </div>
        @{[ renderAddDelButtons('connection') ]}
      </details>


      <details class="box" id="power" $open{power}>
        <summary class="in-toc" data-content-title="パワー">パワー</summary>
        <div>
          <table class="edit-table line-tbody no-border-cells" id="power-table">
            <thead id="power-head">
              <tr><th><th>名称<th>タイプ<th><th>参照
            @{[ renderTemplateLoop(
              'power',
              sub ($num) {
                return <<~"ROW";
                <tbody id="power-row${num}" data-origin="power">
                  <tr>
                    <td rowspan="2" class="handle"> 
                    <td>@{[ input "power${num}Name",'','','placeholder="名称"' ]}
                    <td class="type-col">@{[ input "power${num}Type",'','','placeholder="タイプ" list="list-type"' ]}
                    <td class="price-col">@{[ input "power${num}Price",'number','','placeholder="価格" list="list-price"' ]}
                    <td class="maint-col">@{[ input "power${num}Maint",'number','','placeholder="維持費" list="list-maint"' ]}
                    <td>@{[ input "power${num}Ref",'','','placeholder="参照" list="list-reference"' ]}
                  <tr><td colspan="5">
                    <div>
                      <label class="used-label"><b>使用済</b> @{[ input "power${num}Used", 'checkbox' ]}</label>
                      <span class="cat-wrapper"><b>取得元</b>@{[ input "power${num}Source",'','','placeholder="取得元" list="list-powers"' ]}</span>
                      <b>効果</b>@{[ input "power${num}Note",'','','placeholder="効果"' ]}
                    </div>
                </tbody>
                ROW
              }
            ) ]}
            <tfoot id="power-foot">
              <tr><th><th>名称<th>タイプ<th><th>参照
          </table>
        </div>
        @{[ renderAddDelButtons('power') ]}
      </details>

      <details class="box" id="weapon" $open{weapon}>
        <summary class="in-toc" data-content-title="武器">武器 [<span id="exp-weapon">0</span>]</summary>
        <div>
          <table class="edit-table line-tbody no-border-cells" id="weapon-table">
            <thead id="weapon-head">
              <tr><th><th>名称<th>射程<th>ダメージ<th>補記<th>維持費<th>参照
            @{[ renderTemplateLoop(
              'weapon',
              sub ($num) {
                my $customHtml = renderTemplateLoop(
                  { id => "weapon${num}-custom", numKey => "weapon${num}CustomNum" },
                  sub ($c_num) {
                    return <<~"C_ROW";
                    <tbody id="weapon${num}Custom-row${c_num}" data-origin="weaponCustom">
                      <tr>
                        <td rowspan="2" class="handle custom-handle">
                        <td>@{[ input "weapon${num}Custom${c_num}Name",'','','placeholder="カスタマイズ名"' ]}
                        <td class="type-col">@{[ input "weapon${num}Custom${c_num}Type",'','','placeholder="タイプ"' ]}
                        <td class="price-col">@{[ input "weapon${num}Custom${c_num}Price",'number','calcWeapon','placeholder="価格" list="list-price"' ]}
                        <td class="maint-col">@{[ input "weapon${num}Custom${c_num}Maint",'number','','placeholder="維持費" readonly tabindex="-1"' ]}
                        <td>@{[ input "weapon${num}Custom${c_num}Ref",'','','placeholder="参照" list="list-reference"' ]}
                      <tr><td colspan="5">
                        <div>
                          <label class="used-label"><b>使用済</b> @{[ input "weapon${num}Custom${c_num}Used", 'checkbox' ]}</label>
                          <span class="cat-wrapper"><b>カテゴリ</b>@{[ input "weapon${num}Custom${c_num}Category",'','','placeholder="カテゴリ"' ]}</span>
                          <b>効果</b>@{[ input "weapon${num}Custom${c_num}Note",'','','placeholder="効果"' ]}
                        </div>
                    </tbody>
                    C_ROW
                  }
                );
                return <<~"ROW";
                <tbody id="weapon-row${num}">
                  <tr>
                    <td rowspan="2" class="handle"> 
                    <td>@{[ input "weapon${num}Name",'','calcWeapon','placeholder="名称" list="list-weapon"' ]}
                    <td>@{[ input "weapon${num}Range",'','','placeholder="射程" list="list-range"' ]}
                    <td>@{[ input "weapon${num}Damage",'','','placeholder="ダメージ" list="list-damage"' ]}
                    <td>@{[ input "weapon${num}Note",'','','placeholder="補記" list="list-weponnote"' ]}
                    <td>@{[ input "weapon${num}Maint",'number','calcWeapon','placeholder="維持費" list="list-maint"' ]}
                    <td>@{[ input "weapon${num}Ref",'','','placeholder="参照" list="list-reference"' ]}
                  <tr class="custom-row-container">
                    <td colspan="6" class="custom-cell">
                      <table class="edit-table line-tbody no-border-cells custom-table" id="weapon${num}-custom-table">
                        <thead>
                          <tr><th><th>カスタマイズ名<th><th>価格<th>維持費<th>参照
                        </thead>
                        $customHtml
                      </table>
                      <div class="add-del-button">
                        @{[ input "weapon${num}CustomNum", 'hidden' ]}
                        <a onclick="addWeaponCustom(this)">▼</a><a onclick="delWeaponCustom(this)">▲</a>
                      </div>
                    </td>
                  </tr>
                </tbody>
                ROW
              }
            ) ]}
            <tfoot id="weapon-foot">
              <tr><th><th>名称<th>射程<th>ダメージ<th>補記<th>維持費<th>参照
          </table>
        </div>
        @{[ renderAddDelButtons('weapon') ]}
      </details>

      <!--<div class="box trash-box" id="weapon-trash">
        <h2><span class="material-symbols-outlined">delete</span><span class="shorten">削除武器</span></h2>
        <table class="edit-table line-tbody" id="weapon-trash-table"></table>
        <i class="material-symbols-outlined close-button" onclick="document.getElementById('weapon-trash').style.display = 'none';">close</i>
      </div>-->

      <details class="box" id="wear" $open{wear}>
        <summary class="in-toc" data-content-title="ウェア">ウェア [<span id="exp-wear">0</span>]</summary>
        <div>
          <table class="edit-table line-tbody no-border-cells" id="wear-table">
            <thead id="wear-head">
              <tr><th><th>名称<th><th>価格<th>維持費<th>参照
            @{[ renderTemplateLoop(
              'wear',
              sub ($num) {
                return <<~"ROW";
                <tbody id="wear-row${num}" data-origin="wear">
                  <tr>
                    <td rowspan="2" class="handle"> 
                    <td>@{[ input "wear${num}Name",'','','placeholder="名称"' ]}
                    <td class="type-col">@{[ input "wear${num}Type",'','','placeholder="タイプ"' ]}
                    <td class="price-col">@{[ input "wear${num}Price",'number','calcWear','placeholder="価格" list="list-price"' ]}
                    <td class="maint-col">@{[ input "wear${num}Maint",'number','','placeholder="維持費" readonly tabindex="-1"' ]}
                    <td>@{[ input "wear${num}Ref",'','','placeholder="参照" list="list-reference"' ]}
                  <tr><td colspan="5">
                    <div>
                      <label class="used-label"><b>使用済</b> @{[ input "wear${num}Used", 'checkbox' ]}</label>
                      <span class="cat-wrapper"><b>カテゴリ</b>@{[ input "wear${num}Category",'','','placeholder="カテゴリ" list="list-category"' ]}</span>
                      <b>効果</b>@{[ input "wear${num}Note",'','','placeholder="効果"' ]}
                    </div>
                </tbody>
                ROW
              }
            ) ]}
            <tfoot id="wear-foot">
              <tr><th><th>名称<th><th>価格<th>維持費<th>参照
          </table>
        </div>
        @{[ renderAddDelButtons('wear') ]}
      </details>

      <details class="box" id="item" $open{item}>
        <summary class="in-toc" data-content-title="アイテム">アイテム [<span id="exp-item">0</span>]</summary>
        <div>
          <table class="edit-table line-tbody no-border-cells" id="item-table">
            <thead id="item-head">
              <tr><th><th>名称<th><th>価格<th><th>参照
            @{[ renderTemplateLoop(
              'item',
              sub ($num) {
                return <<~"ROW";
                <tbody id="item-row${num}" data-origin="item">
                  <tr>
                    <td rowspan="2" class="handle"> 
                    <td>@{[ input "item${num}Name",'','','placeholder="名称"' ]}
                    <td class="type-col">@{[ input "item${num}Type",'','','placeholder="タイプ"' ]}
                    <td class="price-col">@{[ input "item${num}Price",'number','calcItem','placeholder="価格" list="list-price"' ]}
                    <td class="maint-col">@{[ input "item${num}Maint",'number','','placeholder="維持費"' ]}
                    <td>@{[ input "item${num}Ref",'','','placeholder="参照" list="list-reference"' ]}
                  <tr><td colspan="5">
                    <div>
                      <label class="used-label" style="cursor: pointer;"><b>使用済</b> @{[ input "item${num}Used", 'checkbox' ]}</label>
                      <span class="cat-wrapper"><b>カテゴリ</b>@{[ input "item${num}Category",'','','placeholder="カテゴリ"' ]}</span>
                      <b>効果</b>@{[ input "item${num}Note",'','','placeholder="効果"' ]}
                    </div>
                </tbody>
                ROW
              }
            ) ]}
            <tfoot id="item-foot">
              <tr><th><th>名称<th><th>価格<th><th>参照
          </table>
        </div>
        @{[ renderAddDelButtons('item') ]}
      </details>

      <div class="box trash-box" id="shared-trash" style="display:none;">
        <h2><span class="material-symbols-outlined">delete</span><span class="共通ゴミ箱">共通ゴミ箱</span></h2>
        <table class="edit-table line-tbody no-border-cells custom-table" id="shared-trash-table"></table>
        <i class="material-symbols-outlined close-button" onclick="document.getElementById('shared-trash').style.display = 'none';">close</i>
      </div>


    <details class="box" id="free-note" @{[$pc{freeNote}?'open':'']}>
      <summary class="in-toc">容姿・経歴・その他メモ</summary>
      <textarea name="freeNote">$pc{freeNote}</textarea>
      @{[ ($::in{log} || $::in{overwrite}) ? '<button type="button" class="set-newest" onclick="setNewestSingleData(\'freeNote\')">最新のメモを適用する</button>' : '' ]}
    </details>

    <details class="box" id="free-history" @{[$pc{freeHistory}?'open':'']}>
      <summary class="in-toc">履歴（自由記入）</summary>
      <textarea name="freeHistory">$pc{freeHistory}</textarea>
      @{[ ($::in{log} || $::in{overwrite}) ? '<button type="button" class="set-newest" onclick="setNewestSingleData(\'freeHistory\')">最新の履歴（自由記入）を適用する</button>' : '' ]}
    </details>
<div class="box" id="history">
        <h2 class="in-toc">セッション履歴</h2>
        <table class="edit-table line-tbody no-border-cells" id="history-table">
          <colgroup id="history-col">
            <col>
            <col class="date  ">
            <col class="title ">
            <col class="income">
            <col class="expense">
            <col class="debt  ">
            <col class="gm    ">
            <col class="member">
          </colgroup>
          <thead id="history-head">
            <tr>
              <th>
              <th>日付
              <th>タイトル
              <th>収入
              <th>支出
              <th>借金増減
              <th>GM
              <th>参加者
            </tr>
            <tr>
              <td>-
              <td>
              <td>キャラクター作成
              <td id="history0-income">$pc{history0Income}
              <td id="history0-expense">$pc{history0expense}
              <td id="history0-dept">$pc{history0debt}
              <td>
              <td>
            </tr>
          </thead>
          @{[ renderTemplateLoop(
            'history',
            sub ($num) {
              return <<~"ROW";
              <tbody id="history-row${num}">
                <tr>
                  <td class="handle" rowspan="2">
                  <td class="date  " rowspan="2">@{[ input "history${num}Date" ]}
                  <td class="title " rowspan="2">@{[ input "history${num}Title" ]}
                  <td class="income  ">@{[ input "history${num}Income",'text','calcCredit','placeholder="収入"' ]}
                  <td class="expense ">@{[ input "history${num}Expense",'text','calcCredit','placeholder="支出"' ]}
                  <td class="debt    ">@{[ input "history${num}Debt",'text','calcDebt','placeholder="借金増減"' ]}
                  <td class="gm    ">@{[ input "history${num}Gm" ]}
                  <td class="member">@{[ input "history${num}Member" ]}
                </tr>
                <tr>
                  <td colspan="5" class="left">@{[ input "history${num}Note",'','','placeholder="備考"' ]}
                </tr>
              </tbody>
              ROW
            }
          ) ]}
          <tfoot id="history-foot">
            <tr><th></th><th>日付</th><th>タイトル</th><th>収入</th><th>支出</th><th>借金増減</th><th>GM</th><th>参加者</th></tr>
          </tfoot>
        </table>
        @{[ renderAddDelButtons('history') ]}

        <h2>記入例</h2>
        <table class="example edit-table line-tbody no-border-cells">
          <colgroup>
            <col>
            <col class="date  ">
            <col class="title ">
            <col class="income">
            <col class="expense">
            <col class="debt  ">
            <col class="gm    ">
            <col class="member">
          </colgroup>
          <thead>
            <tr>
              <th>
              <th>日付
              <th>タイトル
              <th>収入
              <th>支出
              <th>借金増減
              <th>GM
              <th>参加者
            </tr>
          </thead>
          <tbody>
            <tr>
              <td rowspan="2">-
              <td rowspan="2"><input type="text" value="2021/07/04" disabled>
              <td rowspan="2"><input type="text" value="HUNTING GAME" disabled>
              <td><input type="text" value="150" disabled>
              <td><input type="text" value="40+10+20+50" disabled>
              <td><input type="text" value="-50" disabled>
              <td class="gm"><input type="text" value="サンプルGM" disabled>
              <td class="member"><input type="text" value="ディスプレイサー" disabled>
            </tr>
            <tr>
              <td colspan="5" class="left"><input type="text" value="アッパードラッグ、ダウナードラッグ再購入で20クレジット消費。借金を50クレジット返済。" disabled>
            </tr>
          </tbody>
        </table>
        <ul class="annotate">
          <li>クレジット欄は<code>10+5+1</code>など四則演算が有効です（獲得条件の違う収入などを分けて書けます）。
          <li>収入欄には維持費などを引く前のセッションで得られた報酬を入れます。<br>新たに借金をしてクレジットが増える場合もここに入れます。   
          <li>支出欄には維持費、利子、アイテムの再購入、借金の返済のために消費したクレジットを入れます。
          <li>借金増減欄は所持金に影響を及ぼすことはありません。<br>借金によるクレジット獲得は収入に、返済によるクレジット消費は支出に記入してください。
        </ul>
        @{[ ($::in{log} || $::in{overwrite}) ? '<button type="button" class="set-newest" onclick="setNewestHistoryData()">最新のセッション履歴を適用する</button>' : '' ]}
      </div>
<div class="box" id="exp-footer">
        <p>
        総収入[<b id="credit-total">0</b>] + 初期借金[<b id="credit-debt">0</b>] - 
        (
          ( 武器[<b id="credit-used-weapon">0</b>]
          + カスタマイズ[<b id="credit-used-custom">0</b>]
          + ウェア[<b id="credit-used-wear">0</b>]
          + アイテム[<b id="credit-used-item">0</b>]
          )
          + 支出[<b id="credit-expense">0</b>]
        )
           = 残り[<b id="credit-rest">0</b>]クレジット
        </p>
        <p>
        借金合計[<b id="debt-total-view">0</b>]
           
        維持費[<b id="credit-maint">0</b>] = 
        ( レベル[<b id="level-maint">0</b>]
        + 武器[<b id="weapon-maint">0</b>]
        + カスタマイズ[<b id="custom-maint">0</b>]
        + ウェア[<b id="wear-maint">0</b>]
        )
        </p>
      </div>
  </section>
HTML
print renderChatPaletteForm();

print renderEditPageEnd(
  notes => '©ZQワークス「Ventangle」',
  extraHtml => renderDataList() . renderFooterScript(),
);
sub renderDataList {
  return <<~"HTML";
  <datalist id="list-gender">
    <option value="男">
    <option value="女">
    <option value="その他">
    <option value="なし">
    <option value="不明">
    <option value="不詳">
    <option value="元男">
    <option value="元女">
    <option value="両性">
    <option value="無性">
  </datalist>
  <datalist id="list-element">
    <option value="人">
    <option value="妖">
    <option value="人（妖）">
    <option value="人／モブ">
    <option value="妖／モブ">
  </datalist>
  <datalist id="list-conetype">
    <option value="恋人">
    <option value="荒事屋">
    <option value="情報屋">
    <option value="守り手">
    <option value="ツキモノ">
    <option value="パトロン">
    <option value="セラピー">
  </datalist>
  <datalist id="list-outfit">
    <option value="----- 一般的 -----">
    <option value="ボディスーツ">
    <option value="オーソドックス">
    <option value="ストリートスタイル">
    <option value="フォーマル">
    <option value="エッジパンク">
    <option value="アーミールック">
    <option value="----- 特殊 -----">
    <option value="アナクロドレス">
    <option value="ブギーパンク">
    <option value="ディバインコス">
    <option value="メタルスローン">
    <option value="ゴシックドレス">
    <option value="クレアブランド">
    <option value="----- 性的 -----">
    <option value="セクシャルアレンジ">
    <option value="フェチコス">
    <option value="ビザール">
    <option value="シースルー">
    <option value="オーバーワン">
    <option value="ビッチコーデ">
    <option value="-----『AL』追加 -----">
    <option value="ゴシックコーデ">
    <option value="バッドフォーマル">
    <option value="ジャンクバード">
    <option value="サイケドール">
    <option value="エキセントリック">
  </datalist>
  <datalist id="list-housing">
    <option value="----- 困窮 -----">
    <option value="特になし">
    <option value="居候">
    <option value="スラム">
    <option value="マイカー">
    <option value="アパート">
    <option value="廃棄施設">
    <option value="----- それなり -----">
    <option value="貸事務所">
    <option value="マンション">
    <option value="邸宅">
    <option value="店舗">
    <option value="豪邸">
    <option value="異界">
  </datalist>
  <datalist id="list-price">
    <option value="5">
    <option value="6">
    <option value="10">
    <option value="20">
    <option value="30">
    <option value="40">
    <option value="50">
    <option value="100">
    <option value="150">
    <option value="200">
  </datalist>
  <datalist id="list-reference">
    <option value="『基』P">
    <option value="『神』P">
    <option value="『殴』P">
    <option value="『AR』P">
  </datalist>
  <datalist id="list-type">
    <option value="スペル">
    <option value="ギフト">
    <option value="リチュアル">
  </datalist>
  <datalist id="list-powers">
    <option value="オリジン">
    <option value="アデプト">
    <option value="汎用">
    <option value="俗世">
    <option value="闘争">
    <option value="銃劇">
    <option value="死神">
    <option value="幻惑">
    <option value="淫魔">
    <option value="呪術">
    <option value="暗黒">
    <option value="祝福">
    <option value="混沌">
    <option value="技術">
    <option value="野獣">
    <option value="配信">
  </datalist>
  <datalist id="list-weapon">
    <option value="ブレード">
    <option value="マーシャルアーツ">
    <option value="ハンドガン">
    <option value="アサルトライフル">
    <option value="スナイパーライフル">
    <option value="マギタクト">
    <option value="スカージ">
    <option value="テンプテーション">
    <option value="アーティファクト">
    <option value="メタルスーツ">
    <option value="ボウ">
    <option value="フェロー">
    <option value="ヴィークル">
    <option value="VA：シュリケン">
    <option value="VA：サキュバスアーツ">
    <option value="VA：サブマシンガン">
    <option value="VA：ショットガン">
    <option value="VA：レールガン">
    <option value="VA：マギフィスト">
    <option value="VA：テンタクルアーツ">
    <option value="VA：メナス">
    <option value="VA：オフダ">
    <option value="VA：チャリオット">
    <option value="VA：ボウガン">
    <option value="VA：トループ">
    <option value="VA：スティード">
  </datalist>
  <datalist id="list-range">
    <option value="ゼロレンジ">
    <option value="ゼロ～ショートレンジ">
    <option value="ゼロ～ミドルレンジ">
    <option value="ショート～ミドルレンジ">
    <option value="ショート～ロングレンジ">
    <option value="ミドル～ロングレンジ">
    <option value="ミドル～アウトレンジ">
  </datalist>
  <datalist id="list-damage">
    <option value="「気絶」1">
    <option value="「気絶」2">
    <option value="「気絶」3">
    <option value="「気絶」4">
    <option value="「屈服」2">
    <option value="「魅了」2">
    <option value="「気絶か屈服」1">
    <option value="「気絶か魅了」1">
    <option value="「任意属性」2">
  </datalist>
  <datalist id="list-weponnote">
    <option value="スペシャル値－2、一体化">
    <option value="レンジプラス">
    <option value="一体化">
    <option value="銃、レンジプラス、戦闘音">
    <option value="銃、常用不可、レンジプラス、戦闘音">
    <option value="常用不可、戦闘音、制圧、一体化">
    <option value="戦闘音">
    <option value="対妖ダメージ＋2、レンジプラス、制圧">
  </datalist>
  <datalist id="list-maint">
    <option value="0">
    <option value="5">
    <option value="10">
    <option value="15">
  </datalist>
  <datalist id="list-category">
    <option value="ｻｲﾊﾞｰｳｪｱ">
    <option value="ﾏｷﾞｳｪｱ">
    <option value="ﾊﾞｲｵｳｪｱ">
    <option value="ﾅﾉｳｪｱ">
    <option value="性的ｱｲﾃﾑ">
  </datalist>
  HTML
}
sub renderFooterScript {
  my $html;
  $html .= '<script>';
  
  $html .= "const originData = {\n";
  for (my $i = 0; $i < @data::origin; $i += 2) {
    my $ref = $data::origin[$i+1];
    my @arr = ref($ref) eq 'ARRAY' ? @$ref : ();
    $html .= '"' . $data::origin[$i] . '": ["' . join('","', @arr) . '"],'."\n";
  }
  $html .= "};\n";

  $html .= "const adeptData = {\n";
  for (my $i = 0; $i < @data::adept; $i += 2) {
    my $ref = $data::adept[$i+1];
    my @arr = ref($ref) eq 'ARRAY' ? @$ref : ();
    $html .= '"' . $data::adept[$i] . '": ["' . join('","', @arr) . '"],'."\n";
  }
  $html .= "};\n";

  $html .= '</script>';

  return $html;
}

1;