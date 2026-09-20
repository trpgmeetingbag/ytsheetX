################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

require $set::lib_list;
require $set::data_class_mgr; # ガーディアン判定用

### クエリ ###########################################################################################
my @queryKeys = qw(
  mode tag group image name player gender cover mechaName exp-min exp-max class
);
setFields({
  id        => 0,
  date      => 3,
  name      => 4,
  player    => 5,
  group     => 6,
  image     => 7,
  tags      => 8,
  hide      => 9,
  cover     => 10,
  gender    => 11,
  age       => 12,
  exp       => 13,
  level     => 14,
  classes   => 15,
  mechaName => 16,
  session   => 20,
});

### テンプレート読み込み #############################################################################
my $INDEX = setupListTemplate(
  type => '',
);
my ($indexMode, $qLinks) = listQueryInfo(
  queryKeys => \@queryKeys,
  excludeFromQLinks => { group => 1 },
);
my %groups = setupGroupList();

### ファイル読み込み #################################################################################
my @lines = loadLines();

### 検索フィルタ #####################################################################################
@lines = filterGroup(@lines)  if $::in{group} && $::in{group} ne 'all';
@lines = filterTag(@lines)    if $::in{tag};
@lines = filterImage(@lines)  if $::in{image};
@lines = filterGender(@lines) if $::in{gender};
@lines = filterContainsRegex(lines => \@lines, key => 'name',      flags => 'i') if $::in{name};
@lines = filterContainsRegex(lines => \@lines, key => 'player',    flags => 'i') if $::in{player};
@lines = filterContainsRegex(lines => \@lines, key => 'cover',     flags => 'i') if $::in{cover};
@lines = filterContainsRegex(lines => \@lines, key => 'mechaName', flags => 'i') if $::in{mechaName};
@lines = filterContainsRegex(lines => \@lines, key => 'classes', query => $_) foreach split /\s/,$::in{class};

@lines = filterRange(
  lines  => \@lines,
  key    => 'exp',
  minKey => 'exp-min',
  maxKey => 'exp-max',
) if hasInteger($::in{'exp-min'}, $::in{'exp-max'});

### ソート --------------------------------------------------
if($::in{sort}){
  my $s = $::in{sort};
  if   ($s eq 'name'){ my @t = map { sortKeyName($_)       } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'pl')  { my @t = map { capField($_,'player') } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'date'){ my @t = map { capField($_,'date')   } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'lv')  { my @t = map { capField($_,'level')  } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'exp') { my @t = map { capField($_,'exp')    } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'age') { my @t = map { capField($_,'age')    } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
}

### リストを回す --------------------------------------------------
my ($pageLines, $count, $page, $pageStart, $pageEnd, $shouldSkip) = prepareGroupedPage(
  lines         => \@lines,
  selectedGroup => $::in{group},
  hasTagQuery   => $::in{tag},
  countExtraOf  => $set::playerlist ? sub {
    my $line = shift;
    return capField($line, 'player');
  } : undef,
);

my %groupedLists;
foreach (@$pageLines) {
  my %pc = %{ splitField($_) };
  
  # グループ
  $pc{group} = $set::group_default if (!$pc{group} || !$groups{$pc{group}});
  $pc{group} = 'all' if $::in{group} eq 'all';
  
  next if $shouldSkip->(
    group => $pc{group},
    extra => $pc{player},
  );
  
  ## シンプルリスト
  if($indexMode && $set::simplelist){
     my @characters;
    push(@characters, {
      "ID" => $pc{id},
      "NAME" => renderCharacterName($pc{name}),
      "PLAYER" => $pc{player},
      "GROUP" => $pc{group},
      "EXP"    => $pc{exp},
      "LV"     => $pc{level},
      "HIDE" => $pc{hide},
    });
    push(@{$groupedLists{$pc{group}}}, @characters);
  }
  ## 通常リスト
  else {
    # MGR固有：ガーディアンクラスの太字化処理
    my @classes_raw = split(/[\/／]+/, $pc{classes});
    my @classes_formatted;
    foreach my $c (@classes_raw) {
      $c =~ s/^\s+|\s+$//g;
      if ($data::class{$c} && $data::class{$c}{type} eq 'guardian') {
        push(@classes_formatted, "<b class=\"guardian-class\">$c</b>");
      } else {
        push(@classes_formatted, "<span>$c</span>");
      }
    }
    my $class_disp = join('<wbr>/', @classes_formatted);
    
    # 出力用配列へ
    my @characters;
    push(@characters, {
      ID         => $pc{id},
      NAME       => renderCharacterName($pc{name}),
      PLAYER     => $pc{player},
      GROUP      => $pc{group},
      COVER      => $pc{cover} || '',
      MECHA      => $pc{mechaName} || '',
      GENDER     => renderGender($pc{gender}),
      AGE        => renderAge($pc{age}),
      EXP        => $pc{exp},
      LV         => $pc{level},
      CLASS_DISP => $class_disp,
      TAGS       => renderTagLinks($pc{tags}, $pc{session}),
      DATE       => renderUpdateTime($pc{date}),
      HIDE       => $pc{hide},
    });
    push(@{$groupedLists{$pc{group}}}, @characters);
  }
}

### テンプレートへ入力 ###############################################################################
$INDEX->param(Lists => [ makeGroupedLists(
  groupOrder   => [ sort { $groups{$a}{sort} <=> $groups{$b}{sort} } keys %groupedLists ],
  groupedLists => \%groupedLists,
  count        => $count,
  
  makePager => sub {
    my (%args) = @_;
    return makePager(
      count     => $args{count},
      page      => $page,
      enabled   => ($args{id} || $::in{mode} eq 'mylist'),
      queryBase => "group=$::in{group}$qLinks",
    );
  },

  makeGroup => \&makeCharacterGroup,
) ]);

## 検索サマリー --------------------------------------------------
setSearchSummary(
  [ $::in{cover},     'カバー「%s」' ],
  [ $::in{mechaName}, '機体名「%s」' ],
  [ $::in{exp},       '経験点「%s」' ],
  [ $::in{class},     'クラス「%s」' ],
);

### 出力 #############################################################################################
printFinalizedList();

1;