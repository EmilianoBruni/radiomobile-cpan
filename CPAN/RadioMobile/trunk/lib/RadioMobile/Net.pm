package RadioMobile::Net;

use strict;
use warnings;

use Data::Dumper;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

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
							situation hops topology name unknown1/;


__PACKAGE__->valid_params ( map {$_ => {type => SCALAR, default => 1}} (ITEMS));
use Class::MethodMaker [scalar => [ITEMS]];

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	$s->unknown1('');
	return $s;
}

sub dump {
	my $s	= shift;
	return Data::Dumper::Dumper($s->dump_parameters);
}

sub parse {
	my $s		= shift;
	my $f	  	= shift;
	my @struct 	= unpack(PACK,$f->get_bytes(LEN));
	map {$s->{(ITEMS)[$_]} = $struct[$_]} (0..(ITEMS)-1);
}

sub reset {
	my $s	= shift;
	my $index = shift;
	my %def	  = (
					'minfx' => '144',
					'location' => '50',
					'situation' => '70',
					'maxfx' => '148',
					'time' => '50',
					'topology' => 256,
					'eps' => '15',
					'climate' => 5,
					'sgm' => '0.00499999988824129',
					'ens' => '301',
					'pol' => 1,
					'mdvar' => 0,
					'hops' => 0
				);
	while (my ($k,$v) = each %def) { $s->$k($v) }
	$s->name(sprintf('Net%3.3s', $index));
}
1;

__END__
