################## 一覧表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

my $LOGIN_ID = check;

my $mode = $::in{mode};
my $sort = $::in{sort};

### テンプレート読み込み #############################################################################
my $INDEX;
$INDEX = HTML::Template->new( filename  => $set::skin_tmpl , utf8 => 1,
  path => ['./', $::core_dir."/skin/ven", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);


$INDEX->param(modeList => 1);
$INDEX->param(modeMylist => 1) if $mode eq 'mylist';

$INDEX->param(LOGIN_ID => $LOGIN_ID);
$INDEX->param(OAUTH_MODE => $set::oauth_service);
$INDEX->param(OAUTH_LOGIN_URL => $set::oauth_login_url);

$INDEX->param(mode => $mode);

### データ処理 #######################################################################################
### クエリ --------------------------------------------------
my $index_mode;
foreach (keys %::in) {
  $::in{$_} =~ s/</&lt;/g;
  $::in{$_} =~ s/>/&gt;/g;
}
if(!($mode eq 'mylist' || $::in{tag} || $::in{group} || $::in{name} || $::in{player} || $::in{'exp-min'} || $::in{'exp-max'} || $::in{syndrome} || $::in{breed} || $::in{works} || $::in{dlois} || $::in{sign} || $::in{image})){
  $index_mode = 1;
  $INDEX->param(modeIndex => 1);
  $INDEX->param(simpleList => 1) if $set::simplelist;
}
# my @q_links;
# foreach(
#   'mode',
#   'tag',
#   #'group',
#   'name',
#   'player',
#   'exp-min',
#   'exp-max',
#   'syndrome',
#   'breed',
#   'works',
#   'dlois',
#   'sign',
#   'image',
#   'fellow',
#   ){
#   push( @q_links, $_.'='.uri_escape_utf8(decode('utf8', param($_))) ) if param($_);
# }
my @q_links;
foreach(
  'mode',
  'tag',
  #'group',
  'name',
  'player',
  'level-min',    # ← 追加
  'level-max',    # ← 追加
  'attribute',    # ← 追加
  'gender',          # ← 追加
  'origin',
  'adept',
  'fairy',
  'power-lineage',   # ← 追加
  'income-min',
  'income-max',
  'maint-min',
  'maint-max',
  'debt-min',
  'debt-max',
  'sign',
  'image',
  'fellow',
  ){
  push( @q_links, $_.'='.uri_escape_utf8(decode('utf8', param($_))) ) if param($_);
}
my $q_links = @q_links ? '&'.join('&', @q_links) : '';

### ファイル読み込み --------------------------------------------------
## マイリスト取得
my @mylist;
if($mode eq 'mylist'){
  $INDEX->param( playerName => (getplayername($LOGIN_ID))[0] );
  open (my $FH, "<", $set::passfile);
  while(my $line = <$FH>){
    if($line =~ /^(.+?)<>\[$LOGIN_ID\]</){ push(@mylist, $1) }
  }
  close($FH);
}

## リスト取得
my @list;
if($set::simpleindex && $index_mode) { #グループ見出しのみ
  $INDEX->param(simpleIndex => 1);
}
else { #通常
  open (my $FH, "<", $set::listfile);
  @list = <$FH>;
  close($FH);
}
### フィルタ処理 --------------------------------------------------
## マイリスト
if($mode eq 'mylist'){
  my $regex = join('|', @mylist);
  @list = grep { $_ =~ /^(?:$regex)\</ } @list;
}
## 非表示除外
elsif (
     !($set::masterid && $set::masterid eq $LOGIN_ID)
  && !($mode eq 'mylist')
  && !$::in{tag}
){
  @list = grep { !(split(/<>/))[18] } @list;
}

## グループ検索
my $group_query = $::in{group};
my %groups = groupArrayToHash();
$groups{all}{name} = 'すべて' if $::in{group} eq 'all';
$INDEX->param(Groups => groupArrayToList $group_query);

if($group_query && $::in{group} ne 'all') {
  if($group_query eq $set::group_default){ @list = grep { $_ =~ /^(?:[^<]*?<>){6}(\Q$group_query\E)?</ } @list; }
  else { @list = grep { $_ =~ /^(?:[^<]*?<>){6}\Q$group_query\E</ } @list; }
}
$INDEX->param(group => $groups{$group_query}{name});

## タグ検索
my $tag_query = normalizeHashtags(decode('utf8', $::in{tag}));
if($tag_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){17}[^<]*? \Q$tag_query\E / } @list; }
$INDEX->param(tag => $tag_query);

