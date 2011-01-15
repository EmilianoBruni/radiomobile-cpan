package RadioMobile::Cov;

use 5.010000;
use strict;
use warnings;

use Class::Struct;
use File::Binary;

# COVERAGE STRUCTURE - Len 74 bytes
# DMAX				([f] single-precision float - VB Single type - 4 bytes),
# THMIN				([f] single-precision float - VB Single type - 4 bytes),
# THMAX				([f] single-precision float - VB Single type - 4 bytes),
# THINC				([f] single-precision float - VB Single type - 4 bytes),
# ANTAZT			([f] single-precision float - VB Single type - 4 bytes),
# FILE				([A] ASCII string - VB String*20 - 20 bytes),
# TRESHOLD			([s] signed short - VB Integer type - 2 bytes),
# LEVEL				([f] single-precision float - VB Single type - 4 bytes),
# AREA				([S] unsigned short - VB Boolean - 2 bytes, non credo bool)
# CAREA				([l] signed long - VB Integer type - 4 bytes),
# CONTOUR			([S] unsigned short - VB Boolean - 2 bytes)
# CCONTOUR			([l] signed long - VB Integer type - 4 bytes),
# VHS				([f] single-precision float - VB Single type - 4 bytes),
# VHT				([f] single-precision float - VB Single type - 4 bytes),
# DMIN				([f] single-precision float - VB Single type - 4 bytes),
# VCOL				([l] signed long - VB Integer type - 4 bytes),
use constant LEN	=> 74;
use constant PACK	=> 'fffffA20sfSlSlfffl';
use constant ITEMS	=> qw/dmax thmin thmax thinc antazt file treshold level
							area carea contour ccontour vhs vht dmin vcol/;

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