package RadioMobile::Config::LandHeightParser;

use 5.010000;
use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);


__PACKAGE__->valid_params( 
							bfile	=> {isa => 'File::Binary'},
							config	=> {isa => 'RadioMobile::Config'},
);

use Class::MethodMaker [scalar => [qw/bfile config/] ];

# This module parse map file path
sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	return $s;
}

sub parse {
	my $s		= shift;

	my $f	  	= $s->bfile;
	my $c		= $s->config;

	# leght of landheight.dat path
	my $l = unpack("s",$f->get_bytes(2));
	my $landheight = '';
	if ($l > 0) {
		$landheight = unpack("A$l",$f->get_bytes($l));
	} 
	$c->landheight($landheight);
}

1;

__END__
