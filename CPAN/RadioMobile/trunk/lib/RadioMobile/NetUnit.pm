package RadioMobile::NetUnit;

use 5.010000;
use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

__PACKAGE__->valid_params(
							unit	=> { isa  => 'RadioMobile::Unit'},
							net	=> { isa  => 'RadioMobile::Net'},
);
__PACKAGE__->contained_objects(
	'unit'	=> 'RadioMobile::Unit',
	'net'	=> 'RadioMobile::Net',
);

use Class::MethodMaker [ scalar => [qw/unit net isIn role/] ];

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	$s->reset;
	return $s;
}

sub dump {
	my $s	= shift;
	return Data::Dumper::Dumper($s->dump_parameters);
}

sub reset {
	my $s	= shift;
	$s->isIn(0);
}

1;

__END__