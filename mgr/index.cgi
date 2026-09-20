#!/usr/bin/perl

####################################
##     ゆとシートXX for メタリックガーディアン     ##
##          by TRPG集会所(仮)     ##
##      https://x.com/nouminhukuro     ##
####################################

####################################
##     ゆとシートⅡ for DX3rd     ##
##          by ゆとらいず工房     ##
##      https://yutorize.work     ##
####################################
use strict;
#use warnings;
use utf8;
use open ":utf8";
binmode STDOUT, ':utf8';
use CGI::Carp qw(fatalsToBrowser);
use CGI qw/:all/;
use Fcntl;

### 設定読込 #########################################################################################
our $core_dir = '../_core';
use lib '../_core/module';

require $core_dir.'/lib/mgr/config-default.pl';
require './config.cgi';
require $core_dir.'/lib/subroutine.pl';
require $core_dir.'/lib/mgr/subroutine-mgr.pl';

require $core_dir.'/lib/junction.pl';

exit;