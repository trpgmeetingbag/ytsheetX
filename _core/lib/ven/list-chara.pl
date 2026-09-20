################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

require $set::lib_list;

### クエリ ###########################################################################################
my @queryKeys = qw(
  mode tag group image name player gender level-min level-max attribute origin adept fairy power-lineage income-min income-max maint-min maint-max debt-min debt-max
);
setFields({
  id        => 0,
  date      => 3,
  name      => 4,
  player    => 5,
  group     => 6,
  level     => 7,
  attribute => 8,
  age       => 9,
  gender    => 10,
  origin    => 11,
  adept     => 12,
  fairy     => 13,
  income    => 14,
  session   => 15,
  image     => 16,
  tags      => 17,
  hide      => 18,
  rest      => 19,
  maint     => 20,
  debt      => 21,
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

@lines = filterContainsRegex(lines => \@lines, key => 'name', flags => 'i') if $::in{name};
@lines = filterContainsRegex(lines => \@lines, key => 'player', flags => 'i') if $::in{player};
@lines = filterContainsRegex(lines => \@lines, key => 'attribute', flags => 'i') if $::in{attribute};
@lines = filterContainsRegex(lines => \@lines, key => 'origin', flags => 'i') if $::in{origin};
@lines = filterContainsRegex(lines => \@lines, key => 'adept', flags => 'i') if $::in{adept};
@lines = filterContainsRegex(lines => \@lines, key => 'fairy', flags => 'i') if $::in{fairy};

# パワー系統検索（オリジンとアデプトの両方を検索）
if($::in{'power-lineage'}) {
  my $q = $::in{'power-lineage'};
  @lines = grep {
    my %pc = %{ splitField($_) };
    ($pc{origin} && $pc{origin} =~ /\Q$q\E/i) || ($pc{adept} && $pc{adept} =~ /\Q$q\E/i);
  } @lines;
}

# 数値範囲フィルタ
@lines = filterRange(lines => \@lines, key => 'level', minKey => 'level-min', maxKey => 'level-max') if hasInteger($::in{'level-min'}, $::in{'level-max'});
@lines = filterRange(lines => \@lines, key => 'income', minKey => 'income-min', maxKey => 'income-max') if hasInteger($::in{'income-min'}, $::in{'income-max'});
@lines = filterRange(lines => \@lines, key => 'maint', minKey => 'maint-min', maxKey => 'maint-max') if hasInteger($::in{'maint-min'}, $::in{'maint-max'});
@lines = filterRange(lines => \@lines, key => 'debt', minKey => 'debt-min', maxKey => 'debt-max') if hasInteger($::in{'debt-min'}, $::in{'debt-max'});


### ソート --------------------------------------------------
if($::in{sort}){
  my $s = $::in{sort};
  if   ($s eq 'name'){ my @t = map { sortKeyName($_)       } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'pl')  { my @t = map { capField($_,'player') } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'date'){ my @t = map { capField($_,'date')   } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'age') { my @t = map { capField($_,'age')    } @lines; @lines = @lines[sort {$t[$a] cmp $t[$b]} 0 .. $#t]; }
  elsif($s eq 'lv')  { my @t = map { capField($_,'level')  } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'income'){ my @t = map { capField($_,'income') } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'rest')  { my @t = map { capField($_,'rest')   } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'maint') { my @t = map { capField($_,'maint')  } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
  elsif($s eq 'debt')  { my @t = map { capField($_,'debt')   } @lines; @lines = @lines[sort {$t[$b] <=> $t[$a]} 0 .. $#t]; }
}

### リストを回す --------------------------------------------------
my ($pageLines, $count, $page, $pageStart, $pageEnd, $shouldSkip) = prepareGroupedPage(
  lines => \@lines,
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
  
  #グループ
  $pc{group} = $set::group_default if (!$pc{group} || !$groups{$pc{group}});
  $pc{group} = 'all' if $::in{group} eq 'all';
  
  next if $shouldSkip->(
    group => $pc{group},
    extra => $pc{player},
  );
  
  ## シンプルリスト
  if($indexMode && $set::simplelist){
    #出力用配列へ
    my @characters;
    push(@characters, {
      "ID"     => $pc{id},
      "NAME"   => renderCharacterName($pc{name}),
      "PLAYER" => $pc{player},
      "GROUP"  => $pc{group},
      "HIDE"   => $pc{hide},
    });
    push(@{$groupedLists{$pc{group}}}, @characters);
  }
  ## 通常リスト
  else {
    #オリジン (上2つ)
    my @origins = split(/ \/ /, $pc{origin} || '');
    my $origin_html = '';
    foreach (0..1) { $origin_html .= "<span>$origins[$_]</span>" if $origins[$_]; }
    
    #アデプト (上2つ)
    my @adepts = split(/ \/ /, $pc{adept} || '');
    my $adept_html = '';
    foreach (0..1) { $adept_html .= "<span>$adepts[$_]</span>" if $adepts[$_]; }

    #妖精/神 (上3つ)
    my @fairys = split(/ \/ /, $pc{fairy} || '');
    my $fairy_html = '';
    foreach (0..2) { $fairy_html .= "<span>$fairys[$_]</span>" if $fairys[$_]; }
    
    #出力用配列へ
    my @characters;
    push(@characters, {
      ID        => $pc{id},
      NAME      => renderCharacterName($pc{name}),
      PLAYER    => $pc{player},
      GROUP     => $pc{group},
      LEVEL     => $pc{level} || 0,
      ATTRIBUTE => $pc{attribute},
      AGE       => renderAge($pc{age}),
      GENDER    => renderGender($pc{gender}),
      ORIGIN    => $origin_html,
      ADEPT     => $adept_html,
      FAIRY     => $fairy_html,
      INCOME    => $pc{income} || 0,
      REST      => $pc{rest} || 0,
      MAINT     => $pc{maint} || 0,
      INTEREST  => $pc{debt} || 0,
      TAGS      => renderTagLinks($pc{tags}, $pc{session}),
      DATE      => renderUpdateTime($pc{date}),
      HIDE      => $pc{hide},
    });
    push(@{$groupedLists{$pc{group}}}, @characters);
  }
}

### テンプレートへ入力 ###############################################################################
$INDEX->param(Lists => [ makeGroupedLists(
  groupOrder => [ sort { $groups{$a}{sort} <=> $groups{$b}{sort} } keys %groupedLists ],
  groupedLists => \%groupedLists,
  count => $count,
  
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
  [ $::in{'level-min'} || $::in{'level-max'}, 'レベル「%s」' ],
  [ $::in{attribute}, '属性「%s」' ],
  # [ $::in{gender},    '性別「%s」' ],
  [ $::in{origin},    'オリジン「%s」' ],
  [ $::in{adept},     'アデプト「%s」' ],
  [ $::in{fairy},     '妖精／神「%s」' ],
  [ $::in{'power-lineage'}, 'パワー系統「%s」' ],
  [ $::in{'income-min'} || $::in{'income-max'}, '総収入「%s」' ],
  [ $::in{'maint-min'} || $::in{'maint-max'},   '維持費「%s」' ],
  [ $::in{'debt-min'} || $::in{'debt-max'},     '借金「%s」' ],
);

### 出力 #############################################################################################
printFinalizedList();

1;