package RadioMobile::Config;

use 5.010000;
use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

use File::Binary;

# This module parse/generate
# a block of configuration elements. It seems it's 23 bytes long
# but only first 4 bytes are used for Style Networks properties 
# (use two ray LOS, draw green, yello, red and bg line, etc.)
# This is its structure in bits
# b(1): Enabled (1) or disabled (0) "Draw a red line..."
# b(2..8): an unsigned short to draw yellow line if RX >= b(2..8) - 50
# b(9): Enabled (1) or disabled (0) "Draw a yellow line..."
# b(10..16): an unsigned short to draw yellow line if RX >= b(10..16) - 50
# b(17): Enabled (1) or disabled (0) "Draw a green line..."
# b(18..23): Not used
# b(24): Enabled (1) or disabled (0) "Draw lines with dark background"
# b(25..30: Not used
# b(31): Enabled (0) or disabled (1) "Use Two Rays..."
# b(32): Normal (0) or Interference (1) Two Ray Los
#my $res = hex($data[0]) & 0x80;
#print "Draw red: " . ($res >> 7), "\n";
#print "Yellow >=: " . ((hex($data[0]) & 0x7F) - 50),"\n";
#$res = hex($data[1]) & 0x80;
#print "Draw Yellow: " . ($res >> 7), "\n";
#print "Green >=: " . ((hex($data[1]) & 0x7F) - 50),"\n";
#print "Draw green: " . ((hex($data[2]) & 0x80) >> 7), "\n";
#print "Draw backg: " . (hex($data[2]) & 0x01), "\n";
#print "Two ray enabled: " . !((hex($data[3]) & 0x02) >> 1),"\n";
#print "Two ray normal: " . !(hex($data[3]) & 0x01),"\n";
#print "Two ray interfer: " . (hex($data[3]) & 0x01),"\n";

use constant LEN	=> 23;
use constant PACK	=> 'H2H2H2H2';
use constant ITEMS	=> qw/drawRed rxYellow drawYellow rxGreen drawGreen drawBg twoRay twoRayType/;

__PACKAGE__->valid_params ( map {$_ => {type => SCALAR, default => 1}} (ITEMS));
use Class::MethodMaker [scalar => [ITEMS]];

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	# only twoRayType, rxGreen, rxYellow defaults are wrong
	$s->rxYellow(-3);
	$s->rxGreen(3);
	$s->twoRayType("normal");
	return $s;
}

sub parse {
	my $s		= shift;
	my $f	  	= shift;
	my @struct 	= unpack(PACK,$f->get_bytes(LEN));

	$s->drawRed((hex($struct[0]) & 0x80) >> 7);
	$s->rxYellow((hex($struct[0]) & 0x7F) - 50);
	$s->drawYellow((hex($struct[1]) & 0x80) >> 7);
	$s->rxGreen((hex($struct[1]) & 0x7F) - 50);
	$s->drawGreen((hex($struct[2]) & 0x80) >> 7);
	$s->drawBg(hex($struct[2]) & 0x01);
	$s->twoRay(!((hex($struct[3]) & 0x02) >> 1));
	$s->twoRayType((hex($struct[3]) & 0x01) ? 'interference' : 'normal');
}

1;

__END__
