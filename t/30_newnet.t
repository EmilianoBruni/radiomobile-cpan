# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl RadioMobile.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';


use Test::More tests => 1; 
BEGIN { use_ok('RadioMobile') };

my $rm = new RadioMobile(debug => $ENV{'RM_DEBUG'} || 0);

# Add units

# via addNew
my $unit = $rm->units->addNew('Casa di Emiliano');
$unit->lat(32.452532);
$unit->lon(14.535235);
$unit->h(43.33);

#via new
$unit = new RadioMobile::Unit(name => 'Casa di Sugo', lat => 33.535, lon => 13, h => 300);
$rm->units->add($unit);

# Add systems

# via addNew
my $system = $rm->systems->addNew('3Sect120');
$system->rx(-89);
$system->tx(3.2);
$system->antenna('3sect120.ant');
$system->h(10);

#via new
$system = new RadioMobile::System(name => '1Sect120', rx => -89, tx => 3.2, h => 15, antenna => '1sect120.ant' );
$rm->systems->add($system);

# Add Nets

# via addNew
my $Net = $rm->nets->addNew('5Ghz');

#via new
#$system = new RadioMobile::System(name => '1Sect120', rx => -89, tx => 3.2, h => 15, antenna => '1sect120.ant' );
#$rm->systems->add($system);

my $data = $rm->write;


use Data::Dumper;
print Data::Dumper::Dumper($rm);

open(DEBUG,'>./debug.net');

print DEBUG $data;

close(DEBUG);

