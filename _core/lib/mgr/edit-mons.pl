############# フォーム・モンスター #############
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
require $set::data_mons;

### データ読み込み ###################################################################################
my ($data, $file, $message) = loadSheetData();
our %pc = %{ $data };

our $isNewSheet = isNewSheet();

### 出力準備 #########################################################################################
$message = applyMessageName($message, $pc{characterName} || $pc{monsterName} || '無題');
use JSON::PP;

# JSON変換ビルダーの初期化
# my $json_builder = JSON::PP->new->utf8;
my $json_builder = JSON::PP->new->ascii;

# %srs_system_mons と %srs_mons_skills をそれぞれ JSON 文字列に変換
my $srs_system_mons_json = $json_builder->encode(\%data::srs_system_mons);
my $srs_mons_skills_json = $json_builder->encode(\%data::srs_mons_skills);


### 初期設定 --------------------------------------------------
if($isNewSheet){
  $pc{author} = (getPlayerName($LOGIN_ID))[0];
  $pc{protect} ||= $LOGIN_ID ? 'account' : 'password';
}
if($::mode eq 'edit' || ($::mode =~ /^(?:convert|copy)$/ && $pc{ver})){
  %pc = upgradeMonsterData(\%pc);
}
elsif($::mode eq 'blanksheet'){
  $pc{paletteUseBuff} = 1;
  $pc{partsManualInput} = 0;

  %pc = applyCustomizedInitialValues(\%pc, 'm');
}

## カラー
setDefaultColors(\%pc);

## その他
$pc{partsNum}  ||= 1;
$pc{statusNum} ||= 1;
$pc{lootsNum}  ||= 2;

      $pc{baseNum}    ||= 2;
      $pc{sttNum}     ||= 6;
      $pc{battleNum}  ||= 8;
      $pc{defenseNum} ||= 9;
      $pc{attackRowNum} ||= 1;
      $pc{attackColNum} ||= 6;

my $status_text_input = $pc{statusTextInput} || $pc{mount} || 0;

### 改行処理 --------------------------------------------------
convertEscapedBrToNewlines(\%pc,
  qw/skills description chatPalette/,
);

### フォーム表示 #####################################################################################
print renderEditPageStart(
  title => (removeTags removeRuby unescapeTags ( $pc{characterName} || $pc{monsterName} )),
);

print <<"HTML";
<script>
  // Perl側で定義したシステムデータと特技データをJSの定数として保持
  const srsSystemsMons = $srs_system_mons_json;
  const srsMonsSkills  = $srs_mons_skills_json;
</script>
HTML

print renderEditHeaderMenu(
  tabsHtml => <<~'HTML',
    <li onclick="sectionSelect('common');" class="sheet-main"><span>魔物</span><span>データ</span>
    <li onclick="sectionSelect('palette');" class="unit-setting"><span><span class="shorten">ユニット(</span>コマ<span class="shorten">)</span></span><span>設定</span>
  HTML
);
print qq|<aside class="message">$message</aside>| if $message;


