package RadioMobile::Net;

use 5.010000;
use strict;
use warnings;

use Class::Struct;
use File::Binary;

# NET STRUCTURE - Len 72 bytes
# MINFX				([f] single-precision float - VB Single type - 4 bytes),
# MAXFX				([f] single-precision float - VB Single type - 4 bytes),
# POL				([s] signed short - VB Integer type - 2 bytes),
# EPS				([f] single-precision float - VB Single type - 4 bytes),
# SGM				([f] single-precision float - VB Single type - 4 bytes),
# ENS				([f] single-precision float - VB Single type - 4 bytes),
# CLIMATE			([s] signed short - VB Integer type - 2 bytes),
# MDVAR				([s] signed short - VB Integer type - 2 bytes),
# TIME				([f] single-precision float - VB Single type - 4 bytes),
# LOCATION			([f] single-precision float - VB Single type - 4 bytes),
# SITUATION			([f] single-precision float - VB Single type - 4 bytes),
# HOPS				([s] signed short - VB Integer type - 2 bytes),
# TOPOLOGY			([s] signed short - VB Integer type - 2 bytes),
# NAME				([A] ASCII string - VB String*30 - 30 bytes),

use constant LEN	=> 72;
use constant PACK	=> 'ffsfffssfffssA30';
use constant ITEMS	=> qw/minfx maxfx pol eps sgm ens climate mdvar time location
							situation hops topology name/;

struct( map {$_ => '$'} (ITEMS) );

sub parse {
	my $proto	= shift;
	my $f	  	= shift;
	my @struct 	= unpack(PACK,$f->get_bytes(LEN));
	my %params 	= map {(ITEMS)[$_] => $struct[$_]} (0..(ITEMS)-1);
	return $proto->new(%params);
}

1;

__END__
