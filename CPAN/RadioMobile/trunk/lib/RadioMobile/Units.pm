package RadioMobile::Units;

use 5.010000;
use strict;
use warnings;

use base qw/Array::AsObject/;

use File::Binary;

use RadioMobile::Unit;

sub parse {
	my $s	 	= shift;
	my $f	  	= shift;
	my $len		= shift;

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
