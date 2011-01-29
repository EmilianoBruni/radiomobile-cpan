# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl RadioMobile.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

my $res;

use Test::More tests => 13;
BEGIN { use_ok('RadioMobile::Utils::Matrix') };

my $m = new RadioMobile::Utils::Matrix;
is($m->dump,"","Check default matrix 0x0");

$m = new RadioMobile::Utils::Matrix(rowsSize => 3, colsSize => 4);
$res = "| 0 | 0 | 0 | 0 |\n| 0 | 0 | 0 | 0 |\n| 0 | 0 | 0 | 0 |\n";
is($m->dump,$res,"Check empty matrix 3x4");

$m->at(1,3,"Hello");
$res = "| 0 | 0 | 0 | 0 |\n| 0 | 0 | 0 | Hello |\n| 0 | 0 | 0 | 0 |\n";
is($m->dump,$res,"Set a single item");

$m->at(6,4,"olleH");
$res = "| 0 | 0 | 0 | 0 | 0 |\n| 0 | 0 | 0 | Hello " .
"| 0 |\n| 0 | 0 | 0 | 0 | 0 |\n| 0 | 0 | 0 | 0 | 0 " .
"|\n| 0 | 0 | 0 | 0 | 0 |\n| 0 | 0 | 0 | 0 | 0 |\n|" .
" 0 | 0 | 0 | 0 | olleH |\n";
is($m->dump,$res,"Set a single item increasing rows and cols automatically");

$m = new RadioMobile::Utils::Matrix(rowsSize => 2, colsSize => 3);
$m->addRow(1,2,3);
$res = "| 0 | 0 | 0 |\n" .
"| 0 | 0 | 0 |\n" .
"| 1 | 2 | 3 |\n";
is($m->dump,$res,"Add Row");

$m->addRow(1,2,3,4);
$res = "| 0 | 0 | 0 | 0 |\n" .
"| 0 | 0 | 0 | 0 |\n" .
"| 1 | 2 | 3 | 0 |\n" .
"| 1 | 2 | 3 | 4 |\n";
is($m->dump,$res,"Add Row and increase cols automatically");

$m->setRow(0,-1,-2,-3);
$res = "| -1 | -2 | -3 | 0 |\n" .
"| 0 | 0 | 0 | 0 |\n" .
"| 1 | 2 | 3 | 0 |\n" .
"| 1 | 2 | 3 | 4 |\n";
is($m->dump,$res,"Set Row and with few elements");


$m = new RadioMobile::Utils::Matrix(rowsSize => 2, colsSize => 3);
$m->setCol(1,1,2,3);
$res = "| 0 | 1 | 0 |\n" . 
"| 0 | 2 | 0 |\n" . 
"| 0 | 3 | 0 |\n" ;
is($m->dump,$res,"Set col and increase row");

$m->addCol(4,5,6);
$res = "| 0 | 1 | 0 | 4 |\n" .
"| 0 | 2 | 0 | 5 |\n" .
"| 0 | 3 | 0 | 6 |\n";
is($m->dump,$res,"Add col");

$m->addCol(4,5,6,7);
$res = "| 0 | 1 | 0 | 4 | 4 |\n" .
"| 0 | 2 | 0 | 5 | 5 |\n" .
"| 0 | 3 | 0 | 6 | 6 |\n" .
"| 0 | 0 | 0 | 0 | 7 |\n";
is($m->dump,$res,"Add col and increase row");

my @row = $m->getRow(1);
is($row[1],2, "Extract row");

my @col = $m->getCol(3);
is($col[1],5, "Extract col");


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