print <<"HTML";
  <section id="section-common">
    @{[ renderProtectBlock() ]}
    @{[ renderVisibilityBlock() ]}
    <div class="box in-toc" id="group" data-content-title="システム・分類・タグ">
      <dl>
        <dt>システム</dt>
        <dd>
          <div class="select-input">
            <select name="system" onchange="changeSystem();">
            @{[
              map { '<option '. ($pc{system} eq $_ ? ' selected': '') .">$_</option>" }
              sort { $data::srs_system_mons{$a}{sort} cmp $data::srs_system_mons{$b}{sort} }
              keys %data::srs_system_mons
            ]}
            <!-- ★辞書に存在しないシステム名だった場合、自動で「その他」を選択状態にする -->
            <option value="その他" @{[ ($pc{system} && !exists $data::srs_system_mons{$pc{system}}) ? 'selected' : '' ]}>その他</option>
            </select>
            <!-- ★辞書に存在しないシステム名だった場合、ここに入力値として復元して表示する -->
            <input type="text" name="systemFree" id="systemFree" 
                   value="@{[ ($pc{system} && !exists $data::srs_system_mons{$pc{system}}) ? $pc{system} : '' ]}" 
                   style="@{[ ($pc{system} && !exists $data::srs_system_mons{$pc{system}}) ? 'display: inline-block;' : 'display: none;' ]}" 
                   placeholder="任意のシステム名">
          </div>
        </dd>
      </dl>

      <dl>
        <dt>分類</dt>
        <dd>
          <!-- 分類本体のブロック（ここのみJSの表示切り替えの影響を受ける） -->
          <div class="select-input" style="display: inline-block;">
            <select name="taxa" id="taxa" data-saved-value="$pc{taxa}" onchange="selectInputCheck(this,'その他')">
            </select>
            <input type="text" name="taxaFree" id="taxaFree" placeholder="任意の分類名">
          </div>
          
          <!-- サブカテゴリのブロック（独立しているため常に表示される） -->
          <div class="sub-taxa-group">
            <!--<span style="font-size: 0.9em; font-weight: bold;">サブカテゴリ：</span>-->
            （
            <input type="text" name="subTaxa" value="$pc{subTaxa}" placeholder="例：カバリエ" style="width: 10em;">）
          </div>
        </dd>
      </dl>
      <dl>
        <dt>タグ</dt>
        <dd>@{[ input 'tags' ]}</dd>
      </dl>
    </div>

    <div class="box in-toc" id="name-form" data-content-title="名称・製作者">
      <div>
        <dl id="character-name">
          <dt>名称
          <dd>@{[ input 'monsterName','text',"setName",'id="sub-name"' ]}
        </dl>
        <dl id="aka">
          <dt>名前
          <dd>@{[ input 'characterName','text','setName','id="main-name" placeholder="※名前を持つ魔物のみ"' ]}
        </dl>
      </div>
      <dl id="player-name">
        <dt>製作者
        <dd>@{[ input 'author' ]}
      </dl>
    </div>

    <!--<div class="box status in-toc" data-content-title="基本データ">
      <dl class="mount-only price">
        <dt>価格
        <dd>購入@{[ input 'price' ]}G
        <dd>レンタル@{[ input 'priceRental' ]}G
        <dd>部位再生@{[ input 'priceRegenerate' ]}G
      </dl>
      <dl class="mount-only">
        <dt>適正レベル
        <dd>@{[ input 'lvMin','number','checkMountLevel','min="0"' ]} ～ @{[ input 'lvMax','number','checkMountLevel','min="0"' ]}
      </dl>
      <dl>
        <dt><span class="mount-only">騎獣</span>レベル
        <dd>@{[ input 'lv','number','checkLevel','min="0"' ]}
        <dd class="mount-only small">※入力すると、閲覧画面では現在の騎獣レベルのステータスのみ表示されます
      </dl>
      <dl>
        <dt>知能
        <dd>@{[ input 'intellect','','','list="data-intellect"' ]}
      </dl>
      <dl>
        <dt>知覚
        <dd>@{[ input 'perception','','','list="data-perception"' ]}
      </dl>
      <dl class="monster-only">
        <dt>反応
        <dd>@{[ input 'disposition','','','list="data-disposition"' ]}
      </dl>
      <dl>
        <dt>穢れ
        <dd>@{[ input 'sin','number','','min="0"' ]}
      </dl>
      <dl>
        <dt>言語
        <dd>@{[ input 'language','','','list="data-language"' ]}
      </dl>
      <dl class="monster-only">
        <dt>生息地
        <dd>@{[ input 'habitat' ]}
      </dl>
      <dl class="monster-only">
        <dt>知名度／弱点値
        <dd>@{[ input 'reputation' ]}／@{[ input 'reputation+','','','list="list-of-reputation-plus"' ]}
      </dl>
      <dl>
        <dt>弱点
        <dd>@{[ input 'weakness','','','list="data-weakness"' ]}
      </dl>
      <dl class="monster-only">
        <dt>先制値
        <dd>@{[ input 'initiative' ]}
      </dl>
      <dl>
        <dt>移動速度<dd>@{[ input 'mobility' ]}
      </dl>
      <dl class="monster-only">
        <dt>生命抵抗力
        <dd>@{[ input 'vitResist',($status_text_input ? 'text':'number'),'calcVit' ]} <span class=" calc-only">(@{[ input 'vitResistFix','number','calcVitF' ]})</span>
      </dl>
      <dl class="monster-only">
        <dt>精神抵抗力
        <dd>@{[ input 'mndResist',($status_text_input ? 'text':'number'),'calcMnd' ]} <span class=" calc-only">(@{[ input 'mndResistFix','number','calcMndF' ]})</span>
      </dl>
    </div>-->

    

    <div class="box status in-toc" data-content-title="基本データ・戦闘値">
      <div class="status-groups">
        <!-- 基礎部 -->
        <div class="status-section">
          <h4>基礎</h4>
          <ul id="base-list" class="status-grid">
          @{[ map {
            "<li id='base-item${_}' class='srs-status-input-row'><span class='handle'></span>".
            input("base${_}Name", 'text', '', 'class="header-input" placeholder="基礎"')." ： ".
            input("base${_}Value", 'text', '', 'class="value-input" placeholder="値"').
            "</li>"
          } 1 .. $pc{baseNum} ]}
          </ul>
          @{[ renderAddDelButtons('base') ]}
          @{[ input 'baseNum', 'hidden' ]}
        </div>

        <!-- 能力値 -->
        <div class="status-section">
          <h4>能力値</h4>
          <ul id="stt-list" class="status-grid">
          @{[ map {
            "<li id='stt-item${_}' class='srs-status-input-row'><span class='handle'></span>".
            input("stt${_}Name", 'text', '', 'class="header-input" placeholder="能力"')." ： ".
            input("stt${_}Value", 'text', '', 'class="value-input" placeholder="値"').
            "</li>"
          } 1 .. $pc{sttNum} ]}
          </ul>
          @{[ renderAddDelButtons('stt') ]}
          @{[ input 'sttNum', 'hidden' ]}
        </div>

        <!-- 戦闘値 -->
        <div class="status-section">
          <h4>戦闘値</h4>
          <ul id="battle-list" class="status-grid">
          @{[ map {
            "<li id='battle-item${_}' class='srs-status-input-row'><span class='handle'></span>".
            input("battle${_}Name", 'text', '', 'class="header-input" placeholder="戦闘値"')." ： ".
            input("battle${_}Value", 'text', '', 'class="value-input" placeholder="値"').
            "</li>"
          } 1 .. $pc{battleNum} ]}
          </ul>
          @{[ renderAddDelButtons('battle') ]}
          @{[ input 'battleNum', 'hidden' ]}
        </div>

        <!-- 防御修正 -->
        <div class="status-section">
          <h4>防御修正</h4>
          <ul id="defense-list" class="status-grid">
          @{[ map {
            "<li id='defense-item${_}' class='srs-status-input-row'><span class='handle'></span>".
            input("defense${_}Name", 'text', '', 'class="header-input" placeholder="防御"')." ： ".
            input("defense${_}Value", 'text', '', 'class="value-input" placeholder="値"').
            "</li>"
          } 1 .. $pc{defenseNum} ]}
          </ul>
          @{[ renderAddDelButtons('defense') ]}
          @{[ input 'defenseNum', 'hidden' ]}
        </div>
      </div>
    </div>


    <div class="box in-toc" data-content-title="攻撃方法">
      <table id="attack-table" class="status">
        <thead>
          <tr id="attack-head-row">
            <!-- 行ソート用のハンドル列 -->
            <th class=""></th>
            @{[ map {
              my $c = $_;
              "<th id='attack-head-col${c}'>".
              input("attackCol${c}Name", 'text', '', 'class="header-input" placeholder="見出し"').
              "</th>"
            } 1 .. $pc{attackColNum} ]}
          </tr>
        </thead>
        <tbody id="attack-tbody">
          @{[ map {
            my $r = $_;
            "<tr id='attack-row${r}'>\n" .
            "<td class='handle'></td>\n" .
            join("\n", map {
              my $c = $_;
              "<td class='attack-cell-col${c}'>".input("attackRow${r}Col${c}Value", 'text')."</td>"
            } 1 .. $pc{attackColNum}) .
            "\n</tr>"
          } 1 .. $pc{attackRowNum} ]}
        </tbody>
      </table>
      
      <!-- 行と列の増減ボタン -->
      <div class="attack-table-controls">
        <a onclick="addAttackRow()">▼ 行を追加</a>
        <a onclick="delAttackRow()">▲ 行を削除</a>
        <span style="display:inline-block; width: 2em;"></span>
        <a onclick="addAttackCol()">▶ 列を追加</a>
        <a onclick="delAttackCol()">◀ 列を削除</a>
      </div>
      @{[ input 'attackRowNum', 'hidden' ]}
      @{[ input 'attackColNum', 'hidden' ]}
    </div>


    

    <div class="box">
      <h2 class="in-toc">特技</h2>
      <textarea name="skills">$pc{skills}</textarea>
      <div class="annotate">
        <code>《》</code>で囲まれたものを特技（ないし加護等）と判定し、『DoW』『MGC』から特技サマリを自動抽出します。これは加護欄にも有効です。<br>
        <b>行頭に</b><code>◆</code>を置いて<code>《》</code>で囲まれたものは、詳細な解説が行われるものとしてサマリへの抽出がキャンセルされます。<br>
        <b>行頭に</b><code>>></code>を置いて<code>《》</code>で囲み、その後にテキストを続けたものは、『DoW』にないものでも固有の定義として特技サマリに登録されます。<br>
        ヴァレット用の準備はされていないため、ガーディアン特技とヴァレット用特技は自前でサマリを書いてください。<br>
        例：<code>>>《エターナルフォースブリザード》相手は死ぬ</code>
      </div>
    </div>
    <div id="extra-textarea-box" style="display: none;">
      @{[ map {
        my $num = $_;
        <<~"HTML";
        <div class="box extra-textarea-item" id="extra-textarea-${num}" style="display: none;">
          <h2 class="in-toc">
            @{[ input "extra${num}Name", 'text', '', 'class="header-input extra-area-header" placeholder="追加項目（加護など）" style="width: 100%; font-size: 1em;"' ]}
          </h2>
          <textarea name="extra${num}Text" class="extra-area">$pc{"extra${num}Text"}</textarea>
        </div>
        HTML
      } 1 .. 3 ]}
    </div>



    <div class="box">
      <h2 class="in-toc">解説</h2>
      <textarea name="description" class="memo-area">$pc{description}</textarea>
    </div>

    <!-- ⑤ テキスト解析・自動入力（仮設フォーム） -->
    <div class="box">
      <details>
        <!-- summaryタグがクリック可能な見出しになります -->
        <summary class="in-toc" style="cursor: pointer; font-size: 1.1em; font-weight: bold; outline: none;">
          テキスト解析・自動入力（β）
        </summary>
        <div style="margin-top: 1em;">
          <p class="annotate">
            ここにエネミーデータのテキストを貼り付けて「読み込み」ボタンを押すと、ステータスや特技などを自動的に解析して上書きします。<br>
            テキスト出力の形式を基準にして読み込んでいます。<br>
            ・「システム名」は省略可能です。<br>
            ・「種別」の後ろには分類などを置かないでください（レベルの右に置いてください）<br>
            ・能力値は能力値ボーナスまで一緒に記載していないと読み込めません。<br>
            ・戦闘値は各システム毎に合致したものじゃないと壊れます（悪い例：命　良い例：命中）<br>
            ・「特技」「加護」「解説」の後ろには「：」を挟まないでください、戦闘値扱いになります。また、即時改行して単品にしてください。<br>
            ・特技欄用特殊記号「◆」「>>」を解説欄に居れないでください、壊れます。<br>
            読み込みは結構雑なので、うまく読み込めない場合はテキスト出力を参考に整形して読み込んでください（表記揺れに弱いです）。
          </p>
          <!-- DB保存不要なため name 属性は持たせず id だけで管理します -->
          <textarea id="import-raw-text" style="height: 12em;" placeholder="システム名：メタリックガーディアンRPG\n\n超奈落神アドラ＝スティア\n種別：アビスガーディアン（フォートレス）\nレベル：1212 サイズ：XXL\n体力：15／＋5　反射：15／＋5　知覚：15／＋5\n理知：12／＋4　意志：14／＋4　幸運：15／＋5\n命中：13　　回避：60　　砲撃：110　　防壁：70\n移動：40 　　行動：60　　FP：2800 　　EN：1100\n防御修正：斬120／刺50／殴80／炎60／氷60／雷60\n\n主武装：ブレイズソード　攻撃力：〈炎〉+240　判定：白兵　C値：120　対象：単体　射程：0\n\n特技\n《☆BOSS属性》《瞬発行動10》《特殊武装（射撃）300：殴》《ミサイル200》《BS付与：狼狽》\n\n加護\n
