# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl RadioMobile.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

my $filepath 	= 't/net1.net';

use Test::More tests => 4;
BEGIN { use_ok('RadioMobile') };

my $rm = new RadioMobile(debug => $ENV{'RM_DEBUG'} || 0);
ok($rm->isa('RadioMobile'), "Checking ISA");

# testing filepath mode
$rm->filepath($filepath);
$rm->parse;
ok($rm->config->landheight =~ /landheight/i, 'Check last parsing element in filepath mode');

# testing file mode
$rm 		= new RadioMobile(debug => $ENV{'RM_DEBUG'} || 0);
open(NET,$filepath);
binmode(NET);
my $dotnet	= '';
while (read(NET,my $buff,8*2**10)) { $dotnet .=  $buff }
close(NET);
$rm->file($dotnet);
$rm->parse;
ok($rm->config->landheight =~ /landheight/i, 'Check last parsing element in file mode');

