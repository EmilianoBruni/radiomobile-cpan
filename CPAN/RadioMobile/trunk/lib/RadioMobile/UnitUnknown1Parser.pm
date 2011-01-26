package RadioMobile::UnitUnknown1Parser;

use 5.010000;
use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

__PACKAGE__->valid_params( parent => { isa  => 'Class::Container'} ) ;
use Class::MethodMaker [ scalar => [qw/parent/] ];

=head1 NAME

RadioMobile::UnitUnknown1Parser

=head1 DESCRIPTION

This module parse an unknown structure of 2 byte for every units 
after azimut antenas
It updates the RadioMobile::Unit in RadioMobile::Units

=head1 METHODS

=head2 new()

=cut

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	return $s;
}

=head2 parse()

Supposing single items (2 bytes) of unit informations

=cut

sub parse {
	my $s = shift;
	my $f = $s->parent->bfile;
	my $o = $s->parent->units;

	my $b = $f->get_bytes(2);
	my $l = unpack("s",$b);

	$b = $f->get_bytes($l * 2);
	my @u = unpack("s" x $l,$b);

	foreach (0..$l-1) {
		$o->at($_)->unknown1($u[$_]);
	}
}

1;

__END__
