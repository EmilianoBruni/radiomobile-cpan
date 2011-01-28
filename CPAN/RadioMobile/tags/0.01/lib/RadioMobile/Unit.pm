package RadioMobile::Unit;

use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

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
use constant ITEMS	=> qw/lon lat h enabled transparent forecolor 
							backcolor name icon unknown1/;

__PACKAGE__->valid_params ( map {$_ => {type => SCALAR, default => 1}} (ITEMS));
use Class::MethodMaker [scalar => [ITEMS]];

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	$s->icon(0);
	$s->unknown1(undef);
	return $s;
}

sub parse {
	my $s	 	= shift;
	my $f	  	= shift;
	my @struct 	= unpack(PACK,$f->get_bytes(LEN));
	map {$s->{(ITEMS)[$_]} = $struct[$_]} (0..(ITEMS)-1);
}

sub dump {
	my $s	= shift;
	return Data::Dumper::Dumper($s->dump_parameters);
}

1;

__END__