## 名前検索
my $name_query = decode('utf8', $::in{name});
if($name_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){4}[^<]*?\Q$name_query\E/i } @list; }
$INDEX->param(name => $name_query);

## PL名検索
my $pl_query = decode('utf8', $::in{player});
if($pl_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){5}[^<]*?\Q$pl_query\E/i } @list; }
$INDEX->param(player => $pl_query);

## レベル検索
my $level_min = $::in{'level-min'};
my $level_max = $::in{'level-max'};
if($level_min =~ /^[+-]?[0-9]+$/) { @list = grep { (split(/<>/))[7] >= $level_min } @list; }
if($level_max =~ /^[+-]?[0-9]+$/) { @list = grep { (split(/<>/))[7] <= $level_max } @list; }
$INDEX->param(levelMin => $level_min);
$INDEX->param(levelMax => $level_max);
my $level_text;
if   ($level_min eq $level_max){ $level_text = $level_min; }
elsif($level_min || $level_max){ $level_text = $level_min.'～'.$level_max; }
$INDEX->param(levelText => $level_text);

## 属性検索
my $attribute_query = decode('utf8', $::in{attribute});
if($attribute_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){8}[^<]*?\Q$attribute_query\E/i } @list; }
$INDEX->param(attribute => $attribute_query);

## 性別検索
my $gender_query = $::in{gender};
my %gender_text = ('male'=>'♂', 'female'=>'♀', 'cross'=>'⚧', 'none'=>'―', 'unknown'=>'？');
if($gender_query) {
  # ゆとシートの性別判定ロジックを流用してフィルタ
  @list = grep { 
    my $g = (split(/<>/, $_))[10];
    my $m; my $f; my $n;
    $g =~ s/^(.+?)[\(（].*?[）\)]$/$1/;
    $g =~ tr/Ａ-Ｚａ-ｚ/A-Za-z/;
    if($g =~ /男|おとこ|オトコ|♂|雄|オス|爺|漢|ショタ|(?<!fe)m(ale|$)|(?<!wo)man/i) { $m = 1 }
    if($g =~ /女|おんな|オンナ|♀|雌|メス|婆|娘|ロリ|f(em(ale)?|$)|woman/i)       { $f = 1 }
    if($g =~ /無|なし|^[\-ー‐‑–—―−ｰ]$|non/i)                { $n = 1 }
    if($g =~ /元|両|半|トランス|ノンバ|non|Ft[MX]|Mt[FX]|^[XA]/i) { $m = 1; $f = 1 }

    
    my $type = $n ? 'none' : ($m && $f) ? 'cross' : $m ? 'male' : $f ? 'female' : 'unknown';
    $type eq $gender_query;
  } @list;
  $INDEX->param("gender_${gender_query}" => 'selected');
  $INDEX->param(genderText => $gender_text{$gender_query});
}

## パワー系統検索
my $power_query = decode('utf8', $::in{'power-lineage'});
if($power_query) { 
  # [11]オリジン と [12]アデプト の両方の文字列内を検索
  @list = grep { 
    my @cols = split(/<>/, $_);
    $cols[11] =~ /\Q$power_query\E/i || $cols[12] =~ /\Q$power_query\E/i
  } @list; 
}
$INDEX->param(powerLineage => $power_query);

## オリジン検索
my $origin_query = decode('utf8', $::in{origin});
if($origin_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){11}[^<]*?\Q$origin_query\E/i } @list; }
$INDEX->param(origin => $origin_query);

## アデプト検索
my $adept_query = decode('utf8', $::in{adept});
if($adept_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){12}[^<]*?\Q$adept_query\E/i } @list; }
$INDEX->param(adept => $adept_query);

