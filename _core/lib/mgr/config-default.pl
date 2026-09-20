################# デフォルト設定 #################
use strict;
use utf8;

package set;

require $::core_dir . '/lib/config-default.pl';

our $game = 'mgr';

# config.cgiのほうが優先されます
# 変更する場合は同様の項目をconfig.cgiに追記してください
# （CGIアップデート時に上書きされるため）
  
## ●タイトル
  our $title = 'ゆとシートⅡ for MGR(メタリックガーディアン)';


## ●グループ設定
 # ["ID", "ソート順(空欄で非表示)", "分類名", "分類の説明文"],
 # 選択時はここで書いた順番、キャラ一覧(グループ別)ではソート順で数字が小さい方から表示されます
 # 増減OK
  our @groups = (
    ["pc",  "01", "ＰＣ", "プレイヤーキャラクター"],
    ["npc", "99", "ＮＰＣ", "ノンプレイヤーキャラクター"],
  );

 # デフォルトのグループID
  our $group_default = 'pc';


## ●キャラクターシートの各種初期値
  our $make_exp = 130;
  our $make_fix   = 0;


## ●各種ファイルへのパス
  our $data_dir = './data/'; # データ格納ディレクトリ
  our $passfile = $data_dir . 'charpass.cgi'; # パスワード記録ファイル
  our $listfile = $data_dir . 'charlist.cgi'; # キャラクター一覧ファイル
  our $char_dir = $data_dir . 'chara/'; # キャラクターデータ格納ディレクトリ

  our $lib_edit_char   = $::core_dir . '/lib/mgr/edit-chara.pl';  # 編集画面
  our $lib_calc_char   = $::core_dir . '/lib/mgr/calc-chara.pl';  # 保存処理
  our $lib_view_char   = $::core_dir . '/lib/mgr/view-chara.pl';  # シート表示
  our $lib_palette_sub = $::core_dir . '/lib/mgr/palette-sub.pl'; # チャットパレット
  our $lib_list_char   = $::core_dir . '/lib/mgr/list-chara.pl';  # 一覧
  our $lib_list_mons   = $::core_dir . '/lib/mgr/list-mons.pl';  # 一覧
  our $lib_json_sub    = $::core_dir . '/lib/mgr/json-sub.pl';    # JSON出力
  our $lib_convert     = $::core_dir . '/lib/mgr/convert.pl';     # コンバート

  # 各種データ
  our $data_syndrome = $::core_dir . '/lib/mgr/data-syndrome.pl';  # シンドロームのデータ
  our $data_mons = $::core_dir . '/lib/mgr/data-mons.pl';  # システム一覧
  our $data_src = $::core_dir . '/lib/mgr/data-src.pl';  # システム一覧
  our $data_class_mgr   = $::core_dir . '/lib/mgr/data-class-mgr.pl';    # クラスデータ：メタリックガーディアン
  our $data_class_tenka = $::core_dir . '/lib/mgr/data-class-tenka.pl';  # クラスデータ：天下繚乱

  # HTMLテンプレート
  our $skin_tmpl  = $::core_dir . '/skin/mgr/index.html';      # 一覧／登録フォーム等の大枠
  our $skin_sheet = $::core_dir . '/skin/mgr/sheet-chara.html';   # キャラクターシート

  # 魔物・アイテム・魔法/流派などの設定
  our %lib_type = (
    'm' => {
      listFile => $data_dir . 'monslist.cgi',
      dataDir => $data_dir . 'mons/',
      edit => $::core_dir . '/lib/mgr/edit-mons.pl',
      calc => $::core_dir . '/lib/mgr/calc-mons.pl',
      view => $::core_dir . '/lib/mgr/view-mons.pl',
      list => $::core_dir . '/lib/mgr/list-mons.pl',
      skin => $::core_dir . '/skin/mgr/sheet-monster.html',
      sheetType => 'mons',
    },
  );

# シート初期値の変更
our %customizedInitialValues = (
    '' => {
        # 例：「侵蝕率効果表」の「エフェクトアーカイブ適用」を初期状態で有効にする
        # 'encroachEaOn' => '1',
    },
);

1;