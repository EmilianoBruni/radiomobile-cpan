package RadioMobile::Config;

use 5.010000;
use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

use RadioMobile::Config::StyleNetworksProperties;

__PACKAGE__->valid_params(
							stylenetworksproperties	=> { isa  =>
								'RadioMobile::Config::StyleNetworksProperties'},
);
__PACKAGE__->contained_objects(
	stylenetworksproperties => 'RadioMobile::Config::StyleNetworksProperties',
);

use Class::MethodMaker [ scalar => [qw/stylenetworksproperties/] ];

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	return $s;
}

sub dump {
	my $s	= shift;
	return Data::Dumper::Dumper($s) unless (@_);
	my $method = shift;
	my $ret = '';
	foreach (0..$s->rowsCount-1) {
		my @row 	= $s->rows->at($_)->list;
		my @func	= map {$_->$method} @row;
		$ret .= '| ' . join(' | ',@func) . " |\n";
	}
	return $ret;
}

1;
