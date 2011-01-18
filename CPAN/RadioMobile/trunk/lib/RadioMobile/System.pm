package RadioMobile::System;

use 5.010000;
use strict;
use warnings;

use Data::Dumper;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

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

__PACKAGE__->valid_params ( map {$_ => {type => SCALAR, default => 1}} (ITEMS));
use Class::MethodMaker [scalar => [ITEMS]];

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	return $s;
}

sub parse {
	my $s		= shift;
	my $f	  	= shift;
	my @struct 	= unpack(PACK,$f->get_bytes(LEN));
	map {$s->{(ITEMS)[$_]} = $struct[$_]} (0..(ITEMS)-1);
}

sub dump {
	my $s	= shift;
	return Data::Dumper::Dumper($s->dump_parameters);
}

sub reset {
	my $s	= shift;
	my $index = shift;
	$s->tx(10);
	$s->h(2);
	$s->rx(-107);
	$s->loss(0.5);
	$s->ant(2);
	$s->name(sprintf('System%4.4s', $index));
}

1;

__END__