## 妖精/神検索
my $fairy_query = decode('utf8', $::in{fairy});
if($fairy_query) { @list = grep { $_ =~ /^(?:[^<]*?<>){13}[^<]*?\Q$fairy_query\E/i } @list; }
$INDEX->param(fairy => $fairy_query);

## 総収入検索
my $income_min = $::in{'income-min'};
my $income_max = $::in{'income-max'};
if($income_min =~ /^[+-]?[0-9]+$/) { @list = grep { (split(/<>/))[14] >= $income_min } @list; }
if($income_max =~ /^[+-]?[0-9]+$/) { @list = grep { (split(/<>/))[14] <= $income_max } @list; }
$INDEX->param(incomeMin => $income_min);
$INDEX->param(incomeMax => $income_max);
my $income_text;
if   ($income_min eq $income_max){ $income_text = $income_min; }
elsif($income_min || $income_max){ $income_text = $income_min.'～'.$income_max; }
$INDEX->param(incomeText => $income_text);

## 維持費検索
my $maint_min = $::in{'maint-min'};
my $maint_max = $::in{'maint-max'};
if($maint_min =~ /^[+-]?[0-9]+$/) { @list = grep { (split(/<>/))[20] >= $maint_min } @list; }
if($maint_max =~ /^[+-]?[0-9]+$/) { @list = grep { (split(/<>/))[20] <= $maint_max } @list; }
$INDEX->param(maintMin => $maint_min);
$INDEX->param(maintMax => $maint_max);
my $maint_text;
if   ($maint_min eq $maint_max){ $maint_text = $maint_min; }
elsif($maint_min || $maint_max){ $maint_text = $maint_min.'～'.$maint_max; }
$INDEX->param(maintText => $maint_text);

## 借金検索
my $debt_min = $::in{'debt-min'};
my $debt_max = $::in{'debt-max'};
if($debt_min =~ /^[+-]?[0-9]+$/) { @list = grep { (split(/<>/))[21] >= $debt_min } @list; }
if($debt_max =~ /^[+-]?[0-9]+$/) { @list = grep { (split(/<>/))[21] <= $debt_max } @list; }
$INDEX->param(debtMin => $debt_min);
$INDEX->param(debtMax => $debt_max);
my $debt_text;
if   ($debt_min eq $debt_max){ $debt_text = $debt_min; }
elsif($debt_min || $debt_max){ $debt_text = $debt_min.'～'.$debt_max; }
$INDEX->param(debtText => $debt_text);

## 星座検索
my $sign_query = decode('utf8', $::in{sign});
if($sign_query) {
  if   ($sign_query =~ /山羊|磨羯|やぎ/       ){ $sign_query = "山羊|磨羯|やぎ";        $INDEX->param(sign => "山羊座（磨羯宮）"); }
  elsif($sign_query =~ /水瓶|宝瓶|みずがめ/   ){ $sign_query = "水瓶|宝瓶|みずがめ";    $INDEX->param(sign => "水瓶座（宝瓶宮）"); }
  elsif($sign_query =~ /双?魚|うお/           ){ $sign_query = "双?魚|うお";            $INDEX->param(sign => "魚座（双魚宮）"); }
  elsif($sign_query =~ /[牡雄お]羊|おひつじ/  ){ $sign_query = "[牡雄お]羊|おひつじ";   $INDEX->param(sign => "牡羊座（白羊宮）"); }
  elsif($sign_query =~ /[牡雄お]牛|おうし/    ){ $sign_query = "[牡雄お]牛|おうし";     $INDEX->param(sign => "牡牛座（金牛宮）"); }
  elsif($sign_query =~ /双[子児]|ふたご/      ){ $sign_query = "双[子児]|ふたご";       $INDEX->param(sign => "双子座（双児宮）"); }
  elsif($sign_query =~ /蟹|かに/              ){ $sign_query = "蟹|かに";               $INDEX->param(sign => "蟹座（巨蟹宮）"); }
  elsif($sign_query =~ /獅子|しし/            ){ $sign_query = "獅子|しし";             $INDEX->param(sign => "獅子座（獅子宮）"); }
  elsif($sign_query =~ /[乙処]女|おとめ/      ){ $sign_query = "[乙処]女|おとめ";       $INDEX->param(sign => "乙女座（処女宮）"); }
  elsif($sign_query =~ /天秤|てんびん/        ){ $sign_query = "天秤|てんびん";         $INDEX->param(sign => "天秤座（天秤宮）"); }
  elsif($sign_query =~ /蠍|天蝎|さそり|サソリ/){ $sign_query = "蠍|天蝎|さそり|サソリ"; $INDEX->param(sign => "蠍座（天蝎宮）"); }
  elsif($sign_query =~ /人馬|射手|いて/       ){ $sign_query = "人馬|射手|いて";        $INDEX->param(sign => "射手座（人馬宮）"); }
  elsif($sign_query =~ /(蛇|へび)(使|遣|つか)/){ $sign_query = "(蛇|へび)(使|遣|つか)"; $INDEX->param(sign => "蛇遣座"); }
  else { $INDEX->param(sign => $sign_query); }
  
  @list = grep { $_ =~ /^(?:[^<]*?<>){10}[^<]*?(?:\Q$sign_query\E)/ } @list;
}

