package RadioMobile::UnitIconParser;

use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

__PACKAGE__->valid_params( parent => { isa  => 'Class::Container'} ) ;
use Class::MethodMaker [ scalar => [qw/parent/] ];

=head1 NAME

RadioMobile::UnitsIconParser

=head1 DESCRIPTION

This module parse the icon of every unit index base-0
It update the RadioMobile::Unit in RadioMobile::Units.

=head1 METHODS

=head2 new()

=cut

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	return $s;
}

=head2 parse()

=cut

sub parse {
	my $s = shift;
	my $f = $s->parent->bfile;
	my $l = $s->parent->header->unitCount;
	my $u = $s->parent->units;

	$b = $f->get_bytes($l);
	my @unitIcon = unpack('c' x $l,$b);

	foreach (0..$l-1) {
		$u->at($_)->icon($unitIcon[$_]);
	}
}


1;

__END__
