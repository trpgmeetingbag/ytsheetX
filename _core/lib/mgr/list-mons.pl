################## 一覧表示 ##################
use strict;
use utf8;
use open ":utf8";
use HTML::Template;

require $set::lib_list;
require $set::data_mons;

### クエリ ###########################################################################################
my @queryKeys = qw(
  mode tag image system taxa name author lv-max lv-min
);
setFields({
  id      => 0,
  date    => 3,
  name    => 4,
  author  => 5,
  taxa    => 7,
  lv      => 8,
  system  => 6,  # ★ calc-mons.pl でシステム名を保存している列番号に書き換えてください
  tags    => 10,
  hide    => 11,
  skill_search => 13,
});

### テンプレート読み込み #############################################################################
my $INDEX = setupListTemplate(
  type     => 'm',
  typeName => 'エネミー',
);
my ($indexMode, $qLinks) = listQueryInfo(
  queryKeys => \@queryKeys,
  excludeFromQLinks => { system => 1 },
);

### ファイル読み込み #################################################################################
my @lines = loadLines();

### 検索フィルタ #####################################################################################
use Encode; # ★追加：文字コード変換モジュールの呼び出し

# ★追加：skill_search の文字化け（バイト列化）を修復し、UTF-8として正しく認識させる
if ($::in{skill_search} && !Encode::is_utf8($::in{skill_search})) {
  $::in{skill_search} = Encode::decode('utf8', $::in{skill_search});
}

@lines = filterTag(@lines)   if $::in{tag};
@lines = filterImage(@lines) if $::in{image};
@lines = filterContainsRegex(lines => \@lines, key => 'name', flags => 'i') if $::in{name};
@lines = filterContainsRegex(lines => \@lines, key => 'author', flags => 'i') if $::in{author};
@lines = filterContainsRegex(lines => \@lines, key => 'taxa') if $::in{taxa};
@lines = filterContainsRegex(lines => \@lines, key => 'system') if $::in{system} && $::in{system} ne 'all';
@lines = filterContainsRegex(lines => \@lines, key => 'skill_search') if $::in{skill_search};

@lines = filterRange(
  lines => \@lines,
  key => 'lv',
  minValueOf => \&lvMaxCheck,
  maxValueOf => \&lvMinCheck,
) if hasInteger($::in{'lv-min'}, $::in{'lv-max'});

sub lvMinCheck { my ($min, $max) = split('-', shift); return $min || $max; }
sub lvMaxCheck { my ($min, $max) = split('-', shift); return $max || $min; }

### システム・辞書情報の整理 #########################################################################
# 検索プルダウンやグループ分けに使うシステムリストを辞書のソート順で生成
my @systemList = sort { 
  $data::srs_system_mons{$a}{sort} cmp $data::srs_system_mons{$b}{sort} 
} keys %data::srs_system_mons;

$INDEX->param(SystemGroups => [
  ( map { { NAME => $_, SELECTED => ($::in{system} eq $_ ? 'selected' : '') } } @systemList ),
  { NAME => 'その他', SELECTED => ($::in{system} eq 'その他' ? 'selected' : '') }
]);

### ソート ###########################################################################################
if($::in{sort}){
  my $s = $::in{sort};
  if   ($s eq 'name')  { my @t = map { sortKeyName($_)       } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'author'){ my @t = map { capField($_,'author') } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'date')  { my @t = map { capField($_,'date')   } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'lv')    { my @t = map { capField($_,'lv')     } @lines; @lines = @lines[sort {$t[$a] <=> $t[$b]} 0 .. $#t]; }
}

### ページ処理 #######################################################################################
my $selectedGroup = $::in{system} eq 'all' ? 'すべて' : $::in{system};

my ($pageLines, $count, $page, $pageStart, $pageEnd, $shouldSkip) = prepareGroupedPage(
  lines         => \@lines,
  selectedGroup => $selectedGroup,
  hasTagQuery   => $::in{tag},
);

my %groupedLists;
foreach (@$pageLines) {
  my %pc = %{ splitField($_) };

  # システム名の判定（辞書になければ「その他」にする）
  my $sys = $pc{system} || '未定義';
  if ($sys ne '未定義' && !exists $data::srs_system_mons{$sys}) {
    $sys = 'その他';
  }

  if($::in{system} eq 'all'){
    $sys = 'すべて';
  } elsif (!$indexMode) {
    $sys = $::in{system} || 'すべて';
  }

  next if $shouldSkip->( group => $sys );

  $pc{lv} =~ s/^(\d+)-(\d+)$/$1～$2/;


  # ★ 分類の頭につく「その他:」や「その他：」を画面表示時のみ削り取る
      $pc{taxa} =~ s/^その他[:：]//;

  push(@{$groupedLists{$sys}}, {
    ID      => $pc{id},
    NAME    => $pc{name},
    AUTHOR  => $pc{author},
    SYSTEM  => $pc{system}, # 実際の登録システム名を表示
    TAXA    => $pc{taxa},
    LV      => $pc{lv},
    TAGS    => renderTagLinks($pc{tags}),
    DATE    => renderUpdateTime($pc{date}),
    HIDE    => $pc{hide},
  });
}

### テンプレートへ出力 ###############################################################################
my @outputGroups = $indexMode || ($::in{system} && $::in{system} ne 'all')
  ? ( ( map { [ $_, $_, '' ] } @systemList ), ['その他', 'その他', ''] )
  : ( ['すべて', 'すべて', ''] );

$INDEX->param(Lists => [ makeGroupedLists(
  groupOrder => \@outputGroups,
  groupedLists => \%groupedLists,
  count => $count,

  makePager => sub {
    my (%args) = @_;
    return makePager(
      count     => $args{count},
      page      => $page,
      enabled   => ($args{id} || $::in{mode} eq 'mylist'),
      queryBase => "type=m&system=".uri_escape_utf8($args{id})."$qLinks",
    );
  },

  makeGroup => sub {
    my (%args) = @_;
    return {
      QUERYBASE => 'type=m&system='.uri_escape_utf8($args{id}),
      NAME      => $args{id},
      TEXT      => '',
      NUM       => $args{num},
      Lines     => $args{lines},
      PAGER     => $args{pager},
      MORE      => $args{more},
    };
  },
) ]);

## 検索サマリー --------------------------------------------------
setSearchSummary(
  { nameHeader => '名称' },
  [ $selectedGroup, 'システム「%s」' ],
  [ $::in{taxa},    '分類「%s」' ],
  [ $::in{lv},      'レベル「%s」' ],
  [ $::in{skill_search}, '特技・加護「%s」' ],
);

### 出力 #############################################################################################
printFinalizedList();
1;