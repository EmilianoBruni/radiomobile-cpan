package RadioMobile::Header;

use 5.010000;
use strict;
use warnings;

use Class::Struct;
use File::Binary;

# HEADER STRUCTURE - Len 10 bytes
# VERSION 			([f] single-precision float - VB Single type - 4 bytes), 
# NETWORK ELEMENTS 	([s] signed short - VB Integer type - 2 bytes),
# UNIT ELEMENTS 	([s] signed short - VB Integer type - 2 bytes),
# SYSTEM ELEMENTS 	([s] signed short - VB Integer type - 2 bytes),

use constant LEN	=> 10;
use constant PACK	=> 'fsss';
use constant ITEMS	=> qw/version networkCount unitCount systemCount/;

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
