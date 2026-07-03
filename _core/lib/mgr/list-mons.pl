################## エネミー一覧表示（最小構成プレースホルダー） ##################
use strict;
use utf8;
use open ":utf8";
use HTML::Template;

my $LOGIN_ID = check;
my $mode = $::in{mode};

$ENV{HTML_TEMPLATE_ROOT} = $::core_dir;

### テンプレート読み込み
my $INDEX;
$INDEX = HTML::Template->new( filename  => $set::skin_tmpl , utf8 => 1,
  path => ['./', $::core_dir."/skin/mgr", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

# エネミーリスト表示モードをONにする
$INDEX->param(modeMonsList => 1);
$INDEX->param(typeName => 'エネミー');
$INDEX->param(type => 'm');
$INDEX->param(LOGIN_ID => $LOGIN_ID);
$INDEX->param(mode => $mode);

# 現在はデータがないため、空のリストを渡す
$INDEX->param(Lists => []);

$INDEX->param(title => $set::title);
$INDEX->param(ver => $::ver);
$INDEX->param(coreDir => $::core_dir);

### 出力
print "Content-Type: text/html\n\n";
print $INDEX->output;

1;