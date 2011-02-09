package RadioMobile::Units;

use strict;
use warnings;

use Class::Container;
use base qw(Class::Container Array::AsObject);

use File::Binary;

use RadioMobile::Unit;

our $VERSION    = '0.01';

sub parse {
	my $s	 	= shift;
	my $f	  	= $s->container->bfile;
	my $len		= $s->container->header->unitCount;
	foreach (1..$len) {
		my $unit = new RadioMobile::Unit;
		$unit->parse($f);
		$s->push($unit);
	}
}

sub dump {
	my $s	= shift;
	my $ret	= "UNITS => [\n";
	foreach ($s->list) {
		$ret .= "\t" . $_->dump;
	}
	$ret .= "]\n";
	return $ret;
}

1;

__END__
