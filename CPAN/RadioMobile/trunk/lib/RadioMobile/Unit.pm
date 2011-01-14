package RadioMobile::Unit;

use 5.010000;
use strict;
use warnings;

use Class::Struct;
use File::Binary;
# UNIT STRUCTURE - Len 44 bytes
# LON               ([f] single-precision float - VB Single type - 4 bytes),
# LAT               ([f] single-precision float - VB Single type - 4 bytes),
# H                 ([f] single-precision float - VB Single type - 4 bytes),
# ENABLED           ([s] signed short - VB Integer type - 2 bytes),
# TRANSPARENT       ([s] signed short - VB Integer type - 2 bytes),
# FORECOLOR         ([l] signed long - VB Integer type - 4 bytes),
# BACKCOLOR         ([l] signed long - VB Integer type - 4 bytes),
# NAME              ([A] ASCII string - VB String*20 - 20 bytes),
use constant LEN	=> 44;
use constant PACK	=> 'fffssllA20';
use constant ITEMS	=> qw/lon lat h enabled transparent forecolor backcolor name/;

struct( map {$_ => '$'} (ITEMS) );

sub parse {
	my $proto 	= shift;
	my $f	  	= shift;
	my @struct 	= unpack(PACK,$f->get_bytes(LEN));
	my %params 	= map {(ITEMS)[$_] => $struct[$_]} (0..(ITEMS)-1);
	return $proto->new(%params);
}

1;

__END__
