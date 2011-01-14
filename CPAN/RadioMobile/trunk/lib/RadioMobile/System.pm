package RadioMobile::System;

use 5.010000;
use strict;
use warnings;

use Class::Struct;
use File::Binary;

# SYSTEM STRUCTURE - Len 50 bytes
# TX                ([f] single-precision float - VB Single type - 4 bytes),
# RX                ([f] single-precision float - VB Single type - 4 bytes),
# LOSS              ([f] single-precision float - VB Single type - 4 bytes),
# ANT               ([f] single-precision float - VB Single type - 4 bytes),
# H                 ([f] single-precision float - VB Single type - 4 bytes),
# NAME              ([A] ASCII string - VB String*30 - 30 bytes),

use constant LEN	=> 50;
use constant PACK	=> 'fffffA30';
use constant ITEMS	=> qw/tx rx loss ant h name/;

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