《トール》《ニョルド》《ヘイムダル》《ブラギ》\n\n解説\nサンプルシナリオボスもどき。\n\n"></textarea>
          <div style="text-align: center; margin-top: 1ex;">
            <span class="button" onclick="parseRawText()" style="padding: 0.5em 2em; font-size: 1.1em;">読み込み</span>
          </div>
        </div>
      </details>
    </div>
    
  </section>
HTML
print renderChatPaletteForm();

print renderEditPageEnd(
  notes => '©FarEast Amusement Research Co.,Ltd.「'.($::SW2_0 ? 'メタリックガーディアンRPG' : 'メタリックガーディアンRPG').'」',
  extraHtml => renderDataList(),
);

sub renderDataList {
  return <<~"HTML";
  <datalist id="data-intellect">
    <option value="なし">
    <option value="動物並み">
    <option value="低い">
    <option value="人間並み">
    <option value="高い">
    <option value="命令を聞く">
  </datalist>
  <datalist id="data-perception">
    <option value="五感">
    <option value="五感（暗視）">
    <option value="五感（）">
    <option value="魔法">
    <option value="機械">
  </datalist>
  <datalist id="data-disposition">
    <option value="友好的">
    <option value="中立">
    <option value="敵対的">
    <option value="腹具合による">
    <option value="命令による">
  </datalist>
  <datalist id="data-language">
    <option value="なし">
  </datalist>
  <datalist id="list-of-reputation-plus">
    <option>―</option>
  </datalist>
  <datalist id="data-weakness">
    <option value="命中力+1">
    <option value="物理ダメージ+2点">
    <option value="魔法ダメージ+2点">
    <option value="属性ダメージ+3点">
    <option value="回復効果ダメージ+3点">
    <option value="なし">
  </datalist>
  <datalist id="data-roots-num">
    <option value="自動">
  </datalist>
  HTML
}

1;