## 画像フィルタ
if($::in{image} == 1) {
  @list = grep { $_ =~ /^(?:[^<]*?<>){16}[^<0]/ } @list;
  $INDEX->param(image => 1);
}
elsif($::in{image} eq 'N') {
  @list = grep { $_ !~ /^(?:[^<]*?<>){16}[^<0]/ } @list;
  $INDEX->param(image => 1);
}
### ソート --------------------------------------------------
# if   ($sort eq 'name')  { my @tmp = map { sortName((split /<>/)[4]) } @list; @list = @list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp]; }
# elsif($sort eq 'pl')    { my @tmp = map { (split /<>/)[5]           } @list; @list = @list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp]; }
# elsif($sort eq 'date')  { my @tmp = map { (split /<>/)[3]           } @list; @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp]; }
# elsif($sort eq 'exp')   { my @tmp = map { (split /<>/)[7]           } @list; @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp]; }
# elsif($sort eq 'age')   { my @tmp = map { (split /<>/)[9]           } @list; @list = @list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp]; }

### ソート --------------------------------------------------
if   ($sort eq 'name')  { my @tmp = map { sortName((split /<>/)[4]) } @list; @list = @list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp]; }
elsif($sort eq 'pl')    { my @tmp = map { (split /<>/)[5]           } @list; @list = @list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp]; }
elsif($sort eq 'date')  { my @tmp = map { (split /<>/)[3]           } @list; @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp]; }
elsif($sort eq 'age')   { my @tmp = map { (split /<>/)[9]           } @list; @list = @list[sort {$tmp[$a] cmp $tmp[$b]} 0 .. $#tmp]; }
elsif($sort eq 'lv')    { my @tmp = map { (split /<>/)[7]           } @list; @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp]; } # ← 追加
elsif($sort eq 'income'){ my @tmp = map { (split /<>/)[14]          } @list; @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp]; }
elsif($sort eq 'rest')  { my @tmp = map { (split /<>/)[19]          } @list; @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp]; }
elsif($sort eq 'maint') { my @tmp = map { (split /<>/)[20]          } @list; @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp]; }
elsif($sort eq 'debt')  { my @tmp = map { (split /<>/)[21]          } @list; @list = @list[sort {$tmp[$b] <=> $tmp[$a]} 0 .. $#tmp]; }

sub sortName { $_[0] =~ s/^“.*”//; return $_[0]; }

### リストを回す --------------------------------------------------
my %count; my %pl_flag;
my %grouplist;
my $page = $::in{page} || 1;
my $pagestart = $page * $set::pagemax - $set::pagemax + 1;
my $pageend   = $page * $set::pagemax;
foreach (@list) {
  # my (
  #   $id, undef, undef, $updatetime, $name, $player, $group, #0-6
  #   $exp, $gender, $age, $sign, $blood, $works, #7-12
  #   $syndrome, $dlois, #13-14
  #   $session, $image, $tags, $hide, $stage #15-19
  # ) = (split /<>/, $_)[0..19];
  my (
    $id, undef, undef, $updatetime, $name, $player, $group, #0-6
    $level, $attribute, $age, $gender, $origin_list, $adept_list, #7-12
    $fairy_list, $total_income, #13-14
    $session, $image, $tags, $hide, #15-18
    $credit_rest, $total_maint, $total_debt #19-21
  ) = (split /<>/, $_)[0..21];
  
  #グループ
  $group = $set::group_default if (!$group || !$groups{$group});
  $group = 'all' if $::in{group} eq 'all';
  
  #カウント
  $count{PC}{$group}++;
  $count{PL}{$group}++ if !$pl_flag{$group}{$player};
  $pl_flag{$group}{$player} = 1;

  #表示域以外は弾く
  if (
    ( $index_mode && $count{PC}{$group} > $set::list_maxline && $set::list_maxline) || #TOPページ
    (!$index_mode && $set::pagemax && ($count{PC}{$group} < $pagestart || $count{PC}{$group} > $pageend)) #それ以外
  ){
    next;
  }
  
  #名前
  $name =~ s/^“(.*)”(.*)$/<span>“$1”<\/span><span>$2<\/span>/;

  #オリジン (上2つ)
    my @origins = split(/ \/ /, $origin_list);
    my $origin_html = '';
    foreach (0..1) { $origin_html .= "<span>$origins[$_]</span>" if $origins[$_]; }
    
    #アデプト (上2つ)
    my @adepts = split(/ \/ /, $adept_list);
    my $adept_html = '';
    foreach (0..1) { $adept_html .= "<span>$adepts[$_]</span>" if $adepts[$_]; }

    #妖精/神 (上3つ)
    my @fairys = split(/ \/ /, $fairy_list);
    my $fairy_html = '';
    foreach (0..2) { $fairy_html .= "<span>$fairys[$_]</span>" if $fairys[$_]; }
    
    #利子
    my $interest = $total_debt > 0 ? int(($total_debt + 9) / 10) : 0;

  
  ## シンプルリスト
  if($index_mode && $set::simplelist){
    #出力用配列へ
    my @characters;
    push(@characters, {
      "ID" => $id,
      "NAME" => $name,
      "PLAYER" => $player,
      "GROUP" => $group,
      "HIDE" => $hide,
    });
    
    push(@{$grouplist{$group}}, @characters);
  }
  ## 通常リスト
  else {
    #性別
    $gender = stylizeGender($gender);
    
    #年齢
    $age = stylizeAge($age);
    
 

    #タグ
    my $tags_links;
    foreach(grep $_, split(/ /, $tags)){ $tags_links .= '<a href="./?tag='.uri_escape_utf8($_).'">'.$_.'</a>'; }
    
    #最終参加セッション
    if($session){ $tags_links .= '<span class="session">'.$session.'</span>' }
    
    #更新日時
    my ($min,$hour,$day,$mon,$year) = (localtime($updatetime))[1..5];
    $year += 1900; $mon++;
    $updatetime = sprintf("<span>%04d-</span><span>%02d-%02d</span> <span>%02d:%02d</span>",$year,$mon,$day,$hour,$min);
    
    #出力用配列へ
    my @characters;
    # push(@characters, {
    #   "ID" => $id,
    #   "NAME" => $name,
    #   "PLAYER" => $player,
    #   "GROUP" => $group,
    #   "EXP" => $exp - 130,
    #   "AGE" => $age,
    #   "GENDER" => $gender,
    #   "SIGN" => $sign,
    #   "BLOOD" => $blood,
    #   "WORKS" => $works,
    #   "SYNDROME" => join('',@syndromes),
    #   "DLOIS" => join(' ',@dloises),
    #   "TAGS" => $tags_links,
    #   "DATE" => $updatetime,
    #   "HIDE" => $hide,
    # });
    push(@characters, {
      "ID" => $id,
      "NAME" => $name,
      "PLAYER" => $player,
      "GROUP" => $group,
      "AGE" => $age,
      "LEVEL" => $level || 0,        # ← 追加
      "ATTRIBUTE" => $attribute,     # ← 追加
      "GENDER" => $gender,
      "ORIGIN" => $origin_html,
      "ADEPT" => $adept_html,
      "FAIRY" => $fairy_html,
      "INCOME" => $total_income || 0,
      "REST" => $credit_rest || 0,
      "MAINT" => $total_maint || 0,
      "INTEREST" => $total_debt || 0,
      "TAGS" => $tags_links,
      "DATE" => $updatetime,
      "HIDE" => $hide,
    });
        push(@{$grouplist{$group}}, @characters);
  }
}

### 出力用配列 --------------------------------------------------
my @characterlists;
foreach my $id (sort {$groups{$a}{sort} <=> $groups{$b}{sort}} keys %grouplist){
  ## ページネーション
  my $navbar;
  if($set::pagemax && !$index_mode && ($::in{group} || $mode eq 'mylist')){
    my $lastpage = ceil($count{PC}{$id} / $set::pagemax);
    if($lastpage > 1){
      foreach(1 .. $lastpage){
        if($_ == $page){
          $navbar .= '<b>'.$_.'</b> ';
        }
        elsif(
          ($_ <= $page + 4 && $_ >= $page - 4) ||
          $_ == 1 ||
          $_ == $lastpage
        ){
          $navbar .= '<a href="./?group='.$id.$q_links.'&page='.$_.'&sort='.$::in{sort}.'">'.$_.'</a> '
        }
        else { $navbar .= '...' }
      }
      $navbar =~ s/\.{3,}/... /g;
    }
    $navbar = '<div class="navbar">'.$navbar.'</div>' if $navbar;
  }
  
  ##
  push(@characterlists, {
    "ID" => $id,
    "NAME" => $groups{$id}{name},
    "TEXT" => $groups{$id}{text},
    "NUM-PC" => $count{PC}{$id},
    "NUM-PL" => $count{PL}{$id},
    "Characters" => [@{$grouplist{$id}}],
    "NAV" => $navbar,
  });
}

$INDEX->param(qLinks => $q_links);

$INDEX->param(Lists => \@characterlists);


$INDEX->param(ogUrl => self_url());
# $INDEX->param(ogDescript => 
#   ($name_query ? "名前「${name_query}」を含む " : '') .
#   ($pl_query   ? "ＰＬ名「${pl_query}」を含む " : '') .
#   ($tag_query  ? "タグ「${tag_query}」 " : '') .
#   ($exp_query      ? "経験点「${exp_query}」 " : '') .
#   ($breed_text     ? "ブリード「${breed_text}}」" : '') . 
#   (@syndrome_query ? "シンドローム「@{syndrome_query}}」" : '') . 
#   (@dlois_query    ? "Ｄロイス「@{dlois_query}}」" : '') . 
#   ($works_query    ? "ワークス「${works_query}}」" : '') 
# );
$INDEX->param(ogDescript => 
  ($name_query ? "名前「${name_query}」を含む " : '') .
  ($pl_query   ? "ＰＬ名「${pl_query}」を含む " : '') .
  ($tag_query  ? "タグ「${tag_query}」 " : '') .
  ($level_text ? "レベル「${level_text}」 " : '') .        # ← 追加
  ($attribute_query ? "属性「${attribute_query}」 " : '') . # ← 追加
  ($gender_query ? "性別「".$gender_text{$gender_query}."」 " : '') . # ← 追加
  ($origin_query ? "オリジン「${origin_query}」" : '') . 
  ($adept_query  ? "アデプト「${adept_query}」" : '') . 
  ($fairy_query  ? "妖精／神「${fairy_query}」" : '') . 
  ($power_query  ? "パワー系統「${power_query}」" : '') . # ← 追加
  ($income_text  ? "総収入「${income_text}」 " : '') .
  ($maint_text   ? "維持費「${maint_text}」 " : '') .
  ($debt_text    ? "借金「${debt_text}」 " : '') 
);

$INDEX->param(title => $set::title);
$INDEX->param(ver => $::ver);
$INDEX->param(coreDir => $::core_dir);

### 出力 #############################################################################################
print "Content-Type: text/html\n\n";
print $INDEX->output;

1;